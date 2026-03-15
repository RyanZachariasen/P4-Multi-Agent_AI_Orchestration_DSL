import os
from anthropic import Anthropic
import sys
# gemini = genai.Client()

claude = Anthropic(
    api_key=os.environ.get("ANTHROPIC_API_KEY"),
)

message = claude.messages.create(
    max_tokens=10000,
    system = "keep result under 2000 lines",
    messages="this is input text",
    model="claude-sonnet-4-6",
)
message.content[0].text
