open Py_ast
let rec statement (stmt: py_statement) (buffer: Buffer.t) (indent: string) = 
  match stmt with
  | PyAssign (name, expr) ->
    Buffer.add_string buffer (indent ^ name ^ " = ");
    Codegen_expr.expression expr buffer;
    Buffer.add_string buffer ("\n");
  
  | PyExpr expr -> 
    Buffer.add_string buffer (indent);
    Codegen_expr.expression expr buffer;     
    Buffer.add_string buffer ("\n");

  
  | PyReturn expr ->
    Buffer.add_string buffer (indent ^ "return ");
    Codegen_expr.expression expr buffer;
    Buffer.add_string buffer ("\n");

  | PyFuncDef (name, args, body) ->
    Buffer.add_string buffer "def " ;
    Buffer.add_string buffer (name^" ") ;
    let args_string = String.concat ", " args in
    
    Buffer.add_string buffer ("(" ^ args_string ^"):\n");
    List.iter (fun s ->
          statement s buffer (indent^"\t");
    ) body;
      Buffer.add_string buffer ("\n");
  
  | PyImport module_name ->
    Buffer.add_string buffer ("import " ^ module_name ^ "\n")

  | PyImportFrom (module_name, names) ->
    let names_string = String.concat ", " names in
    Buffer.add_string buffer ("from " ^ module_name ^ " import " ^ names_string ^ "\n")

  | PyClassDef (class_name, base_class, fields) ->
      Buffer.add_string buffer ("class " ^ class_name ^ "(" ^ base_class ^ "):\n");
      List.iter (fun (name, typ) -> 
            Buffer.add_string buffer (indent ^ "\t" ^ name ^ ": " ^ typ ^ "\n");
      ) fields;
      Buffer.add_string buffer ("\n");   
  
  | PyIf (expr, body) -> 
      Buffer.add_string buffer (indent ^ "if ");
      Codegen_expr.expression expr buffer;
      Buffer.add_string buffer (":\n");
      List.iter (fun (s) ->
          statement s buffer (indent ^ "\t");
      ) body;
      Buffer.add_string buffer ("\n");

  | PyIfElse (expr, if_body, else_body) -> 
      Buffer.add_string buffer ("if ");
      Codegen_expr.expression expr buffer;
      Buffer.add_string buffer (":\n");
      List.iter (fun (s) ->
          statement s buffer (indent ^ "\t");
      ) if_body;
      Buffer.add_string buffer (indent ^"else:\n");
      List.iter (fun (s) ->
          statement s buffer (indent ^ "\t");
      ) else_body;
      Buffer.add_string buffer ("\n");