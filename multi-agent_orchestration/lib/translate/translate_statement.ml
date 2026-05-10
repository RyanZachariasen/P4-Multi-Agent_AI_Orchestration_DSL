open Py_ast
open Typed_ast

let statement (stmt: statement) : py_statement = 
  match stmt with
  | SLet (name, typ, expr) -> PyAssign (name, Translate_expr.expr expr)
  | SPrint expr -> PyExpr (PyCall (PyName "print", [ Translate_expr.expr expr], []))
  | SReadFile expr -> PyExpr (PyCall (PyAttr (PyCall (PyName "open", [Translate_expr.expr expr; PyConst (PyString "r")], []), "read"), [], []))
  | SWriteFile (expr_1, expr_2) -> PyExpr (PyCall (PyAttr (PyCall (PyName "open", [Translate_expr.expr expr_1; PyConst (PyString "w")], []), "write"), [Translate_expr.expr expr_2], []))