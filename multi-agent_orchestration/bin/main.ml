open Multi_agent_orchestration
open Lexer

let parse_only = ref false
let type_only = ref false
let ifile = ref ""

let set_file s = ifile := s

let options =
  [ "--parse-only", Arg.Set parse_only, "  stops after parsing";
    "--type-only",  Arg.Set type_only,  "  stops after typing";
  ]

let usage = "usage: mai [options] file.mai"

let handle_lexer_error (error_message : string) (lexbuf: Lexing.lexbuf) = 
  let pos = lexbuf.lex_curr_p in
  Printf.eprintf "Lexical error at %s:%d:%d: %s\n"
  pos.pos_fname pos.pos_lnum (pos.pos_cnum - pos.pos_bol) error_message

let handle_parser_error (lexbuf: Lexing.lexbuf) = 
  let pos = lexbuf.lex_curr_p in
  Printf.eprintf "Syntax error at %s:%d:%d\n" 
    pos.pos_fname pos.pos_lnum (pos.pos_cnum - pos.pos_bol);
  exit 1

let () =
  Arg.parse options set_file usage;
  if !ifile = "" then begin Printf.eprintf "No file given\n"; exit 1 end;
  let file_channel = open_in !ifile in
  let lexbuf = Lexing.from_channel file_channel in
  lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = !ifile };
  try
    let _ast = Parser.program Lexer.next_token lexbuf in
    close_in file_channel;
    if !parse_only then exit 0;
    (*let _typed_ast = Typing.program _ast in*)
    if !type_only then exit 0;
  with
  | Lexer.Lexing_error error_message ->
    handle_lexer_error error_message lexbuf
  | Parser.Error ->
    handle_parser_error lexbuf