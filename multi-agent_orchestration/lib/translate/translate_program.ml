let program (prog : Typed_ast.program) : Py_ast.py_module =
  let declarations =
    List.map Translate_declaration.declaration prog.prog_decls
  in
  let workflow_body = Translate_workflow.workflow prog.prog_workflow in
  let main_guard =
    Py_ast.PyIf (
      Py_ast.PyCompare (
        Py_ast.PyName "__name__",
        Py_ast.Eq,
        Py_ast.PyConst (Py_ast.PyString "__main__")
      ),
      workflow_body
    )
  in
  {
    imports = [];
    body = declarations @ [main_guard];
  }
