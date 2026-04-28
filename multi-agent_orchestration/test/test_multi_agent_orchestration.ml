open Multi_agent_orchestration
open Parser

let lex input =
  let lexbuf = Lexing.from_string input in
  let rec loop acc =
    let tok = Lexer.next_token lexbuf in
    if tok = EOF then List.rev (EOF :: acc)
    else loop (tok :: acc)
  in
  loop []

let assert_tokens input expected =
  let actual = lex input in
  if actual <> expected then
    failwith "Lexer test failed"

let () =
  assert_tokens
    "workflow:\n    x = 1\n"
    [ WORKFLOW; COLON; NEWLINE; BEGIN; IDENT "x"; ASSIGN; INT 1; NEWLINE; END;
      EOF ];

  assert_tokens
    "Resource agent = openai(\"gpt-4\")\n"
    [ RESOURCE; IDENT "agent"; ASSIGN; OPENAI; LPAREN; TEXT "gpt-4"; RPAREN;
      NEWLINE; EOF ]
