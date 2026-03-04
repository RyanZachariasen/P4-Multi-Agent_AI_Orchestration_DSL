(* Basic types for our multi-agent language *)
type ident = string

type expr =
  | Econst of int
  | Evar of ident
  | Ebinop of binop * expr * expr

and binop = Add | Sub | Mul | Div

type stmt =
  | Sassign of ident * expr
  | Sif of expr * stmt * stmt
  | Sblock of stmt list
  | Sspawn of ident (* Specific to your multi-agent theme *)

type file = stmt list