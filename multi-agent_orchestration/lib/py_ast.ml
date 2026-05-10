(** py_ast.ml — Python AST nodes for mAI codegen *)

type py_expr =
  | PyName      of string                              (* x, _client_Sonnet *)
  | PyConst     of py_constant                         (* 42, "hello", True *)
  | PyCall      of py_expr * py_expr list * (string * py_expr) list   (* f(args, key=val) *)
  | PyAttr      of py_expr * string                    (* response.content *)
  | PyBinOp     of py_binop * py_expr * py_expr        (* x + y *)
  | PySubscript of py_expr * py_expr                   (* x[0] *)
  | PyFString   of string * (string * py_expr) list    (* f"hello {name}" *)

and py_constant =
  | PyInt    of int
  | PyFloat  of float
  | PyBool   of bool
  | PyString of string
  | PyNone

and py_binop = PyAdd | PySub | PyMul | PyDiv | PyConcat

type py_statement =
  | PyAssign     of string * py_expr                        (* x = expr *)
  | PyExpr       of py_expr                                 (* print(x) *)
  | PyReturn     of py_expr                                 (* return x *)
  | PyFuncDef    of string * string list * string list * py_statement list                                                            (* def f(args, *, kwargs): body *)
  | PyImport     of string                                  (* import anthropic *)
  | PyImportFrom of string * string list                    (* from pydantic import BaseModel *)
  | PyClassDef   of string * string * (string * string) list  
                                                            (* class Verdict(BaseModel): fields *)

type py_module = {
  imports : py_statement list;   (* all imports at top *)
  body    : py_statement list;   (* rest of the code *)
}