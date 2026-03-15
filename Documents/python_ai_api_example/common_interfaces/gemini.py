from google import genai


gemini = genai.Client()

response = gemini.models.generate_content(
    model="gemini-3-flash-preview",
    contents="this is a prompt",
    config={
        "maxOutputTokens": 10000,
    },)

response.text

"""EVERY PARAMETER FOR THE "GENERATE_CONTENT" METHOD USED ABOVE:

      self,
      *,
      model: str,
      contents: types.ContentListUnionDict,
      config: Optional[types.GenerateContentConfigOrDict] = None,

  
  """