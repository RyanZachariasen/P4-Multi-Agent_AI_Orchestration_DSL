open Ast

(* Type til string*)
let string_of_typ = function
  | TText    -> "Text"
  | TInt     -> "Int"
  | TBool    -> "Bool"
  | TCode    -> "Code"
  | TFile    -> "File"
  | TFloat   -> "Float"
  | TCustomType s -> s



(* Error handling - mangler måske noget der sikrer uniqueness?*)
exception Type_error of location option * string
let error ?location msg = raise (Type_error (location, msg))

let unbound_var           ?location x     = error ?location ("Unbound variable: " ^ x)
let unbound_fun           ?location f     = error ?location ("Unbound function: " ^ f)
let unbound_type          ?location t     = error ?location ("Unbound type: " ^ t)
let unbound_resource      ?location r     = error ?location ("Unbound resource: " ^ r)
let unbound_field         ?location s f   = error ?location ("Unbound field: Type " ^ s ^ " has no field " ^ f)
let resource_required     ?location f     = error ?location ("Resource required: Call to " ^ f ^ " requires a resource")
let duplicate_declaration ?location f     = error ?location ("Resource required: Call to " ^ f ^ " requires a resource")

let bad_arity ?location f expected got =
  error ?location ("Bad arity: function " ^ f ^ " expects " ^
              string_of_int expected ^ " arguments, got " ^
              string_of_int got)

let type_mismatch ?location t1 t2 =
  error ?location ("Type mismatch: expected " ^ string_of_typ t2 ^
              ", got " ^ string_of_typ t1)

(* Environment setup - Måske ændre til at bruge Maps i stedet for Hash tables*)
let function_env: (name, func_declaration) Hashtbl.t = Hashtbl.create 8
let resource_env: (name, resource_declaration) Hashtbl.t = Hashtbl.create 8
let type_env: (name, custom_type_declaration) Hashtbl.t = Hashtbl.create 8
let variable_env: (name, constant) Hashtbl.t = Hashtbl.create 8

let add_new_func (ident: Ast.name) (func: Ast.func_declaration) = 
  if (Hashtbl.mem function_env ident) then
    duplicate_declaration(ident)
  else Hashtbl.add function_env ident func;


