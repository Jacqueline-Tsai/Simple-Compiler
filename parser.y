%{
	#include <iostream>
	#include <stdio.h>
	#include <string>
	#include <cmath>
	#include "symbol.hpp"
	#include "lex.yy.cpp"
	#define Trace(t) if (trace) {cout<<"TRACE => " << t << endl; symboltablestack.dump(); };
	using namespace std;
	void yyerror(string s);

	int trace = 0;
	ofstream fout;
	SymbolTableStack symboltablestack;
	Generator generator;
%}
	// define type
    %union {
        bool boolean_data; 					// boolean
        string* string_data;				// string
        int integer_data;					// integer
        double float_data;
        Symbol* symbol;
        Type type;
    }
    
    %token LE GE EQ NEQ ADDA SUBA MULA DIVA
    %token BOOLEAN FLOAT INTEGER STRING
    %token CONST BREAK CHAR CASE CLASS VAL VAR DD
    %token CONTINUE DECLARE DO ELSE EXIT FUN IF PRINT PRINTLN LOOP WHILE FOR RETURN READ IN
    
	// token with different types
	%token <string_data> IDENTIFIER_VALUE
    %token <boolean_data> BOOLEAN_VALUE
    %token <integer_data> INTEGER_VALUE 
    %token <float_data> FLOAT_VALUE 
    %token <string_data> STRING_VALUE

    // operator precedence
    %left '|'
    %left '&'
    %right '!'
    %left '<' '>' LE GE EQ NEQ
    %left '+' '-'
    %left '*' '/' '%'
    %left '(' ')'
	%nonassoc UMINUS

	// return type of each element
	%type <type> type simple_statement argument expression function_invocation 
	%type <symbol> constant_expression function identifier 
	%type <string_data> function_title function_procedure_title

%%
    program : class 
			| function
			| class program
			| function program
	
    class : CLASS IDENTIFIER_VALUE {
				generator.class_name = *$2;
				symboltablestack.push();
				generator.class_start(*$2);
			} '{' class_block '}' {
				Trace("program");
				symboltablestack.pop();
				generator.class_end();
			};

    class_block : function
            | constant_declaration
            | variable_declaration
            | function class_block
            | constant_declaration class_block
            | variable_declaration class_block ;

    constant_declaration : VAL IDENTIFIER_VALUE '=' constant_expression {
							Trace("constant_declaration");
							Symbol new_symbol;
							new_symbol.name = *$2;
							new_symbol.variable_type = constant_variable_type;
							new_symbol.return_or_data_type = $4->return_or_data_type;
							new_symbol.array_size = -1;
							new_symbol.value = $4->value;
							symboltablestack.insert_symbol(new_symbol);
						}
                        | VAL IDENTIFIER_VALUE ':' type '=' constant_expression {
							Trace("constant_declaration");
							if($6->return_or_data_type != $4) yyerror("variable type inconsistant");
							Symbol new_symbol;
							new_symbol.name = *$2;
							new_symbol.variable_type = constant_variable_type;
							new_symbol.return_or_data_type = $6->return_or_data_type;
							new_symbol.array_size = -1;
							new_symbol.value = $6->value;
							symboltablestack.insert_symbol(new_symbol);
						} ;

    variable_declaration : VAR IDENTIFIER_VALUE {
							Trace("variable_declaration");
							Symbol new_symbol;
							new_symbol.name = *$2;
							new_symbol.variable_type = variable_type;
							new_symbol.return_or_data_type = integer_type;
							new_symbol.array_size = -1;
							if(symboltablestack.stack.size() == 1){
								generator.global_variable_declaration(integer_type, *$2);
							}
							else{								
								new_symbol.stack_buffer = generator.buffer_number;
								generator.buffer_number += 1;
							}
							symboltablestack.insert_symbol(new_symbol);
						}
                        | VAR IDENTIFIER_VALUE ':' type {
							Trace("variable_declaration");
							Symbol new_symbol;
							new_symbol.name = *$2;
							new_symbol.variable_type = variable_type;
							new_symbol.return_or_data_type = $4;
							new_symbol.array_size = -1;
							if(symboltablestack.stack.size() == 1){
								generator.global_variable_declaration($4, *$2);
							}
							else{								
								new_symbol.stack_buffer = generator.buffer_number;
								generator.buffer_number += 1;
							}
							symboltablestack.insert_symbol(new_symbol);
						}
                        | VAR IDENTIFIER_VALUE '=' constant_expression {
							Trace("variable_declaration");
							Symbol new_symbol;
							new_symbol.name = *$2;
							new_symbol.variable_type = variable_type;
							new_symbol.return_or_data_type = $4->return_or_data_type;
							new_symbol.array_size = -1;
							if(symboltablestack.stack.size() == 1){
								generator.global_variable_value($4->return_or_data_type, *$2, $4->value);
							}
							else{								
								new_symbol.stack_buffer = generator.buffer_number;
								generator.buffer_number += 1;
								generator.assign_value($4->return_or_data_type, new_symbol.stack_buffer, $4->value);
							}
							symboltablestack.insert_symbol(new_symbol);
						}
                        | VAR IDENTIFIER_VALUE ':' type '=' constant_expression {
							Trace("variable_declaration");
							if($6->return_or_data_type != $4) yyerror("variable type inconsistant");
							Symbol new_symbol;
							new_symbol.name = *$2;
							new_symbol.variable_type = variable_type;
							new_symbol.return_or_data_type = $6->return_or_data_type;
							new_symbol.array_size = -1;
							if(symboltablestack.stack.size() == 1){
								generator.global_variable_value($6->return_or_data_type, *$2, $6->value);
							}
							else{								
								new_symbol.stack_buffer = generator.buffer_number;
								generator.buffer_number += 1;
								generator.assign_value($6->return_or_data_type, new_symbol.stack_buffer, $6->value);
							}
							symboltablestack.insert_symbol(new_symbol);
						}
                        | VAR IDENTIFIER_VALUE ':' type '[' INTEGER_VALUE ']' {
							Trace("variable_declaration");
							Symbol new_symbol;
							new_symbol.name = *$2;
							new_symbol.variable_type = variable_type;
							new_symbol.return_or_data_type = $4;
							new_symbol.array_size = $6;
							symboltablestack.insert_symbol(new_symbol);
						};

    type : BOOLEAN { Trace("boolean"); $$ = boolean_type; }
        | INTEGER { Trace("integer"); $$ = integer_type; }
        | FLOAT { Trace("float"); $$ = float_type; }
        | STRING { Trace("string"); $$ = string_type; } ;

    constant_expression : BOOLEAN_VALUE {
							Symbol *symbol = new Symbol();
							symbol->return_or_data_type = constant_variable_type;
							symbol->return_or_data_type = boolean_type;
							symbol->value = $1? 1:0;
							$$ = symbol;
						}
						| INTEGER_VALUE {
							Symbol *symbol = new Symbol();
							symbol->return_or_data_type = constant_variable_type;
							symbol->return_or_data_type = integer_type;
							symbol->value = $1;
							$$ = symbol;
						}
						| FLOAT_VALUE {
							Symbol *symbol = new Symbol();
							symbol->return_or_data_type = constant_variable_type;
							symbol->return_or_data_type = float_type;
							$$ = symbol;
						}
						| STRING_VALUE {
							Symbol *symbol = new Symbol();
							symbol->return_or_data_type = constant_variable_type;
							symbol->return_or_data_type = string_type;
							$$ = symbol;
							generator.string_const(*$1);
						};

	function_title : FUN IDENTIFIER_VALUE { 
						Trace("function_title");
						Symbol new_symbol;
						new_symbol.name = *$2;
						new_symbol.variable_type = function_type;
						new_symbol.array_size = -1;
						symboltablestack.insert_symbol(new_symbol);
						symboltablestack.push();
						generator.function_start_name(*$2);
					} ;

    function : function_title '(' arguments ')' {
				symboltablestack.add_return_type(void_type);
				generator.function_start_return(void_type);
			} block {
				symboltablestack.pop();
				generator.function_end();
			}
            | function_title '(' arguments ')' ':' type {
				symboltablestack.add_return_type($6);
				generator.function_start_return($6);
			} block {
				symboltablestack.pop();
				generator.function_end();
			} ;

    arguments : argument
            | argument ',' arguments
			| ;

    argument : IDENTIFIER_VALUE ':' type {
				symboltablestack.add_argument(*$1, $3, generator.buffer_number);
				generator.buffer_number += 1;
				generator.function_start_argument($3);
			} ;

    block : '{' in_block '}' {
				Trace("block");
			} ;

    in_block : constant_declaration in_block
            | variable_declaration in_block
            | simple_statement in_block
            | conditional_statement in_block
            | loop_statement in_block
            | procedure_invocation in_block
            | ;             

    simple_statement : IDENTIFIER_VALUE '=' expression {
						Trace("identifier = expression");
						Symbol id = symboltablestack.get_symbol(*$1);
						if(id.variable_type != variable_type) yyerror(id.name + " is not variable");
						if(id.return_or_data_type != void_type && id.return_or_data_type != $3 && !(id.return_or_data_type == float_type && $3 == integer_type)) yyerror("variable type inconsistant");
						if(id.index == 1) generator.put_global_variable(id);
						else generator.put_local_variable(id);
					}
                    | identifier '[' expression ']' '=' expression {
						Trace("simple_statement");
						if ($1->array_size < 0) yyerror($1->name + " is not an array");
						if ($3 != integer_type) yyerror($1->name + "index is not integer");
						if ($1->return_or_data_type != $6) yyerror($1->name + "type inconsistant");
					}
                    | PRINT {
						generator.print_start();
					} expression { 
						Trace("print"); 
						generator.print_end($3, false);
					}
                    | PRINTLN {
						generator.print_start();
					} expression { 
						Trace("println"); 
						generator.print_end($3, true);
					}
                    | READ identifier { Trace("read");}
                    | RETURN { 
						Trace("return");  
						if(!symboltablestack.check_function_return_type(void_type)) yyerror("incorrect return type");
					}
                    | RETURN expression { 
						Trace("return expression"); 
						if(!symboltablestack.check_function_return_type($2)) yyerror("incorrect return type");
					} ;

    conditional_statement : if_title block_or_simple_statement {
								generator.if_end();
							}
							| if_else_title block_or_simple_statement  {
								generator.if_else_end();
							} ;

	if_title:   IF '(' expression ')'  
                { 
                    Trace("conditional_statement");
					if($3 != boolean_type) yyerror("not bool type");
                    generator.if_start();
                }

	if_else_title:	if_title block_or_simple_statement ELSE
					{
						generator.else_start();
					}

	loop_statement : WHILE {
						generator.while_start();
					} '(' expression ')' {
						generator.while_mid();
					} block_or_simple_statement {
						if($4 != boolean_type) yyerror("not bool type");
						generator.while_end();
					}
                    | FOR '(' IDENTIFIER_VALUE IN INTEGER_VALUE DD INTEGER_VALUE ')' {
						symboltablestack.push();
						Symbol new_symbol;
						new_symbol.name = *$3;
						new_symbol.variable_type = variable_type;
						new_symbol.return_or_data_type = integer_type;
						new_symbol.array_size = -1;
						new_symbol.stack_buffer = generator.buffer_number;
						generator.buffer_number += 1;
						symboltablestack.insert_symbol(new_symbol);
						generator.for_start(new_symbol, $5, $7);					
					} block_or_simple_statement {
						generator.for_end(symboltablestack.get_symbol(*$3), $5, $7);
						symboltablestack.pop();
					} ;

	function_procedure_title	:	IDENTIFIER_VALUE {
		Trace("function_procedure_title");
		symboltablestack.tmp.resize(0);
		Symbol id = symboltablestack.get_symbol(*$1);
		if (id.variable_type != function_type) yyerror(id.name + " is not a function or procedure");
		$$ = $1;
	}

    procedure_invocation : function_procedure_title '(' comma_separated_expressions ')' {
		Trace("procedure_invocation");
		Symbol id = symboltablestack.get_symbol(*$1);
		if (id.return_or_data_type != void_type) yyerror(" is not a procedure");
		generator.function_invocation(id);
	} ;

    function_invocation : function_procedure_title '(' comma_separated_expressions ')' {
		Trace("function_invocation");
		Symbol id = symboltablestack.get_symbol(*$1);
		if (id.return_or_data_type == void_type) yyerror("is not a function");
		//if (!symboltablestack.check_params($1->name)) yyerror("function parameters type don't match");
		$$ = id.return_or_data_type;
		generator.function_invocation(id);
	} ;

    comma_separated_expressions : expression ',' comma_separated_expressions {
									symboltablestack.tmp.push_back($1);
								}
                                | expression {
									symboltablestack.tmp.push_back($1);
								}
								| ;

    block_or_simple_statement : block
                            | simple_statement ;


    expression : '-' expression %prec UMINUS {
			if($2 != integer_type && $2 != float_type)	yyerror("type inconsistant");
			$$ = $2;
			generator.operation("ineg");
		}
        | expression '|' expression {
			if($1 != boolean_type || $3 != boolean_type)	yyerror("incorrect type");
			$$ = boolean_type;
			generator.operation("ixor");
		}
        | expression '&' expression { 
			if($1 != boolean_type || $3 != boolean_type)	yyerror("incorrect type");
			$$ = boolean_type;
			generator.operation("iand");
		}
        | '!' expression {
			if($2 != boolean_type)	yyerror("incorrect type");
			$$ = boolean_type;			
			generator.operation("ineg");
		}
        | expression '<' expression {
			if(($1 != integer_type && $1 != float_type) || ($3 != integer_type && $3 != float_type))	yyerror("incorrect type");
			$$ = boolean_type;
			generator.operation_if("iflt");
		}
        | expression '>' expression {
			if(($1 != integer_type && $1 != float_type) || ($3 != integer_type && $3 != float_type))	yyerror("incorrect type");
			$$ = boolean_type;
			generator.operation_if("ifgt");
		}
        | expression LE expression {
			if(($1 != integer_type && $1 != float_type) || ($3 != integer_type && $3 != float_type))	yyerror("incorrect type");
			$$ = boolean_type;
			generator.operation_if("ifle");
		}
        | expression GE expression {
			if(($1 != integer_type && $1 != float_type) || ($3 != integer_type && $3 != float_type))	yyerror("incorrect type");
			$$ = boolean_type;
			generator.operation_if("ifge");
		}
        | expression EQ expression {
			if($1 != $3) yyerror("incorrect type");
			$$ = boolean_type;
			generator.operation_if("ifeq");
		}
        | expression NEQ expression {
			if($1 != $3) yyerror("incorrect type");
			$$ = boolean_type;
			generator.operation_if("ifne");
		}
        | expression '+' expression {
			if($1 == string_type && $3 == string_type){
				$$ = string_type;
			}
			else if ($1 == integer_type && $3 == integer_type){
				$$ = integer_type;
			}
			else if (($1 == integer_type || $1 == float_type) && ($3 == integer_type || $3 == float_type)){
				$$ = float_type;
			}
			else	yyerror("incorrect type");
			generator.operation("iadd");
		}
        | expression '-' expression {
			if($1 == string_type && $3 == string_type){
				$$ = string_type;
			}
			else if ($1 == integer_type && $3 == integer_type){
				$$ = integer_type;
			}
			else if (($1 == integer_type || $1 == float_type) && ($3 == integer_type || $3 == float_type)){
				$$ = float_type;
			}
			else	yyerror("incorrect type");
			generator.operation("isub");
		}
        | expression '*' expression {
			if ($1 == integer_type && $3 == integer_type){
				$$ = integer_type;
			}
			else if (($1 == integer_type || $1 == float_type) && ($3 == integer_type || $3 == float_type)){
				$$ = float_type;
			}
			else	yyerror("incorrect type");
			generator.operation("imul");
		}
        | expression '/' expression {
			if ($1 == integer_type && $3 == integer_type){
				$$ = integer_type;
			}
			else if (($1 == integer_type || $1 == float_type) && ($3 == integer_type || $3 == float_type)){
				$$ = float_type;
			}
			else	yyerror("incorrect type");
			generator.operation("idiv");
		}
        | expression '%' expression {
			if ($1 != integer_type || $3 != integer_type)	yyerror("incorrect type");
			$$ = integer_type;
			generator.operation("irem");
		}
        | '(' expression ')' { $$ = $2; }
		| identifier {
			if ($1->array_size != -1) yyerror($1->name + " is an array");
			if ($1->variable_type == function_type) yyerror($1->name + " is a function");
			$$ = $1->return_or_data_type;
	 	}
		| identifier '[' expression ']' {
			if ($1->array_size < 0) yyerror($1->name + " is not an array");
			if ($3 != integer_type ) yyerror($1->name + " index of array must be integer");
			$$ = $1->return_or_data_type;
		}
        | constant_expression { 
			$$ = $1->return_or_data_type;
			generator.get_constant_variable(*$1);
		}
        | function_invocation {
			Trace("expression");
			$$ = $1;
		} ;

		identifier : IDENTIFIER_VALUE {
			Trace("identifier " + *$1);
			if (!symboltablestack.lookup(*$1)) yyerror(*$1 + " not defined");
			Symbol symbol = symboltablestack.get_symbol(*$1);
			$$ = &symbol;
			if(symbol.variable_type == constant_variable_type)
				generator.get_constant_variable(symbol);
			else if(symbol.index == 1)
				generator.get_global_variable(symbol);
			else
				generator.get_local_variable(symbol);
		}    

%%

    void yyerror(string s) {
        cerr << "line " << linenum << " ERROR : " << s << endl;
		exit(1);
    }

    int main(int argc, char *argv[]) {
		if (argc != 2) {
        	printf ("Usage: sc filename\n");
        	exit(1);
		}
		yyin = fopen(argv[1], "r");         /* open input file */
		
		string fileName = string(argv[1]);
		fileName = fileName.substr(0, fileName.find("."));
		fout.open(fileName + ".jasm");

		/* perform parsing */
		if (yyparse() == 1)                 /* parsing */
			yyerror("Parsing error !");     /* syntax error */
	}
