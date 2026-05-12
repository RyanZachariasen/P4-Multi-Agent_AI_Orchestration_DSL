coder = {"client":Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY",),), "model":"claude-sonnet", "provider":"anthropic", "max_tokens":100000, "system_prompt":"", }
reviewer = {"client":OpenAI(api_key=os.getenv("OPENAI_API_KEY",),), "model":"gpt-4", "provider":"openai", "max_tokens":100000, "system_prompt":"", }
reviewer1 = {"client":Client(api_key=os.getenv("GROK_API_KEY",),), "model":"gpt-4", "provider":"grok", "max_tokens":100000, "system_prompt":"", }
reviewer2 = {"client":genai.Client(api_key=os.getenv("GEMINI_API_KEY",),), "model":"gpt-4", "provider":"gemini", "max_tokens":100000, "system_prompt":"", }
def code_something (input, _resource):
	if _resource.provider == "gemini":
		_result = _resource.client.models.generate_content(max_tokens=_resource.max_tokens,model=_resource.model,contents=f"{"This is a prompt:"}{input}{"="}",config=types.GenerateContentConfig(system_instruction=_resource.system_prompt,),).text
	if _resource.provider == "anthropic":
		_result = _resource.client.messages.create(max_tokens=_resource.max_tokens,model=_resource.model,messages=[{"role":"user", "content":f"{"This is a prompt:"}{input}{"="}", }, ],system=_resource.system_prompt,).content
	if _resource.provider == "grok":
		_chat = _resource.client.chat.create(model=_resource.model,)
		_chat.append(user(f"{"This is a prompt:"}{input}{"="}",),)
		_chat.append(system(_resource.system_prompt,),)
		_result = _chat.sample().content
	if _resource.provider == "openai":
		_result = _resource.client.responses.create(model=_resource.model,input=f"{"This is a prompt:"}{input}{"="}",instructions=_resource.system_prompt,max_output_tokens=_resource.max_tokens,).output_text
	return _result

print("hello",)
