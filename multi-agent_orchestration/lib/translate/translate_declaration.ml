let rec declaration (decl: Typed_ast.declaration) : Py_ast.py_statement  = 
  match decl with
  | Typed_ast.DFunc func ->
      if func.func_needs_resource then
        func_with_resource func 
      else func_without_resource func

  | Typed_ast.DResource resource -> raise Not_found
  | Typed_ast.DCustomType custom_type-> raise Not_found

and func_with_resource func =
  (*let params_to_names = List.map (fun (name, typ) -> name  ) func.func_params in*)
  
  (*Py_ast.PyFuncDef (func.name, params_to_names,)*)

  raise Not_found

and func_without_resource func =
  (* let params_to_names = List.map (fun (name, typ) -> name  ) func.func_params in
  Py_ast.PyFuncDef (func.name, params_to_names,) *)
  raise Not_found

and gemini_call (prompt: Py_ast.py_expr) =
  let client = Py_ast.PyName "client" in
  let models = Py_ast.PyAttr (client, "models") in
  let generate_content = Py_ast.PyAttr (models, "generate_content") in
  let params = [("max_tokens", Py_ast.PyName "max_tokens"); ("model", Py_ast.PyName "model"); ("contents",  prompt)] in
  let call = Py_ast.PyCall (generate_content, [], params) in

  let response_text = Py_ast.PyAttr (call, "text") in
  response_text
  (*  client.models.generate_content(
      model="gemini-3-flash-preview",
      contents="Explain how AI works in a few words").text *)