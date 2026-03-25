import os
from pypdf import PdfReader
from openai import OpenAI


# extract.text.pdf keyword from .mai
def extract_pdf_text(pdf_path):
    reader = PdfReader(pdf_path)

    extracted_text = "\n".join(p.extract_text() for p in reader.pages)

    return extracted_text

# summarize_text function from .mai
def summarize_pdf(user_prompt, text):
    pdf_text = text

    gpt = OpenAI(api_key=OPENAI_API_KEY)
    response = gpt.chat.completions.create(
        model = "gpt-4o-mini",
        messages = [
            {"role": "system", "content": "You are an assistant for summarizing documents and text. When you summarize make it concise and easily understandable."},
            {"role": "user", "content": f"{user_prompt}\n\nDocument:\n{pdf_text}"}
        ],
        max_tokens=10000
    )

    return response.choices[0].message.content

# hightlight_key_points function from .mai
def highlight_key_points(user_prompt, text):
    pdf_text = text

    gpt = OpenAI(api_key=OPENAI_API_KEY)
    response = gpt.chat.completions.create(
        model = "gpt-5.4-mini",
        messages = [
            {"role": "system", "content": "You are an assistant for extracting and highlighting the key and most important parts of a text or document."},
            {"role": "user", "content": f"{user_prompt}\n\nDocument:\n{pdf_text}"}
        ],
        temperature=0.3,
    )

    return response.choices[0].message.content

# Workflow from .mai
if __name__ == "__main__":

    summary = summarize_pdf("Summarize this text in 50 words or less", extract_pdf_text("C:/Desktop/P4/P4-Multi-Agent_AI_Orchestration_DSL/Documents/language_examples/asbjorn/pdf_and_text_example/doc.pdf"))
    key_points = highlight_key_points("Highlight and bulletize the key and most important parts of this text", extract_pdf_text("C:/Desktop/P4/P4-Multi-Agent_AI_Orchestration_DSL/Documents/language_examples/asbjorn/pdf_and_text_example/doc.pdf"))
    print(summary + "\n")
    print(key_points + "\n")

