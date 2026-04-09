%{
  open Parsing
  open Ast
  (* CREATE HASHTABLE FOR FUNCTIONS *)
    (* Check if exists *)
    (* Check for arity *)
    (* assign type *)

%}

%token <Ast.constant> CONST
%token <int> INT

%token <string> VAR
%token PLUS MINUS TIMES DIV CONCAT
%token EOF

/* Precedence rules to handle ambiguity (Week 4-5 content) */
%left PLUS MINUS
%left TIMES DIV
%start <Ast.file> file
%%

file:
| el = list(expr); EOF { el };

expr:
| c = constant { EConst c }
| e1 = expr; opperand = opperand; e2 = expr { EBinOp (opperand, e1, e2)}
;

opperand:
| PLUS {Add} | MINUS {Sub} |  TIMES {Mul} | DIV {Div} | CONCAT {Concat}

constant:
| c = INT { CInt c }
| c = TEXT { CText c }
| c = FLOAT { CFloat c }
| c = BOOL { CBool c }
| c = CODE { CCode c }
| c = FILE { CFile c }
| c = RECORD { CRecord c }
;

stmt:
| c = SL