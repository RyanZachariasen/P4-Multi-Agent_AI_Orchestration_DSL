let rec declaration (decl: Typed_ast.declaration) : Py_ast.py_statement  = 
  match decl with
  | Typed_ast.DFunc func ->
      if func.func_needs_resource then
        func_with_resource func 
      else func_without_resource func
  | Typed_ast.DResource resource -> handle_resource_declaration resource
  | Typed_ast.DCustomType custom_type -> handle_type_declaration custom_type

and handle_type_declaration (custom_type: Typed_ast.custom_type_declaration) = 
  let name = custom_type.type_name in
  let fields = List.map (fun (name, typ) -> (name,  type_to_string typ)) custom_type.type_fields in 

  Py_ast.PyClassDef (name, "BaseModel",fields)  
  (*
  class Verdict(BaseModel):
    field_1: int
    field_2: str
    ...
  *)

and type_to_string (typ: Typed_ast.typ ) : string = 
  match typ with
    | TText -> "str"
    | TFile -> "str"
    | TCode -> "str"
    | TInt -> "int"
    | TFloat -> "float"
    | TBool -> "bool"
    | TCustomType name -> name
 

and handle_resource_declaration (resource: Typed_ast.resource_declaration) = 
  let client = get_correct_client resource.resource_provider in
  let provider = provider_to_pystring resource.resource_provider in
  let model = string_to_pystring resource.resource_model in

  let system_prompt = 
    match resource.system_prompt with
    | Some p -> string_to_pystring p
    | None ->  string_to_pystring "" in

  let max_tokens = match resource.max_tokens with
    | Some n -> Py_ast.PyConst (Py_ast.PyInt n)
    | None ->  Py_ast.PyConst (Py_ast.PyInt 100000) in

  let resource_object = Py_ast.PyDict [
    (Py_ast.PyString "client", client);
    (Py_ast.PyString "model", model); 
    (Py_ast.PyString "provider", provider); 
    (Py_ast.PyString "max_tokens", max_tokens); 
    (Py_ast.PyString "system_prompt", system_prompt) ] in 
  
  let assign_resource = Py_ast.PyAssign (resource.resource_name, resource_object) in
  assign_resource

  (* EXAMPLE 
    coder = {
      client = genai.Client(api_key="GEMINI_API_KEY"),
      provider="gemini",
      model="gemini-3-flash-preview",
      max_tokens="1024",
      system_prompt="helpful assistant..."
    }
  *)

and string_to_pystring str = 
  Py_ast.PyConst (Py_ast.PyString str)

and provider_to_pystring provider = 
  match provider with
  | Typed_ast.Anthropic -> string_to_pystring "anthropic"
  | Typed_ast.Gemini -> string_to_pystring "gemini"
  | Typed_ast.OpenAI -> string_to_pystring "openai"
  | Typed_ast.Grok -> string_to_pystring "grok"

and getenv_call str =
  let os = Py_ast.PyName "os" in 
  let get_env = Py_ast.PyAttr (os, "getenv") in
  Py_ast.PyCall (get_env, [string_to_pystring str], [])

and get_correct_client (provider: Typed_ast.provider) : Py_ast.py_expr = 
  match  provider with
    | Typed_ast.Anthropic -> 
      let anthropic_method =  Py_ast.PyName "Anthropic" in
      Py_ast.PyCall (anthropic_method, [], [("api_key", getenv_call "ANTHROPIC_API_KEY")])
      (* client = anthropic.Anthropic(api_key="ANTROPIC_API_KEY") *)

    | Typed_ast.Gemini -> 
      let genai = Py_ast.PyName "genai" in
      let client_method = Py_ast.PyAttr (genai, "Client") in

      Py_ast.PyCall (client_method, [], [("api_key", getenv_call "GEMINI_API_KEY")])
      (* client = genai.Client(api_key="GEMINI_API_KEY") *)

    | Typed_ast.OpenAI -> 
      let openai_method = Py_ast.PyName ("OpenAI") in
      Py_ast.PyCall (openai_method, [], [("api_key", getenv_call  "OPENAI_API_KEY")]) 
      (* client = OpenAI(api_key="OPENAI_API_KEY") *)

    | Typed_ast.Grok -> 
      let client_method = Py_ast.PyName ("Client") in
      Py_ast.PyCall (client_method, [], [("api_key", getenv_call  "GROK_API_KEY")]) 
      (* client = Client(api_key=os.getenv("GROK_API_KEY")) *)

and func_with_resource func =
  let params_to_names = List.map (fun (name, _) -> name ) func.func_params in

  (* Find the data from the Resource object *)
  let params_with_resource = List.append params_to_names ["_resource"] in

  let system_prompt = Py_ast.PySubscript (Py_ast.PyName ("_resource"), string_to_pystring "system_prompt") in
  let model = Py_ast.PySubscript (Py_ast.PyName ("_resource"), string_to_pystring "model") in
  let provider = Py_ast.PySubscript (Py_ast.PyName ("_resource"), string_to_pystring "provider") in
  let max_tokens = Py_ast.PySubscript (Py_ast.PyName ("_resource"),string_to_pystring "max_tokens") in
  let client = Py_ast.PySubscript (Py_ast.PyName ("_resource"), string_to_pystring "client") in
  let prompt = translate_prompt func.func_prompt in

  (*get all the statements for an ai call*)
  let gemini_call_statement = gemini_call max_tokens system_prompt model prompt client in
  let openai_call_statement = openai_call max_tokens system_prompt model prompt client in
  let anthropic_call_statement = anthropic_call max_tokens system_prompt model prompt client in
  let grok_call_statements = grok_call max_tokens system_prompt model prompt client in

  (*If statements to choose correct AI*)
  let gemini_if = Py_ast.PyIf  (Py_ast.PyCompare (provider, Py_ast.Eq, string_to_pystring "gemini"), [gemini_call_statement]) in
  let anthropic_if = Py_ast.PyIf  (Py_ast.PyCompare (provider, Py_ast.Eq, string_to_pystring "anthropic"), [anthropic_call_statement]) in
  let grok_if = Py_ast.PyIf  (Py_ast.PyCompare (provider, Py_ast.Eq, string_to_pystring "grok"), grok_call_statements) in
  let openai_if = Py_ast.PyIf  (Py_ast.PyCompare (provider, Py_ast.Eq, string_to_pystring "openai"), [openai_call_statement]) in

  let return_statement = Py_ast.PyReturn (Py_ast.PyName "_result") in

  let body = [gemini_if; anthropic_if; grok_if; openai_if; return_statement] in

  Py_ast.PyFuncDef (func.func_name, params_with_resource, body)
(*

def code (some_input_text, prompt, _resource):
  prompt = _resource.prompt
  max_tokens = _resource.max_tokens



  if _resource.provider == 'anthropic':
    _result = client.models.generate_content(
            model="gemini-3-flash-preview",
            config=types.GenerateContentConfig(system_instruction="You are a cat. Your name is Neko."),
            contents="Explain how AI works in a few words").text
    return
  if _resource.provider == 'gemini':
      ...
  if _resource.provider == 'openai':
    ...
  if _resource.provider == 'grok':
    _result = client.messages.create(
      max_tokens=1024,
      messages=[
          {
              "role": "user",
              "content": "Hello, Claude",
          }
      ],
      model="claude-opus-4-7",)
    return _result

*)
and translate_prompt (prompt : Typed_ast.prompt_part list) : Py_ast.py_expr =
  let fstring = List.map (fun part ->  
    match part with
  | Typed_ast.PromptText text -> (text, string_to_pystring "")
  | Typed_ast.PromptHole expr ->  
    let expr = Translate_expr.expr expr in
    ("", expr);
  ) prompt in
  
  Py_ast.PyFString ("", fstring)

    
and func_without_resource func =
  (* let params_to_names = List.map (fun (name, typ) -> name  ) func.func_params in
  Py_ast.PyFuncDef (func.name, params_to_names,) *)
  failwith "not implemented"


and gemini_call (max_tokens: Py_ast.py_expr) (system_prompt: Py_ast.py_expr) (model: Py_ast.py_expr) (prompt: Py_ast.py_expr) (client: Py_ast.py_expr) : Py_ast.py_statement =
  let models = Py_ast.PyAttr (client, "models") in
  let generate_content = Py_ast.PyAttr (models, "generate_content") in

  let generate_content_config = Py_ast.PyAttr (Py_ast.PyName "types", "GenerateContentConfig") in
  let config = Py_ast.PyCall(generate_content_config, [], [("system_instruction", system_prompt)]) in
    
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


and anthropic_call (max_tokens: Py_ast.py_expr) (system_prompt: Py_ast.py_expr) (model: Py_ast.py_expr) (prompt: Py_ast.py_expr) (client: Py_ast.py_expr) : Py_ast.py_statement =
  let messages = Py_ast.PyAttr (client, "messages") in
  let create = Py_ast.PyAttr (messages, "create") in
  let user =  string_to_pystring "user" in
  let message_body =  [(Py_ast.PyString "role", user); (Py_ast.PyString "content", prompt)] in
  let messages = Py_ast.PyList [Py_ast.PyDict message_body] in
  let params = [("max_tokens", max_tokens); ("model", model); ("messages",  messages); ("system", system_prompt)] in

  let call = Py_ast.PyCall (create, [], params) in

  let response_text = Py_ast.PyAttr (call, "content") in

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
    model="claude-opus-4-7",).content
    *)

and openai_call (max_tokens: Py_ast.py_expr) (system_prompt: Py_ast.py_expr) (model: Py_ast.py_expr) (prompt: Py_ast.py_expr) (client: Py_ast.py_expr) : Py_ast.py_statement =
  let responses = Py_ast.PyAttr (client, "responses") in
  let create = Py_ast.PyAttr (responses, "create") in
  
  let params = [("model", model); ("input",  prompt); ("instructions", system_prompt); ("max_output_tokens", max_tokens)] in

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

and grok_call (max_tokens: Py_ast.py_expr) (system_prompt: Py_ast.py_expr) (model: Py_ast.py_expr) (prompt: Py_ast.py_expr) (client: Py_ast.py_expr) : Py_ast.py_statement list =
  let chat_field = Py_ast.PyAttr (client, "chat") in
  let create = Py_ast.PyAttr (chat_field, "create") in
  
  let call_create = Py_ast.PyCall (create, [], [("model", model)]) in
  
  let assign_chat = Py_ast.PyAssign ("_chat", call_create) in
  let chat = Py_ast.PyName "_chat" in
  let append = Py_ast.PyAttr (chat,"append") in
  let grok_user = Py_ast.PyName "user" in
  let grok_system = Py_ast.PyName "system" in
  let user_call = Py_ast.PyCall (grok_user, [prompt],[]) in
  let system_call = Py_ast.PyCall (grok_system, [system_prompt],[]) in

  let call_append_user = Py_ast.PyCall (append, [user_call],[]) in
  let call_append_system = Py_ast.PyCall (append, [system_call],[]) in

  let sample = Py_ast.PyAttr (chat, "sample") in
  let call_sample = Py_ast.PyCall (sample, [], []) in

  let response_text = Py_ast.PyAttr (call_sample, "content") in

  let assign_to_result = Py_ast.PyAssign ("_result", response_text) in
  
  [assign_chat; Py_ast.PyExpr call_append_user; Py_ast.PyExpr call_append_system; assign_to_result]
  (*
    chat = client.chat.create(model="grok-4.3")
    chat.append(system("You are Grok, a highly intelligent, helpful AI assistant."))
    chat.append(user("What is the meaning of life, the universe, and everything?"))
    result = chat.sample().content
  *)