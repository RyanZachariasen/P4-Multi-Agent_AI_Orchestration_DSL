open Py_ast
open Typed_ast

let statement (stmt: statement) : py_statement = 
  match stmt with
  | SLet (name, _, expr) -> PyAssign (name, Translate_expr.expr expr)
  | SPrint expr -> 
    let value = Translate_expr.expr expr in
    PyExpr (PyCall (PyName "print", [value], []))
    
  | SReadFile expr -> 
    let file = Translate_expr.expr expr in
    let open_call = PyCall (PyName "open", [file; PyConst (PyString "r")], []) in
    let read_call = PyAttr (open_call, "read") in
    PyExpr read_call
    
  
    | SWriteFile (expr_1, expr_2) -> 
    let file = Translate_expr.expr expr_1 in
    let content_expr = Translate_expr.expr expr_2 in
    let open_call =PyCall (PyName "open", [file; PyConst (PyString "w")], []) in
    let write_call = PyCall (PyAttr(open_call, "write"), [content_expr], []) in
    PyExpr write_call
    