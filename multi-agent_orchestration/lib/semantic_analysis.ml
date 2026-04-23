open Ast

exception Semantic_error of location * string
let error location msg = raise (Semantic_error (location, msg))

let unbound_var location x = error location ("Unbound variable: " ^ x)
let unbound_fun location f = error location ("Unbound function: " ^ f)
let unbound_resource location r = error location ("Unbound resource: " ^ r)
let unbound_custom_type location r = error location ("Unbound unbound_custom_type: " ^ r)
let unbound_field location s f = error location ("Unbound field: Type " ^ s ^ " has no field " ^ f)
let resource_required location f = error location ("Resource required: Call to " ^ f ^ " requires a resource")
let duplicate_declaration location f = error location ("Duplicate declaration: " ^ f ^ " is already declared")

let function_env: (name, func_declaration) Hashtbl.t = Hashtbl.create 8
let resource_env: (name, resource_declaration) Hashtbl.t = Hashtbl.create 8
let custom_type_env: (name, custom_type_declaration) Hashtbl.t = Hashtbl.create 8
let variable_env: (name, typ) Hashtbl.t = Hashtbl.create 8



let rec check_expr expr = check_expr_node expr.expr_node expr.expr_location

and check_expr_node (expr_node: expr_node) (location: location) =
  match expr_node with
  | EVar var_name -> 
      if (not (Hashtbl.mem variable_env var_name) && not (Hashtbl.mem custom_type_env var_name))
         then unbound_var location var_name;
  | ECall (func_name, args, resource) -> 
      check_func_call func_name args resource location
  | EBinOp (binop, e1, e2) -> 
      check_expr e1; check_expr e2;
  | _ -> () 


and check_func_call (func_name: name) (args: expr list) (resource: name) (location: location) =
  try
    List.iter (fun expr -> check_expr expr ) args; (* Check each argument expression *)

    let func_declaration = Hashtbl.find function_env func_name in
    (* Check if the number of arguments matches the number of parameters *)
    if List.length args <> List.length func_declaration.func_params then
      error location ("Argument count mismatch: Function " ^ func_name )
  with 
    | Not_found -> unbound_fun location func_name
    | Invalid_argument error_message -> unbound_fun location func_name

and check_statement (stmt: statement) = 
  check_statement_node stmt.statement_node stmt.statement_location
  
and check_statement_node (statement_node: statement_node) (location: Ast.location) =
  match statement_node with
  | SLet (name, expr) -> 
    if (Hashtbl.mem variable_env name) then duplicate_declaration location name;
    check_expr expr;
  | SPrint expr -> check_expr expr
  | SWriteFile (expr_1, expr_2) -> check_expr expr_1; check_expr expr_2;
  | SReadFile (expr) -> check_expr expr

and add_new_func (ident: name) (func: func_declaration) (location: location) = 
  if (Hashtbl.mem function_env ident) then
    duplicate_declaration location ident
  else Hashtbl.add function_env ident func;;