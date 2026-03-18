from openai import OpenAI
from pypdf import PdfReader
import os

# Henter API key fra miljøvariabel
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def read_pdf(pdf_path):
    reader = PdfReader(pdf_path)
    text = ""

    for page in reader.pages:
        extracted = page.extract_text()
        if extracted:
            text += extracted + "\n"

    return text

def summarize_pdf(pdf_path, user_prompt):
    pdf_text = read_pdf(pdf_path)

    response = client.responses.create(
        model="gpt-4.1-mini",
        input=f"""
Du er en hjælpsom assistent.

Brugerens instruktion:
{user_prompt}

Indhold fra PDF:
{pdf_text}

Lav et kort og klart summary på dansk.
"""
    )

    return response.output_text

if __name__ == "__main__":
    pdf_file = "doc.pdf"
    prompt = "Giv mig et kort summary af dokumentet med de vigtigste pointer."

    summary = summarize_pdf(pdf_file, prompt)
    print("\nSUMMARY:\n")
    print(summary)