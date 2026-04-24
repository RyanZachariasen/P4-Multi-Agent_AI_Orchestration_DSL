(** ast_v1.mli — Minimal mAI: resource-parametric functions, sequential workflow *)  
  
type name = string  
type location = { file: string; line: int; col: int }  

type provider = Anthropic | OpenAI | Gemini | Grok

type typ =  
  | TText              (** raw text *)  
  | TInt                   (** compiler generates int() *)  
  | TFloat             (** compiler generates float() *)  
  | TBool                 (** compiler generates bool parse *)  
  | TCode                  (** text + fence stripping; Code <= Text *)  
  | TFile             (** file path for builtin tools *)  
  | TCustomType of name 

and constant =  
  | CText of string                (** raw text *)  
  | CInt of int                  (** compiler generates int() *)  
  | CFloat of float                (** compiler generates float() *)  
  | CBool of bool                (** compiler generates bool parse *)  
  | CCode of string                 (** text + fence stripping; Code <= Text *)  
  | CFile of string                   (** file path for builtin tools *)  
  | CCustomType of name           (** user-declared record → Pydantic *)  
  
type expr =
  { expr_node: expr_node;
    expr_location: location}

and expr_node = 
  | EVar of name
  | EConst of constant
  | ECall  of name * expr list * name option  
      (** f(a,b) on Sonnet → ECall("f",[a;b], Some "Sonnet")  
          read_pdf(x)      → ECall("read_pdf",[x], None)      *)  
  | EField  of expr * name   (** verdict.score *)
  | EBinOp  of binop * expr * expr


and binop = Add | Sub | Mul | Div | Concat  

type statement = 
  {statement_node: statement_node;
   statement_location: location}

and statement_node =  
  | SLet   of name * expr      (** x = f(y) on R *)  
  | SPrint of expr
  | SWriteFile of expr * expr
  | SReadFile of expr      (** write_file(path, content) *)  
  
type resource_declaration = {  
  resource_name: name;
  resource_provider: provider;  
  resource_model: string;
  max_tokens: int option;
  system_prompt: string option; 
  resource_location: location;
}  (* add more stuff like max-tokens, system prompt*)


type func_declaration = {
  func_name: name;  
  func_params: (name * typ) list;   (** typed parameters *)  
  func_return: typ;                  (** return type = codegen directive *)  
  func_needs_resource: bool;         (** true → call site must provide "on R" *)  
  func_prompt: string option;        (** prompt template **)
  func_prompt_holes:  (name * typ) list; (** prompt holes that corresponds to the func_params **)
  func_builtin: bool;                (** true for read_pdf etc *)  
  func_location: location;  
}  


(*
x = read_file("hello.txt")
y = read_code("hello.py")
z = read_pdf("hello.pdf")
q = "hello"
w = 42


*)

type custom_type_declaration = {  
  type_name: name;  
  type_fields: (name * typ) list;  
  type_location: location;  
}

type declaration =  
  | DResource of resource_declaration  
  | DFunc of func_declaration  
  | DCustomType of custom_type_declaration  

type workflow = {  
  workflow_body: statement_node list;  
  workflow_location: location;  
}  
  
type program = {  
  prog_decls: declaration list;  
  prog_workflow: workflow;  
}

