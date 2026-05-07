let expr (expr: Typed_ast.expr) : Py_ast.py_expr = 
  let expr_node = expr.expr_node in
  match expr_node with
  | Typed_ast.EVar name -> raise Not_found
  | Typed_ast.EBinOp (opp, e1, e2) -> raise Not_found
  | Typed_ast.ECall (name, expr_list, on_resource_option) -> raise Not_found
  | Typed_ast.EField (expr, name, typ)-> raise Not_found
  | Typed_ast.EConst const-> raise Not_found