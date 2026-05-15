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
        add (PyImport "os");
        add (PyImportFrom("anthropic", ["Anthropic"]));
        add (PyImportFrom("openai", ["OpenAI"]));
        add (PyImportFrom("google", ["genai"]));
        add (PyImportFrom("xai_sdk", ["Client"]));
        add (PyImportFrom("xai_sdk.chat", ["user"; "system"]));

    (* type declaration → pydantic *)
    | DCustomType _ ->
        add (PyImportFrom("pydantic", ["BaseModel"]))

    (* func → no builtin check anymore *)
    | DFunc _ -> ()

  ) prog.prog_decls;

  List.rev !imports