

def gemini_call(text) -> str:
    try:
        response = gemini.models.generate_content(
            model="gemini-3-flash-preview",
            contents=text)
        return response.text
    except:
        print("gemini error")