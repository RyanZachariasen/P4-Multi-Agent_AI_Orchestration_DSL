let rec expr (expr: Typed_ast.expr) : Py_ast.py_expr = 
  expr_node expr.expr_node

and expr_node (node: Typed_ast.expr_node) : Py_ast.py_expr =
  match node with
  | Typed_ast.EVar name -> Py_ast.PyName name
  | Typed_ast.EConst const -> constant const

  | Typed_ast.EBinOp (opperation, expr_1, expr_2) -> 
    let binop_expr_1 = expr expr_1 in
    let binop_expr_2 = expr expr_2 in
    let binop_opperation = binop opperation in
    Py_ast.PyBinOp (binop_opperation, binop_expr_1, binop_expr_2)
    
  | Typed_ast.EReadFile path_expr ->
    let file_arg = expr path_expr in
    let open_call = Py_ast.PyCall (Py_ast.PyName "open", [file_arg; Py_ast.PyConst (Py_ast.PyString "r")], []) in
    Py_ast.PyCall (Py_ast.PyAttr (open_call, "read"), [], [])
  | Typed_ast.ECall (name, expr_list, on_resource_option) -> raise Not_found

  | Typed_ast.EField (expr_record, flield_name, typ) ->
    let py_expr = expr expr_record in
    Py_ast.PyAttr (py_expr, flield_name)

  | Typed_ast.ECall (name, expr_list, on_resource_option) -> 
    let function_name = Py_ast.PyName name in
    let ecall_arguments = List.map expr expr_list in
    match on_resource_option with
    | None -> Py_ast.PyCall(function_name, ecall_arguments, [])
    | Some resource_name -> 
      let ecall_arguments = ecall_arguments @ [Py_ast.PyName resource_name] in
      Py_ast.PyCall(function_name, ecall_arguments, [])
  

and constant (const: Typed_ast.constant) : Py_ast.py_expr = 
  match const with
  | Typed_ast.CText str -> Py_ast.PyConst (Py_ast.PyString str)
  | Typed_ast.CInt int -> Py_ast.PyConst (Py_ast.PyInt int)
  | Typed_ast.CFloat float -> Py_ast.PyConst (Py_ast.PyFloat float)
  | Typed_ast.CBool bool -> Py_ast.PyConst (Py_ast.PyBool bool)
  | Typed_ast.CCode str -> Py_ast.PyConst (Py_ast.PyString str)
  | Typed_ast.CFile str -> Py_ast.PyConst (Py_ast.PyString str)
  | Typed_ast.CCustomType name -> Py_ast.PyName name

and binop (binop: Typed_ast.binop) : Py_ast.py_binop = 
  match binop with
  | Typed_ast.Add -> Py_ast.PyAdd
  | Typed_ast.Sub -> Py_ast.PySub
  | Typed_ast.Mul -> Py_ast.PyMul
  | Typed_ast.Div -> Py_ast.PyDiv