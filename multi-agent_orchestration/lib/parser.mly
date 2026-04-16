%{
  open Parsing
  open Ast

  let function_env = Hashtbl.create 8
  let custom_type_env = Hashtbl.create 8
  let variable_env = Hashtbl.create 8

  (* CREATE HASHTABLE FOR FUNCTIONS *)
    (* Check if exists *)
    (* Check for arity *)
    (* assign type *)



%}

%token <string> IDENT

%token TINT TCODE TFLOAT TBOOL TTEXT TFILE 

%token <int> INT
%token <string> FILE
%token <string> TEXT
%token <string> CODE
%token <float> FLOAT
%token <bool> BOOL

%token COMMA LBRACE RBRACE DOT LPAREN RPAREN ASSIGN

%token WRITE_FILE READ_FILE PRINT

%token PLUS MINUS TIMES DIV CONCAT

%token RESOURCE ANTHROPIC OPENAI GEMINI GROK

%token FUNC ARROW WORKFLOW TYPE

%token EOF

/* Precedence rules to handle ambiguity (Week 4-5 content) */
%left PLUS MINUS
%left TIMES DIV
%start <Ast.file> file
%%

file:
| expr_list = list(expr); EOF { expr_list };

expr:
| ident = IDENT { EVar ident }

| const = constant { EConst const }
| expr_1 = expr; opperand = opperand; expr_2 = expr { EBinOp (opperand, expr_1, expr_2)}
| expr = expr; DOT; ident = IDENT { EField (expr, ident) }
;

type: 
| TINT {TInt}| TCODE {TCode} | TFLOAT {TFloat} | TBOOL {TBool}| TTEXT {TText}| TFILE {TFile}

opperand:
| PLUS {Add} | MINUS {Sub} |  TIMES {Mul} | DIV {Div} | CONCAT {Concat}

constant:
| const = INT { CInt const }
| const = TEXT { CText const }
| const = FLOAT { CFloat const }
| const = BOOL { CBool const }
| const = CODE { CCode const }
| const = FILE { CFile const }
;

stmt:
| ident = IDENT; ASSIGN; expr = expr  { SLet (ident, expr) }
| PRINT; LPAREN; expr = expr RPAREN; { SPrint expr }
| WRITE_FILE ; LPAREN ; file = FILE ; COMMA; expr = expr; RPAREN { SWriteFile (file, expr)}
| READ_FILE ; LPAREN ; file = FILE ; RPAREN { SReadFile file }

declaration:
| RESOURCE; ident=IDENT; ASSIGN; provider=provider; LPAREN; model=TEXT; optionals=resource_optionals; RPAREN  { 
    let (max_tokens, system_prompt) = optionals in
    DResource {
      resourceName = ident, 
      resourceProvider = provider, 
      resourceModel = model, 
      max_tokens = max_tokens, 
      system_prompt = system_prompt, 
      resourceLocation = { $startpos.pos_fname; $startpos.pos_lnum, $endpos.pos_cnum }
    }
  }
| TYPE; ident = IDENT; ASSIGN; LBRACE; exprList = separated_list(COMMA, custom_type_field) ; RBRACE; { CCustomType (ident, exprList) }

| FUNC; ident = IDENT; LPAREN; func_params = separated_list(COMMA, func_parameter); RPAREN; ARROW; return_type = TYPE; COLON; 
    { Hashtbl.add function_env ident (func_params, return_type) 
      DFunc {
        name=ident;
        func_params=func_params;
        func_return=return_type;
        
      }
    }

;

func_parameter:
| ident = IDENT ; COLON ; typ = type; {(ident, typ)}

custom_type_field:
| ident = IDENT ; ASSIGN ; expr = expr { (ident, expr) }
;

resource_optionals: 
| { (None, None) }

| COMMA ; ident = IDENT ; ASSIGN ; system_prompt = TEXT; rest = resource_optionals {
  let (max_tokens, _) = rest in
  (max_tokens, system_prompt) }

| COMMA ; ident = IDENT ; ASSIGN ; max_tokens = INT; rest = resource_optionals {
  let (_, system_prompt) = rest in
  (max_tokens, system_prompt) }

provider:
| GROK { Grok }
| OPENAI { OpenAI }
| ANTHROPIC { Anthropic }
| GEMINI { Gemini }