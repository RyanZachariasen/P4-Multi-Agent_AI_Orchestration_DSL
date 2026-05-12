open Py_ast

let rec codegen_module (modul: py_module) : bytes = 
  let buffer = Buffer.create 100000 in

  handle_imports modul.imports buffer;
  handle_body modul.body buffer;
  
  Buffer.to_bytes buffer

and handle_imports imports buffer = 
  List.iter (fun x -> 
      match x with 
      | PyImport import -> Buffer.add_string buffer ("import " ^ import ^ "\n")
      | _ -> failwith "error generating module"
    ) imports;

and handle_body statements buffer = 
  List.iter (fun statement ->
    Codegen_statement.statement statement buffer ""
  ) statements;
  