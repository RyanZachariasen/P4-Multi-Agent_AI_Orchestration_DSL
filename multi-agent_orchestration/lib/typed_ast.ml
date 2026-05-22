
type name = string
type provider = Anthropic | OpenAI | Gemini | Grok

type typ =
  | TText
  | TInt
  | TFloat
  | TBool
  | TCode
  | TFile
  | TCustomType of name

type constant =
  | CText  of string
  | CInt   of int
  | CFloat of float
  | CBool  of bool
  | CCode  of string
  | CFile  of string
  | CCustomType of name

type binop = Add | Sub | Mul | Div


type expr = {
  expr_node: expr_node;
  expr_typ:  typ;
}

and expr_node =
  | EVar   of name
  | EConst of constant
  | ECall  of name * expr list * name option
  | EField of expr * name * typ
  | EBinOp of binop * expr * expr
  | EReadFile of expr

and resource_declaration = {
  resource_name:     name;
  resource_provider: provider;
  resource_model:    string;
  max_tokens:        int option;
  system_prompt:     string option;
}

type statement =
  | SLet       of name * typ * expr
  | SPrint     of expr
  | SWhile     of expr * statement list
  | SIf        of expr * statement list * statement list option
  | SWriteFile of expr * expr


type prompt_part =
  | PromptText of string
  | PromptHole of expr   

type func_declaration = {
  func_name:          name;
  func_params:        (name * typ) list;
  func_return:        typ;
  func_needs_resource: bool;
  func_prompt:        prompt_part list;
  func_body:          statement list;
}
type custom_type_declaration = {
  type_name:     name;
  type_fields:   (name * typ) list;
}

type declaration =
  | DResource   of resource_declaration
  | DFunc       of func_declaration
  | DCustomType of custom_type_declaration

type workflow = {
  workflow_name:   name;
  workflow_params: (name * typ) list;
  workflow_body:   statement list;
}

type program = {
  prog_decls:    declaration list;
  prog_workflow: workflow;
}
