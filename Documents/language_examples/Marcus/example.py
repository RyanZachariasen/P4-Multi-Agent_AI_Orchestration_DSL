import time
import openai
from pydantic import BaseModel

# ---------------------------------------------------------
# COMPILER SETUP: Resources, Tools, and Schemas
# ---------------------------------------------------------
client = openai.OpenAI()

def tool_read_pdf(file_path: str) -> str:
    # (Implementation for PDF reading inserted here)
    return f"[Extracted content from {file_path}]"

class EvaluatorSchema(BaseModel):
    passed: bool
    feedback: str

# ---------------------------------------------------------
# COMPILED FLOW: DocumentSummarizer
# ---------------------------------------------------------
def run_document_summarizer(query: str, file_path: str) -> str:
    
    # The compiler initializes a State Context to track outputs for injection
    context = {
        "query": query,
        "Director": {"output": ""},
        "Reader": {"output": ""},
        "Evaluator": {"feedback": ""} # Starts empty for the first cycle
    }

    # --- 1. AGENT: Director ---
    prompt_director = f"""
        Analyze the user's intent: {context['query']}
        Write a strict instruction set for a summarizer agent. 
        Dictate the required tone, personality, and specific focus areas.
    """
    res_director = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": prompt_director}]
    )
    context["Director"]["output"] = res_director.choices[0].message.content


    # --- 2. THE ROUTING CYCLE (Reader -> Evaluator) ---
    max_cycles = 3
    current_cycle = 0

    while current_cycle < max_cycles:
        
        # --- 3. AGENT: Reader (With System Retries) ---
        reader_success = False
        reader_attempts = 0
        
        while reader_attempts < 3 and not reader_success:
            try:
                # Tool execution injected into prompt
                pdf_text = tool_read_pdf(file_path) 
                
                prompt_reader = f"""
                    Follow these instructions carefully: {context["Director"]["output"]}
                    
                    Document text: {pdf_text}
                    
                    Previous feedback to fix (if any): {context["Evaluator"]["feedback"]}
                """
                res_reader = client.chat.completions.create(
                    model="gpt-4o",
                    messages=[{"role": "user", "content": prompt_reader}]
                )
                context["Reader"]["output"] = res_reader.choices[0].message.content
                reader_success = True
                
            except Exception as e:
                reader_attempts += 1
                if reader_attempts == 3:
                    # System failure threshold reached
                    raise RuntimeError(f"Agent Reader failed after 3 system retries. Error: {e}")
                time.sleep(2) # Exponential backoff could be added here

        # --- 4. AGENT: Evaluator (With Structured Output) ---
        prompt_evaluator = f"""
            Did Reader follow Director's instructions?
            Instructions: {context["Director"]["output"]}
            Summary: {context["Reader"]["output"]}
        """
        res_evaluator = client.beta.chat.completions.parse(
            model="gpt-4o",
            messages=[{"role": "user", "content": prompt_evaluator}],
            response_format=EvaluatorSchema
        )
        evaluation = res_evaluator.choices[0].message.parsed
        
        # Update state with feedback for the next potential cycle
        context["Evaluator"]["feedback"] = evaluation.feedback

        # --- 5. EVALUATE ROUTE ---
        if evaluation.passed is True:
            # Route: True >> Exit(Reader.output)
            return context["Reader"]["output"]
        else:
            # Route: False >> Reader (max_cycles: 3, inject: Evaluator.feedback)
            current_cycle += 1
            
    # Fallback if the max_cycles are exhausted
    return f"Workflow exited: Reached max cognitive cycles ({max_cycles}) without passing evaluation. Last draft: {context['Reader']['output']}"