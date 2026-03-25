import anthropic
import base64
from pydantic import BaseModel

class Summary(BaseModel):
    title: str
    bullets: list[str]
    word_count: int

def SummarisePDF(pdf_path: str, prompt: str, output_lang: str = "english"):
    with open(pdf_path, "rb") as _f:
        pdf_document = base64.b64encode(_f.read()).decode("utf-8")
    system_prompt = 'You are a document summariser. Always respond in {{ lang }}. Return ONLY a JSON object with title (string), bullets (list of strings), word_count (int).'
    system_prompt = system_prompt.replace("{{ lang }}", output_lang)
    _client = anthropic.Anthropic()
    _resp = _client.messages.create(
        model="claude-sonnet-4-5",
        max_tokens=1024,
        system=system_prompt,
        messages=[{
            "role": "user",
            "content": [
                {
                    "type": "document",
                    "source": {
                        "type": "base64",
                        "media_type": "application/pdf",
                        "data": pdf_document,
                    }
                },
                {
                    "type": "text",
                    "text": f"{prompt}",
                }
            ]
        }]
    )
    _raw   = _resp.content[0].text
    _clean = _raw.replace("```json", "").replace("```", "").strip()
    llm_response = Summary.model_validate_json(_clean)
    final_result = {"summary": llm_response}
    print("\n" + "=" * 50)
    print("TITLE")
    print("=" * 50)
    print(final_result["summary"].title)
    print("\nBULLET POINTS")
    for b in final_result["summary"].bullets:
        print(f"  - {b}")
    print(f"\nWORD COUNT: {final_result['summary'].word_count}")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--pdf", required=True, dest="pdf_path")
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--output_lang", default="english")
    args = parser.parse_args()
    SummarisePDF(pdf_path=args.pdf_path, prompt=args.prompt, output_lang=args.output_lang)