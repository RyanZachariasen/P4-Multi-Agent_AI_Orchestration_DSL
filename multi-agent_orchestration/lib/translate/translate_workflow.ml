let workflow (wf : Typed_ast.workflow) : Py_ast.py_statement list =
  List.map Translate_statement.statement wf.workflow_body
