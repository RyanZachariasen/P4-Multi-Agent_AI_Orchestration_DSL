import os
from openai import OpenAI
from pypdf import PdfReader
from dotenv import load_dotenv

load_dotenv()

class AIWorkflowEngine:
    def __init__(self):
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            raise ValueError("OPENAI_API_KEY not found in .env!")
        self.client = OpenAI(api_key=api_key)
        
        # The Registry for our DSL Manifest
        self.agents = {} 
        self.tasks = {}

    # --- DSL REGISTRATION METHODS ---
    def register_agent(self, name, model, role):
        self.agents[name] = {"model": model, "role": role}

    def register_task(self, name, agent_name, objective):
        self.tasks[name] = {"agent": agent_name, "objective": objective}

    # --- TOOLS ---
    def read_pdf(self, path):
        if not os.path.exists(path):
            return f"Error: File {path} not found."
        reader = PdfReader(path)
        return "".join(page.extract_text() or "" for page in reader.pages)

    # --- EXECUTION ---
    def execute_task(self, agent_config, task_input):
  
        response = self.client.chat.completions.create(
            model=agent_config.get("model"),
            messages=[
                {"role": "system", "content": agent_config.get("role")},
                {"role": "user", "content": f"{agent_config.get('objective')}\n\n{task_input}"}
            ]
        )
        return response.choices[0].message.content

    def run_task(self, task_name, task_input):

        task = self.tasks.get(task_name)
        if not task:
            return f"Error: Task {task_name} not registered."
            
        agent = self.agents.get(task["agent"])
        if not agent:
            return f"Error: Agent {task['agent']} not found for task {task_name}."
        
        # Combine the registered info into the format execute_task expects
        full_config = {
            "model": agent["model"],
            "role": agent["role"],
            "objective": task["objective"]
        }
        return self.execute_task(full_config, task_input)

# --- TESTING THE ENGINE ---
engine = AIWorkflowEngine()

#simulating the @agent and @task definitions from dsl
engine.register_agent("summarise_agent", "gpt-4o-mini", "You are a PhD researcher.")
engine.register_task("SummariseText", "summarise_agent", "Summarize this text in three bullet points.")

#running the workflow
pdf_path = "/Users/ryanzachariasen/Desktop/OCAML Progs/P4-Multi-Agent_AI_Orchestration_DSL/Documents/language_examples/Ryan/not_even_funny.pdf"
text = engine.read_pdf(pdf_path)

if "Error" not in text:
    # Now we call 'run_task' using the name we defined in the DSL!
    result = engine.run_task("SummariseText", text[:10000])
    print("--- DSL WORKFLOW RESULT ---")
    print(result)
else:
    print(text)