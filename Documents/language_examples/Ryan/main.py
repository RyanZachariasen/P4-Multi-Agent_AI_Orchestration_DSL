from dotenv import load_dotenv
load_dotenv()
import os
from pdf_reader import extract_text
from summarise import summariser


text = extract_text("/Users/ryanzachariasen/Desktop/OCAML Progs/P4-Multi-Agent_AI_Orchestration_DSL/Documents/language_examples/Ryan/not_even_funny.pdf")

summary = summariser(text[:5000])


print(summary)