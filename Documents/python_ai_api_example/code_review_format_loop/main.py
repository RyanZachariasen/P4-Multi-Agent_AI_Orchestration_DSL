import os
from anthropic import Anthropic
from google import genai
import sys
# gemini = genai.Client()

claude = Anthropic(
    api_key=os.environ.get("ANTHROPIC_API_KEY"),
)
#def gemini_call(text) -> str:
#    try:
#        response = gemini.models.generate_content(
#            model="gemini-3-flash-preview",
#            contents=text)
#        return response.text
#    except:
#        print("gemini error")

history = []
def claude_call(model="claude-haiku-4-5-20251001") -> str:
    max_tokens=20024
    message = claude.messages.create(
        max_tokens=max_tokens,
        system = "keep result under 2000 lines",
        messages=history,
        model=model,
    )
    return message.content[0].text

def review_code():
    print("reviewing...")
    input = "review the code for bugs o"
    history.append({"role": "user", "content": input})
    response = claude_call()
    history.append({"role": "assistant", "content": response})
    return response


def code():
    print("coding...")
    input = "improve the code based on the last review"
    history.append({"role": "user", "content": input})
    response =claude_call("claude-sonnet-4-6")
    history.append({"role": "assistant", "content": response}) 
    return response


def format_code():
    print("formatting...")
    input = "You are a code output machine. Return ONLY raw code. No markdown, no backticks, no comments, no explanations. If you write anything other than code, you have failed."
    history.append({"role": "user", "content": input})
    response = claude_call()
    history.append({"role": "assistant", "content": response}) 
    return response

def clean_up(text: str):
    lines = text.strip().splitlines()
    if lines[0].startswith( "```"):
        lines.pop[0]
    if lines[-1].startswith("```"):
        lines.pop[-1]
    return "".join(lines)
def main():
    input = sys.argv[1]
    print(f"INPUT: {input}")
    history.append({"role": "user", "content": input})
    codebase = claude_call()
    history.append({"role": "assistant", "content": codebase}) 

    for _ in range(2):
        review_code()
        code()
        history.pop(-1)

    codebase = format_code()

    codebase = clean_up(codebase)

    with open("output_end.html", "w", encoding="utf-8") as f:
        f.write(codebase)
    


if __name__== "__main__":
    main()

