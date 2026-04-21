%{
  open Parsing
  open Ast
  open Typing
%}

%token <string> IDENT

%token TINT TCODE TFLOAT TBOOL TTEXT TFILE 

%token <int> INT
%token <string> FILE
%token <string> TEXT
%token <string> CODE
%token <float> FLOAT
%token <bool> BOOL

%token COMMA LBRACE RBRACE DOT LPAREN RPAREN ASSIGN COLON ON_RESOURCE BEGIN END

%token WRITE_FILE READ_FILE PRINT

%token PLUS MINUS TIMES DIV CONCAT

%token RESOURCE ANTHROPIC OPENAI GEMINI GROK

%token FUNC ARROW WORKFLOW TYPE

%token NEWLINE

%token EOF

/* Precedence rules to handle ambiguity (Week 4-5 content) */
%left PLUS MINUS
%left TIMES DIV
%start <Ast.program> program
%%

program:
| decls = separated_list(NEWLINE, declaration); wf = workflow; EOF
      { { prog_decls    = decls;
          prog_workflow = wf } }

workflow:
| WORKFLOW ; COLON ; BEGIN ; body = separated_list(NEWLINE, stmt) ; END { 
{ workflow_body = body;
  workflow_location = { file = $startpos.pos_fname; line = $startpos.pos_lnum; col = $endpos.pos_cnum };
}


expr:
| node = expr_node { { expr_node = node; expr_location = { file = $startpos.pos_fname; line = $startpos.pos_lnum; col = $endpos.pos_cnum } } }


expr_node:
| ident = IDENT { EVar ident }
| const = constant { EConst const }
| expr_1 = expr; operand = operand; expr_2 = expr { EBinOp (operand, expr_1, expr_2)}
| expr = expr; DOT; ident = IDENT { EField (expr, ident) }
;

typ: 
| TINT {TInt}| TCODE {TCode} | TFLOAT {TFloat} | TBOOL {TBool}| TTEXT {TText}| TFILE {TFile}

operand:
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
| READ_FILE ; LPAREN ; file = FILE ; RPAREN { SReadFile (EConst (CFile file)) }

declaration:
| RESOURCE; ident=IDENT; ASSIGN; provider=provider; LPAREN; model=TEXT; optionals=resource_optionals; RPAREN  { 
    let (max_tokens, system_prompt) = optionals in
    DResource {
      resource_name = ident; 
      resource_provider = provider;
      resource_model = model;
      max_tokens = max_tokens;
      system_prompt = system_prompt;
      resource_location = { file = $startpos.pos_fname; line = $startpos.pos_lnum; col = $endpos.pos_cnum }
    }
  }
| TYPE; ident = IDENT; ASSIGN; LBRACE; exprList = separated_list(COMMA, custom_type_field) ; RBRACE; { CCustomType (ident, exprList) }

| FUNC; ident = IDENT;
  LPAREN; func_params = separated_list(COMMA, func_parameter); RPAREN;
  ARROW; return_type = typ;
  ON_RESOURCE;
  prompt = TEXT;
    { Hashtbl.add Typing.function_env ident (func_params, return_type);
      DFunc {
        func_name = ident;
        func_params = func_params;
        func_return = return_type;
        func_needsResource = true;
        func_prompt = Some prompt;
        func_prompt_holes = [];
        func_builtin = false;
        func_location = { file = $startpos.pos_fname; line = $startpos.pos_lnum; col = $endpos.pos_cnum };
      } }

func_parameter:
| ident = IDENT ; COLON ; typ = typ; {(ident, typ)}

custom_type_field:
| ident = IDENT ; ASSIGN ; expr = expr { (ident, expr) }
;

resource_optionals: 
| { (None, None) }

| COMMA ; ident = IDENT ; ASSIGN ; system_prompt = TEXT; rest = resource_optionals {
  let (max_tokens, _) = rest in
  (max_tokens, Some system_prompt) }

| COMMA ; ident = IDENT ; ASSIGN ; max_tokens = INT; rest = resource_optionals {
  let (_, system_prompt) = rest in
  (Some max_tokens, system_prompt) }

provider:
| GROK { Grok }
| OPENAI { OpenAI }
| ANTHROPIC { Anthropic }
| GEMINI { Gemini }