import os
from anthropic import Anthropic
import sys


claude = Anthropic(
    api_key=os.environ.get("ANTHROPIC_API_KEY"),
)

def remove_markdown_fences(code):
    lines = code.splitlines()
    for i in range(len(lines)):
        if lines[i].strip().startswith("```"):
            lines[i] = ""
    code = "\n".join(lines)
    return code

def claude_code(text):
    code = claude.messages.create(
        max_tokens=10000,
        system = "You are a helpful assistant that can write code. You will be given a prompt and you should write code to solve the problem. You should only write code and not include any explanations or markdown comments.",
        messages=text,
        model="claude-sonnet-4-6",
    ).content[0].text
    return remove_markdown_fences(code)

def claude_review(code):
    return claude.messages.create(
        max_tokens=10000,
        system = "You are a helpful assistant that can review code. You will be given a prompt and some code. You should review the code and provide feedback on how to improve it.",
        messages=code,
        model="claude-haiku-4-5-20251001",
    ).content[0].text

def claude_improve(code, review):
    return claude.messages.create(
        max_tokens=10000,
        system = "You are a helpful assistant that can improve code. You will be given a prompt and some code. You should review the code and improve it based on the prompt. You should only write code and not include any explanations or markdown comments.",
        messages=code + "\n" + review,
        model="claude-sonnet-4-6",
    ).content[0].text
    
if __name__ == "__main__":
    code = claude_code(sys.argv[1])
    review = claude_review(code)
    improved_code = claude_review(code, review)

    with open("./improved_code.js", "w") as f:
        f.write(improved_code)
