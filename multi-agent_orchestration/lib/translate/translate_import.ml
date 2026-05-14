open Typed_ast
open Py_ast

let collect_imports (prog : Typed_ast.program) : py_statement list =
  let imports = ref [] in
  
  let add i =
    if not (List.mem i !imports) then
      imports := i :: !imports
  in

  List.iter (fun decl -> match decl with

    (* resource → provider import *)
    | DResource r -> 
        add (PyImport "os");    (* add os import! *)
        (match r.resource_provider with
        | Anthropic -> add (PyImport "anthropic")
        | OpenAI    -> add (PyImportFrom("openai", ["OpenAI"]))
        | Gemini    -> add (PyImportFrom("google", ["genai"]))
        | Grok      -> add (PyImport "groq"))

    (* type declaration → pydantic *)
    | DCustomType _ ->
        add (PyImportFrom("pydantic", ["BaseModel"]))

    (* func → no builtin check anymore *)
    | DFunc _ -> ()

  ) prog.prog_decls;

  List.rev !imports