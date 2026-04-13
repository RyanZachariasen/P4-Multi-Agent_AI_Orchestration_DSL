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
  | TRecord of name 

type expr = 
  | EVar of name
  | EConst of constant
  | ECall  of name * expr list * name option  
      (** f(a,b) on Sonnet → ECall("f",[a;b], Some "Sonnet")  
          read_pdf(x)      → ECall("read_pdf",[x], None)      *)  
  | EField  of expr * name  (** verdict.score *)
  | EBinOp  of binop * expr * expr  

and constant =  
  | CText of string                (** raw text *)  
  | CInt of int                  (** compiler generates int() *)  
  | CFloat of float                (** compiler generates float() *)  
  | CBool of bool                (** compiler generates bool parse *)  
  | CCode of string                 (** text + fence stripping; Code <= Text *)  
  | CFile of string                   (** file path for builtin tools *)  
  | CCustomType of name           (** user-declared record → Pydantic *)  

and binop = Add | Sub | Mul | Div | Concat  

type stmt =  
  | SLet   of name * expr      (** x = f(y) on R *)  
  | SPrint of expr  
  | SWriteFile of expr * expr
  | SReadFile of expr      (** write_file(path, content) *)  
  
type resourceDeclaration = {  
  resourceName: name;
  resourceProvider: provider;  
  resourceModel: string;
  maxTokens: int option;
  systemPrompt: string option; 
  resourceLocation: location;
}  (* add more stuff like max-tokens, system prompt*)



type funcDeclaration = {
  funcName: name;  
  funcParams: (name * typ) list;   (** typed parameters *)  
  funcReturn: typ;                  (** return type = codegen directive *)  
  funcNeedsResource: bool;         (** true → call site must provide "on R" *)  
  funcPrompt: string option * (name * typ) list;        (** prompt template with {holes} and computed either at parsing or and type checking time the list of used parameters as holes — maybe you can remove that part for now *)  
  funcBuiltin: bool;                (** true for read_pdf etc *)  
  funcLocation: location;  
}  

type customTypeDeclaration = {  
  tdName: name;  
  tdFields: (name * typ) list;  
  tdLocation: location;  
}

type declaration =  
  | DResource of resourceDeclaration  
  | DFunc of funcDeclaration  
  | DCustomType of customTypeDeclaration  

type workflow = {  
  workflowName: name;  
  wf_params: (name * typ) list;  
  wf_body: stmt list;  
  wf_loc: location;  
}  
  
type program = {  
  prog_decls: declaration list;  
  prog_workflow: workflow;  
}

type file = expr list