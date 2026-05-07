exception Type_error of Ast.location * string

val check_program:  Ast.program -> Typed_ast.program