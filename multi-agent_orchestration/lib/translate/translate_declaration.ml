let rec declaration (decl: Typed_ast.declaration) : Py_ast.py_statement  = 
  match decl with
  | Typed_ast.DFunc func ->
      if func.func_needs_resource then
        func_with_resource func 
      else func_without_resource func

  | Typed_ast.DResource resource -> raise Not_found
  | Typed_ast.DCustomType custom_type-> raise Not_found

and handle_prompt (prompt : Typed_ast.prompt_part list) : Py_ast.py_expr =
    raise Not_found

and func_with_resource func =
  let params_to_names = List.map (fun (name, typ) -> name ) func.func_params in

  (*create body*)
  let params_with_resource = List.append params_to_names ["_resource"] in
  let system_prompt = Py_ast.PyAttr (Py_ast.PyName ("_resource"), "system_prompt") in
  let model = Py_ast.PyAttr (Py_ast.PyName ("_resource"), "model") in
  let provider = Py_ast.PyAttr (Py_ast.PyName ("_resource"), "provider") in
  let max_tokens = Py_ast.PyAttr (Py_ast.PyName ("_resource"), "max_tokens") in
  let prompt = handle_prompt func.func_prompt in
  
  let gemini_string = Py_ast.PyConst (Py_ast.PyString "gemini") in
  let antropic_string = Py_ast.PyConst (Py_ast.PyString "antropic") in
  let open_ai_string = Py_ast.PyConst (Py_ast.PyString "openai") in
  let grok_string = Py_ast.PyConst (Py_ast.PyString "hello") in

  
  let gemini_call_statement = gemini_call max_tokens system_prompt model prompt in
  let openai_call_statement = openai_call max_tokens system_prompt model prompt in
  let anthropic_call_statement = antropic_call max_tokens system_prompt model prompt in
  let grok_call_statements = grok_call max_tokens system_prompt model prompt in

  let gemini_if = Py_ast.PyIf  (Py_ast.PyCompare (provider, Py_ast.Eq, gemini_string), [gemini_call_statement]) in
  let antropic_if = Py_ast.PyIf  (Py_ast.PyCompare (provider, Py_ast.Eq, antropic_string), [anthropic_call_statement]) in
  let grok_if = Py_ast.PyIf  (Py_ast.PyCompare (provider, Py_ast.Eq, grok_string), grok_call_statements) in
  let openai_if = Py_ast.PyIf  (Py_ast.PyCompare (provider, Py_ast.Eq, open_ai_string), [openai_call_statement]) in

  let return_statement = Py_ast.PyReturn (Py_ast.PyName "_result") in

  let body = [gemini_if; antropic_if; grok_if; openai_if; return_statement] in

  Py_ast.PyFuncDef (func.func_name, params_with_resource, body)

and func_without_resource func =
  (* let params_to_names = List.map (fun (name, typ) -> name  ) func.func_params in
  Py_ast.PyFuncDef (func.name, params_to_names,) *)
  raise Not_found

and gemini_call (max_tokens: Py_ast.py_expr) (system_prompt: Py_ast.py_expr) (model: Py_ast.py_expr) (prompt: Py_ast.py_expr) : Py_ast.py_statement =
  let client = Py_ast.PyName "client" in
  let models = Py_ast.PyAttr (client, "models") in
  let generate_content = Py_ast.PyAttr (models, "generate_content") in

  let generate_content_config = Py_ast.PyAttr (Py_ast.PyName "types", "GenerateContentConfig") in
  let config = Py_ast.PyCall(generate_content_config, [], ["system_instruction", system_prompt]) in
    
  let params = [("max_tokens", max_tokens); ("model", model); ("contents",  prompt); ("config", config)] in

  let call = Py_ast.PyCall (generate_content, [], params) in

  let response_text = Py_ast.PyAttr (call, "text") in
  let assign_to_result = Py_ast.PyAssign ("_result", response_text) in
  assign_to_result

  (*  Generates
    _result = client.models.generate_content(
            model="gemini-3-flash-preview",
            config=types.GenerateContentConfig(system_instruction="You are a cat. Your name is Neko."),
            contents="Explain how AI works in a few words").text *)


and antropic_call (max_tokens: Py_ast.py_expr) (system_prompt: Py_ast.py_expr) (model: Py_ast.py_expr) (prompt: Py_ast.py_expr) : Py_ast.py_statement =
  let client = Py_ast.PyName "client" in
  let messages = Py_ast.PyAttr (client, "messages") in
  let create = Py_ast.PyAttr (messages, "create") in
  let user =  Py_ast.PyConst (Py_ast.PyString "user") in
  let message_body =  [("role", user); ("content", prompt)] in
  let messages = Py_ast.PyList [Py_ast.PyDict message_body] in
  let params = [("max_tokens", max_tokens); ("model", model); ("messages",  messages); ("system", system_prompt)] in

  let call = Py_ast.PyCall (create, [], params) in

  let response_text = Py_ast.PyAttr (call, "text") in

  let assign_to_result = Py_ast.PyAssign ("_result", response_text) in

  assign_to_result
  (*
  message = client.messages.create(
    max_tokens=1024,
    messages=[
        {
            "role": "user",
            "content": "Hello, Claude",
        }
    ],
    model="claude-opus-4-7",)
    *)

and openai_call (max_tokens: Py_ast.py_expr) (system_prompt: Py_ast.py_expr) (model: Py_ast.py_expr) (prompt: Py_ast.py_expr) : Py_ast.py_statement =
  let client = Py_ast.PyName "client" in
  let responses = Py_ast.PyAttr (client, "responses") in
  let create = Py_ast.PyAttr (responses, "create") in
  
  let params = [("model", model); ("input",  prompt);] in

  let call = Py_ast.PyCall (create, [], params) in

  let output_text = Py_ast.PyAttr (call, "output_text") in

  let assign_to_result = Py_ast.PyAssign ("_result", output_text) in

  assign_to_result
  (*
    _response = client.responses.create(
        model="gpt-5.5",
        input="Write a short bedtime story about a unicorn."
    ).output_text
  *)

and grok_call (max_tokens: Py_ast.py_expr) (system_prompt: Py_ast.py_expr) (model: Py_ast.py_expr) (prompt: Py_ast.py_expr) : Py_ast.py_statement list =
  let statements : Py_ast.py_statement list = []  in

  let client = Py_ast.PyName "client" in
  let chat = Py_ast.PyAttr (client, "chat") in
  let create = Py_ast.PyAttr (chat, "create") in
  
  let call_create = Py_ast.PyCall (create, [], ["model", model]) in
  
  let assign_chat = Py_ast.PyAssign ("_chat", call_create) in
  let append = Py_ast.PyAttr (Py_ast.PyName "_chat","append") in
  let grok_user = Py_ast.PyName "user" in
  let grok_system = Py_ast.PyName "system" in
  let user_call = Py_ast.PyCall (grok_user, [prompt],[]) in
  let system_call = Py_ast.PyCall (grok_system, [prompt],[]) in

  let call_append_user = Py_ast.PyCall (append, [user_call],[]) in
  let call_append_system = Py_ast.PyCall (append, [system_call],[]) in

  let sample = Py_ast.PyAttr (chat, "sample") in
  let call_sample = Py_ast.PyCall (sample, [], []) in

  let response_text = Py_ast.PyAttr (call_sample, "content") in

  let assign_to_result = Py_ast.PyAssign ("_result", response_text) in
  
  List.append [assign_chat; Py_ast.PyExpr call_append_user; Py_ast.PyExpr call_append_system; assign_to_result] statements
  (*
    chat = client.chat.create(model="grok-4.3")
    chat.append(system("You are Grok, a highly intelligent, helpful AI assistant."))
    chat.append(user("What is the meaning of life, the universe, and everything?"))
    result = chat.sample().content
  *)