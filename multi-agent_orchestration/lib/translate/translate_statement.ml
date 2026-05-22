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
  | SWhile (e, stmt_list) -> 
    let py_expr = Translate_expr.expr e in
    let py_stmt_list = List.map (fun stmt -> (statement stmt)) stmt_list in
    Py_ast.PyWhile (py_expr, py_stmt_list)
  | SIf (cond, then_body, else_branch) ->
    let rec convert_if (cond, then_body, orelse) =
      let py_cond = Translate_expr.expr cond in
      let py_then = List.map (fun s -> statement s) then_body in
      let py_orelse =
        match orelse with
        | None -> []
        | Some else_branch ->
          begin match else_branch with
          | [SIf (ic, it, io)] -> [convert_if (ic, it, io)]
          | _ -> List.map (fun s -> statement s) else_branch
          end
      in
      Py_ast.PyIf (py_cond, py_then, py_orelse)
    in
    convert_if (cond, then_body, else_branch)
    