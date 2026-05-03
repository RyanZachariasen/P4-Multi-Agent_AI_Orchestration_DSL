type empty = []

and identifier = string
and type_param = string
and arguments = (identifier * type_param)list


and operator = Add | Sub | Mult | Div 

and expr_context = Load | Store | Del

and expr = 
| BinOp of expr * operator * expr
| Call of expr * expr list * empty list
| Name of identifier * expr_context

and withitem = expr * expr option


and stmt =
  | FunctionDef of {
    name: identifier; 
    args: arguments;
    body: stmt list;
    decorator_list: expr list;
    returns: expr;
    type_comment: string;
    type_params: type_param list; 
    }
  | With of withitem * stmt list * string option
  | Open of expr


