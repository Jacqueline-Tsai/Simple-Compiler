TARGET = compiler

all: $(TARGET)

$(TARGET): lex.yy.cpp y.tab.cpp symbol.cpp symbol.hpp 
	g++ y.tab.cpp symbol.cpp -o $@ -ll -ly

lex.yy.cpp: scanner.l
	flex -o $@ $^

y.tab.cpp: parser.y
	yacc -y -d $^ -o $@

clean:
	rm parser lex.yy.cpp y.tab.* *.jasm javaa *.class
