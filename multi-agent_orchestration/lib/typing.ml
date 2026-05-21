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
let duplicate_declaration location name = error location ("Duplicate declaration: " ^ name ^ " is already declared")
let resource_not_needed location name = error location ("Resource not needed: " ^ name ^ " does not take a resource")
let invalid_function_body location = error location "Function body must contain statements and end with an assignment"
let bad_arity location func expected got = error location ("Bad arity: function " ^ func ^ " expects " ^ string_of_int expected ^ " arguments, got " ^ string_of_int got)
let type_mismatch location typ1 typ2 = error location ("Type mismatch: expected " ^ string_of_typ typ2 ^ ", got " ^ string_of_typ typ1)

(* Environment setup *)

type funcion_env = (name, func_declaration) Hashtbl.t
type resource_env = (name, resource_declaration) Hashtbl.t
type custom_type_env = (name, custom_type_declaration) Hashtbl.t
type variable_env = (name, typ) Hashtbl.t

let rec check_subtype (t1 : typ) (t2 : typ) : bool = match t1, t2 with
| TCode, TText -> true
| t1, t2 -> t1 = t2

and check_program (program : Ast.program) : program =
  let alpha: funcion_env  = Hashtbl.create 8 in
  let beta: resource_env = Hashtbl.create 8 in
  let delta: custom_type_env = Hashtbl.create 8 in
  let gamma: variable_env = Hashtbl.create 8 in

  let typed_decls = List.map (fun decl -> check_declaration decl delta gamma alpha beta) program.prog_decls in

  let typed_wf = check_workflow program.prog_workflow delta gamma alpha beta in

  { prog_decls    = typed_decls;
    prog_workflow = typed_wf }

and check_workflow (wf : Ast.workflow) delta gamma alpha beta =
  let typed_body = List.map (fun stmt -> check_statement stmt delta gamma alpha beta) wf.workflow_body in 
  {
    workflow_name = "workflow";
    workflow_params = [];
    workflow_body = typed_body;
  }

and check_declaration (decl : Ast.declaration) delta gamma alpha beta : declaration = 
    match decl with
    | Ast.DFunc func -> check_func_declaration func delta gamma alpha beta
     
    | Ast.DResource r ->
      if Hashtbl.mem beta r.resource_name then duplicate_declaration r.resource_location r.resource_name;
      let typed_r = {
        resource_name     = r.resource_name;
        resource_provider = convert_provider r.resource_provider;
        resource_model    = r.resource_model;
        max_tokens        = r.max_tokens;
        system_prompt     = r.system_prompt;
      } in
      Hashtbl.add beta r.resource_name typed_r;
      DResource typed_r 

    | Ast.DCustomType ct ->
      if Hashtbl.mem delta ct.type_name then
        duplicate_declaration ct.type_location ct.type_name;
        
      let typed_fields = List.map (fun (name, typ) -> (name, (convert_type typ delta ct.type_location))) ct.type_fields in

      let typed_ct = {
        type_name     = ct.type_name;
        type_fields   = typed_fields;
      } in
      Hashtbl.add delta ct.type_name typed_ct;
      DCustomType typed_ct

and convert_provider (provider: Ast.provider) =
  match provider with
  | Ast.Anthropic -> Anthropic
  | Ast.OpenAI -> OpenAI
  | Ast.Grok -> Grok
  | Ast.Gemini -> Gemini

and check_func_declaration (func: Ast.func_declaration) delta gamma alpha beta = 
  if Hashtbl.mem alpha func.func_name then
          duplicate_declaration func.func_location func.func_name;
        let typed_params = List.map (fun (name, param) -> (name, convert_type param delta func.func_location)) func.func_params in
        let typed_return = convert_type func.func_return delta func.func_location in
        let typed_prompt =
          if func.func_needs_resource then
            check_prompt_holes func delta gamma alpha beta
          else
            []
        in
        let typed_body =
          if func.func_needs_resource then
            []
          else
            check_function_body func typed_params typed_return delta alpha beta
        in

        let typed_f = {
          func_name          = func.func_name;
          func_params        = typed_params;
          func_return        = typed_return;
          func_needs_resource = func.func_needs_resource;
          func_prompt        = typed_prompt;
          func_body          = typed_body;
        } in
        Hashtbl.add alpha func.func_name typed_f;
        DFunc typed_f

and check_function_body (func : Ast.func_declaration) typed_params typed_return delta alpha beta : statement list =
  let gamma_local : variable_env = Hashtbl.create (List.length typed_params) in
  List.iter (fun (p, t) -> Hashtbl.add gamma_local p t) typed_params;
  let typed_body = List.map (fun stmt -> check_statement stmt delta gamma_local alpha beta) func.func_body in
  match List.rev typed_body with
  | SLet (_, last_typ, _) :: _ ->
      if not (check_subtype last_typ typed_return) then
        type_mismatch func.func_location last_typ typed_return;
      typed_body
  | _ -> invalid_function_body func.func_location



and expr_with_expected_type (untyped_expr : Ast.expr) (expected: typ option) 
    delta gamma alpha beta : expr =
  let typed = check_expr untyped_expr delta gamma alpha beta in
  match expected, typed.expr_typ with
  | Some TCode, TText ->
      { expr_node = typed.expr_node; expr_typ = TCode }
  | _ -> typed

and check_expr (untyped_expr : Ast.expr) delta gamma alpha beta : expr =
  let typed_expr, typ = check_expr_node untyped_expr.expr_node untyped_expr.expr_location delta gamma alpha beta in
  { expr_node = typed_expr; 
    expr_typ = typ }


and check_expr_node (node : Ast.expr_node) (location: Ast.location) delta gamma alpha beta : expr_node * typ = 
  match node with
  | Ast.EVar x -> check_variable x location delta gamma alpha beta
  | Ast.EConst c -> check_constant c delta location
  | Ast.ECall (func_name, args, resource_optional) -> check_func_call func_name args resource_optional delta gamma alpha beta location
  | Ast.EField (e, field_name) -> check_field e field_name location delta gamma alpha beta
  | Ast.EBinOp (opperand, e1, e2) -> check_binop opperand e1 e2 location delta gamma alpha beta
  | Ast.EReadFile path_expr ->
    let typed_path = check_expr path_expr delta gamma alpha beta in
    if not (check_subtype typed_path.expr_typ TText) then
      type_mismatch location typed_path.expr_typ TText;
    EReadFile typed_path, TText

and check_constant (const: Ast.constant) delta (location: Ast.location) : expr_node * typ = 
  let const, typ = match const with
      | Ast.CText text            -> CText text, TText
      | Ast.CInt   int            -> CInt int, TInt
      | Ast.CFloat float          -> CFloat float, TFloat
      | Ast.CBool  bool           -> CBool bool, TBool
      | Ast.CCode  code           -> CCode code, TCode
      | Ast.CFile  file           -> CFile file, TFile
      | Ast.CCustomType name   ->
          if Hashtbl.mem delta name then
            CCustomType name, TCustomType name
          else unbound_type location name
    in
    EConst const, typ

and check_variable (x: name) (location: Ast.location) delta gamma alpha beta: expr_node * typ =
  let ty = match Hashtbl.find_opt gamma x with
      | Some t -> t
      | None -> unbound_var location x
    in
    EVar x, ty

and check_field (e: Ast.expr) (field_name: name) (location: Ast.location) delta gamma alpha beta : expr_node * typ= 
  let expr = check_expr e delta gamma alpha beta in

  let field_type = match expr.expr_typ with
  | TCustomType typ ->
      let declaration = Hashtbl.find delta typ in
      (match List.assoc_opt field_name declaration.type_fields with
        | Some t -> t
        | None -> unbound_field location typ field_name)
  | _ -> error location "field access on non-object type"
  in
  EField (expr, field_name, field_type), field_type

and check_func_call (func_name: Ast.name) (args: Ast.expr list) (resource_optional: name option) delta gamma alpha beta (location: Ast.location) =
  let decl = match Hashtbl.find_opt alpha func_name with
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
      let targ = expr_with_expected_type arg (Some param_typ) delta gamma alpha beta in
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
      (match Hashtbl.find_opt beta resource with
        | Some res_decl -> Some res_decl
        | None          -> unbound_resource location resource);
    in
    ECall (func_name, typed_args, resource_optional), decl.func_return

and check_binop (opperand : Ast.binop) (expr_1 : Ast.expr) (expr_2 : Ast.expr) (location: Ast.location) delta gamma alpha beta : expr_node * typ = 
    let typed_expr_1 = check_expr expr_1 delta gamma alpha beta in
    let typed_expr_2 = check_expr expr_2 delta gamma alpha beta in

    let t_opperand = match opperand with
    | Ast.Add -> Add
    | Ast.Mul -> Mul
    | Ast.Div -> Div
    | Ast.Sub -> Sub
    in

  let result_typ = 
  match opperand, typed_expr_1.expr_typ, typed_expr_2.expr_typ with
  | Add, TText, TText -> TText
  | Add, TCode, TText -> TText
  | Add, TText, TCode -> TText
  | Add, TCode, TCode -> TText
  | _, TInt,   TInt   -> TInt
  | _, TFloat, TFloat -> TFloat
  | _, TFloat, TInt   -> TFloat
  | _, TInt,   TFloat -> TFloat
  | _, typ1, typ2    -> error location ("Arithmetic requires compatible operands, got " ^
                     string_of_typ typ1 ^ " and " ^ string_of_typ typ2) in
    EBinOp (t_opperand, typed_expr_1, typed_expr_2), result_typ
  
and check_statement (statement: Ast.statement) delta gamma alpha beta : statement =
  check_statement_node statement.statement_node statement.statement_location delta gamma alpha beta

and check_statement_node (node: Ast.statement_node) (location: Ast.location) delta gamma alpha beta : statement= 
  match node with
  | Ast.SLet (x, e) ->
    let typed_e = check_expr e delta gamma alpha beta in
    Hashtbl.replace gamma x typed_e.expr_typ;
    SLet (x, typed_e.expr_typ, typed_e)

  | Ast.SPrint e ->
    let typed_e = check_expr e delta gamma alpha beta in
    SPrint typed_e

  | Ast.SWriteFile (path_expr, content_expr) ->
    let typed_path = check_expr path_expr delta gamma alpha beta in
    let typed_content = check_expr content_expr delta gamma alpha beta in
    if not (check_subtype typed_path.expr_typ TFile) then
      type_mismatch location typed_path.expr_typ TFile;
    if not (check_subtype typed_content.expr_typ TText) then
      type_mismatch location typed_content.expr_typ TText;
    SWriteFile (typed_path, typed_content)
  | Ast.SWhile (e, stmt_list) ->
    let typed_e = check_expr e delta gamma alpha beta in
    let typed_stmt_list = List.map (fun stmt -> check_statement stmt delta gamma alpha beta) stmt_list in
    SWhile (typed_e, typed_stmt_list)



and check_prompt_holes (func : Ast.func_declaration) delta gamma alpha beta: prompt_part list =
  let gamma_local : variable_env = Hashtbl.create (List.length func.func_params) in

  List.iter (fun (p, t) -> Hashtbl.add gamma_local p (convert_type t delta func.func_location)) func.func_params;
  List.map (function
    | Ast.PromptText s -> PromptText s

    | Ast.PromptHole e -> 
       let expected = match e.expr_node with
          | Ast.EVar name -> Hashtbl.find_opt gamma_local name
          | _ -> None
        in
        PromptHole (expr_with_expected_type e expected delta gamma_local alpha beta))
    func.func_prompt

and convert_type (typ : Ast.typ) delta location: typ  = 
  match typ with 
  | Ast.TText -> TText
  | Ast.TBool -> TBool
  | Ast.TCustomType n -> if (Hashtbl.mem delta n) then TCustomType n else unbound_type location n
  | Ast.TCode -> TCode
  | Ast.TInt -> TInt
  | Ast.TFloat -> TFloat
  | Ast.TFile -> TFile
