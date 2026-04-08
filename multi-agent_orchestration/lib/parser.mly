%{
  open Ast
%}

%token <int> INT
%token <string> IDENT
%token PLUS MINUS TIMES DIV CONCAT
%token EOF

/* Precedence rules to handle ambiguity (Week 4-5 content) */
%left PLUS MINUS
%left TIMES DIV

%start <Ast.file> file

%%

file:
| s = list(Ast.stmt); EOF { s }

