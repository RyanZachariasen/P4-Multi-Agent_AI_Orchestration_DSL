let program (prog : Typed_ast.program) : Py_ast.py_module =
  Printf.printf "Translating imports...\n%!";
  let imports = Translate_import.collect_imports prog in
  Printf.printf "Translating declarations...\n%!";
  let declarations = List.map Translate_declaration.declaration prog.prog_decls in
  Printf.printf "Translating workflow...\n%!";
  let workflow_body = Translate_workflow.workflow prog.prog_workflow in
  Printf.printf "Done!\n%!";
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
    imports = imports;
    body = declarations @ [main_guard];
  }