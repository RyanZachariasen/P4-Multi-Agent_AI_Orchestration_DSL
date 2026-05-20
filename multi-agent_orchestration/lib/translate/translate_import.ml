
open Py_ast

let collect_imports (prog : Typed_ast.program) : py_statement list =
  let imports = ref [] in
  
  let add i =
    if not (List.mem i !imports) then
      imports := i :: !imports
  in

  List.iter (fun decl -> match decl with
    | Typed_ast.DResource r -> 
        add (PyImport "os");
        begin match r.resource_provider with 
        | Typed_ast.Anthropic -> add (PyImportFrom("anthropic", ["Anthropic"]));
        | Typed_ast.Gemini -> add (PyImportFrom("google", ["genai"]));
        | Typed_ast.Grok -> add (PyImportFrom("xai_sdk", ["Client"]));
        | Typed_ast.OpenAI -> add (PyImportFrom("openai", ["OpenAI"]));
        end

    | Typed_ast.DCustomType _ -> add (PyImportFrom("pydantic", ["BaseModel"]))

    | Typed_ast.DFunc _ -> 
      add (PyImportFrom("xai_sdk.chat", ["user"; "system"]));
      add (PyImportFrom("google.genai", ["types"]));



  ) prog.prog_decls;

  List.rev !imports