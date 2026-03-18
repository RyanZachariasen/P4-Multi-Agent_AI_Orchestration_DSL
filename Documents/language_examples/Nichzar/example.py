import sys
import io
from PyPDF2 import PdfReader
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

from openai import OpenAI
import json

PDFFile = r"Documents\language_examples\Nichzar\test.pdf"

with open("putercreds.json") as f:
    creds = json.load(f)

client = OpenAI(
    base_url = "https://api.puter.com/puterai/openai/v1/",
    api_key = creds["puter_token"] 
)

def readPDF(PDFFile):
    text = ""
    reader = PdfReader(PDFFile)
    for page in reader.pages:
        text += page.extract_text()
    
    return text

def SummarizePDF():
    textFromPDF = readPDF(PDFFile)
    Summarize = client.chat.completions.create(
        model="gpt-4o-mini", 
        messages=[
            {"role": "system", "content": "Summerize this text"},
            {"role": "user", "content": textFromPDF}
        ]
    )

    return Summarize

Summary = SummarizePDF()

PromptAnswer = Summary.choices[0].message.content
print("#Summary#\n" + PromptAnswer + "\n")
