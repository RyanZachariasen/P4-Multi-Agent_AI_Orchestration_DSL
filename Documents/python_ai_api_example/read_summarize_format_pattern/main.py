import logging
from google import genai

client = genai.Client()



logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("summarizer")

INPUT_FILE = "ingested.txt"
OUTPUT_FILE = "summary.txt"



SYSTEM_PROMPT = (
    "You are a helpful assistant that summarizes long text "
    "into key bullet points. Each bullet should be one "
    "concise sentence capturing a core insight."
)

MAX_RETRIES = 3
RETRY_DELAY = 5  # seconds

def summarize(text, retries=MAX_RETRIES):
    """Call the LLM API with retry logic for rate limits."""
    for attempt in range(retries):
        try:
            response = client.models.generate_content(
                model="gemini-3-flash-preview",
                contents=text[:8000])
            return response.text
        except:
            print("error")
    raise RuntimeError("Max retries exceeded for LLM API call")

def format(text, retries=MAX_RETRIES):
    """Call the LLM API with retry logic for rate limits."""
    for attempt in range(retries):
        try:
            response = client.models.generate_content(
                model="gemini-3-flash-preview",
                contents=text[:8000])
            return response.text
        except:
            print("error")
    raise RuntimeError("Max retries exceeded for LLM API call")

def main():
    with open(INPUT_FILE, "r", encoding="utf-8") as f:
        raw_text = f.read()

    if not raw_text.strip():
        logger.warning("Empty input. Writing fallback summary.")
        summary = "No content to summarize."
    else:
        try:
            summary = summarize(raw_text)
            formatted = format("Format this to a nice markdown overview: "+summary)
        except Exception as e:
            logger.error(f"Summarization failed: {e}")
            summary = f"Summarization failed: {e}"

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(formatted)
    logger.info(f"Summary written to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()