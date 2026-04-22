open typed_ast

(* Type til string*)
let string_of_typ = function
  | TText    -> "Text"
  | TInt     -> "Int"
  | TBool    -> "Bool"
  | TCode    -> "Code"
  | TFile    -> "File"
  | TFloat   -> "Float"
  | TCustomType s -> s



(* Error handling*)
exception Type_error of location option * string
let error ?location msg = raise (Type_error (location, msg))

let unbound_var           ?location x     = error ?location ("Unbound variable: " ^ x)
let unbound_fun           ?location f     = error ?location ("Unbound function: " ^ f)
let unbound_type          ?location t     = error ?location ("Unbound type: " ^ t)
let unbound_resource      ?location r     = error ?location ("Unbound resource: " ^ r)
let unbound_field         ?location s f   = error ?location ("Unbound field: Type " ^ s ^ " has no field " ^ f)
let resource_required     ?location f     = error ?location ("Resource required: Call to " ^ f ^ " requires a resource")
let duplicate_declaration ?location f     = error ?location ("Duplicate declaration: " ^ f ^ " is already declared")

let bad_arity ?location f expected got =
  error ?location ("Bad arity: function " ^ f ^ " expects " ^
              string_of_int expected ^ " arguments, got " ^
              string_of_int got)

let type_mismatch ?location t1 t2 =
  error ?location ("Type mismatch: expected " ^ string_of_typ t2 ^
              ", got " ^ string_of_typ t1)

(* Environment setup *)
let function_env: (name, func_declaration) Hashtbl.t = Hashtbl.create 8
let resource_env: (name, resource_declaration) Hashtbl.t = Hashtbl.create 8
let custom_type_env: (name, custom_type_declaration) Hashtbl.t = Hashtbl.create 8
let variable_env: (name, typ) Hashtbl.t = Hashtbl.create 8

let add_new_func (ident: Ast.name) (func: Ast.func_declaration) = 
  if (Hashtbl.mem function_env ident) then
    duplicate_declaration(ident)
  else Hashtbl.add function_env ident func;

let check_subtype = match t1, t2 with
| TCode, TText -> true
| t1, t2 -> t1 = t2

let check_binop op type1 type2 = match op, type1, type2 with
  | Concat, TText, TText -> TText
  | Concat, TCode, TText -> TText
  | Concat, TText, TCode -> TText
  | Concat, TCode, TCode -> TText
  | _, TInt,   TInt   -> TInt
  | _, TFloat, TFloat -> TFloat
  | _, TFloat, TInt   -> TFloat
  | _, TInt,   TFloat -> TFloat
  | Concat, _, _ -> error ("Concat requires Text operands")
  | _, t1, t2    -> error ("Arithmetic requires numeric operands, got " ^
                     string_of_typ t1 ^ " and " ^ string_of_typ t2)

let rec expr (delta : custom_type_env) (gamma : variable_env) untyped_expr =
  let typed_expr, typ = expr_node delta gamma untyped_expr.expr_node in
  {expr_node = typed_expr; expr_typ = typ}

and expr_node (delta : custom_type_env) (gamma : variable_env) = function
(* EVar *)
  | EVar x ->
      let ty = match Hashtbl.find_opt gamma x with
        | Some t -> t
        | None   -> unbound_var x
      in
      EVar x, ty

(* EConst *)
  | ast.EConst(ast.CText, e) ->
    EConst e, TText
  | ast.EConst(ast.CInt, e) ->
    EConst e, TInt
  | ast.EConst(ast.CFloat, e) ->
    EConst e, TFloat
  | ast.EConst(ast.CBool, e) ->
    EConst e, TBool
  | ast.EConst(ast.CCode, e) ->
    EConst e, TCode
  | ast.EConst(ast.CFile, e) ->
    EConst e, TFile
  | ast.EConst(ast.CCustomType, e) ->
    EConst e, TCustomType

(* ECall *)
  | ast.ECall (func_name, args, resource_optional) ->
    let decl = match Hashtbl.find_opt function_env func_name with
      | Some func_decl  -> func_decl
      | None            -> unbound_fun func_name
  in
      (* Tjekker for arity*)
  let expected_arguments = List.length decl.func_params in
  let receive_arguments = List.length args in
  if expected_arguments <> receive_arguments 
  then bad_arity func_name expected_arguments receive_arguments;
  (* Tjekker func args*)
  let typed_args = List.map2
    (fun (_, param_typ) arg ->
      let targ = expr delta gamma arg in
      check_subtype targ.expr_typ param_typ;
      targ)
    decl.func_params args
  in
      (* Tjekker resource*)
  let typed_resource = match decl.func_needsResource, resource_optional with
    | true, None    -> resource_required func_name
    | false, Some _ -> resource_not_needed func_name
    | false, None   -> None
    | true, Some r  ->
      (match Hashtbl.find_opt resource_env r with
        | Some res_decl -> Some res_decl
        | None          -> unbound_resource r)
    in
    ECall (func_name, typed_args, typed_resource), decl.func_return

(* EField *)
  | ast.EField (e, field_name) ->
    let typed_e = expr delta gamma e in
    let field_type = match typed_e.expr_typ with
      | TCustomType custom_name ->
        let decl = match Hashtbl.find_opt delta custom_name with
          | Some d -> d
          | None   -> unbound_type custom_name
        in
        (match List.assoc_opt field_name decl.type_fields with
          | Some t -> t
          | None   -> unbound_field custom_name field_name)
    in
    EField (typed_e, field_name, field_type), field_type
    
    
(* EBinOp *)
  | ast.EBinOp (op, e1, e2) ->
    let te1 = expr delta gamma e1 in
    let te2 = expr delta gamma e2 in
    let result_typ = check_binop op te1.expr_typ te2.expr_typ in
    EBinOp (op, te1, te2), result_typ

  






  

