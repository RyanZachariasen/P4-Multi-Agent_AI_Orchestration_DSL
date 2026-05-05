open Multi_agent_orchestration
open Lexer

exception No_file_error of string
exception Invalid_flag_error of string * string

let flags = [ "--parse-only"; "--type-only" ]

let handle_lexer_error (error_message : string) (lexbuf : Lexing.lexbuf) =
  let pos = lexbuf.lex_curr_p in
  Printf.eprintf "Lexical error at %s:%d:%d: %s\n" pos.pos_fname pos.pos_lnum
    (pos.pos_cnum - pos.pos_bol)
    error_message;
  exit 1;;

let handle_parser_error (lexbuf : Lexing.lexbuf) =
  let pos = lexbuf.lex_curr_p in
  Printf.eprintf "Syntax error at %s:%d:%d\n" pos.pos_fname pos.pos_lnum
    (pos.pos_cnum - pos.pos_bol);
  exit 1;;


let parse_file (filename : string) lexbuf : Ast.program =
  let ast = Parser.program Lexer.next_token lexbuf in
  Printf.printf "Successfully parsed: %s\n" filename;
  ast;;

let typecheck_ast (ast: Ast.program) : Typed_ast.program = 
    let typed_ast = Typing.check_program program;
    Printf.printf "Successfully typechecked program!";
    typed_ast;;


let get_file_name (args : string array) : string =
  if Array.length args > 1 then args.(1)
  else raise (No_file_error "No file given as argument")

let get_compiler_mode (args : string array) : string option =
  if Array.length args > 2 then
    if List.mem args.(2) flags then (
      Printf.printf "Running compiler mode: %s\n" args.(2);
      Some args.(2))
    else raise (Invalid_flag_error ("This flag is not valid: ", args.(2)))
  else None

let () =
  let filename = get_file_name Sys.argv in
  let compiler_mode = get_compiler_mode Sys.argv in
  let file_channel = open_in filename in

  let lexbuf = Lexing.from_channel file_channel in
  lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = filename };
  close_in file_channel;
  try
    let ast = parse_file filename lexbuf;

    if compiler_mode = Some "--parse-only" then (
      print_endline "Exiting in parse only mode";
      exit 0);

    

    let typed_ast = typecheck_ast ast;

    if compiler_mode = Some "--type-only" then (
      print_endline "Exiting in type only mode";
      exit 0);
    

  with
  | Lexer.Lexing_error error_message -> handle_lexer_error error_message lexbuf
  | Parser.Error -> handle_parser_error lexbuf
  | Typing.Type_error location message -> Printf.printf "Typing error occured at"