open Py_ast

let rec expression (expr : py_expr) (buffer: Buffer.t) : unit =
  match expr with
  | PyName name -> Buffer.add_string buffer name;

  | PyConst const -> constant const buffer;

  | PyCall (func, args, kwargs) ->
    expression func buffer;
    Buffer.add_string buffer "(";
    List.iter (fun arg -> 
        expression arg buffer;
        Buffer.add_string buffer ",";
    ) args;
    List.iter (fun (name, arg) -> 
        Buffer.add_string buffer (name^"=");
        expression arg buffer;
        Buffer.add_string buffer ",";
    ) kwargs;
    Buffer.add_string buffer ")";

  | PyList items ->
    Buffer.add_string buffer "[";
    List.iter (fun arg -> expression arg buffer) items;
    Buffer.add_string buffer ", ";
    Buffer.add_string buffer "]";

  | PyDict fields ->
    Buffer.add_string buffer "{";
    List.iter (fun (key, value) ->
        constant key buffer;
        Buffer.add_string buffer (":");
        expression value buffer;
        Buffer.add_string buffer ", ")
        fields;
    Buffer.add_string buffer "}";

  | PyAttr (value, attr) ->
    expression value buffer;
    Buffer.add_string buffer ("." ^ attr) 

  | PyBinOp (op, left, right) ->
    expression left buffer;
    binop op buffer;
    expression right buffer;

  | PySubscript (value, index) ->
    expression value buffer;
    Buffer.add_char buffer '[';
    expression index buffer;
    Buffer.add_char buffer ']';

  | PyFString (prefix, holes) ->
    Buffer.add_string buffer ("f\"" ^prefix);
    List.iter (fun (str, hole) -> 
            Buffer.add_string buffer str;
            Buffer.add_char buffer '{';
            expression hole buffer;
            Buffer.add_char buffer '}';
            
        ) holes;
    Buffer.add_char buffer '\"';

  | PyCompare (left, op, right) ->
    expression left buffer;
    compare_operator op buffer;
    expression right buffer;

and constant (const : py_constant) (buffer: Buffer.t) =
  match const with
  | PyInt n -> Buffer.add_string buffer (Int.to_string n)

  | PyFloat f -> Buffer.add_string buffer (Float.to_string f)
 
  | PyBool b -> 
    if b then Buffer.add_string buffer "True"
    else Buffer.add_string buffer "False"

  | PyString s -> Buffer.add_string buffer ("\"" ^ s ^ "\"")

  | PyNone -> Buffer.add_string buffer "None"

and binop (op : py_binop)(buffer: Buffer.t) =
  match op with
  | PyAdd -> Buffer.add_string buffer " + ";

  | PySub -> Buffer.add_string buffer " - ";

  | PyMul -> Buffer.add_string buffer " * ";

  | PyDiv -> Buffer.add_string buffer " / ";

  | PyConcat -> failwith "not implemented"

and compare_operator (op : compare_operator) (buffer: Buffer.t) =
  match op with
  | Eq -> Buffer.add_string buffer " == ";

  | NotEq -> Buffer.add_string buffer " != ";

  | Lt -> Buffer.add_string buffer " < ";

  | LtE -> Buffer.add_string buffer " <= ";

  | Gt -> Buffer.add_string buffer " > ";

  | GtE -> Buffer.add_string buffer " >= ";

  | Is -> Buffer.add_string buffer " is ";

  | IsNot -> Buffer.add_string buffer " is not ";

  | In -> Buffer.add_string buffer " in ";

  | NotIn -> Buffer.add_string buffer " not in ";