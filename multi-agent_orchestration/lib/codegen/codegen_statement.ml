let rec statement (stmt: Py_ast.py_statement) (buffer: Buffer.t) (indent: string) = 
  match stmt with
  | Py_ast.PyAssign (name, expr) ->
    Buffer.add_string buffer (indent ^ name ^ "= ");
    Codegen_expr.expr expr buffer;
    Buffer.add_string buffer ("\n");
  
  | Py_ast.PyExpr expr ->  Codegen_expr.expr expr buffer
  
  | Py_ast.PyReturn expr ->
    Buffer.add_string buffer ("return ");
    Codegen_expr.expr expr buffer;
    Buffer.add_string buffer ("\n");

  | Py_ast.PyFuncDef (name, args, body) ->
    Buffer.add_string buffer "def " ;
    let args_string = String.concat ", " args in
    
    Buffer.add_string buffer ("(" ^ args_string ^"):\n");
    List.iter (fun s ->
          Buffer.add_string buffer (indent^"\t");
          statement s buffer (indent^"\t");
    ) body;
      Buffer.add_string buffer ("\n");
  
  | Py_ast.PyImport module_name ->
    Buffer.add_string buffer ("import" ^ module_name)

  | Py_ast.PyImportFrom (module_name, names) ->
    let names_string = String.concat "," names in
    Buffer.add_string buffer ("from" ^ module_name  ^ "import" ^ names_string ^"\n")

  | Py_ast.PyClassDef (class_name, base_class, fields) ->
    Buffer.add_string buffer "class (BaseModel):\n" ;
    List.iter (fun (name, typ) -> 
          Buffer.add_string buffer (indent ^ "\t" ^ name ^": "^ typ ^ "\n");
    ) fields;
  
  | Py_ast.PyIf (expr, body) -> 
    Buffer.add_string buffer ("if ");
    Codegen_expr.expr expr buffer;
    Buffer.add_string buffer (":\n");
    List.iter (fun (s) ->
        statement s buffer (indent ^ "\t");
    ) body;

  | Py_ast.PyIfElse (expr, if_body, else_body) -> 
      Buffer.add_string buffer ("if ");
      Codegen_expr.expr expr buffer;
      Buffer.add_string buffer (":\n");
      List.iter (fun (s) ->
          statement s buffer (indent ^ "\t");
      ) if_body;
      Buffer.add_string buffer (indent ^"else:\n");
      List.iter (fun (s) ->
          statement s buffer (indent ^ "\t");
      ) else_body;