import os
from language_examples.jakob.anthropic import Anthropic
import sys
# gemini = genai.Client()

claude = Anthropic(
    api_key=os.environ.get("ANTHROPIC_API_KEY"),
)

def call(text):
    return claude.messages.create(
        max_tokens=10000,
        system = "keep result under 2000 lines",
        messages=text,
        model="claude-sonnet-4-6",
    )

def main(*args):
    print(call("This is a prompt").content[0].text)
    print(args[1])
    
if __name__ == "__main__":    
    main(*sys.argv)
