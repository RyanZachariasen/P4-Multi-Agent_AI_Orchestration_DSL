#   
AST.mli   
  
(** ast_v1.mli — Minimal mAI: resource-parametric functions, sequential workflow *)  
  
type name = string  
type loc = { file: string; line: int; col: int }  

type provider = Anthropic | OpenAI | Gemini | Grok
  
type typ =  
  | TText                       (** raw text *)  
  | TInt                        (** compiler generates int() *)  
  | TFloat                      (** compiler generates float() *)  
  | TBool                       (** compiler generates bool parse *)  
  | TCode                       (** text + fence stripping; Code <= Text *)  
  | TFile                       (** file path for builtin tools *)  
  | TNamed of name              (** user-declared record → Pydantic *)  
  
type binop = Add | Sub | Mul | Div | Concat  
  
type expr =  
  | EVar    of name  
  | EString of string
  | EInt    of int
  | EBool   of bool
  | ECall   of name * expr list * name option  
      (** f(a,b) on Sonnet → ECall("f",[a;b], Some "Sonnet")  
          read_pdf(x)      → ECall("read_pdf",[x], None)      *)  
  | EField  of expr * name     (** verdict.score *)
  | EBinOp  of binop * expr * expr  
  
type stmt =  
  | SLet   of name * expr      (** x = f(y) on R *)  
  | SPrint of expr  
  | SWrite of expr * expr      (** write_file(path, content) *)  
  
type resource_decl = {  
  rs_name: name; rs_provider: provider;  
  rs_model: string; max_tokens: int; system_prompt: string; list; rs_loc: loc;
}  (* add more stuff like max-tokens, system prompt*)
  
type func_decl = {
  fn_name: name;  
  fn_params: (name * typ) list;   (** typed parameters *)  
  fn_return: typ;                  (** return type = codegen directive *)  
  fn_needs_resource: bool;         (** true → call site must provide "on R" *)  
  fn_prompt: string option * (name * typ) list;        (** prompt template with {holes} and computed either at parsing or and type checking time the list of used parameters as holes — maybe you can remove that part for now *)  
  fn_builtin: bool;                (** true for read_pdf etc *)  
  fn_loc: loc;  
}  
  
type type_decl = {  
  td_name: name;  
  td_fields: (name * typ) list;  
  td_loc: loc;  
}  
  
type decl =  
  | DResource of resource_decl  
  | DFunc of func_decl  
  | DType of type_decl  
  
type workflow = {  
  wf_name: name;  
  wf_params: (name * typ) list;  
  wf_body: stmt list;  
  wf_loc: loc;  
}  
  
type program = {  
  prog_decls: decl list;  
  prog_workflow: workflow;  
}  
