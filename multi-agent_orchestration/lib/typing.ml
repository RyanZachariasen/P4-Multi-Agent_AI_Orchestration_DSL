open Ast

(* Type til string*)
let string_of_typ = function
  | TText    -> "Text"
  | TInt     -> "Int"
  | TBool    -> "Bool"
  | TCode    -> "Code"
  | TFile    -> "File"
  | TFloat   -> "Float"
  | TNamed s -> s


(* Error handling - mangler måske noget der sikrer uniqueness?*)
exception Type_error of loc option * string
let error ?loc msg = raise (Type_error (loc, msg))

let unbound_var         ?loc x              = error ?loc ("Unbound variable: " ^ x)
let unbound_fun         ?loc f              = error ?loc ("Unbound function: " ^ f)
let unbound_type        ?loc t              = error ?loc ("Unbound type: " ^ t)
let unbound_resource    ?loc r              = error ?loc ("Unbound resource: " ^ r)
let unbound_field       ?loc s f            = error ?loc ("Unbound field: Type " ^ s ^ " has no field " ^ f)
let resource_required   ?loc f              = error ?loc ("Resource required: Call to " ^ f ^ " requires a resource")

let bad_arity ?loc f expected got =
  error ?loc ("Bad arity: function " ^ f ^ " expects " ^
              string_of_int expected ^ " arguments, got " ^
              string_of_int got)

let type_mismatch ?loc t1 t2 =
  error ?loc ("Type mismatch: expected " ^ string_of_typ t2 ^
              ", got " ^ string_of_typ t1)

(* Environment setup - Måske ændre til at bruge Maps i stedet for Hash tables*)
let function_env = Hashtbl.create 8
let resource_env = Hashtbl.create 8
let type_env     = Hashtbl.create 8
let variable_env = Hashtbl.create 8