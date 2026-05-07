let declaration (decl: Typed_ast.declaration) : Py_ast.py_statement  = 
  match decl with
  | Typed_ast.DFunc func -> raise Not_found
  | Typed_ast.DResource resource -> raise Not_found
  | Typed_ast.DCustomType custom_type-> raise Not_found