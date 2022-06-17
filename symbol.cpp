#include "symbol.hpp"

Symbol::Symbol(){
	name = "";
}

SymbolTableStack::SymbolTableStack(){
	stack.resize(0);
}

bool SymbolTableStack::push(){
	vector<Symbol> new_table(0);
	stack.push_back(new_table);
	return true;
}

bool SymbolTableStack::pop(){
	if(stack.size() == 0) return false;
	stack.pop_back();
	return true;
}

bool SymbolTableStack::lookup(string symbol_name){
	for (vector<Symbol> table : stack){
		for (Symbol symbol : table){
			if (symbol.name == symbol_name){
				return true;
			}
		}
	}
	return false;
}

Symbol SymbolTableStack::get_symbol(string symbol_name){
	Symbol ans = Symbol();
	for (vector<Symbol> table : stack){
		for (Symbol symbol : table){
			if (symbol.name == symbol_name){
				ans = symbol;
			}
		}
	}
	return ans;
}

bool SymbolTableStack::insert_symbol(Symbol new_symbol){
	if(stack.size()==0)	return false;
	new_symbol.index = stack.size();
	for (Symbol s : stack[stack.size() - 1]){
		if (s.name == new_symbol.name) return false;
	}
	stack[stack.size() - 1].push_back(new_symbol);
	return true;
}

bool SymbolTableStack::insert_symbol(string symbol_name, Type symbol_variable_type, Type symbol_type, Type return_type){
	if(stack.size()==0)	return false;
	for (Symbol s : stack[stack.size() - 1]){
		if (s.name == symbol_name) return false;
	}
	Symbol new_symbol;
	new_symbol.name = symbol_name;
	new_symbol.variable_type = symbol_variable_type;
	new_symbol.return_or_data_type = symbol_type;
	new_symbol.index = stack.size();
	stack[stack.size() - 1].push_back(new_symbol);
	return true;
}

void SymbolTableStack::dump(){
	for (vector<Symbol> table : stack){
		cout << "==================================================\n";
		for (Symbol symbol : table){
			cout << "name : " << symbol.name << "	variable_type : " << symbol.variable_type
			 << "	return and data type : " << symbol.return_or_data_type
			 << "	array_size : " << symbol.array_size + "\n";
		}
	}
	cout << "==================================================\n";
}

bool SymbolTableStack::add_argument(string identidier, Type argument_type, int buffer_number){
	Symbol new_symbol;
	new_symbol.name = identidier;
	new_symbol.variable_type = variable_type;
	new_symbol.return_or_data_type = argument_type;
	new_symbol.array_size = -1;
	new_symbol.stack_buffer = buffer_number;
	new_symbol.index = stack.size();
	insert_symbol(new_symbol);
	stack[stack.size() - 2][stack[stack.size() - 2].size() - 1].arguments.push_back(argument_type);
	return true;
}

bool SymbolTableStack::add_return_type(Type return_type){
	stack[stack.size() - 2][stack[stack.size() - 2].size() - 1].return_or_data_type = return_type;
}

bool SymbolTableStack::check_function_return_type(Type check_type){
	for (size_t i = stack.size() - 2; i >= 0; i--){
		if (stack[i][stack[i].size() - 1].variable_type == function_type){
			if(stack[i][stack[i].size() - 1].return_or_data_type == check_type)	return true;
			else return false;
		}
	}
}

bool SymbolTableStack::check_params(string function_name){
	for (vector<Symbol> table : stack){
		for (Symbol symbol : table){
			if (symbol.name == function_name){
				if (symbol.arguments == tmp) return true;
				else return false;
			}
		}
	}
	return false;
}

Generator::Generator() {
	block_number = 1;
	fout << "class example\n{\nmethod public static void main (java.lang.String[])\nmax_stack 2\n{\ngetstatic java.io.PrintStream java.lang.System.out\nldc \"Hello World!\"\ninvokevirtual void java.io.PrintStream.println(java.lang.String)\nreturn\n}\n}\n";
}

void Generator::class_start(string name) {
	fout << "class " + name + "\n{\n";
}

void Generator::class_end() {
	fout << "}\n";
}

void Generator::function_start_name(string name) {
	function_name = name;
	function_type.resize(0);
}
void Generator::function_start_argument(Type type) {
	function_type.push_back(type);
}

void Generator::function_start_return(Type t) {
	string arg = "";
	if (function_type.size() == 0){
		arg = "java.lang.String[]";
	}
	else{
		for (Type& tt : function_type){
			arg += type[tt] + ",";
		}
		arg.pop_back();
	}
	function_type.push_back(t);
	fout << "method public static " + type[t] + " " + function_name + "(" + arg + ")\nmax_stack 15\nmax_locals 15\n{\n";
}

void Generator::function_end() {
	if(function_type[function_type.size()-1] == void_type)
		fout << "return\n}\n";
	else
		fout << "ireturn\n}\n";
	function_type.clear();
}

void Generator::function_invocation(Symbol identidier) {
	fout << "invokestatic " + type[identidier.return_or_data_type] + " " + class_name + "." + identidier.name + "(";
	for (int i = 0; i < identidier.arguments.size(); i++){
		if(i!=0) fout << ",";
		fout << type[identidier.arguments[i]];
	}
	fout << ")\n";
}

void Generator::global_variable_declaration(Type t, string name){
	fout << "field static " + type[t] + " " + name + "\n";
}

void Generator::global_variable_value(Type t, string name, int value){
	if(t == boolean_type){
		if(value == 1) fout << "field static " + type[t] + " " + name + " = 1" + "\n";
		else fout << "field static " + type[t] + " " + name + " = 0" + "\n";
	}
	else if(t == integer_type){
		fout << "field static " + type[t] + " " + name + " = " + to_string(value) + "\n";
	}
}

void Generator::const_value(Type t, int value){
	if(t == boolean_type) {
		if (value == 1) fout << "iconst_1\n";
		if (value == 0) fout << "iconst_0\n";
	}
	else if(t == integer_type) {
		fout << "sipush " << to_string(value) + "\n";
	}
}

void Generator::assign_value(Type t, int buffer, int value){
	const_value(t, value);
	fout << "istore " + to_string(buffer) + "\n";
}

void Generator::get_constant_variable(Symbol identidier){
	if(identidier.return_or_data_type == boolean_type) {
		if (identidier.value == 1) fout << "iconst_1\n";
		if (identidier.value == 0) fout << "iconst_0\n";
	}
	else if(identidier.return_or_data_type == integer_type) {
		fout << "sipush " << to_string(identidier.value) + "\n";
	}
}

void Generator::put_global_variable(Symbol identidier){
	fout << "putstatic " + type[identidier.return_or_data_type] << " " << class_name << "." << identidier.name + "\n";
}

void Generator::put_local_variable(Symbol identidier){
	fout << "istore " + to_string(identidier.stack_buffer) + "\n";
}

void Generator::get_global_variable(Symbol identidier){
	fout << "getstatic " + type[identidier.return_or_data_type] + " " + class_name + "." + identidier.name + "\n";
}

void Generator::get_local_variable(Symbol identidier){
	fout << "iload " + to_string(identidier.stack_buffer) + "\n";
}

void Generator::operation(string op) {
	fout << op + "\n";
}

void Generator::operation_if(string op) {
	fout << "isub\n" + op + " L" + to_string(block_number) + "if\n"
                    +"iconst_0\n"
                    +"goto L" + to_string(block_number) + "else\n"
                    +"L" +to_string(block_number) + "if:\niconst_1\n"
                    +"L" << to_string(block_number)+"else:\nnop\n";
	block_number += 1;
}

void Generator::for_start(Symbol identidier, int start, int end){
	block_name.push_back("L" + to_string(block_number));
	block_number += 1;
	fout << "sipush " << to_string(start) + "\n";
	fout << "istore " << to_string(identidier.stack_buffer) + "\n";
	fout << block_name[block_name.size()-1] + "if:\nnop\n";
	if(start <= end)
	{
		fout << "iload " << to_string(identidier.stack_buffer) + "\n";
		fout << "sipush " << to_string(end) + "\n";
		fout << "isub\n";
		fout << "ifgt " + block_name[block_name.size()-1] + "else\n";
	}
	else
	{
		fout << "sipush " << to_string(end) + "\n";
		fout << "iload " << to_string(identidier.stack_buffer) + "\n";
		fout << "isub\n";
		fout << "ifgt " + block_name[block_name.size()-1] + "else\n";
	}
}

void Generator::for_end(Symbol identidier, int start, int end){
	cout<<identidier.name<<endl;
	fout << "iload " << to_string(identidier.stack_buffer) << endl;
	fout << "sipush 1" << endl;
	if(end >= start) fout << "iadd" << endl;
	else fout << "isub" << endl;
	fout << "istore " << to_string(identidier.stack_buffer) << endl;
	fout << "goto " + block_name[block_name.size()-1] + "if\n";
	fout << block_name[block_name.size()-1] + "else:\n";
	block_name.pop_back();
}

void Generator::print_start(){
	fout << "getstatic java.io.PrintStream java.lang.System.out\n";
}

void Generator::print_end(Type t, bool ln){
	string println = ln? "ln":"";
	if(t == string_type)
	{
		fout << "invokevirtual void java.io.PrintStream.print" + println + "(java.lang.String)\n";
	}
	else 
	{
		fout << "invokevirtual void java.io.PrintStream.print" + println + "(int)\n";
	}
}

void Generator::string_const(string s){
	fout << "ldc \"" + s + "\"\n";
}

void Generator::if_start(){
	block_name.push_back("L" + to_string(block_number));
	block_number += 1;
	fout << "ifeq " + block_name[block_name.size()-1] + "else" << endl;
}

void Generator::else_start(){
	fout << "goto " + block_name[block_name.size()-1] + "exit\n";
    fout << block_name[block_name.size()-1] + "else:\nnop\n";
}

void Generator::if_end(){
    fout << block_name[block_name.size()-1] + "else:\nnop\n";
	fout << "goto " + block_name[block_name.size()-1] + "exit\n";
	fout << block_name[block_name.size()-1] + "exit:\nnop\n";
	block_name.pop_back();
}

void Generator::if_else_end(){
    fout << block_name[block_name.size()-1] << "exit:\nnop\n";
	block_name.pop_back();
}

void Generator::while_start(){
	block_name.push_back("L" + to_string(block_number));
	block_number += 1;
	fout << block_name[block_name.size()-1] + "if:\nnop\n";
}

void Generator::while_mid(){
	fout << "ifeq " + block_name[block_name.size()-1] + "exit\n";
	fout << block_name[block_name.size()-1] + "begin:\nnop\n";
}

void Generator::while_end(){
	fout << "goto " + block_name[block_name.size()-1] + "if\n";
	fout << block_name[block_name.size()-1] + "exit:\nnop\n";
	block_name.pop_back();
}
