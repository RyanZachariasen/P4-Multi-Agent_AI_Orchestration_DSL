import os
from pypdf import PdfReader
from openai import OpenAI

gpt = OpenAI(api_key="OPENAI_API_KEY")

base_dir = os.path.dirname(__file__)
pdf_path = os.path.join(base_dir, "doc.pdf")

def extract_pdf_text(pdf_path):
    reader = PdfReader(pdf_path)

    extracted_text = "\n".join(p.extract_text() for p in reader.pages)

    return extracted_text

def summarize_pdf(pdf_path, user_prompt):
    pdf_text = extract_pdf_text(pdf_path)

    response = gpt.chat.completions.create(
        model = "gpt-4o-mini",
        messages = [
            {"role": "system", "content": "You summarize documents in a concise and easily understandable way"},
            {"role": "user", "content": f"{user_prompt}\n\nDocument:\n{pdf_text}"}
        ],
        temperature = 0.3,

    )

    return response.choices[0].message.content

if __name__ == "__main__":
    prompt = "Summarize this document in 50 words or less."

    document_summary = summarize_pdf(pdf_path, prompt)
    print(document_summary)