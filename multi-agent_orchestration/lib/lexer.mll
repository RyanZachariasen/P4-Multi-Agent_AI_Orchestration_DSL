{
  open Parser
  exception Error of string
}

let digit = ['0'-'9']
let alpha = ['a'-'z' 'A'-'Z']
let ident = alpha (alpha | digit | '_')*

rule token = parse
  | [' ' '\t' '\n'] { token lexbuf } (* Skip whitespace *)
  | "if"            { IF }
  | "else"          { ELSE }
  | "spawn"         { SPAWN }
  | '='             { ASSIGN }
  | '+'             { PLUS }
  | '-'             { MINUS }
  | '*'             { TIMES }
  |','              {COMMA}
  | '/'             { DIV }
  | '('             { LP }
  | ')'             { RP }
  | '{'             { LBRACE }
  | '}'             { RBRACE }
  | digit+ as n     { INT (int_of_string n) }
  | ident as id     { IDENT id }
  | eof             { EOF }
  | _               { raise (Error ("Unexpected character: " ^ Lexing.lexeme lexbuf)) }
  | "type"          {TYPE}
  | "func"          {FUNC}
  | "resource".     {RESOURCE}
  | "text".         {TEXT}
  | "Code".         {CODE}
  | "on resource"   {ON RESOURCE}
  | ':'             {:}
  | '"'             {""}
  | "->".           {ARROW}
  | "string".       {STRING}
  | "int".          {INT}
  | "workflow".     {WORKFLOW}
  | "print".        {PRINT}
  | "Bool".         {BOOL}
  | "anthropic".    {ANTHROPIC}
  | "openai".       {OPENAI}
  | "gemini".       {GEMINI}
  | "double".       {DOUBLE}
  
  and comment = parse
  | "*/" { () }
  | '\n' { newline lexbuf; comment lexbuf }
  | _    { comment lexbuf }
  | eof  { raise (Lexical_error "unterminated comment") }

