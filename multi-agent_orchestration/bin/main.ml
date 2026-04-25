open Multi_agent_orchestration
open Lexer
let handle_filename_given () : string  = 
  Printf.printf "Using %s \n" Sys.argv.(1);
  Sys.argv.(1);;

let handle_no_filename_given () : string = 
  Printf.eprintf "No file given, trying main.mai\n";
  "main.mai";;

let parse_file (filename : string) (lexbuf) : Ast.program = 
      let ast = Parser.program Lexer.next_token lexbuf in
      Printf.printf "Successfully parsed: %s\n" filename;
      ast;;

let check_semantics (program: Ast.program) =
      try 
        Semantic_analysis.check_program program;
        Printf.printf "Successfully checked semantics\n";
      with Semantic_analysis.Semantic_error (location, message) -> 
        Printf.printf "Error in file %s %i:%i %s" location.file location.line location.col message;;


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
    

    lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = filename };
    

    try
      let ast = parse_file filename lexbuf in
      close_in file_channel;
      check_semantics ast


    with
      | Lexer.Lexing_error error_message ->
        handle_lexer_error error_message lexbuf
      | Parser.Error ->
        handle_parser_error lexbuf
    