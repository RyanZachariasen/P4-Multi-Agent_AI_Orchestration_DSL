open Py_ast

let rec codegen_module (modul: py_module) (output_file : out_channel) = 
  
  handle_imports modul.imports output_file;
  handle_body modul.body output_file;
  
and handle_imports imports output_file = 
  List.iter (fun x -> 
      match x with 
      | PyImport import -> output_string output_file ("import " ^ import ^ "\n")
      | PyImportFrom (from, imports) -> output_string output_file ("from " ^ from ^" import " ^ (String.concat "," imports) ^ "\n")
      | _ ->failwith "error generating module"
    ) imports;

and handle_body statements output_file = 
  List.iter (fun statement ->
    Codegen_statement.statement statement output_file ""
  ) statements;
  