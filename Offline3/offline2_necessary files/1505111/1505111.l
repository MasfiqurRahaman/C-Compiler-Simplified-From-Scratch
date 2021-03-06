%option noyywrap yylineno

%{

#include "1505111_SymbolTable.h"

//int line_count=1;
int error_count=0;
SymbollTable tables(20);
//FILE *logout;
FILE *tokenout;

//CHAR_LITERAL \'[ -~]\'|\'\\n\'|\'\\t\'|\'\\\\'|\'\\a\'|\'\\f\'|\'\\r\'|\'\\b\'|\'\\v\'|\'\\0\'
// ILL FORM NUM // (INTEGER|FLOATING_POINT)([eE][0-9]*\.[0-9]*)
%}
SPECIAL_CHAR \\n|\\t|\\\\|\\a|\\f|\\r|\\b|\\v|\\0
DIGIT [0-9]
LETTER [a-zA-Z]
INTEGER {DIGIT}+
FLOATING_POINT (({DIGIT}+\.{DIGIT}*)|(\.{DIGIT}+)) 

HEX_NUM 0x([ABCDEF]|[0-9])+
TOO_MANY_DEC_ERROR {DIGIT}*\.{DIGIT}*\.{DIGIT}*
ILL_FORMED_NUMBER_ERROR ({INTEGER}|{FLOATING_POINT})([eE][0-9]*\.[0-9]*)
INVALID_SUFFIX_PREFIX_ERROR {DIGIT}+[A-DF-Za-df-z_]+
MULTI_CHAR_CONST_ERROR \'([ -&(-[\]-~]|{SPECIAL_CHAR})([ -&(-[\]-~]|{SPECIAL_CHAR})+\'
UNFINISHED_CHAR_ERROR (\')|(\'([ -&(-[\]-~]|{SPECIAL_CHAR}))|(\'\\\')
UNFINISHED_STRING_ERROR \"([ -!#-[\]-~]|{SPECIAL_CHAR}|\\\\|\\\n)*
UNRECOGNIZED_CHAR_ERROR [^ -~\n\t\a\f\r\b\v\0]
UNFINISHED_COMMENT \/\*([^*]|\*+[^\/*])*
EMPTY_CHAR_ERROR \'\'

STRING \"([ -!#-[\]-~]|\\\"|\\n|\\t|\\a|\\f|\\r|\\b|\\v|\\0|\\\\|\\\n)+\"
FLOATING_POINT_WITH_EXP ({FLOATING_POINT}([eE][+-]?{DIGIT}+)?)|({INTEGER}[eE][+-]?{DIGIT}+)
CHAR_LITERAL \'([ -&(-[\]-~]|\\n|\\t|\\\\|\\a|\\f|\\r|\\b|\\v|\\0)\'
NEWLINE (\r\n|\r|\n)
WHITESPACE [ \t\f\r\v]+ 
IDENTIFIER [a-zA-Z_][a-zA-Z0-9_]*
COMMENT \/\/(\\\n|[^\n])*|(\/\*([^*]|\*+[^\/*])*\*\/)

%% 

{TOO_MANY_DEC_ERROR}	{
			error_count++;
			fprintf(logout,"Error at Line no %d:Too many decimal point in %s\n\n",yylineno, yytext);
}
{ILL_FORMED_NUMBER_ERROR}	{
			error_count++;
			fprintf(logout,"Error at Line no %d:Ill formed number in %s\n\n",yylineno, yytext);
}
{INVALID_SUFFIX_PREFIX_ERROR}	{
			error_count++;
			fprintf(logout,"Error at Line no %d:Invalid suffix on numberic constant, or invalid prefix on identifier %s\n\n",yylineno, yytext);
}
{MULTI_CHAR_CONST_ERROR} {
			error_count++;
			fprintf(logout,"Error at Line no %d:Multi character constant %s\n\n",yylineno, yytext);
}
{UNFINISHED_CHAR_ERROR}	{
			error_count++;
			fprintf(logout,"Error at Line no %d:Unterminated character %s\n\n",yylineno, yytext);
}
{UNFINISHED_STRING_ERROR} {
			error_count++;
			fprintf(logout,"Error at Line no %d:Unterminated string %s\n\n",yylineno, yytext);
			for(int i=0; i<strlen(yytext); i++){
				if(i+1<strlen(yytext) && yytext[i] == '\\' && yytext[i+1] == '\n'){
					//line_count++;
				}
			}
}
{UNRECOGNIZED_CHAR_ERROR} {
			error_count++;
			fprintf(logout,"Error at Line no %d:Unrecognized character %s\n\n",yylineno, yytext);
}
{UNFINISHED_COMMENT} {
			error_count++;
			fprintf(logout,"Error at Line no %d:Unfinished comment %s\n\n",yylineno, yytext);
			for(int i=0; i<strlen(yytext); i++){
				if(i+1<strlen(yytext) && yytext[i] == '\\' && yytext[i+1] == '\n'){
					//line_count++;
				}
			}
}
{EMPTY_CHAR_ERROR} {
			error_count++;
			fprintf(logout,"Error at Line no %d:Empty char constant %s\n\n",yylineno, yytext);
			
}
"if"	{ //Keywords.............................................
			fprintf(tokenout, "<IF> ");
			fprintf(logout,"Line no %d: TOKEN <IF>  Lexeme %s found\n\n",yylineno,yytext);
}
		
"for"	{
			fprintf(tokenout, "<FOR> ");
			fprintf(logout,"Line no %d: TOKEN <FOR>  Lexeme %s found\n\n",yylineno,yytext);
		}
		
"do"	{
			fprintf(tokenout, "<DO> ");
			fprintf(logout,"Line no %d: TOKEN <DO>  Lexeme %s found\n\n",yylineno,yytext);
		}
		
"int"	{
			fprintf(tokenout, "<INT> ");
			fprintf(logout,"Line no %d: TOKEN <INT>  Lexeme %s found\n\n",yylineno,yytext);
		}
		
"float"	{
			fprintf(tokenout, "<FLOAT> ");
			fprintf(logout,"Line no %d: TOKEN <FLOAT>  Lexeme %s found\n\n",yylineno,yytext);
		}
		
"void"	{
			fprintf(tokenout,"<VOID> ");
			fprintf(logout,"Line no %d: TOKEN <VOID>  Lexeme %s found\n\n",yylineno,yytext);
		}
		
"switch"	{
			fprintf(tokenout, "<SWITCH> ");
			fprintf(logout,"Line no %d: TOKEN <SWITCH>  Lexeme %s found\n\n",yylineno,yytext);
		}
		
"default"	{
			fprintf(tokenout, "<DEFAULT> ");
			fprintf(logout,"Line no %d: TOKEN <DEFAULT>  Lexeme %s found\n\n",yylineno,yytext);

		}
"else"	{
			fprintf(tokenout, "<ELSE> ");
			fprintf(logout,"Line no %d: TOKEN <ELSE>  Lexeme %s found\n\n",yylineno,yytext);
		}
		
"while"	{
			fprintf(tokenout, "<WHILE> ");
			fprintf(logout,"Line no %d: TOKEN <WHILE>  Lexeme %s found\n\n",yylineno,yytext);
		}
		
"break"	{
			fprintf(tokenout, "<BREAK> ");
			fprintf(logout,"Line no %d: TOKEN <BREAK>  Lexeme %s found\n\n",yylineno,yytext);
		}
		
"char"	{
			fprintf(tokenout, "<CHAR> ");
			fprintf(logout,"Line no %d: TOKEN <CHAR>  Lexeme %s found\n\n",yylineno,yytext);
		}
		
"double"	{
			fprintf(tokenout, "<DOUBLE> ");
			fprintf(logout,"Line no %d: TOKEN <DOUBLE>  Lexeme %s found\n\n",yylineno,yytext);
		}
		
"return"	{
			fprintf(tokenout, "<RETURN> ");
			fprintf(logout,"Line no %d: TOKEN <RETURN>  Lexeme %s found\n\n",yylineno,yytext);
		}
		
"case"	{
			fprintf(tokenout, "<CASE> ");
			fprintf(logout,"Line no %d: TOKEN <CASE>  Lexeme %s found\n\n",yylineno,yytext);
		}
		
"continue"	{
			fprintf(tokenout, "<CONTINUE> ");
			fprintf(logout,"Line no %d: TOKEN <CONTINUE>  Lexeme %s found\n\n",yylineno,yytext);
//keywords finish.....................................		
}

{HEX_NUM}				{

   //string str(yylex);
	
   int val=0;
   int len = strlen(yytext);
   for(int i=2;i<len;i++){

        int int_val = yytext[i]-'0';
        if(yytext[i] == 'A'){int_val=10;}
        else if(yytext[i] == 'B'){int_val=11;}
        else if(yytext[i] == 'C'){int_val=12;}
        else if(yytext[i] == 'D'){int_val=13;}
        else if(yytext[i] == 'E'){int_val=14;}
        else if(yytext[i] == 'F'){int_val=15;}
        val+=pow(16,len-i-1)*int_val;
        //cout<<(int)yytext[i]<<endl;
        //new_yytext+=yytext[i];
   }
			string result;          // string which will contain the result
			ostringstream convert;   // stream used for the conversion
			convert << val;      // insert the textual representation of 'Number' in the characters in the stream
			result = convert.str();
			
			fprintf(tokenout,"<CONST_INT, %s> ",result.c_str());
			fprintf(logout,"Line no %d: TOKEN <CONST_INT>  Lexeme %s found\n\n",yylineno,yytext);
				//insert in symbol table and print symbol table content(only non empty buckets)
			tables.Insert(result,"CONST_INT");
			tables.PrintAllScopeTable();
}
{INTEGER} 	{
				
			fprintf(tokenout,"<CONST_INT, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <CONST_INT>  Lexeme %s found\n\n",yylineno,yytext);
				//insert in symbol table and print symbol table content(only non empty buckets)
			tables.Insert(yytext,"CONST_INT");
			tables.PrintAllScopeTable();	
}

{FLOATING_POINT_WITH_EXP}	{
			fprintf(tokenout, "<CONST_FLOAT, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <CONST_FLOAT>  Lexeme %s found\n\n",yylineno,yytext);
			tables.Insert(yytext,"CONST_FLOAT");
			tables.PrintAllScopeTable();	
}
{CHAR_LITERAL}		{
			char ch;
			if(strlen(yytext) == 3){
				ch = yytext[1];
			}
			else if(strlen(yytext) == 4){
				if(yytext[2] == 'n'){ch='\n';}
				else if(yytext[2] == 't'){ch='\t';}
				else if(yytext[2] == '\\'){ch='\\';}
				else if(yytext[2] == 'a'){ch='\a';}
				else if(yytext[2] == 'f'){ch='\f';}
				else if(yytext[2] == 'r'){ch='\r';}
				else if(yytext[2] == 'b'){ch='\b';}
				else if(yytext[2] == 'v'){ch='\v';}
				else if(yytext[2] == '\0'){ch='\0';}
			}	
			
			fprintf(tokenout, "<CONST_CHAR ,%c> ",ch);
			fprintf(logout,"Line no %d: TOKEN <CONST_CHAR>  Lexeme %s found\n\n",yylineno,yytext);
			
			string str(1,ch);
			tables.Insert(str,"CONST_FLOAT");
			tables.PrintAllScopeTable();	
}


{NEWLINE}		{}
{WHITESPACE}		{}
"+"			|

"-"			{
			fprintf(tokenout,"<ADDOP, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <ADDOP>  Lexeme %s found\n\n",yylineno,yytext);
			//insert in symbol table and print symbol table content(only non empty buckets)
			tables.Insert(yytext,"ADDOP");
			tables.PrintAllScopeTable();
			// There is a '|' in "+"'s rule, this means match execute the action for following rule
			
}
[*/%]			{
			fprintf(tokenout,"<MULOP, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <MULOP>  Lexeme %s found\n\n",yylineno,yytext);
			tables.Insert(yytext,"MULOP");
			tables.PrintAllScopeTable();
}
"++"	| 
"--"			{
			fprintf(tokenout,"<INCOP, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <INCOP> Lexeme %s found\n\n",yylineno,yytext);
			tables.Insert(yytext,"INCOP");
			tables.PrintAllScopeTable();	
}
"<"	|
"<="	|
">"	|
">="	|
"=="	|
"!="			{
			fprintf(tokenout,"<RELOP, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <RELOP> Lexeme %s found\n\n",yylineno,yytext);
			tables.Insert(yytext,"RELOP");
			tables.PrintAllScopeTable();	
}
"="			{
			fprintf(tokenout,"<ASSIGNOP, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <ASSIGNOP> Lexeme %s found\n\n",yylineno,yytext);
			tables.Insert(yytext,"ASSIGNOP");
			tables.PrintAllScopeTable();	
}
"&&"	|
"||"			{
			fprintf(tokenout,"<LOGICOP, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <LOGICOP> Lexeme %s found\n\n",yylineno,yytext);
			tables.Insert(yytext,"LOGICOP");
			tables.PrintAllScopeTable();	
}
"&"	|
"|"	|
"^"	|
"<<"	|
">>"			{
			fprintf(tokenout,"<BITOP, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <BITOP> Lexeme %s found\n\n",yylineno,yytext);
			tables.Insert(yytext,"BITOP");
			tables.PrintAllScopeTable();	
}
"!"			{
			fprintf(tokenout,"<NOT, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <NOT> Lexeme %s found\n\n",yylineno,yytext);
			tables.Insert(yytext,"NOT");
			tables.PrintAllScopeTable();	
}
"("			{
			fprintf(tokenout,"<LPAREN, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <LPAREN> Lexeme %s found\n\n",yylineno,yytext);
			tables.Insert(yytext,"LPAREN");
			tables.PrintAllScopeTable();	
}
")"			{
			fprintf(tokenout,"<RPAREN, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <RPAREN> Lexeme %s found\n\n",yylineno,yytext);
			tables.Insert(yytext,"RPAREN");
			tables.PrintAllScopeTable();	
}
"{"			{
			fprintf(tokenout,"<LCURL, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <LCURL> Lexeme %s found\n\n",yylineno,yytext);
			tables.Insert(yytext,"LCURL");
			tables.PrintAllScopeTable();	
}
"}"			{
			fprintf(tokenout,"<RCURL,%s>",yytext);
			fprintf(logout,"Line no %d: TOKEN <RCURL> Lexeme %s found\n\n",yylineno,yytext);
			tables.Insert(yytext,"RCURL");
			tables.PrintAllScopeTable();	
}
"["			{
			fprintf(tokenout,"<LTHIRD, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <LTHIRD> Lexeme %s found\n\n",yylineno,yytext);
			tables.Insert(yytext,"LTHIRD");
			tables.PrintAllScopeTable();	
}
"]"			{
			fprintf(tokenout,"<RTHIRD, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <RTHIRD> Lexeme %s found\n\n",yylineno,yytext);
			tables.Insert(yytext,"RTHIRD");
			tables.PrintAllScopeTable();	
}
","			{
			fprintf(tokenout,"<COMMA, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <COMMA> Lexeme %s found\n\n",yylineno,yytext);
			tables.Insert(yytext,"COMMA");
			tables.PrintAllScopeTable();	
}
";"			{
			fprintf(tokenout,"<SEMICOLON, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <SEMICOLON> Lexeme %s found\n\n",yylineno,yytext);
			tables.Insert(yytext,"SEMICOLON");
			tables.PrintAllScopeTable();	
}
{IDENTIFIER}		{
			fprintf(tokenout,"<ID, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <ID> Lexeme %s found\n\n",yylineno,yytext);
			tables.Insert(yytext,"ID");
			tables.PrintAllScopeTable();	
}
{STRING}		{

			
			string str="";
			for(int i=0; i<strlen(yytext); i++){
				if(yytext[i] == '\\'){
					if(yytext[i+1] == '\n'){
						i++;
						//line_count++;
						//str+='\t';
					}
					else if(yytext[i+1] == 't'){
						i++;
						str+='\t';
					}
					else if(yytext[i+1] == 'n'){
						i++;
						str+='\n';
					}
					else if(yytext[i+1] == '"'){
						i++;
						str+='"';
					}
				}
				else{
					str+=yytext[i];
				}
			}
			fprintf(logout,"Line no %d: TOKEN <STRING> Lexeme %s found\n\n",yylineno,yytext);			
			fprintf(tokenout,"<STRING, %s> ",str.c_str());
			tables.Insert(yytext,"STRING");
			tables.PrintAllScopeTable();
}
{COMMENT}	{
			fprintf(logout,"Line no %d: TOKEN <COMMENT> Lexeme %s found\n\n",yylineno,yytext);
			for(int i=0;i<strlen(yytext);i++){
				if(yytext[i] == '\n'){
					//line_count++;
				}
			}
			
}		
			

%%

int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	logout= fopen("1505111_log.txt","w");
	tokenout= fopen("1505111_token.txt","w");
	yyin= fin;



	//output.open("1505111_log.txt");



	yylex();
	tables.PrintAllScopeTable();
	fprintf(logout,"num of errors: %d\n",error_count);
	fprintf(logout,"num of lines in input file: %d\n",yylineno);
	fclose(yyin);
	fclose(tokenout);
	fclose(logout);
	return 0;
}
