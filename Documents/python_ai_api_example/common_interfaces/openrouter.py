import os
import requests

OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions"

api_key = os.getenv("OPENROUTER_API_KEY")

message = "this is a prompt"

headers = {
    "Authorization": f"Bearer {api_key}",
    "Content-Type": "application/json"
}

payload = {
    "model": "openai/gpt-3.5-turbo",
    "messages": [{"role": "user", "content":  message}]
}
response = requests.post(OPENROUTER_API_URL, headers=headers, json=payload)
response.json()['choices'][0]['message']['content']
