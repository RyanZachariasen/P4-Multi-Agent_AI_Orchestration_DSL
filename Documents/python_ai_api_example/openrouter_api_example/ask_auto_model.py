import os
import requests

OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions"

api_key = os.getenv("OPENROUTER_API_KEY")



def code(headers, message) -> str:
    p = {
        "model": "openai/gpt-3.5-turbo",
        "messages": [{"role": "user", "content": "Write code: " + message}]
    }
    response = requests.post(OPENROUTER_API_URL, headers=headers, json=p)
    return response.json()['choices'][0]['message']['content']

def review(headers, message) -> str:
    p = {
        "model": "openrouter/auto",
        "messages": [{"role": "user", "content": "check for bugs and errors and propose improvements for this code in text: " + message}]
    }
    response = requests.post(OPENROUTER_API_URL, headers=headers, json=p)
    return response.json()['choices'][0]['message']['content']

def format_code(headers, message) -> str:
    p = {
        "model": "openrouter/auto",
        "messages": [{"role": "user", "content": "give me the raw code. It should be copy pastable into one file and run from there" + message}]
    }
    response = requests.post(OPENROUTER_API_URL, headers=headers, json=p)
    return response.json()['choices'][0]['message']['content']

def main():
    
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    final_code = code (headers, "A javascript tic tac toe game against computer")
    review_text = ""
    
    with open(f"output.html", "w", encoding="utf-8") as f:
            f.write(format_code (headers,final_code))
"""
    for i in range (3):
        print(f"reviewing {i+1}")
        review_text = review (headers, final_code)
        print(f"coding {i+1}")
        final_code = code (headers, "make these improvements:  " +review_text + "to this code: " + final_code) 

        with open(f"output{i}.txt", "w", encoding="utf-8") as f:
            f.write(final_code)
        
    with open(f"output.html", "w", encoding="utf-8") as f:
        f.write(format_code(headers,final_code))
"""
if __name__ == "__main__":
    main()