%{
  open Parsing
  open Ast
  open Lexing
%}

%token <string> IDENT

%token TINT TCODE TFLOAT TBOOL TTEXT TFILE 

%token <int> INT

%token <string> TEXT

%token <float> FLOAT
%token <bool> BOOL
%token <string> PROMPT
%token <string> HOLE

%token COMMA LBRACE RBRACE DOT LPAREN RPAREN ASSIGN COLON BEGIN END

%token WRITE_FILE READ_FILE PRINT

%token PLUS MINUS TIMES DIV

%token RESOURCE ANTHROPIC OPENAI GEMINI GROK

%token FUNC ARROW WORKFLOW TYPE ON MAX_TOKENS SYSTEM_PROMPT WHILE

%token NEWLINE

%token EOF

/* Precedence rules to handle ambiguity (Week 4-5 content) */
%left PLUS MINUS
%left TIMES DIV
%start <Ast.program> program
%%

program:
| NEWLINE? decls = list(declaration); NEWLINE?; wf = workflow; NEWLINE?; EOF;
      { { prog_decls    = decls;
          prog_workflow = wf } }

workflow:
| WORKFLOW ; COLON ; NEWLINE; BEGIN; body = list(stmt); END;  
  { { workflow_body = body;
    workflow_location = {
          file = $startpos.pos_fname;
          line = $startpos.pos_lnum;
          col  = $startpos.pos_cnum - $startpos.pos_bol;
        };
    }
  }

expr:
| node = expr_node
  {
    { expr_node = node;
      expr_location = {
          file = $startpos.pos_fname;
          line = $startpos.pos_lnum;
          col  = $startpos.pos_cnum - $startpos.pos_bol;
        };
    }
  }

expr_node:
| ident = IDENT { EVar ident }
| const = constant { EConst const }
| ident = IDENT; LPAREN; args = separated_list(COMMA, expr); RPAREN
    { ECall (ident, List.map (fun e -> e) args, None) }

| ident = IDENT; LPAREN; args = separated_list(COMMA, expr); RPAREN; ON; r = IDENT
    { ECall (ident, List.map (fun e -> e) args, Some r) }
| expr_1 = expr; DOT; ident = IDENT { EField (expr_1, ident) }
| expr_1 = expr; operand = operand; expr_2 = expr { EBinOp (operand, expr_1, expr_2)}
| READ_FILE ; LPAREN ; arg = expr ; RPAREN { EReadFile arg }
;

typ: 
| TINT {TInt}| TCODE {TCode} | TFLOAT {TFloat} | TBOOL {TBool}| TTEXT {TText}| TFILE {TFile} | ident = IDENT { TCustomType ident }

operand:
| PLUS {Add} | MINUS {Sub} |  TIMES {Mul} | DIV {Div}

constant:
| const = INT { CInt const }
| const = TEXT { CText const }
| const = FLOAT { CFloat const }
| const = BOOL { CBool const }
;

stmt:
| node = stmt_node NEWLINE?;
  {
    { statement_node = node;
      statement_location = {
          file = $startpos.pos_fname;
          line = $startpos.pos_lnum;
          col  = $startpos.pos_cnum - $startpos.pos_bol;
      }; 
    }
  } 

stmt_node:
| ident = IDENT; ASSIGN; expr = expr  { SLet (ident, expr) }
| PRINT; LPAREN; expr = expr RPAREN; { SPrint expr }
| WRITE_FILE ; LPAREN ; file = TEXT ; COMMA; expr = expr; RPAREN { 
    SWriteFile ({
      expr_node= EConst (CFile file);
      expr_location = {
          file = $startpos.pos_fname;
          line = $startpos.pos_lnum;
          col  = $startpos.pos_cnum - $startpos.pos_bol;
        };
    }, expr)}
| WHILE; e = expr; COLON; NEWLINE; BEGIN; s = list(stmt); NEWLINE?; END; { SWhile (e, s)}

declaration:
| RESOURCE; ident=IDENT; ASSIGN; provider=provider; LPAREN; model=TEXT; optionals=resource_optionals; RPAREN ; NEWLINE { 
    let (max_tokens, system_prompt) = optionals in
    DResource {
      resource_name = ident;
      resource_provider = provider;
      resource_model = model;
      max_tokens = max_tokens;
      system_prompt = system_prompt;
      resource_location  = {
          file = $startpos.pos_fname;
          line = $startpos.pos_lnum;
          col  = $startpos.pos_cnum - $startpos.pos_bol;
      };
    }
  }
| TYPE; ident = IDENT; ASSIGN; LBRACE;
  fields = separated_list(COMMA, custom_type_field);
  RBRACE; NEWLINE;
  {
    DCustomType {
      type_name = ident;
      type_fields = fields;
      type_location = {
        file = $startpos.pos_fname;
        line = $startpos.pos_lnum;
        col  = $startpos.pos_cnum - $startpos.pos_bol;
      };
    }
  }


| FUNC; ident = IDENT; LPAREN;
  func_params = separated_list(COMMA, func_parameter); RPAREN;
  ARROW; return_type = typ; COLON; NEWLINE;
  BEGIN;
  ON ; RESOURCE ; NEWLINE ;
  prompt = list(prompt_part); 
  NEWLINE;
  END; 
      {
      let function_declaration = {
        func_name = ident;
        func_params = func_params;
        func_return = return_type;
        func_needs_resource = true;
        func_prompt = prompt;
        func_body = [];
        func_builtin = false;
        func_location = {
          file = $startpos.pos_fname;
          line = $startpos.pos_lnum;
          col  = $startpos.pos_cnum - $startpos.pos_bol;
        };
      } in
      DFunc function_declaration }
| FUNC; ident = IDENT; LPAREN;
  func_params = separated_list(COMMA, func_parameter); RPAREN;
  ARROW; return_type = typ; COLON; NEWLINE;
  BEGIN;
  body = nonempty_list(stmt);
  END;
      {
      let function_declaration = {
        func_name = ident;
        func_params = func_params;
        func_return = return_type;
        func_needs_resource = false;
        func_prompt = [];
        func_body = body;
        func_builtin = false;
        func_location = {
          file = $startpos.pos_fname;
          line = $startpos.pos_lnum;
          col  = $startpos.pos_cnum - $startpos.pos_bol;
        };
      } in
      DFunc function_declaration }

prompt_part:
| text = PROMPT { PromptText text }
| name = HOLE   { PromptHole { expr_node = EVar name; 
  expr_location = { file = $startpos.pos_fname; 
  line = $startpos.pos_lnum; 
  col  = $startpos.pos_cnum - $startpos.pos_bol } } }

func_parameter:
| ident = IDENT ; COLON ; typ = typ; {(ident, typ)}

custom_type_field:
| ident = IDENT; COLON; typ = typ { (ident, typ) }


resource_optionals: 
| { (None, None) }
| COMMA ; SYSTEM_PROMPT ; ASSIGN ; system_prompt = TEXT; rest = resource_optionals {
  let (max_tokens, _) = rest in
  (max_tokens, Some system_prompt) }
| COMMA ; MAX_TOKENS ; ASSIGN ; max_tokens = INT; rest = resource_optionals {
  let (_, system_prompt) = rest in
  (Some max_tokens, system_prompt) }

provider:
| GROK { Grok }
| OPENAI { OpenAI }
| ANTHROPIC { Anthropic }
| GEMINI { Gemini }
