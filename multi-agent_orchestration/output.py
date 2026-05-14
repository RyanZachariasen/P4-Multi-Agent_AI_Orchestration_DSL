import os
import anthropic
coding_agent = {"client":Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY",),), "model":"claude-sonnet", "provider":"anthropic", "max_tokens":100000, "system_prompt":"", }
def code (input, _resource):
	if _resource.provider == "gemini":
		_result = _resource.client.models.generate_content(max_tokens=_resource.max_tokens,model=_resource.model,contents=f"{" Code this program: {input}"}",config=types.GenerateContentConfig(system_instruction=_resource.system_prompt,),).text

	if _resource.provider == "anthropic":
		_result = _resource.client.messages.create(max_tokens=_resource.max_tokens,model=_resource.model,messages=[{"role":"user", "content":f"{" Code this program: {input}"}", }, ],system=_resource.system_prompt,).content

	if _resource.provider == "grok":
		_chat = _resource.client.chat.create(model=_resource.model,)
		_chat.append(user(f"{" Code this program: {input}"}",),)
		_chat.append(system(_resource.system_prompt,),)
		_result = _chat.sample().content

	if _resource.provider == "openai":
		_result = _resource.client.responses.create(model=_resource.model,input=f"{" Code this program: {input}"}",instructions=_resource.system_prompt,max_output_tokens=_resource.max_tokens,).output_text

	return _result

if __name__ == "__main__":
	x = code("javascript tic-tac-toe game",coding_agent,)

