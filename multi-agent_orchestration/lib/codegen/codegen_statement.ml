open Py_ast
let rec statement (stmt: py_statement) (output_file: out_channel) (indent: string) = 
  match stmt with
  | PyAssign (name, expr) ->
    output_string output_file (indent ^ name ^ " = ");
    Codegen_expr.expression expr output_file;
    output_string output_file ("\n");
  
  | PyExpr expr -> 
    output_string output_file (indent);
    Codegen_expr.expression expr output_file;     
    output_string output_file ("\n");

  
  | PyReturn expr ->
    output_string output_file (indent);
    output_string output_file ("return ");
    Codegen_expr.expression expr output_file;
    output_string output_file ("\n");

  | PyFuncDef (name, args, body) ->
    output_string output_file (indent);
    output_string output_file "def " ;
    output_string output_file (name^" ") ;
    let args_string = String.concat ", " args in
    
    output_string output_file ("(" ^ args_string ^"):\n");
    List.iter (fun s ->
          statement s output_file (indent^"\t");
    ) body;
      output_string output_file ("\n");
  
  | PyImport module_name ->
    output_string output_file (indent);
    output_string output_file ("import" ^ module_name)

  | PyImportFrom (module_name, names) ->
    output_string output_file (indent);
    let names_string = String.concat "," names in
    output_string output_file ("from" ^ module_name  ^ "import" ^ names_string ^"\n")

  | PyClassDef (class_name, base_class, fields) ->
    output_string output_file (indent);
    output_string output_file ("class " ^ class_name ^ "(BaseModel):\n") ;
    List.iter (fun (name, typ) -> 
          output_string output_file (indent ^ "\t" ^ name ^": "^ typ ^ "\n");
    ) fields;
  
  | PyIf (expr, body) -> 
    output_string output_file (indent);
    output_string output_file ("if ");
    Codegen_expr.expression expr output_file;
    output_string output_file (":\n");
    List.iter (fun (s) ->
        statement s output_file (indent ^ "\t");
    ) body;

  | PyIfElse (expr, if_body, else_body) -> 
      output_string output_file (indent);
      output_string output_file ("if ");
      Codegen_expr.expression expr output_file;
      output_string output_file (":\n");
      List.iter (fun (s) ->
          statement s output_file (indent ^ "\t");
      ) if_body;
      output_string output_file (indent ^"else:\n");
      List.iter (fun (s) ->
          statement s output_file (indent ^ "\t");
      ) else_body;
  | PyWhile (expr, body) ->
    output_string output_file (indent);
    output_string output_file ("while ");
    Codegen_expr.expression expr output_file;
    output_string output_file (":\n");
    List.iter (fun (s) ->
        statement s output_file (indent ^ "\t");
    ) body;
