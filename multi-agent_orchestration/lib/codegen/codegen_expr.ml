open Py_ast

let rec expression (expr : py_expr) (output_file: out_channel) : unit =
  match expr with
  | PyName name -> output_string output_file name;

  | PyConst const -> constant const output_file;

  | PyCall (func, args, kwargs) ->
    expression func output_file;
    output_string output_file "(";
    List.iter (fun arg -> 
        expression arg output_file;
        output_string output_file ",";
    ) args;
    List.iter (fun (name, arg) -> 
        output_string output_file (name^"=");
        expression arg output_file;
        output_string output_file ",";
    ) kwargs;
    output_string output_file ")";

  | PyList items ->
    output_string output_file "[";
    List.iter (fun arg -> expression arg output_file) items;
    output_string output_file ", ";
    output_string output_file "]";

  | PyDict fields ->
    output_string output_file "{";
    List.iter (fun (key, value) ->
        constant key output_file;
        output_string output_file (":");
        expression value output_file;
        output_string output_file ", ")
        fields;
    output_string output_file "}";

  | PyAttr (value, attr) ->
    expression value output_file;
    output_string output_file ("." ^ attr) 

  | PyBinOp (op, left, right) ->
    expression left output_file;
    binop op output_file;
    expression right output_file;

  | PySubscript (value, index) ->
    expression value output_file;
    output_char output_file '[';
    expression index output_file;
    output_char output_file ']';

  | PyFString (prefix, holes) ->
    output_string output_file ("f\"" ^prefix);
    List.iter (fun (str, hole) -> 
            output_string output_file str;
            output_char output_file '{';
            expression hole output_file;
            output_char output_file '}';
            
        ) holes;
    output_char output_file '\"';

  | PyCompare (left, op, right) ->
    expression left output_file;
    compare_operator op output_file;
    expression right output_file;

and constant (const : py_constant) (output_file: out_channel) =
  match const with
  | PyInt n -> output_string output_file (Int.to_string n)

  | PyFloat f -> output_string output_file (Float.to_string f)
 
  | PyBool b -> 
    if b then output_string output_file "True"
    else output_string output_file "False"

  | PyString s -> output_string output_file ("\"" ^ s ^ "\"")

  | PyNone -> output_string output_file "None"

and binop (op : py_binop)(output_file: out_channel) =
  match op with
  | PyAdd -> output_string output_file " + ";

  | PySub -> output_string output_file " - ";

  | PyMul -> output_string output_file " * ";

  | PyDiv -> output_string output_file " / ";

and compare_operator (op : compare_operator) (output_file: out_channel) =
  match op with
  | Eq -> output_string output_file " == ";

  | NotEq -> output_string output_file " != ";

  | Lt -> output_string output_file " < ";

  | LtE -> output_string output_file " <= ";

  | Gt -> output_string output_file " > ";

  | GtE -> output_string output_file " >= ";

  | Is -> output_string output_file " is ";

  | IsNot -> output_string output_file " is not ";

  | In -> output_string output_file " in ";

  | NotIn -> output_string output_file " not in ";