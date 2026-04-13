%{
  open Parsing
  open Ast
  (* CREATE HASHTABLE FOR FUNCTIONS *)
    (* Check if exists *)
    (* Check for arity *)
    (* assign type *)

%}

%token <Ast.constant> CONST
%token <string> IDENT

%token <int> INT
%token <string> FILE
%token <string> TEXT
%token <string> CODE
%token <float> FLOAT
%token <bool> BOOL

%token COMMA ASSIGN LBRACE RBRACE RECORD DOT PRINT LPAREN RPAREN WRITE READ
%token PLUS MINUS TIMES DIV CONCAT
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
| expr1 = expr; opperand = opperand; expr2 = expr { EBinOp (opperand, expr1, expr2)}
| expr = expr; DOT; ident = IDENT { EField (expr, ident) }
;

opperand:
| PLUS {Add} | MINUS {Sub} |  TIMES {Mul} | DIV {Div} | CONCAT {Concat}

constant:
| const = INT { CInt const }
| const = TEXT { CText const }
| const = FLOAT { CFloat const }
| const = BOOL { CBool const }
| const = CODE { CCode const }
| const = FILE { CFile const }
| RECORD; ident = IDENT; ASSIGN; LBRACE; exprList = separated_list(COMMA, recordField) ; RBRACE; { CRecord (ident, exprList) }
;
recordField:
| ident = IDENT ; ASSIGN ; expr = expr { (ident, expr) }
;

stmt:
| ident = IDENT; ASSIGN; expr = expr  { SLet (ident, expr) }
| PRINT; LPAREN; expr=expr RPAREN; { SPrint expr }
| WRITE ; LPAREN ; file = FILE ; COMMA; expr = expr; RPAREN { SWriteFile(file, expr )}
| READ ; LRPAREN ; file = FILE ; RPAREN { SReadFile file }
