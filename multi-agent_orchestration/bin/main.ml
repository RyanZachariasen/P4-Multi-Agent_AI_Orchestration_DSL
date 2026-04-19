open Multi_agent_orchestration


let handle_filename_given () : string  = 
  Printf.printf "Using %s \n" Sys.argv.(1);
  Sys.argv.(1);;

let handle_no_filename_given () : string = 
  Printf.eprintf "No file given, trying main.mai\n";
  "main.mai"

let parse_file (filename : string) (lexbuf) = 
      let _ast = Parser.file Lexer.next_token lexbuf in
      Printf.printf "Successfully parsed: %s\n" filename;;

let handle_lexer_error (error_message : string) (lexbuf: Lexing.lexbuf) = 
  let pos = lexbuf.lex_curr_p in
  Printf.eprintf "Lexical error at %s:%d:%d: %s\n"
  pos.pos_fname pos.pos_lnum (pos.pos_cnum - pos.pos_bol) error_message;;

let handle_parser_error (lexbuf: Lexing.lexbuf) = 
    let pos = lexbuf.lex_curr_p in
    Printf.eprintf "Syntax error at %s:%d:%d\n" 
      pos.pos_fname pos.pos_lnum (pos.pos_cnum - pos.pos_bol);
    exit 1

let () =
    let filename = (if Array.length Sys.argv > 0 then handle_filename_given() else handle_no_filename_given()) in
    let file_channel = open_in filename in
    let lexbuf = Lexing.from_channel file_channel in
    
    (* Set the filename in lexbuf for better error messages: 
    lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = filename };
    *)
  
    try
      parse_file filename lexbuf;
      close_in file_channel
    with
      | Lexer.Lexing_error error_message ->
        handle_lexer_error error_message lexbuf
      | Parser.Error ->
        handle_parser_error lexbuf
    