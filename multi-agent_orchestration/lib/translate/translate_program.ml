let program (prog : Typed_ast.program) : Py_ast.py_module =
  let declarations =
    List.map Translate_declaration.declaration prog.prog_decls
  in
  let workflow_body = Translate_workflow.workflow prog.prog_workflow in
  {
    imports = [];
    body = declarations @ workflow_body;
  }