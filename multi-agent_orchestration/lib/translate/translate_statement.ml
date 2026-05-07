let statement (stmt: Typed_ast.statement) : Py_ast.py_statement = 
  match stmt with
  | Typed_ast.SLet (name, typ, expr) -> raise Not_found
  | Typed_ast.SPrint expr -> raise Not_found
  | Typed_ast.SReadFile expr -> raise Not_found
  | Typed_ast.SWriteFile (expr_1, expr_2) -> raise Not_found