%{
    #include <iostream>
    using namespace std;
    #include "y.tab.hpp"

    #define LIST     strcat(buf,yytext)
    #define token(t) {LIST; if(token) printf("<%s>\n", #t);}
    #define tokenInteger(t,i) {LIST; if(token) printf("<%s: %d>\n", #t, i);}
    #define tokenString(t,s) {LIST; if(token) printf("<%s: %s>\n", #t, s);}

    #define MAX_LINE_LENG 256

    int linenum = 1;				// line number
    char buf[MAX_LINE_LENG];		// line buffer
    char strbuf[MAX_LINE_LENG];		// string buffer

    int token = 0;
%}

whitespace [ \t]+
comment1 "//".*
comment2 "/*"((\*+[^/*])|([^*]))*\**"*/"

letter [A-Za-z_]
digit [0-9]
fraction [0-9]+
float {integer}"."{fraction}

identifier ({letter})({letter}|{digit})*
integer [0-9]*
real [+-]?({integer}|{float})([eE][-+]?[0-9]+)?
string \"(\\.|[^"\\])*\" 

%%

{comment1}   {LIST;}
{comment2}   {
        char tmpBuf[MAX_LINE_LENG];
        int index = 0;
        for(int i=0; i<yyleng; i++) {
            tmpBuf[index++] = yytext[i];
            if(yytext[i]=='\n'){
                tmpBuf[index] = '\0';
                index = 0;
                strcat(buf, tmpBuf);
                linenum++;
                if(token) printf("%d: %s", linenum, buf);
                buf[0] = '\0';
            }
        }
        tmpBuf[index] = '\0';
        strcat(buf, tmpBuf);
    }
[ \t]*      {LIST;}

","     {token(','); return yytext[0];}
":"     {token(':'); return yytext[0];}
";"     {token(';'); return yytext[0];}
"->"    {token('->');}
"("     {token('('); return yytext[0];}
")"     {token(')'); return yytext[0];}
"["     {token('['); return yytext[0];}
"]"     {token(']'); return yytext[0];}
"{"     {token('{'); return yytext[0];}
"}"     {token('}'); return yytext[0];}

"<="    {token('<='); return LE;}
">="    {token('>='); return GE;}
"=="    {token('=='); return EQ;}
"!="    {token('!='); return NEQ;}
"+="    {token('+='); return ADDA;}
"-="    {token('-='); return SUBA;}
"*="    {token('*='); return MULA;}
"/="    {token('/='); return DIVA;}
".."     {token('..'); return DD;}
"+"     {token('+'); return yytext[0];}
"-"     {token('-'); return yytext[0];}
"*"     {token('*'); return yytext[0];}
"/"     {token('/'); return yytext[0];}
"%"     {token('%'); return yytext[0];}
"<"     {token('<'); return yytext[0];}
">"     {token('>'); return yytext[0];}
"&"     {token('&'); return yytext[0];}
"|"     {token('|'); return yytext[0];}
"!"     {token('!'); return yytext[0];}
"="     {token('='); return yytext[0];}

"bool"  {token(BOOL); return BOOLEAN;}
"boolean"  {token(BOOLEAN); return BOOLEAN;}
"float"  {token(FLOAT); return FLOAT;}
"int"  {token(INT); return INTEGER;}
"integer"  {token(INTEGER); return INTEGER;}
"string"  {token(STRING); return STRING;}

"break"  {token(BREAK); return BREAK;}
"char"  {token(CHAR); return CHAR;}
"case"  {token(CASE); return CASE;}
"class"  {token(CLASS); return CLASS;}
"continue"  {token(CONTINUE); return CONTINUE;}
"declare"  {token(DECLARE); return DECLARE;}
"do"  {token(DO); return DO;}
"else"  {token(ELSE); return ELSE;}
"exit"  {token(EXIT); return EXIT;}
"for"  {token(FOR); return FOR;}
"fun"  {token(FUN); return FUN;}
"if"  {token(IF); return IF;}
"loop"  {token(LOOP); return LOOP;}
"print"  {token(PRINT); return PRINT;}
"println"  {token(PRINTLN); return PRINTLN;}
"return"  {token(RETURN); return RETURN;}
"val"  {token(VAL); return VAL;}
"var"  {token(VAR); return VAR;}
"while"  {token(WHILE); return WHILE;}
"read"  {token(READ); return READ;}
"in" {token(IN); return IN;}

"true"   {
    tokenString(bool, yytext);
    yylval.boolean_data = true;
	return BOOLEAN_VALUE;
}
"false"   {
    tokenString(bool, yytext);
    yylval.boolean_data = false;
	return BOOLEAN_VALUE;
}
{identifier} {
    tokenString(id, yytext);
    yylval.string_data = new string(yytext);
	return IDENTIFIER_VALUE;
}
{integer}   {
    tokenInteger(integer, atoi(yytext));
    yylval.integer_data = atoi(yytext);
	return INTEGER_VALUE;
}
{float}      {
    tokenString(float, yytext);
    yylval.float_data = atof(yytext);
	return FLOAT_VALUE;
}
{string} {
        LIST;
        for(int i=0; i<yyleng-2; i++) {
            yytext[i] = yytext[i+1];
        }
        yytext[yyleng-2] = '\0';
        tokenString(string, yytext);
        yylval.string_data = new string(yytext);
	    return STRING_VALUE;
    }

\n      {
            LIST;
            linenum++;
            if(token) printf("%d: %s", linenum, buf);
            buf[0] = '\0';
        }

.       {
            LIST;
            if(token) printf("bad character:'%s'\n", yytext);
        }
%%


