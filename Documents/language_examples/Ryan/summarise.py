from openai import OpenAI

client = OpenAI()

def summariser(text):
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "user", "content": f"Summarise this:\n\n{text}"}
        ]
    )

    return response.choices[0].message.content