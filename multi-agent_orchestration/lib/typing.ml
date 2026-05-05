open Typed_ast

(* Type til string*)
let string_of_typ (t : typ) : string = match t with
  | TText    -> "Text"
  | TInt     -> "Int"
  | TBool    -> "Bool"
  | TCode    -> "Code"
  | TFile    -> "File"
  | TFloat   -> "Float"
  | TCustomType s -> s

(* Error handling*)
exception Type_error of Ast.location * string
let error location msg = raise (Type_error (location, msg))

let unbound_var location x = error location ("Unbound variable: " ^ x)
let unbound_func location func = error location ("Unbound function: " ^ func)
let unbound_type location typ = error location ("Unbound type: " ^ typ)
let unbound_resource location resource = error location ("Unbound resource: " ^ resource)
let unbound_field location typ field = error location ("Unbound field: Type " ^ typ ^ " has no field " ^ field)
let resource_required location func = error location ("Resource required: Call to " ^ func ^ " requires a resource")
let duplicate_declaration location f = error location ("Duplicate declaration: " ^ f ^ " is already declared")
let resource_not_needed location f = error location ("Resource not needed: " ^ f ^ " does not take a resource")
let bad_arity location func expected got = error location ("Bad arity: function " ^ func ^ " expects " ^ string_of_int expected ^ " arguments, got " ^ string_of_int got)
let type_mismatch location typ1 typ2 = error location ("Type mismatch: expected " ^ string_of_typ typ2 ^ ", got " ^ string_of_typ typ1)

(* Environment setup *)
let function_env: (name, func_declaration) Hashtbl.t = Hashtbl.create 8
let resource_env: (name, resource_declaration) Hashtbl.t = Hashtbl.create 8
let custom_type_env: (name, custom_type_declaration) Hashtbl.t = Hashtbl.create 8
let variable_env: (name, typ) Hashtbl.t = Hashtbl.create 8

let check_subtype (t1 : typ) (t2 : typ) : bool = match t1, t2 with
| TCode, TText -> true
| t1, t2 -> t1 = t2

let rec expr delta gamma (untyped_expr : Ast.expr) : expr =
  let typed_expr, typ = check_expr_node delta gamma untyped_expr.expr_node untyped_expr.expr_location in
  { expr_node = typed_expr; 
    expr_typ = typ }

and check_field (e: Ast.expr) (field_name: name) delta gamma (location: Ast.location) : expr_node * typ= 
  let custom_type = expr delta gamma e in
  let field_type = match custom_type.expr_node with
  | EConst CCustomType name ->
      let declaration = Hashtbl.find custom_type_env name in
      (match List.assoc_opt field_name declaration.type_fields with
        | Some typ -> typ
        | None   -> unbound_field location name field_name)
  | _ -> error location "error accessing field"
  in

  EField (custom_type, field_name, field_type), field_type
and check_expr_node delta gamma (node : Ast.expr_node) (location: Ast.location) : expr_node * typ = 
  match node with
  | Ast.EVar x -> check_variable x gamma location
  | Ast.EConst c -> check_constant c delta location
  | Ast.ECall (func_name, args, resource_optional) -> check_func_call func_name args resource_optional delta gamma location
  | Ast.EField (e, field_name) -> check_field e field_name delta gamma location
    
    
(* EBinOp *)
  | Ast.EBinOp (op, e1, e2) ->
    let te1 = expr delta gamma e1 in
    let te2 = expr delta gamma e2 in
    let result_typ = check_binop op te1.expr_typ te2.expr_typ in
    EBinOp (op, te1, te2), result_typ

and check_constant (const: Ast.constant) delta (location: Ast.location) : expr_node * typ = 
  let const, typ = match const with
      | Ast.CText  text           -> CText text, TText
      | Ast.CInt   int           -> CInt int, TInt
      | Ast.CFloat float           -> CFloat float, TFloat
      | Ast.CBool  bool           -> CBool bool, TBool
      | Ast.CCode  code           -> CCode code, TCode
      | Ast.CFile  file           -> CFile file, TFile
      | Ast.CCustomType name   ->
          if Hashtbl.mem delta name then
            CCustomType name, TCustomType name
          else unbound_type location name
    in
    EConst const, typ
and check_variable (x: name) (gamma : (name, typ) Hashtbl.t) (location: Ast.location) : expr_node * typ =
  let ty = match Hashtbl.find_opt gamma x with
      | Some t -> t
      | None   -> unbound_var location x
    in
    EVar x, ty

and check_func_call (func_name: Ast.name) (args: Ast.expr list) (resource_optional: name option) delta gamma (location: Ast.location) =
  let decl = match Hashtbl.find_opt function_env func_name with
    | Some func_decl  -> func_decl
    | None -> unbound_func location func_name
  in
  (* Tjekker for arity*)
  let expected_arguments = List.length decl.func_params in
  let receive_arguments = List.length args in
  if expected_arguments <> receive_arguments then
     bad_arity location func_name expected_arguments receive_arguments;

  (* Tjekker func args*)
  let typed_args = List.map2
    (fun (_, param_typ) arg ->
      let targ = expr delta gamma arg in
      if not (check_subtype targ.expr_typ param_typ) then
        type_mismatch location targ.expr_typ param_typ;
      targ)
    decl.func_params args
  in
  (* Tjekker resource*)
  let _ = match decl.func_needs_resource, resource_optional with
    | true, None    -> resource_required location func_name
    | false, Some _ -> resource_not_needed location func_name
    | false, None   -> None
    | true, Some resource  ->
      (match Hashtbl.find_opt resource_env resource with
        | Some res_decl -> Some res_decl
        | None          -> unbound_resource location resource);
    in
    ECall (func_name, typed_args, resource_optional), decl.func_return

and check_binop (op : binop) (type1 : typ) (type2 : typ) (location: Ast.location) : typ = match op, type1, type2 with
  | Concat, TText, TText -> TText
  | Concat, TCode, TText -> TText
  | Concat, TText, TCode -> TText
  | Concat, TCode, TCode -> TText
  | _, TInt,   TInt   -> TInt
  | _, TFloat, TFloat -> TFloat
  | _, TFloat, TInt   -> TFloat
  | _, TInt,   TFloat -> TFloat
  | Concat, _, _ -> error location "Concat requires Text operands"
  | _, typ1, typ2    -> error location ("Arithmetic requires numeric operands, got " ^
                     string_of_typ typ1 ^ " and " ^ string_of_typ typ2)

and statement (delta) (gamma) (location: Ast.location)= function

  | Ast.SLet (x, e) ->
    let typed_e = expr delta gamma e in
    Hashtbl.replace gamma x typed_e.expr_typ;
    SLet (x, typed_e.expr_typ, typed_e)

  | Ast.SPrint e ->
    let typed_e = expr delta gamma e in
    SPrint typed_e

  | Ast.SWriteFile (path_expr, content_expr) ->
    let typed_path = expr delta gamma path_expr in
    let typed_content = expr delta gamma content_expr in
    if not (check_subtype typed_path.expr_typ TFile) then
      type_mismatch location typed_path.expr_typ TFile;
    if not (check_subtype typed_content.expr_typ TText) then
      type_mismatch location typed_content.expr_typ TText;
    SWriteFile (typed_path, typed_content)

  | Ast.SReadFile path_expr ->
    let typed_path = expr delta gamma path_expr in
    if not (check_subtype typed_path.expr_typ TFile) then
      type_mismatch location typed_path.expr_typ TFile;
    SReadFile typed_path

  
and check_prompt_holes delta (f : Ast.func_declaration) : prompt_part list =
  let gamma = Hashtbl.create (List.length f.func_params) in
  List.iter (fun (p, t) -> Hashtbl.add gamma p t) f.func_params;
  List.map (function
    | Ast.PromptText s -> PromptText s
    | Ast.PromptHole e -> PromptHole (expr delta gamma e))
    f.func_prompt

and convert_location (location: Ast.location) : Ast.location =
    {
      file = location.file;
      line = location.line;
      col = location.col;
    }

and check_declaration (decl : Ast.declaration) : declaration = match decl with
    | Ast.DFunc f ->
      if Hashtbl.mem function_env f.func_name then
        duplicate_declaration f.func_location f.func_name;
      let typed_prompt = check_prompt_holes custom_type_env f in
      
      let typed_f = {
        func_name          = f.func_name;
        func_params        = f.func_params;
        func_return        = f.func_return;
        func_needsResource = f.func_needs_resource;
        func_prompt        = f.func_prompt;
      } in
      Hashtbl.add function_env f.func_name typed_f;
      DFunc typed_f

    | Ast.DResource r ->
      if Hashtbl.mem resource_env r.resource_name then
        duplicate_declaration r.resource_name;
      let typed_r = {
        resource_name     = r.resource_name;
        resource_provider = r.resource_provider;
        resource_model    = r.resource_model;
        max_tokens        = r.max_tokens;
        system_prompt     = r.system_prompt;
        resource_location = r.resource_location;
      } in
      Hashtbl.add resource_env r.resource_name typed_r;
      DResource typed_r 

    | Ast.DCustomType ct ->
      if Hashtbl.mem custom_type_env ct.type_name then
        duplicate_declaration ct.type_name;
      let typed_ct = {
        type_name     = ct.type_name;
        type_fields   = ct.type_fields;
        type_location = ct.type_location;
      } in
      Hashtbl.add custom_type_env ct.type_name typed_ct;
      DCustomType typed_ct

and workflow delta gamma (wf : Ast.workflow) =
  let typed_body = List.map (statement delta gamma) wf.workflow_body in 
  {
    workflow_name = "workflow";
    workflow_params = [];
    workflow_body = typed_body;
    workflow_loc = wf.workflow_location;
  }

and check_program (p : Ast.program) : program =
  let typed_decls = List.map check_declaration p.prog_decls in
  let typed_wf = workflow custom_type_env variable_env p.prog_workflow in

  { prog_decls    = typed_decls;
    prog_workflow = typed_wf }