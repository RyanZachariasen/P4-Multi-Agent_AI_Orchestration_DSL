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
        "workflow", WORKFLOW; "Resource", RESOURCE; "func", FUNC; "type", TYPE;

        "anthropic", ANTHROPIC; "openai", OPENAI; "gemini", GEMINI; "grok", GROK; 
    
        "int", TINT; "float", TFLOAT; "bool", TBOOL;
        "write_file", WRITE_FILE; "read_file", READ_FILE; "print", PRINT;
        
        "Text", TTEXT; "File", TFILE; "Code", TCODE;

        "True", BOOL(true); "False", BOOL(false);
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
  | space+
                    { next_tokens lexbuf }
  | "/*"            { comment lexbuf; next_tokens lexbuf }
  | "\"\"\""        { [TEXT (triple_string lexbuf)] }
  | "$"             { [TEXT (triple_string lexbuf)] }
  | "->"            { [ARROW] }
  |','              { [COMMA] }
  |'.'              { [DOT] }
  |'='              { [ASSIGN] }
  | '('             { [LPAREN] }
  | ')'             { [RPAREN] }
  | '{'             { [LBRACE] }
  | '}'             { [RBRACE] }
  | ':'             { [COLON] }
  | '"'             { [TEXT (string lexbuf)] }
  | '+'             { [PLUS] }
  | '-'             { [MINUS] }
  | '*'             { [TIMES] }
  | '/'             { [DIV] }
  | integer as s
            { try [INT (int_of_string s)]
              with _ -> raise (Lexing_error ("constant too large: " ^ s)) }
  | ident as id     { [id_or_keyword id]}
  | eof             { unindent 0 @ [EOF] } (* appends END TOKENS from unindent 0*)
  | _ as c  { raise (Lexing_error ("illegal character: " ^ String.make 1 c)) }



and string = parse
  | '"' { let s = Buffer.contents string_buffer in Buffer.reset string_buffer; s }
  | "\\n" { Buffer.add_char string_buffer '\n'; string lexbuf }
  | "\\\"" { Buffer.add_char string_buffer '"'; string lexbuf }
  | _ as c { Buffer.add_char string_buffer c; string lexbuf }
  | eof { raise (Lexing_error "unterminated string") }


and comment = parse
  | "*/" { () }
  | '\n' { new_line lexbuf; comment lexbuf }
  | _    { comment lexbuf }
  | eof  { raise (Lexing_error "unterminated comment") }


and triple_string = parse
  | "\"\"\""        { let s = Buffer.contents string_buffer in Buffer.reset string_buffer; s }
  | "$"             { let s = Buffer.contents string_buffer in Buffer.reset string_buffer; s}
  | _ as c          { Buffer.add_char string_buffer c; triple_string lexbuf }
  | eof             { raise (Lexing_error "unterminated triple string") }

and indentation = parse
  | space* '\n'{ new_line lexbuf; indentation lexbuf }
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