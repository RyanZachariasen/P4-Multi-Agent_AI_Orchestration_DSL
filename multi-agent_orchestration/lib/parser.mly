%{
  open Ast
%}

%token <Ast.constant> CONST
%token <int> INT

%token <string> VAR
%token PLUS MINUS TIMES DIV CONCAT
%token EOF

/* Precedence rules to handle ambiguity (Week 4-5 content) */
%left PLUS MINUS
%left TIMES DIV
%start file
%type <Ast.file> file %%

file:
| s = nonempty_list(expr); EOF { s }

expr:
| c = CONST { EConst c }
| e1 = expr PLUS e1 = expr { EBinOp (Add, e1, e2)}
| e1 = expr; MINUS; e1 = expr { EBinOp (Sub, e1, e2)}
| e1 = expr; TIMES; e1 = expr; { EBinOp (Mul, e1, e2)}
| e1 = expr; DIV; e1 = expr; { EBinOp (Div, e1, e2)}
| e1 = expr; CONCAT; e1 = expr; { EBinOp (Concat, e1, e2)}