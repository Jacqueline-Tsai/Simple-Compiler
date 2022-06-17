#include <iostream>
#include <map>
#include <vector>
#include <stdio.h>
#include <fstream>
using namespace std;

extern ofstream fout;

enum Type{
	boolean_type,
	integer_type,
	float_type,
	string_type,
	boolean_array_type,
	integer_array_type,
	float_array_type,
	string_array_type,
	void_type,
	constant_variable_type,
	variable_type, 
	function_type
};

string get_type_string(Type);

struct Symbol {
	int value, stack_buffer, array_size, index; 			//not :-1
	string name;
	Type variable_type;			//constant_variable, variable, function
	Type return_or_data_type;	//bool, string, integer, float, array, void
	vector<Type> arguments;
	Symbol();
};

class SymbolTableStack{
public:
	SymbolTableStack();
	vector<Type> tmp;
	vector<vector<Symbol>>  stack;
	bool push();
	bool pop();
	bool lookup(string);
	Symbol get_symbol(string);	//symbol_name
	bool insert_symbol(Symbol);
	bool insert_symbol(string symbol_name, Type symbol_variable_type, Type symbol_data_type, Type return_type);
	void dump();						// dump all SymbolTable (from top to 0)
	bool add_argument(string, Type, int);
	bool add_return_type(Type);
	bool check_function_return_type(Type);
	bool check_params(string);
};

class Generator{
public:
	Generator();
	void class_start(string);
	void class_end();
	void function_start_name(string);
	void function_start_argument(Type);
	void function_start_return(Type);
	void function_end();
	void function_invocation(Symbol);
	void global_variable_declaration(Type, string);
	void global_variable_value(Type, string, int);
	void const_value(Type, int);
	void assign_value(Type, int, int);
	void get_constant_variable(Symbol);
	void get_global_variable(Symbol);
	void get_local_variable(Symbol);
	void put_global_variable(Symbol);
	void put_local_variable(Symbol);
	void operation(string);
	void operation_if(string);
	void for_start(Symbol, int, int);
	void for_end(Symbol, int, int);
	void print_start();
	void print_end(Type, bool);
	void string_const(string);
	void if_start();
	void else_start();
	void if_end();
	void if_else_end();
	void while_start();
	void while_mid();
	void while_end();
	vector<Type> function_type;
	vector<string> block_name;
	string function_name, class_name;
	int block_number, buffer_number;
	string type[12] = {"boolean", "int", "float", "string", "", "", "", "", "void"};
};
