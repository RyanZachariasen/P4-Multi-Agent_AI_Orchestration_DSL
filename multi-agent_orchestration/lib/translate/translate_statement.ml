open Py_ast
open Typed_ast

let rec statement (stmt: statement) : py_statement = 
  match stmt with
  | SLet (name, _, expr) -> PyAssign (name, Translate_expr.expr expr)
  | SPrint expr -> 
    let value = Translate_expr.expr expr in
    PyExpr (PyCall (PyName "print", [value], []))
    
  
  | SWriteFile (expr_1, expr_2) -> 
    let file = Translate_expr.expr expr_1 in
    let content_expr = Translate_expr.expr expr_2 in
    let open_call =PyCall (PyName "open", [file; PyConst (PyString "w")], []) in
    let write_call = PyCall (PyAttr(open_call, "write"), [content_expr], []) in
    PyExpr write_call
  | SWhile (e, body) -> 
    let py_expr = Translate_expr.expr e in
    let py_body = List.map (fun s -> (statement s)) body in
    Py_ast.PyWhile (py_expr, py_body)
    