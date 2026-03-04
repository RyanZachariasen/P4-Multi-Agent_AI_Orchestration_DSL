%{
  open Ast
%}

%token <int> INT
%token <string> IDENT
%token IF ELSE SPAWN ASSIGN
%token PLUS MINUS TIMES DIV
%token LP RP LBRACE RBRACE
%token EOF

/* Precedence rules to handle ambiguity (Week 4-5 content) */
%left PLUS MINUS
%left TIMES DIV

%start <Ast.file> file

%%

file:
| s = list(stmt); EOF { s }

stmt:
| id = IDENT; ASSIGN; e = expr { Sassign(id, e) }
| SPAWN; id = IDENT { Sspawn(id) }
| IF; e = expr; s1 = stmt; ELSE; s2 = stmt { Sif(e, s1, s2) }
| LBRACE; s = list(stmt); RBRACE { Sblock(s) }

expr:
| n = INT { Econst(n) }
| id = IDENT { Evar(id) }
| e1 = expr; op = binop; e2 = expr { Ebinop(op, e1, e2) }

%inline binop:
| PLUS { Add } | MINUS { Sub } | TIMES { Mul } | DIV { Div }