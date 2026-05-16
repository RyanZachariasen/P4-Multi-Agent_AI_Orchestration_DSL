open Typed_ast
open Py_ast

let collect_imports (prog : Typed_ast.program) : py_statement list =
  let imports = ref [] in
  
  let add i =
    if not (List.mem i !imports) then
      imports := i :: !imports
  in

  List.iter (fun decl -> match decl with
    | DResource r -> 
        add (PyImport "os");
        (match r.resource_provider with
        | Anthropic -> add (PyImportFrom("anthropic", ["Anthropic"]))
        | OpenAI    -> add (PyImportFrom("openai", ["OpenAI"]))
        | Gemini    -> add (PyImportFrom("google", ["genai"]))
        | Grok      -> 
            add (PyImportFrom("xai_sdk", ["Client"]));
            add (PyImportFrom("xai_sdk.chat", ["user"; "system"])))

    | DCustomType _ ->
        add (PyImportFrom("pydantic", ["BaseModel"]))

    | DFunc _ -> ()

  ) prog.prog_decls;

  List.rev !imports