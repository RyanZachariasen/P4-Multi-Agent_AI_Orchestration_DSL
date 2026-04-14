{
  open Lexing
  open Ast
  open Parser
  exception Lexing_error of string


(*--------------------Keywords--------------------*)
  let id_or_keyword =
    let h = Hashtbl.create 32 in
    List.iter (fun (s, tok) -> Hashtbl.add h s tok)
      [
        "def", DEF; "if", IF; "else", ELSE;
        
        "workflow", WORKFLOW; "resource", RESOURCE; "func", FUNC;
        "type", TYPE; "on", ON;

        "anthropic", ANTHROPIC; "openai", OPENAI; "gemini", GEMINI;

        "string", STRING; "int", INT; "double", DOUBLE; "bool", BOOL;
        "Text", TEXT; "File", FILE; "Code", CODE;

        "True", CST (Cbool true); "False", CST (Cbool false);
        "builtin", BUILTIN;
        
        ];
   fun s -> try Hashtbl.find h s with Not_found -> IDENT s
(*----------------------------------------------*)


  let string_buffer = Buffer.create 1024

  let stack = ref [0]  (* indentation stack *)

  let rec unindent n = match !stack with
    | m :: _ when m = n -> []
    | m :: st when m > n -> stack := st; END :: unindent n
    | _ -> raise (Lexing_error "bad indentation")

  let update_stack n =
    match !stack with
    | m :: _ when m < n ->
      stack := n :: !stack;
      [NEWLINE; BEGIN]
    | _ ->
      NEWLINE :: unindent n
}

(*----------------------REGEX----------------------*)
let letter = ['a'-'z' 'A'-'Z']
let digit = ['0'-'9']
let ident = (letter | '_') (letter | digit | '_')*
let integer = '0' | ['1'-'9'] digit*
let space = ' ' | '\t'



rule next_tokens = parse
  | '\n'    { new_line lexbuf; update_stack (indentation lexbuf) }
  | (space | comment)+
                    { next_tokens lexbuf }
  | "/*"            { comment lexbuf; next_tokens lexbuf }
  | "\"\"\""        { [CST (Cstring (triple_string lexbuf))] }
  |','              { [COMMA] }
  |'.'              { [DOT] }
  |'='              { [ASSIGN] }
  | '('             { [LPAREN] }
  | ')'             { [RPAREN] }
  | '{'             { [LBRACE] }
  | '}'             { [RBRACE] }
  | ':'             { [COLON] }
  | '"'             { [CST (Cstring (string lexbuf))] }
  | "->"            {[ARROW]}
  | integer as s
            { try [CST (Cint (Int64.of_string s))]
              with _ -> raise (Lexing_error ("constant too large: " ^ s)) }
  | ident as id     { [id_or_keyword id]}
  | _               { raise (Lexical_error ("Unexpected character: " ^ Lexing.lexeme lexbuf)) }
  | eof             { [EOF] }
  | _ as c  { raise (Lexing_error ("illegal character: " ^ String.make 1 c)) }

(*--------------------------------------------------*)



and string = parse
  | '"' { let s = Buffer.contents string_buffer in Buffer.reset string_buffer; s }
  | "\\n" { Buffer.add_char string_buffer '\n'; string lexbuf }
  | "\\\"" { Buffer.add_char string_buffer '"'; string lexbuf }
  | _ as c { Buffer.add_char string_buffer c; string lexbuf }
  | eof { raise (Lexing_error "unterminated string") }


and comment = parse
  | "*/" { () }
  | '\n' { newline lexbuf; comment lexbuf }
  | _    { comment lexbuf }
  | eof  { raise (Lexical_error "unterminated comment") }


and triple_string = parse
  | "\"\"\""        { let s = Buffer.contents string_buffer in Buffer.reset string_buffer; s }
  | _ as c          { Buffer.add_char string_buffer c; triple_string lexbuf }
  | eof             { raise (Lexing_error "unterminated triple string") }

and indentation = parse
  | (space | comment)* '\n'{ new_line lexbuf; indentation lexbuf }
  | space* as s { String.length s }


{
  let next_token =
    let tokens = Queue.create () in (* next tokens to emit *)
    fun lb ->
      if Queue.is_empty tokens then begin
	let l = next_tokens lb in
	List.iter (fun t -> Queue.add t tokens) l
      end;
      Queue.pop tokens
}