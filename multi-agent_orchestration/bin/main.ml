open Multi_agent_orchestration

let () =
  (* Check if a filename was provided *)
  if Array.length Sys.argv < 2 then (
    Printf.eprintf "Usage: %s <file.ma>\n" Sys.argv.(0);
    exit 1
  ) else
    let filename = Sys.argv.(1) in
    let ic = open_in filename in
    let lexbuf = Lexing.from_channel ic in
    
    (* Set the filename in lexbuf for better error messages *)
    lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = filename };

    try
      (* This calls the Parser and Lexer you defined in /lib *)
      let _ast = Parser.file Lexer.token lexbuf in
      Printf.printf "Successfully parsed: %s\n" filename;
      close_in ic
    with
    | Lexer.Error msg ->
        let pos = lexbuf.lex_curr_p in
        Printf.eprintf "Lexical error at %s:%d:%d: %s\n" 
          pos.pos_fname pos.pos_lnum (pos.pos_cnum - pos.pos_bol) msg;
        exit 1
    | Parser.Error ->
        let pos = lexbuf.lex_curr_p in
        Printf.eprintf "Syntax error at %s:%d:%d\n" 
          pos.pos_fname pos.pos_lnum (pos.pos_cnum - pos.pos_bol);
        exit 1