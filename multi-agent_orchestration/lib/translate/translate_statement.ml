open Py_ast
open Typed_ast

let statement (stmt: statement) : py_statement = 
  match stmt with
  | SLet (name, typ, expr) -> PyAssign (name, Translate_expr.expr expr)
  | SPrint expr -> 
    let value = Translate_expr.expr expr in
    PyExpr (PyCall (PyName "print", [value], []))
    (*PyExpr (PyCall (PyName "print", [ Translate_expr.expr expr], []))*)
  | SReadFile expr -> 
    let file = Translate_expr.expr expr in
    let open_call = PyCall (PyName "open", [file; PyConst (PyString "r")], []) in
    let read_call = PyAttr (open_call, "read") in
    PyExpr read_call
    (*PyExpr (PyCall (PyAttr (PyCall (PyName "open", [Translate_expr.expr expr; PyConst (PyString "r")], []), "read"), [], []))*)
  
  | SWriteFile (expr_1, expr_2) -> 
    let file = Translate_expr.expr expr_1 in
    let content_expr = Translate_expr.expr expr_2 in
    let open_call =PyCall (PyName "open", [file; PyConst (PyString "w")], []) in
    let write_call = PyCall (PyAttr(open_call, "write"), [content_expr], []) in
    PyExpr write_call
    (*PyExpr (PyCall (PyAttr (PyCall (PyName "open", [Translate_expr.expr expr_1; PyConst (PyString "w")], []), "write"), [Translate_expr.expr expr_2], []))*)