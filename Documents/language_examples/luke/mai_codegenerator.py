"""
mai_codegen_simple.py
─────────────────────
Reads a .mai workflow file and generates executable Python.

Usage:
    python mai_codegen_simple.py summarise_pdf_simple.mai
    python mai_codegen_simple.py summarise_pdf_simple.mai --output out.py
"""

import yaml
import re
import argparse
from pathlib import Path


MAI_TO_PYTHON_TYPES = {
    "String":   "str",
    "String[]": "list[str]",
    "Int":      "int",
    "Float":    "float",
    "Bool":     "bool",
    "File":     "str",
}


def load_mai(path: str) -> dict:
    with open(path) as f:
        return yaml.safe_load(f)


def parse_type_block(name: str, fields: dict) -> dict:
    return {
        "name":   name,
        "fields": {k: MAI_TO_PYTHON_TYPES.get(str(v), "str") for k, v in fields.items()}
    }


def parse_input(name: str, spec: str) -> dict:
    base    = re.match(r"(\w+)", str(spec)).group(1)
    default = re.search(r'default=["\']?([^"\')\s]+)["\']?', str(spec))
    return {
        "name":    name,
        "type":    MAI_TO_PYTHON_TYPES.get(base, "str"),
        "default": default.group(1) if default else None,
    }


def resolve_ref(value) -> str:
    if isinstance(value, str) and value.startswith("$inputs."):
        return value.replace("$inputs.", "")
    if isinstance(value, str) and value.startswith("$"):
        return value[1:]
    if isinstance(value, str):
        return repr(value)
    return str(value)


class CodeGenerator:

    def __init__(self, raw: dict):
        self.raw   = raw
        self.lines = []

    def w(self, line: str = ""):
        self.lines.append(line)

    def generate(self) -> str:
        self._imports()
        self._types()
        self._function()
        return "\n".join(self.lines)

    def _imports(self):
        self.w("import anthropic")
        self.w("import base64")
        self.w("from pydantic import BaseModel")
        self.w()

    def _types(self):
        for key, val in self.raw.items():
            if key in ("workflow", "inputs", "steps", "output"):
                continue
            if isinstance(key, str) and key.startswith("type ") and isinstance(val, dict):
                tname = key[5:].strip()
                t = parse_type_block(tname, val)
                self.w(f"class {t['name']}(BaseModel):")
                for fname, ftype in t["fields"].items():
                    self.w(f"    {fname}: {ftype}")
                self.w()
            elif isinstance(val, dict) and isinstance(key, str) and key[0].isupper():
                t = parse_type_block(key, val)
                self.w(f"class {t['name']}(BaseModel):")
                for fname, ftype in t["fields"].items():
                    self.w(f"    {fname}: {ftype}")
                self.w()

    def _function(self):
        wf_name    = self.raw.get("workflow", "Workflow")
        inputs_raw = self.raw.get("inputs", {})
        steps_raw  = self.raw.get("steps",  [])
        output_raw = self.raw.get("output", {})

        inputs = [parse_input(k, v) for k, v in inputs_raw.items()]
        args   = []
        for inp in inputs:
            if inp["default"]:
                args.append(f'{inp["name"]}: {inp["type"]} = "{inp["default"]}"')
            else:
                args.append(f'{inp["name"]}: {inp["type"]}')

        self.w(f"def {wf_name}({', '.join(args)}):")

        for step in steps_raw:
            self._step(step)

        self._output(output_raw)
        self.w()
        self._entrypoint(wf_name, inputs)

    def _step(self, step: dict):
        use = step.get("use", "")
        if   use == "tool.ReadFile":       self._read_file(step)
        elif use == "tool.TemplateRender": self._template_render(step)
        elif use == "agent.LLM":           self._llm(step)
        elif use == "tool.MergeObjects":   self._merge_objects(step)

    def _read_file(self, step: dict):
        w    = step.get("with", {})
        path = resolve_ref(w.get("path", ""))
        out  = step.get("as", "_result")
        self.w(f'    with open({path}, "rb") as _f:')
        self.w(f'        {out} = base64.b64encode(_f.read()).decode("utf-8")')

    def _template_render(self, step: dict):
        w        = step.get("with", {})
        template = str(w.get("template", "")).strip()
        vars_    = w.get("vars", {}) or {}
        out      = step.get("as", "_result")
        self.w(f'    {out} = {repr(template)}')
        for var, ref in vars_.items():
            val = resolve_ref(ref)
            self.w(f'    {out} = {out}.replace("{{{{ {var} }}}}", {val})')

    def _llm(self, step: dict):
        w       = step.get("with", {})
        model   = w.get("model", "claude-sonnet-4-5")
        system  = resolve_ref(w.get("system", "")) if w.get("system") else None
        prompt  = w.get("prompt", "")
        max_tok = w.get("max_tokens", 1024)
        returns = step.get("returns")
        out     = step.get("as", "_result")

        if isinstance(prompt, str):
            prompt = re.sub(r"\{\{\s*inputs\.(\w+)\s*\}\}", r"{\1}", prompt.strip())
            prompt = re.sub(r"\{\{\s*(\w+)\s*\}\}", r"{\1}", prompt)

        self.w(f"    _client = anthropic.Anthropic()")
        self.w(f"    _resp = _client.messages.create(")
        self.w(f'        model="{model}",')
        self.w(f"        max_tokens={max_tok},")
        if system:
            self.w(f"        system={system},")
        self.w(f"        messages=[{{")
        self.w(f'            "role": "user",')
        self.w(f'            "content": [')
        self.w(f'                {{')
        self.w(f'                    "type": "document",')
        self.w(f'                    "source": {{')
        self.w(f'                        "type": "base64",')
        self.w(f'                        "media_type": "application/pdf",')
        self.w(f'                        "data": pdf_document,')
        self.w(f'                    }}')
        self.w(f'                }},')
        self.w(f'                {{')
        self.w(f'                    "type": "text",')
        self.w(f'                    "text": f"{prompt}",')
        self.w(f'                }}')
        self.w(f'            ]')
        self.w(f"        }}]")
        self.w(f"    )")
        if returns:
            self.w(f'    _raw   = _resp.content[0].text')
            self.w(f'    _clean = _raw.replace("```json", "").replace("```", "").strip()')
            self.w(f'    {out} = {returns}.model_validate_json(_clean)')
        else:
            self.w(f'    {out} = _resp.content[0].text')

    def _merge_objects(self, step: dict):
        w   = step.get("with", {})
        out = step.get("as", "_result")
        pairs = ", ".join(f'"{k}": {resolve_ref(v)}' for k, v in w.items())
        self.w(f"    {out} = {{{pairs}}}")

    def _output(self, output_raw):
        if not output_raw:
            return
        fmt   = output_raw.get("format", "terminal") if isinstance(output_raw, dict) else "terminal"
        value = resolve_ref(output_raw.get("value", "final_result")) if isinstance(output_raw, dict) else resolve_ref(output_raw)

        if fmt == "terminal":
            self.w(f'    print("\\n" + "=" * 50)')
            self.w(f'    print("TITLE")')
            self.w(f'    print("=" * 50)')
            self.w(f'    print({value}["summary"].title)')
            self.w(f'    print("\\nBULLET POINTS")')
            self.w(f'    for b in {value}["summary"].bullets:')
            self.w(f'        print(f"  - {{b}}")')
            self.w(f'    print(f"\\nWORD COUNT: {{{value}[\'summary\'].word_count}}")')
        elif fmt == "txt":
            path = output_raw.get("path", "output.txt")
            self.w(f'    with open("{path}", "w") as _out:')
            self.w(f'        _out.write({value}["summary"].title + "\\n")')
            self.w(f'        for b in {value}["summary"].bullets:')
            self.w(f'            _out.write(f"  - {{b}}\\n")')
            self.w(f'    print("Saved to {path}")')
        elif fmt == "json":
            self.w(f'    import json')
            self.w(f'    print(json.dumps({{')
            self.w(f'        "title":      {value}["summary"].title,')
            self.w(f'        "bullets":    {value}["summary"].bullets,')
            self.w(f'        "word_count": {value}["summary"].word_count,')
            self.w(f'    }}, indent=2))')
        else:
            self.w(f'    return {value}')

    def _entrypoint(self, wf_name: str, inputs: list):
        self.w('if __name__ == "__main__":')
        self.w('    import argparse')
        self.w('    parser = argparse.ArgumentParser()')
        for inp in inputs:
            if inp["name"] == "pdf_path":
                self.w(f'    parser.add_argument("--pdf", required=True, dest="pdf_path")')
            elif inp["default"]:
                self.w(f'    parser.add_argument("--{inp["name"]}", default="{inp["default"]}")')
            else:
                self.w(f'    parser.add_argument("--{inp["name"]}", required=True)')
        self.w('    args = parser.parse_args()')
        call_args = ", ".join(f'{inp["name"]}=args.{inp["name"]}' for inp in inputs)
        self.w(f'    {wf_name}({call_args})')


def main():
    parser = argparse.ArgumentParser(description="Generate Python from a .mai file")
    parser.add_argument("mai_file",       help="Path to .mai file")
    parser.add_argument("--output", "-o", help="Output .py file")
    args = parser.parse_args()

    print(f"[1] Parsing:    {args.mai_file}")
    raw = load_mai(args.mai_file)

    print(f"[2] Generating Python...")
    gen  = CodeGenerator(raw)
    code = gen.generate()

    if args.output:
        Path(args.output).write_text(code)
        print(f"[3] Written to: {args.output}")
        print(f"\nTo run:")
        print(f"    pip install anthropic pydantic")
        print(f"    export ANTHROPIC_API_KEY=sk-ant-...")
        print(f"    python {args.output} --pdf your_doc.pdf --prompt \"Summarise this\"")
    else:
        print()
        print(code)


if __name__ == "__main__":
    main()
