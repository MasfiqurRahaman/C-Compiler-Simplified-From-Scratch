%{
#include<iostream>
#include<stdio.h>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<vector>
#include "1505111_SymbolTable.h"
#define YYSTYPE SymbollInfo*

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;
extern int yylineno;

FILE *fp;
FILE *logFile,*errorFile, *assembly;
extern int error_count;
SymbollTable table(20);//num of buckets 7
vector<SymbollInfo * > parameter;
vector< SymbollInfo * > func_args;
SymbollInfo *currecnt_func;
vector<string> variables;
int var_count=0;
string code_inside_main;
string code_inside_procedure;
vector<string> procedures;

int labelCount=0;
int tempCount=0;


char *newLabel()
{
	char *lb= new char[4];
	strcpy(lb,"L");
	char b[3];
	sprintf(b,"%d", labelCount);
	labelCount++;
	strcat(lb,b);
	return lb;
}

char *newTemp()
{
	char *t= new char[4];
	strcpy(t,"t");
	char b[3];
	sprintf(b,"%d", tempCount);
	tempCount++;
	strcat(t,b);
	return t;
}

void yyerror(const char *s)
{
	error_count++;
	fprintf(errorFile, "Line No %d:%s\n",yylineno,s);
}
//global vars----
string func_name("");
//---------------
//global funcs-----
string assemblyVarName(string var_name, int scopeId){
	stringstream convert; // stringstream used for the conversion
	convert << scopeId;//add the value of Number to the characters in the stream
	string var_name_assembly=var_name + "_" + convert.str();
	return var_name_assembly;
}
string println()
{
	string print_code="PRINT_ID proc\n\tpush ax\n";
	print_code += "\tpush bx\n\tpush cx\n\tpush dx\n";
			
	print_code+="\tor ax,ax\n";
	
	
	
	
	print_code+="\tjge end_if1\n";
	print_code += "\tpush ax\n\tmov dl,'-'\n";
	print_code += "\tmov ah,2\n\tint 21h\n\tpop ax\n\tneg ax\n";
			
	print_code+="end_if1:\n\txor cx,cx\n\tmov bx,10\nrepeat:\n\txor dx,dx\n\tdiv bx\n\tpush dx\n\tinc cx\n";
	print_code+="\tor ax,ax\n\tjne repeat\n\tmov ah,2\nprint:\n";
	print_code += "\tpop dx\n\tor dl,30h\n\tint 21h\n\tloop print\n";

	print_code+="\tpop dx\n\tpop cx\n\tpop bx\n\tpop ax\n\tret\nPRINT_ID endp\n";

	return print_code;
}
//-----------------

%}

%define parse.error verbose
%token IF FOR DO INT FLOAT VOID SWITCH DEFAULT ELSE WHILE BREAK CHAR 
%token DOUBLE RETURN CASE CONTINUE INCOP DECOP ASSIGNOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON COMMENT CONST_INT 
%token CONST_FLOAT CONST_CHAR ADDOP MULOP RELOP LOGICOP ID BITOP STRING PRINTLN

/*
%type <SymbollInfo*> start program unit func_declaration func_defination parameter_list compound_statement var_declaration type_specifier 
%type <SymbollInfo*> declaration_list statements statement expression_statement variable expression logic_expression rel_expression
%type <SymbollInfo*> simple_expression term unary_expression factor argument_list arguments
*/
%nonassoc IFX
%nonassoc ELSE


%%

start: program		{
		
		// string str=$1->getName();
		// SymbollInfo *si = new SymbollInfo(str);
		$$=$1;
		fprintf(logFile,"At line no: %d start : program\n\n%s\n\n",yylineno,$$->getName().c_str());

		//assembly
		fprintf(assembly, ".MODEL SMALL\n.STACK 100H\n.DATA\n");
		//.DATA
		while(!variables.empty()){
		    fprintf(assembly, variables.back().c_str());	
		    fprintf(assembly, "\n");			
					
			variables.pop_back();
			var_count++;
		}
		//.CODE
			//main
		fprintf(assembly, ".CODE\nMAIN PROC\n\n");
		if(var_count > 0){
			fprintf(assembly, "MOV AX,@DATA\nMOV DS,AX\n");		
		}

		fprintf(assembly,code_inside_main.c_str());

		fprintf(assembly, "\tMOV AH,4CH\n\tINT 21H\nMAIN ENDP\n");


			//other functions
		while(!procedures.empty()){
		    fprintf(assembly, procedures.back().c_str());	
		    fprintf(assembly, "\n");			
					
			procedures.pop_back();
		}
		fprintf(assembly, println().c_str());
		fprintf(assembly, "END MAIN\n");
		
	}
	;

program:
    program unit	{
		string str=$1->getName()+"\n"+$2->getName();
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d program : program unit\n\n%s\n\n",yylineno,str.c_str());
	}
	| unit			{
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d program: unit\n\n%s\n\n",yylineno,$1->getName().c_str());
	
	}
	;
	
unit: var_declaration	{
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d unit: var_declaration \n\n%s\n\n",yylineno,$1->getName().c_str());
	}
     | func_declaration {
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str);
		$$=si; 
		fprintf(logFile,"At line no: %d unit: func_declaration \n\n\%s\n\n",yylineno,$1->getName().c_str());
	}
     | func_definition	{
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str);
		$$=si; 
		fprintf(logFile,"At line no: %d unit: func_defination \n\n\%s\n\n",yylineno,$1->getName().c_str());
	}
     ;
     
func_declaration: type_specifier ID  LPAREN  parameter_list RPAREN 
		{
			//Insert into smbolltable
			if(table.LookUpAtCurrentScope($2->getName()) == 0){
				SymbollInfo *sym_info = new SymbollInfo($2->getName(), $2->getType()+"_"+$1->getType());
				sym_info->id_type = "FUNC";
				sym_info->func_param = parameter;
				sym_info->func_ret_type = $1->getType();
				currecnt_func=sym_info;
				table.Insert(sym_info);
			}
			else{
				error_count++;
				fprintf(errorFile,"Line No %d: Multiple Declaration of %s\n\n",yylineno,$2->getName().c_str());
			}

			//scope enter
			table.EnterScope();
			while(!parameter.empty()){
				string type_spec = parameter.back()->getType();
				string var_name = parameter.back()->getName();
				parameter.pop_back();
				if(!var_name.empty()){
					SymbollInfo *sym_info = new SymbollInfo(var_name, type_spec);
					
					table.Insert(sym_info);
				}
			}
			parameter.clear();
		} 
		SEMICOLON	{
		string str=$1->getName()+" "+$2->getName()+"("+$4->getName()+")"+";";
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d func_declaration: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON \n\n%s\n\n",yylineno,str.c_str());
		
		//scope exit
		table.PrintAllScopeTable();
		table.ExitScope();
	}
		| type_specifier ID LPAREN RPAREN SEMICOLON	{
		string str=$1->getName()+" "+$2->getName()+"("+")"+";";
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d func_declaration: type_specifier ID LPAREN RPAREN SEMICOLON \n\n%s\n\n",yylineno,str.c_str());
		//Insert into smbolltable
		if(table.LookUpAtCurrentScope($2->getName()) == 0){
			SymbollInfo *sym_info = new SymbollInfo($2->getName(), $2->getType()+"_"+$1->getType());
			sym_info->id_type = "FUNC";
			sym_info->func_param = parameter;
			sym_info->func_ret_type = $1->getType();
			currecnt_func=sym_info;
			table.Insert(sym_info);
		}
		else{
			error_count++;
			fprintf(errorFile,"Line No %d: Multiple Declaration of %s\n\n",yylineno,$2->getName().c_str());
		}
		parameter.clear();
	}
		;
		 
func_definition: type_specifier ID LPAREN  parameter_list RPAREN 
		{

			//Insert into smbolltable
			if(table.LookUp($2->getName()) == 0){
				SymbollInfo *sym_info = new SymbollInfo($2->getName(), $2->getType()+"_"+$1->getType());
				sym_info->id_type = "FUNC";
				sym_info->func_param = parameter;
				sym_info->func_ret_type = $1->getType();
				sym_info->isDefinedFunction=true;
				currecnt_func=sym_info;
				if(table.currentScopeTable->parentScopeTable != 0){
					table.currentScopeTable->parentScopeTable->Insert(sym_info);

					
				}

			}
			else{
				cout<<"identifier exist"<<endl;
				SymbollInfo *temp=table.LookUp($2->getName());
				cout<<yylineno<<"func_defination rule: "<<temp->func_ret_type<<"	"<<$1->getType()<<endl;
				if(temp->func_ret_type.compare($1->getType()) !=0 ){
					error_count++;
					fprintf(errorFile,"Line No %d: Mismatch of return type in function declaration and defination.\n\n",yylineno);
				}
				vector<SymbollInfo * > declaration_param=parameter;
				vector<SymbollInfo * > func_param=temp->func_param;
				if(declaration_param.size() != func_param.size()){
					error_count++;
					fprintf(errorFile,"Line No %d: Mismatch of parameter in function declaration and defination.\n\n",yylineno);
					
				}
				else{
					while(!declaration_param.empty()){
						string n1=declaration_param.back()->getName();
						string n2=func_param.back()->getName();
						string t1=declaration_param.back()->getType();
						string t2=func_param.back()->getType();
						if( n1.compare(n2) !=0 ||  t1.compare(t2) !=0){
							error_count++;
							fprintf(errorFile,"Line No %d: Mismatch of parameter in function declaration and defination.\n\n",yylineno);
						}
						declaration_param.pop_back();
					}
					cout<<yylineno<<" :here"<<endl;
				}
				
			}
			
			while(!parameter.empty()){
				string type_spec = parameter.back()->getType();
				string var_name = parameter.back()->getName();
				parameter.pop_back();
				if(!var_name.empty()){
					SymbollInfo *sym_info = new SymbollInfo(var_name, type_spec);
					table.Insert(sym_info);

					string var_name_assembly = assemblyVarName(sym_info->getName(), table.currentScopeTable->scopeId);
					variables.push_back(var_name_assembly+" DW ?");
				}
			}
			parameter.clear();
			
			
		} compound_statement	{		
		
		
		string str=$1->getName()+" "+$2->getName()+"("+$4->getName()+")"+$7->getName();
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d function_defination: type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n%s\n\n",yylineno,str.c_str());
		

		//assembly
		if($2->getName().compare("main") == 0){
			cout<<">>>>>>>>>>>>main"<<endl;
			code_inside_main = $7->code;
		}
		else{
			code_inside_procedure = $2->getName()+" PROC\n";
			code_inside_procedure += "PUSH AX\nPUSH BX\n";
			code_inside_procedure += $7->code;
			code_inside_procedure += "POP BX\nPOP AX\nret\n";			
			code_inside_procedure += $2->getName()+" ENDP\n";
			procedures.push_back(code_inside_procedure);
			
		}

	}
	| type_specifier ID LPAREN  RPAREN  
		{
			//Insert into smbolltable
			if(table.LookUp($2->getName()) == 0){
				SymbollInfo *sym_info = new SymbollInfo($2->getName(), $2->getType()+"_"+$1->getType());
				sym_info->id_type = "FUNC";
				sym_info->func_param = parameter;
				sym_info->func_ret_type = $1->getType();
				sym_info->isDefinedFunction=true;
				currecnt_func=sym_info;
				if(table.currentScopeTable->parentScopeTable != 0){
					table.currentScopeTable->parentScopeTable->Insert(sym_info);

					
				}
				
			}
			else{
				cout<<"identifier exist"<<endl;
				SymbollInfo *temp=table.LookUp($2->getName());
				cout<<yylineno<<"func_defination rule: "<<temp->func_ret_type<<"	"<<$1->getType()<<endl;
				if(temp->func_ret_type.compare($1->getType()) != 0){
					error_count++;
					fprintf(errorFile,"Line No %d: Mismatch of return type in function declaration and defination.\n\n",yylineno);
				}

				vector<SymbollInfo * > declaration_param=parameter;
				if(declaration_param.size() != 0){
					error_count++;
					fprintf(errorFile,"Line No %d: Mismatch of parameter in function declaration and defination.\n\n",yylineno);		
				}
			}
			parameter.clear();

		
			
		} compound_statement	{
		

		string str=$1->getName()+" "+$2->getName()+"()"+$6->getName();
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d function_defination: type_specifier ID LPAREN RPAREN compound_statement\n\n%s\n\n",yylineno,str.c_str());
		
		//assembly
		if($2->getName().compare("main") == 0){
			cout<<">>>>>>>>>>>>main"<<endl;
			code_inside_main = $6->code;
		}
		else{
			code_inside_procedure = $2->getName()+" PROC\n";
			code_inside_procedure += "PUSH AX\nPUSH BX\n";
			code_inside_procedure += $6->code;
			code_inside_procedure += "POP BX\nPOP AX\nret\n";				
			code_inside_procedure += $2->getName()+" ENDP\n";
			procedures.push_back(code_inside_procedure);
		}
		
		
	}		;				


parameter_list: parameter_list COMMA type_specifier ID	{
			string str=$1->getName()+","+$3->getName()+" "+$4->getName();
			SymbollInfo *si = new SymbollInfo(str);
			$$=si;
			fprintf(logFile,"At line no: %d parameter_list: parameter_list COMMA type_specifier ID \n\n%s\n\n",yylineno,str.c_str());

			SymbollInfo *sym_info=new SymbollInfo($4->getName(), "ID_"+$3->getType());
			sym_info->id_type="VAR";
			parameter.push_back(sym_info);
			
			
	}
		| parameter_list COMMA type_specifier	{

			string str=$1->getName()+","+$3->getName();
			SymbollInfo *si = new SymbollInfo(str);
			$$=si;
			fprintf(logFile,"At line no: %d parameter_list: parameter_list COMMA type_specifier \n\n%s\n\n",yylineno,str.c_str());
			
			SymbollInfo *sym_info=new SymbollInfo("", "ID_"+$3->getType());
			sym_info->id_type="VAR";
			parameter.push_back(sym_info);
			
	
	}
	 	| type_specifier ID	{	

			string str=$1->getName()+" "+$2->getName();
			SymbollInfo *si = new SymbollInfo(str);
			$$=si;

			SymbollInfo *sym_info=new SymbollInfo($2->getName(), "ID_"+$1->getType());
			sym_info->id_type="VAR";
			parameter.push_back(sym_info);
	}
		| type_specifier	{
			string str=$1->getName();
			SymbollInfo *si = new SymbollInfo(str);
			$$=si;
			fprintf(logFile,"At line no: %d parameter_list: type_specifier \n\n%s\n\n",yylineno,str.c_str());
			
			SymbollInfo *sym_info=new SymbollInfo("", "ID_"+$1->getType());
			sym_info->id_type="VAR";
			parameter.push_back(sym_info);			
	}
	 		;

 		
compound_statement: LCURL statements RCURL	{
		
		string str="{\n"+$2->getName()+"}";
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d compound_statement: LCURL statements RCURL \n\n%s\n\n",yylineno,str.c_str());
		//scope exit
		table.PrintAllScopeTable();
		table.ExitScope();

		//assembly
		$$->code = $2->code;
	}
 		| LCURL RCURL	{
		
		string str="{}";
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d compound_statement: LCURL RCURL\n\n%s\n\n",yylineno,str.c_str());
		//scope exit
		table.PrintAllScopeTable();
		table.ExitScope();
		
	}
 		    ;
 		    
var_declaration: type_specifier declaration_list SEMICOLON	{
		string str=$1->getName()+" "+$2->getName()+";";
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d var_declaration: type_specifier declaration_list SEMICOLON\n\n%s\n\n",yylineno,str.c_str());
	
		//spitting declaration list.
		string str_in=$2->getName();cout<<"declaration_list: "<<str_in<<endl;
		string result("");
		for(int i=0;i<str_in.size();i++){
			if(str_in[i]==','){
				if(!result.empty()){

					if(!table.LookUpAtCurrentScope(result)){
						 cout<<yylineno<<"  at rule var_declaation1: "<<result<<endl;
						SymbollInfo *sym_info = new SymbollInfo(result,"ID_"+$1->getType());
						sym_info->id_type="VAR";
						table.Insert(sym_info);

						string var_name_assembly = assemblyVarName(sym_info->getName(), table.currentScopeTable->scopeId);
						variables.push_back(var_name_assembly+" DW ?");
						
						// stringstream convert; // stringstream used for the conversion
						// convert << table.currentScopeTable->scopeId;//add the value of Number to the characters in the stream
						// string var_name_assembly=sym_info->getName() + "_" + convert.str();
						// variables.push_back(var_name_assembly+" DW");
					}
					else{
						error_count++;
						fprintf(errorFile,"Line No %d: Multiple Declaration of %s\n\n",yylineno,result.c_str());
					}
				}
				result="";
			}
			else if(str_in[i]=='['){
				cout<<result<<endl;
				if(!result.empty()){
					
					if(!table.LookUpAtCurrentScope(result)){
						SymbollInfo *sym_info = new SymbollInfo(result,"ID_"+$1->getType());
						sym_info->id_type="ARR";				cout<<yylineno<<"var_declaration rule: ------------------"<<sym_info->getName()<<endl;

						int j=i+1;
						string num("");
						while(str_in[j]!=']'){num.push_back(str_in[j]);j++;}
						sym_info->arr_size=atoi(num.c_str());
						table.Insert(sym_info);

						string var_name_assembly = assemblyVarName(sym_info->getName(), table.currentScopeTable->scopeId);
						variables.push_back(var_name_assembly+" DW ?");

						// stringstream convert; // stringstream used for the conversion
						// convert << table.currentScopeTable->scopeId;//add the value of Number to the characters in the stream
						// string var_name_assembly=sym_info->getName() + "_" + convert.str();
						// variables.push_back(var_name_assembly+" DW");
						
					}
					else{
						error_count++;
						fprintf(errorFile,"Line No %d: Multiple Declaration of %s\n\n",yylineno,result.c_str());
					}
				}
				result="";
				while(str_in[i]!=']'){i++;}
				i++;
			}
			else{
				result.push_back(str_in[i]);
			}
		}
		if(!result.empty()){

			if(!table.LookUpAtCurrentScope(result)){
			cout<<yylineno<<"  at rule var_declaation1: "<<result<<endl;
				SymbollInfo *sym_info = new SymbollInfo(result,"ID_"+$1->getType());
				sym_info->id_type="VAR";
				table.Insert(sym_info);

				string var_name_assembly = assemblyVarName(sym_info->getName(), table.currentScopeTable->scopeId);
				variables.push_back(var_name_assembly+" DW ?");
				
				// stringstream convert; // stringstream used for the conversion
				// convert << table.currentScopeTable->scopeId;//add the value of Number to the characters in the stream
				// string var_name_assembly=sym_info->getName() + "_" + convert.str();
				// variables.push_back(var_name_assembly+" DW");
			}
			else{
				error_count++;
				fprintf(errorFile,"Line No %d: Multiple Declaration of %s\n\n",yylineno,result.c_str());
			}
		}

	}
 		 ;
 		 
type_specifier: INT	{
		SymbollInfo *si = new SymbollInfo("int","INT");
		$$=si;
		fprintf(logFile,"At line no: %d type_specifier: INT\n\n%s\n\n",yylineno,"int");
	}
 		| FLOAT	{
		SymbollInfo *si = new SymbollInfo("float","FLOAT");
		$$=si;
		fprintf(logFile,"At line no: %d type_specifier: FLOAT\n\n%s\n\n",yylineno,"float");
	}
 		| VOID{
		SymbollInfo *si = new SymbollInfo("void","VOID");
		$$=si;
		fprintf(logFile,"At line no: %d type_specifier: VOID\n\n%s\n\n",yylineno,"void");
	}
 		;
 		
declaration_list: declaration_list COMMA ID	{
				
				string str=$1->getName()+","+$3->getName();
				SymbollInfo *si = new SymbollInfo(str);
				$$=si;
				fprintf(logFile,"At line no: %d declaration_list: declaration_list COMMA ID\n\n%s\n\n",yylineno,str.c_str());
								
			}
			| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD	{
				
				string str=$1->getName()+","+$3->getName()+'['+$5->getName()+']';
				SymbollInfo *si = new SymbollInfo(str);
				$$=si;
				fprintf(logFile,"At line no: %d declaration_list: declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n%s\n\n",yylineno,str.c_str());
					
			}
 	    	| ID	{
			  
			   fprintf(logFile,"At line no: %d declaration_list: ID\n\n%s\n\n",yylineno,$1->getName().c_str());
			   $$=$1;
			   
			   }
 		   | ID LTHIRD CONST_INT RTHIRD	{
				
				string str=$1->getName()+"["+$3->getName()+"]";
				SymbollInfo *si = new SymbollInfo(str,$1->getType());
				$$=si;
				fprintf(logFile,"At line no: %d declaration_list: ID LTHIRD CONST_INT RTHIRD\n\n%s\n\n",yylineno,str.c_str());
				
			}
 		  ;
 		  
statements: statement	{
		string str=$1->getName()+"\n";
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d statements: statement\n\n%s\n\n",yylineno,str.c_str());

		//assembly;
		$$->code = $1->code;
	}
	   | statements statement	{
		   string str=$1->getName()+$2->getName()+"\n";
		   SymbollInfo *si = new SymbollInfo(str);
		   $$=si;
		   fprintf(logFile,"At line no: %d statements: statements statement\n\n%s\n\n",yylineno,str.c_str());

			//assembly;
			$$->code = $1->code + $2->code;
	}
	   ;
	   
statement: var_declaration	{
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d statement: var_declaration\n\n%s\n\n",yylineno,str.c_str());
	}
	  | expression_statement	{
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d statement: expression-statement \n\n%s\n\n",yylineno,str.c_str());

		//assembly;
		$$->code = $1->code;
	}
	  | compound_statement	{
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d statement: compound_statement \n\n%s\n\n",yylineno,str.c_str());
	
		//assembly
		$$->code = $1->code;
	}
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement	{
		string str= "for("+$3->getName()+$4->getName()+$5->getName()+")"+$6->getName();
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d statement: FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n%s\n\n",yylineno,str.c_str());
	
		//assembly
		/*
			$3's code at first, which is already done by assigning $$=$3
			create two labels and append one of them in $$->code
			compare $4's symbol with 0
			if equal jump to 2nd label
			append $7's code
			append $5's code
			append the second label in the code
		*/
		$$->code+=$3->code;
		char *label1=newLabel();
		char *label2 = newLabel();
		$$->code += string (label1)+":\n";
		$$->code+=$4->code;
		string var = $4->getName();
		if(var[0] != 't' && table.getScopeId(var)!=0){
			string var_name_assembly=assemblyVarName(var, table.getScopeId($4->getName()));
			$$->code+="mov ax, "+var_name_assembly+"\n";
		}
		else{
			$$->code+="mov ax, "+var+"\n";
		}
		
		$$->code+="cmp ax, 0\n";
		$$->code+="je "+string(label2)+"\n";
		$$->code += $7->code;
		$$->code += $5->code;
		$$->code+="jmp "+string(label1)+"\n";	//included by my opinion	
		$$->code += string(label2)+":\n";

		
	}
	  | IF LPAREN expression RPAREN statement %prec IFX	 {
		string str="if("+$3->getName()+")"+$5->getName();
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d statement: IF LPAREN expression RPAREN statement\n\n%s\n\n",yylineno,str.c_str());
	
		//assembly
		$$->code = $3->code;
		char *label=newLabel();
		string var = $3->getName();
		if(var[0] != 't' && table.getScopeId(var)!=0){
			string var_name_assembly=assemblyVarName(var, table.getScopeId($4->getName()));
			$$->code+="mov ax, "+var_name_assembly+"\n";
		}
		else{
			$$->code+="mov ax, "+var+"\n";
		}
		$$->code+="cmp ax, 0\n";
		$$->code+="je "+string(label)+"\n"; //modified to jne.
		$$->code+=$5->code;
		$$->code+=string(label)+":\n";
		
		$$->setName("if");//not necessary
	}
	  | IF LPAREN expression RPAREN statement ELSE statement	{
		string str=$3->getName();
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d statement: IF LPAREN expression RPAREN statement ELSE statement\n\n%s\n\n",yylineno,str.c_str());
	
		//assembly
		$$->code = $3->code;
		//similar to if part
		char *label1=newLabel();
		char *label2=newLabel();
		
		string var = $3->getName();
		if(var[0] != 't' && table.getScopeId(var)!=0){
			string var_name_assembly=assemblyVarName(var, table.getScopeId($4->getName()));
			$$->code+="mov ax, "+var_name_assembly+"\n";
		}
		else{
			$$->code+="mov ax, "+var+"\n";
		}
		$$->code+="cmp ax, 0\n";
		$$->code+="je "+string(label1)+"\n";
		$$->code+=$5->code;
		$$->code+="jmp "+string(label2)+"\n";
		$$->code+=string(label1)+":\n";
		$$->code+=$7->code;
		$$->code+=string(label2)+":\n";
		
	}
	  | WHILE LPAREN expression RPAREN statement	{
		string str=$3->getName();
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d statement: WHILE LPAREN expression RPAREN statement\n\n%s\n\n",yylineno,str.c_str());
	
		//assembly
		// should be easy given you understood or implemented for loops part
		char *label1=newLabel();
		char *label2 = newLabel();
		$$->code += string (label1)+":\n";
		$$->code += $3->code;
		string var = $3->getName();
		if(var[0] != 't' && table.getScopeId(var)!=0){
			string var_name_assembly=assemblyVarName(var, table.getScopeId($4->getName()));
			$$->code+="mov ax, "+var_name_assembly+"\n";
		}
		else{
			$$->code+="mov ax, "+var+"\n";
		}
		

		$$->code+="cmp ax, 0\n";
		$$->code+="je "+string(label2)+"\n";
		$$->code += $5->code;
		$$->code+="jmp "+string(label1)+"\n";	//included by my opinion	
		$$->code += string(label2)+":\n";		
	}
	|	PRINTLN LPAREN ID RPAREN SEMICOLON {
			// write code for printing an ID. You may assume that ID is an integer variable.
			SymbollInfo *si = new SymbollInfo("println","nonterminal");
			$$=si;
			//assembly
			string var = $3->getName();
			if(var[0] != 't' && table.getScopeId(var)!=0){
				string var_name_assembly=assemblyVarName(var, table.getScopeId($4->getName()));
				$$->code+="mov ax, "+var_name_assembly+"\n";
			}
			else{
				$$->code+="mov ax, "+var+"\n";
			}
			$$->code += "call PRINT_ID\n";
		}
	  | RETURN expression SEMICOLON	{
		string str="return "+$2->getName()+";";
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d statement: RETURN expression SEMICOLON\n\n%s\n\n",yylineno,str.c_str());
		std::size_t pos1 = $2->getType().find("_");cout<<"pos: "<<pos1<<endl;     
		if($2->id_type=="VAR"){
			if(pos1!=std::string::npos){
				std::string s1 = $2->getType().substr(pos1); 		
				std::string s3 = "_"+currecnt_func->func_ret_type;    	
				if(s1.compare(s3) != 0){
					error_count++;
					fprintf(errorFile,"Line No %d : Return Type Mismatch.\n\n",yylineno);
				}
			}
		}
		else{
			cout<<"I am in else."<<endl;
		}

		//assembly
		$$->code = $1->code;
		// write code for return.
		
	}
	  ;
	  
expression_statement: SEMICOLON	{
		string str=";";
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d expression_statement: SEMICOLON\n\n;\n\n",yylineno);
		
		//assembly
		$$->code = "";
		
	}			
		| expression SEMICOLON {
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d expression_statement: expression SEMICOLON\n\n%s\n\n",yylineno,str.c_str());
	
		//assembly;
		$$->code += $1->code;
		
	}
			;
	  
variable: ID	{
		string str=$1->getName();//cout<<"here: "<<$1->getName()<<endl;
		fprintf(logFile,"At line no: %d variable: ID\n\n%s\n\n",yylineno,str.c_str());

		SymbollInfo *temp = table.LookUp($1->getName());
		//error
		if(temp==0){
			//cout<<"Undeclared Variable."<<endl;
			error_count++;
			fprintf(errorFile,"Line No %d : Undeclared Variable: %s.\n\n",yylineno,$1->getName().c_str());
			SymbollInfo *si = new SymbollInfo(str,"UNDECLARED");
			$$=si;
		}
		else{
			if(temp->id_type == "ARR"){
				temp->id_type = "MALFORMED_ARR";
			}
			SymbollInfo *si = new SymbollInfo(str,temp->getType());
			si->id_type = temp->id_type;cout<<yylineno<<" :"<<temp->id_type<<endl;
			si->arr_size = temp->arr_size;
			$$=si;
		}

		//assembly
		$$->code="";
		
	} 		
	 | ID LTHIRD expression RTHIRD 	{
		string str=$1->getName();
		fprintf(logFile,"At line no: %d variable: ID LTHIRD expression RTHIRD \n\n%s\n\n",yylineno,str.c_str());
		
		SymbollInfo *temp = table.LookUp($1->getName());
		//error
		if(temp==0){
			//cout<<"Undeclared Variable."<<endl;
			error_count++;
			fprintf(errorFile,"Line No %d : Undeclared Variable: %s.\n\n",yylineno,$1->getName().c_str());
		}
		else{	
			//ERROR
			if(temp->id_type.compare("VAR") == 0){
				error_count++;
				fprintf(errorFile,"Linr No %d : %s is not an array.\n\n",yylineno,temp->getName().c_str());
			}
			else if($3->getType().compare("CONST_FLOAT")==0 || $3->getType().compare("ID_FLOAT")==0 || $3->getType().compare("ID_VOID")==0){
				error_count++;
				fprintf(errorFile, "Line No %d : Non-integer Array Index.\n\n ",yylineno);
			}
			SymbollInfo *si = new SymbollInfo(str,temp->getType());
			si->id_type = "ARR";
			$$=si;
			
		}
		
		//assembly
		$$->code+=$3->code;
		string var = $3->getName();
		if(var[0] != 't' && table.getScopeId(var)!=0){
			string var_name_assembly=assemblyVarName(var, table.getScopeId($3->getName()));
			$$->code+="mov bx, "+var_name_assembly+"\n";
		}
		else{
			$$->code+="mov bx, "+var+"\n";
		}
		$$->code+="add bx, bx\n";
		
	} 	
	 ;
	 
expression: logic_expression	{
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str,$1->getType());
		si->id_type=$1->id_type;
		$$=si;
		fprintf(logFile,"At line no: %d expression: logic_expression\n\n%s\n\n",yylineno,str.c_str());

		//assembly;
		$$->code += $1->code;
		
	}	
	   | variable ASSIGNOP logic_expression 	{
		string str=$1->getName()+$2->getName()+$3->getName();

		SymbollInfo *si = new SymbollInfo(str,"CONST_INT");
		si->id_type="VAR";
		$$=si;
		fprintf(logFile,"At line no: %d expression: variable ASSIGNOP logic_expression\n\n%s\n\n",yylineno,str.c_str());
		if($1->getType() != "UNDECLARED" && $3->getType()!="UNDECLARED"){
			//error
			cout<<yylineno<<"sasas: "<<$1->id_type<<"	"<<$3->id_type<<endl;

			
			if($1->id_type == "FUNC"){
				//error
				error_count++;
				fprintf(errorFile,"Line No %d : Type Mismatch.\n\n",yylineno);
			}
			else if($1->id_type == "MALFORMED_ARR" || $3->id_type == "MALFORMED_ARR"){
				//error
				error_count++;
				fprintf(errorFile,"Line No %d : Type Mismatch.\n\n",yylineno);
			}

			else{
				std::size_t pos1 = $1->getType().find("_");cout<<"pos: "<<pos1<<endl;     
				std::size_t pos2 = $3->getType().find("_");     cout<<"pos: "<<pos2<<endl;
				if(pos1!=std::string::npos && pos2!=std::string::npos){
					std::string s1 = $1->getType().substr(pos1); 		
					std::string s3 = $3->getType().substr(pos2);    
					
					if(s1.compare(s3) != 0){
						error_count++;
						fprintf(errorFile,"Line No %d : Type Mismatch.\n\n",yylineno);
					}
				}			
			}
		}

		//assembly
		$$->code=$3->code+$1->code;
		string var = $3->getName();
		if(var[0] != 't' && table.getScopeId(var)!=0){
			string var_name_assembly=assemblyVarName(var, table.getScopeId($3->getName()));
			$$->code+="mov ax, "+var_name_assembly+"\n";
		}
		else{
			$$->code+="mov ax, "+var+"\n";
		}
		
		if($1->id_type!="ARR"){ 
			string var = $1->getName();
			if(var[0] != 't' && table.getScopeId(var)!=0){
				string var_name_assembly=assemblyVarName(var, table.getScopeId($1->getName()));
				$$->code+="mov "+var_name_assembly+", ax\n";
			}
			else{
				$$->code+= "mov "+var+", ax\n";
			}
		}
		else{
			string var = $1->getName();
			if(var[0] != 't' && table.getScopeId(var)!=0){
				string var_name_assembly=assemblyVarName(var, table.getScopeId($1->getName()));
				$$->code+="mov "+var_name_assembly+"[bx], ax\n";
			}
			else{
				$$->code+= "mov "+var+"[bx], ax\n";
			}
		}
	}
		   ;
			
logic_expression: rel_expression{
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str,$1->getType());
		si->id_type=$1->id_type;
		$$=si;
		fprintf(logFile,"At line no: %d logic_expression: rel_expression\n\n%s\n\n",yylineno,str.c_str());

		//assembly;
		$$->code += $1->code;
		
	}		
		 | rel_expression LOGICOP rel_expression 	{
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str,"CONST_INT");
		si->id_type="VAR";
		$$=si;
		fprintf(logFile,"At line no: %d logic_expression: rel_expression LOGICOP rel_expression \n\n%s\n\n",yylineno,str.c_str());
	
		//assembly
		$$->code+=$3->code+$1->code;			
		if($2->getName()=="&&"){
			/* 
			Check whether both operands value is 1. If both are one set value of a temporary variable to 1
			otherwise 0
			*/
			char *label1=newLabel();
			char *label2=newLabel();
			char *temp=newTemp();
			variables.push_back(string(temp)+" DW ?");
			$$->code+="cmp "+$1->getName()+", 0\n";
			$$->code+="je "+string(label1)+"\n";
			$$->code+="cmp "+$3->getName()+", 0\n";
			$$->code+="je "+string(label1)+"\n";
			$$->code+="mov "+string(temp)+", 1\n";
			$$->code+="jmp "+string(label2)+"\n";
			$$->code+=string(label1)+":";
			$$->code+="mov "+string(temp)+", 0\n";
			$$->code+=string(label2)+":";
			$$->setName(string(temp));
			
		}
		else if($2->getName()=="||"){
			char *label1=newLabel();
			char *label2=newLabel();
			char *temp=newTemp();
			variables.push_back(string(temp)+" DW ?");
			$$->code+="cmp "+$1->getName()+", 1\n";
			$$->code+="je "+string(label1)+"\n";
			$$->code+="cmp "+$3->getName()+", 1\n";
			$$->code+="je "+string(label1)+"\n";
			$$->code+="jmp "+string(label2)+"\n";
			$$->code+=string(label1)+":";
			$$->code+="mov "+string(temp)+", 1\n";
			$$->code+=string(label2)+":";
			$$->setName(string(temp));
		}
	}
		 ;
			
rel_expression: simple_expression	{
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str,$1->getType());
		si->id_type=$1->id_type;
		$$=si;
		fprintf(logFile,"At line no: %d rel_expression: simple_expression\n\n%s\n\n",yylineno,str.c_str());
	
		//assembly;
		$$->code += $1->code;

		
	}	
		| simple_expression RELOP simple_expression		{
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str,"CONST_INT");//bool and int are same 
		si->id_type="VAR";
		$$=si;
		fprintf(logFile,"At line no: %d rel_expression: simple_expression RELOP simple_expression	\n\n%s\n\n",yylineno,str.c_str());
	cout<<"here>>>>>>>>>>>>>>>>>>>>"<<endl;
		//assembly
		$$->code+=$3->code;
		string var = $1->getName();
		if(var[0] != 't' && table.getScopeId(var)!=0){
			string var_name_assembly=assemblyVarName(var, table.getScopeId($1->getName()));
			$$->code+="mov ax, "+var_name_assembly+"\n";
		}
		else{
			$$->code+="mov ax, "+var+"\n";
		}
		$$->code+="cmp ax, " + $3->getName()+"\n";
		char *temp=newTemp();
		//string var_name_assembly = assemblyVarName(string(temp), table.currentScopeTable->scopeId);
		variables.push_back(string(temp)+" DW ?");
		
		char *label1=newLabel();
		char *label2=newLabel();
		if($2->getName()=="<"){
			$$->code+="jl " + string(label1)+"\n";
		}
		else if($2->getName()=="<="){
			$$->code+="jle " + string(label1)+"\n";
		}
		else if($2->getName()==">"){
			$$->code+="jg " + string(label1)+"\n";
		}
		else if($2->getName()==">="){
			$$->code+="jge " + string(label1)+"\n";
		}
		else if($2->getName()=="=="){
			$$->code+="je " + string(label1)+"\n";
		}
		else{
		}
		
		$$->code+="mov "+string(temp) +", 0\n";
		$$->code+="jmp "+string(label2) +"\n";
		$$->code+=string(label1)+":\nmov "+string(temp)+", 1\n";
		$$->code+=string(label2)+":\n";
		$$->setName(temp);


		
		
	}	;
				
simple_expression: term	{
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str,$1->getType());
		si->id_type=$1->id_type;
		$$=si;
		fprintf(logFile,"At line no: %d simple_expression: term\n\n%s\n\n",yylineno,str.c_str());
	
		//assembly;
		$$->code = $1->code;
	}	
		  | simple_expression ADDOP term {
		string str=$1->getName();
		string type;
		if($1->getType()=="ID_FLOAT" || $1->getType()=="CONST_FLOAT" || $3->getType()=="ID_FLOAT" || $3->getType()=="CONST_FLOAT"){
			type="CONST_FLOAT";
		}
		else{
			type="CONST_INT";
		}
		SymbollInfo *si = new SymbollInfo(str,type);
		si->id_type="VAR";
		$$=si;
		fprintf(logFile,"At line no: %d simple_expression: simple_expression ADDOP term\n\n%s\n\n",yylineno,str.c_str());
	
		//assembly
		$$->code+=$3->code;
		// move one of the operands to a register, 
		//perform addition or subtraction with the other operand 
		//and move the result in a temporary variable  
				
		string var1 = $1->getName();
		string var2 = $3->getName();
		string var_name_assembly1;
		string var_name_assembly2;			
		if(var1[0] != 't' && table.getScopeId(var1)!=0){
			var_name_assembly1=assemblyVarName(var1, table.getScopeId(var1));			
		}
		else{
			var_name_assembly1 = var1;
		}
		$$->code+="mov ax, "+var_name_assembly1+"\n";
		if(var2[0] != 't' && table.getScopeId(var2)!=0){
		 	var_name_assembly2=assemblyVarName(var2, table.getScopeId(var2));			
		}
		else{
			var_name_assembly2 = var2;
		}
		if($2->getName()=="+"){			
			$$->code+="add ax, "+var_name_assembly2+"\n";
			char *temp=newTemp();
			variables.push_back(string(temp)+" DW ?");
			$$->code+="mov "+string(temp) +", ax\n";
			$$->setName(temp);
		}
		else{
			$$->code+="sub ax, "+var_name_assembly2+"\n";
			char *temp=newTemp();
			variables.push_back(string(temp)+" DW ?");
			$$->code+="mov "+string(temp) +", ax\n";
			$$->setName(temp);
		}
		
		
	}
		  ;
					
term:	unary_expression	{
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str,$1->getType());
		si->id_type=$1->id_type;
		$$=si;
		fprintf(logFile,"At line no: %d term:	unary_expression\n\n%s\n\n",yylineno,str.c_str());
	
		//assembly;
		$$->code = $1->code;
	}	
     |  term MULOP unary_expression	{
		string str=$1->getName()+$2->getName()+$3->getName();
		string type;
		
		if($2->getName().compare("*")==0 || $2->getName().compare("/")==0){
			if($1->getType()=="ID_FLOAT" || $1->getType()=="CONST_FLOAT" || $3->getType()=="ID_FLOAT" || $3->getType()=="CONST_FLOAT"){
				type="CONST_FLOAT";
			}
			else{
				type="CONST_INT";
			}
		}
		
		//error
		if($2->getName().compare("%")==0){
			cout<<"here_2 :"<<yylineno<<$1->getType().c_str()<<endl;
			cout<<"here_2 "<<yylineno<<$3->getType().c_str()<<endl;
			std::size_t pos = $1->getType().find("_");     
			std::string s1 = $1->getType().substr(pos); 
			pos = $3->getType().find("_");     
			std::string s3 = $3->getType().substr(pos);    
			if(s1.compare("_FLOAT")==0 ||  s3.compare("_FLOAT")==0){
				error_count++;
				fprintf(errorFile,"Line No: %d : Integer operand on modulus operator.\n\n",yylineno);

			}
			else{
				type="CONST_INT";
			}
		}
		SymbollInfo *si = new SymbollInfo(str,type);
		si->id_type="VAR";
		$$=si;
		fprintf(logFile,"At line no: %d term: term MULOP unary_expression \n\n%s\n\n",yylineno,str.c_str());


		//assembly
		$$->code += $3->code;
		string var = $1->getName();
		if(var[0] != 't' && table.getScopeId(var)!=0){
			string var_name_assembly=assemblyVarName(var, table.getScopeId($1->getName()));
			$$->code+="mov ax, "+var_name_assembly+"\n";
		}
		else{
			$$->code+="mov ax, "+var+"\n";
		}
		// $$->code += "mov bx, "+ $3->getName() +"\n";
	    var = $3->getName();
		if(var[0] != 't' && table.getScopeId(var)!=0){
			string var_name_assembly=assemblyVarName(var, table.getScopeId($3->getName()));
			$$->code+="mov bx, "+var_name_assembly+"\n";
		}
		else{
			$$->code+="mov bx, "+var+"\n";
		}
		
		char *temp=newTemp();
		//string var_name_assembly = assemblyVarName(string(temp), table.currentScopeTable->scopeId);
		variables.push_back(string(temp)+" DW ?");
		if($2->getName()=="*"){
			$$->code += "mul bx\n";
			$$->code += "mov "+ string(temp) + ", ax\n";
		}
		else if($2->getName()=="/"){
			// clear dx, perform 'div bx' and mov ax to temp
			$$->code += "xor dx, dx\n";
			$$->code += "div bx\n";
			$$->code += "mov "+ string(temp) + ", ax\n";
		}
		else if($2->getName()=="%"){
			// clear dx, perform 'div bx' and mov dx to temp
			$$->code += "xor dx, dx\n";
			$$->code += "div bx\n";
			$$->code += "mov "+ string(temp) + ", dx\n";
		}
		$$->setName(temp);
	}
     ; 

unary_expression: ADDOP unary_expression	{
		string str=$2->getName();
		SymbollInfo *si = new SymbollInfo(str,$2->getType());
		si->id_type="VAR";
		$$=si;
		fprintf(logFile,"At line no: %d unary_expression: ADDOP unary_expression\n\n%s\n\n",yylineno,str.c_str());
	
		//assembly
		$$->code += $2->code;
		
		if($1->getName() == "-"){
			string var = $2->getName();
			if(var[0] != 't' && table.getScopeId(var)!=0){
				string var_name_assembly=assemblyVarName(var, table.getScopeId($2->getName()));
				$$->code+="mov ax, "+var_name_assembly+"\n";
				$$->code += "neg ax\n";
				$$->code += "mov "+var_name_assembly+", ax\n";
			}
			else{
				$$->code+="mov ax, "+var+"\n";
				$$->code += "neg ax\n";
				$$->code += "mov "+var+", ax\n";
			}
		}

	}  
		 | NOT unary_expression {
		string str=$2->getName();
		SymbollInfo *si = new SymbollInfo(str,$2->getType());
		si->id_type="VAR";
		$$=si;
		fprintf(logFile,"At line no: %d unary_expression: NOT unary_expression\n\n%s\n\n",yylineno,str.c_str());
	
		//assembly
		char *temp=newTemp();
		//string var_name_assembly = assemblyVarName(string(temp), table.currentScopeTable->scopeId);
		variables.push_back(string(temp)+" DW ?");
		string var = $2->getName();
		if(var[0] != 't' && table.getScopeId(var)!=0){
			string var_name_assembly=assemblyVarName(var, table.getScopeId($2->getName()));
			$$->code+="mov ax, "+var_name_assembly+"\n";
		}
		else{
			$$->code+="mov ax, "+var+"\n";
		}
		$$->code+="not ax\n";
		$$->code+="mov "+string(temp)+", ax";
	}
		 | factor {
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str,$1->getType());
		si->id_type=$1->id_type;
		$$=si;
		fprintf(logFile,"At line no: %d unary_expression: factor\n\n%s\n\n",yylineno,str.c_str());
	
		//assembly;
		$$->code = $1->code;
	}
		 ;
	
factor: variable	{
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str,$1->getType());
		si->id_type=$1->id_type;
		$$=si;
		fprintf(logFile,"At line no: %d factor: variable\n\n%s\n\n",yylineno,str.c_str());
	
		//assembly;
		$$->code += $1->code;
		if($$->id_type !="ARR"){
			//do nothing ,cause no temp variable is needed.
		}
		
		else{
			char *temp= newTemp();
			//string var_name_assembly = assemblyVarName(string(temp), table.currentScopeTable->scopeId);
			variables.push_back(string(temp)+" DW ?");
			string var = $1->getName();
			if(var[0] != 't' && table.getScopeId(var)!=0){
				string var_name_assembly=assemblyVarName(var, table.getScopeId($1->getName()));
				$$->code+="mov ax, "+var_name_assembly+"[bx]\n";
			}
			else{
				$$->code+="mov ax, "+var+"[bx]\n";
			}
			$$->code+= "mov " + string(temp) + ", ax\n";cout<<"here: "<<$$->code<<endl;
			$$->setName(temp);
		}

	} 
	| ID LPAREN argument_list RPAREN	{
		string str=$1->getName()+"("+$3->getName()+")";
		fprintf(logFile,"At line no: %d factor: ID LPAREN argument_list RPAREN\n\n%s\n\n",yylineno,str.c_str());
		
		cout<<yylineno<<": factor rule2: "<<$1->getName()<<endl;
		SymbollInfo *temp = table.LookUp($1->getName());
		//error
		if(temp==0){
			//cout<<"Undeclared Variable."<<endl;
			error_count++;
			fprintf(errorFile,"Line No %d : Undeclared Function: %s.\n\n",yylineno,$1->getName().c_str());
			SymbollInfo *si = new SymbollInfo(str,"UNDECLARED");
			$$=si;
		}
		else{
			//error
			if( ! temp->isDefinedFunction ){
				error_count++;
				fprintf(errorFile,"Line No %d : Function Not defined yet.\n\n",yylineno);

				SymbollInfo *si = new SymbollInfo(str,"UNDECLARED");
				si->id_type="AR";//cout<<yylineno<<": factor rule: "<<si->id_type<<endl;
				$$=si;
			}
			else{
				SymbollInfo *si = new SymbollInfo(str,temp->getType());
				si->id_type="VAR";//cout<<yylineno<<": factor rule: "<<si->id_type<<endl;
				$$=si;
				vector<SymbollInfo * > func_param=temp->func_param;
				cout<<yylineno<<": "<<func_param.size()<<"	"<<func_args.size()<<endl;
				if(func_param.size() != func_args.size()){
					error_count++;
					fprintf(errorFile,"Line No %d : Too few or more args: %s.\n\n",yylineno,$1->getName().c_str());	
							
				}
				else{
					while(!func_args.empty()){
						string id_type = func_args.back()->id_type;
						cout<<yylineno<<": func_args: "<<id_type<<endl;					
						if(id_type == "ARR"){
							error_count++;
							fprintf(errorFile,"Line No %d : Type Mismatch.\n\n",yylineno);						
						}
						else{
							string type_args = func_args.back()->getType();
							string type_param = func_param.back()->getType();
							
							std::size_t pos1 = type_args.find("_");//cout<<"pos: "<<pos1<<endl;     
							std::size_t pos2 = type_param.find("_");    // cout<<"pos: "<<pos2<<endl;
							
							if(pos1!=std::string::npos && pos2!=std::string::npos){
								type_args = type_args.substr(pos1); 		
								type_param = type_param.substr(pos2);    
							cout<<yylineno<<": factor rule: "<<type_args<<" "<<type_param<<endl;
								if(type_args.compare(type_param) != 0){
									error_count++;
									fprintf(errorFile,"Line No %d : Type Mismatch.\n\n",yylineno);
								}
							}						
						}
						func_args.pop_back();
						func_param.pop_back();
					}
				}
			}
			
		}
		func_args.clear();

		//assembly
		$$->code += "call "+$1->getName()+"\n";
	}
	| LPAREN expression RPAREN	{
		string str="("+$2->getName()+")";
		SymbollInfo *si = new SymbollInfo(str,$2->getType());
		si->id_type=$2->id_type;
		$$=si;
		fprintf(logFile,"At line no: %d factor: LPAREN expression RPAREN\n\n%s\n\n",yylineno,str.c_str());
		//assembly
		$$->code+=$2->code;
	}
	| CONST_INT {
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str,$1->getType());
		si->id_type="VAR";
		$$=si;
		fprintf(logFile,"At line no: %d factor: CONST_INT\n\n%s\n\n",yylineno,str.c_str());
	}
	| CONST_FLOAT	{
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str,$1->getType());
		si->id_type="VAR";
		$$=si;
		fprintf(logFile,"At line no: %d factor: CONST_FLOAT\n\n%s\n\n",yylineno,str.c_str());
	}
	| variable INCOP {
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str,$1->getType());
		si->id_type="VAR";
		$$=si;
		fprintf(logFile,"At line no: %d FACTOR: variable INCOP\n\n%s\n\n",yylineno,str.c_str());
		if($1->id_type == "ARR"){
			fprintf(errorFile,"Line No %d : increment on arr is not valid.\n\n",yylineno);
		}

		//assembly
		string var = $1->getName();
		if(var[0] != 't' && table.getScopeId(var)!=0){
			string var_name_assembly=assemblyVarName(var, table.getScopeId($1->getName()));
			$$->code+="inc "+var_name_assembly+"\n";
		}
		else{
			$$->code+="inc "+var+"\n";
		}
		

		
	}
	| variable DECOP {
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str,$1->getType());
		si->id_type="VAR";
		$$=si;
		fprintf(logFile,"At line no: %d FACTOR: variable DECOP\n\n%s\n\n",yylineno,str.c_str());
		if($1->id_type == "ARR"){
			fprintf(errorFile,"Line No %d : increment on arr is not valid.\n\n",yylineno);
		}

		//assembly
		string var = $1->getName();
		if(var[0] != 't' && table.getScopeId(var)!=0){
			string var_name_assembly=assemblyVarName(var, table.getScopeId($1->getName()));
			$$->code+="dec "+var_name_assembly+"\n";
		}
		else{
			$$->code+="dec "+var+"\n";
		}
		

		
	}
	;
	
argument_list: arguments	{
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str);
		$$=si;
		fprintf(logFile,"At line no: %d argument_list: arguments\n\n%s\n\n",yylineno,str.c_str());
	}
			  | {
				  SymbollInfo *temp = new SymbollInfo("","");
				  $$=temp;
			  }
			  ;
	
arguments: arguments COMMA logic_expression	{
		string str=$1->getName()+","+$3->getName();
		SymbollInfo *si = new SymbollInfo(str);cout<<yylineno<<": arguments rule1: "<<si->getName()<<endl;
		$$=si;
		fprintf(logFile,"At line no: %d arguments: arguments COMMA logic_expression\n\n%s\n\n",yylineno,str.c_str());

		SymbollInfo *sym_info=new SymbollInfo($3->getName(), $3->getType());
		sym_info->id_type=$3->id_type;
		func_args.push_back(sym_info);
	}
	      | logic_expression	{
		string str=$1->getName();
		SymbollInfo *si = new SymbollInfo(str);cout<<yylineno<<": arguments rule2: "<<si->getName()<<endl;
		$$=si;
		 fprintf(logFile,"At line no: %d arguments: logic_expression\n\n%s\n\n",yylineno,str.c_str());
	
		SymbollInfo *sym_info=new SymbollInfo($1->getName(), $1->getType());
		sym_info->id_type=$1->id_type;
		func_args.push_back(sym_info);		
	}
	      ;
 

%%

int main(int argc,char *argv[])
{

	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	
	logFile= fopen(argv[2],"w");
	errorFile= fopen(argv[3],"w");
	assembly= fopen(argv[4],"w");
	
	
	//entering 1st and outermost scope.
	table.EnterScope();

	yyin=fp;
	yyparse();
	table.PrintAllScopeTable();
	fprintf(errorFile, "Total Errors: %d\n\n",error_count);
	fprintf(logFile, "Total line: %d\n\n",yylineno-1);
	fprintf(logFile, "Total Errors: %d\n\n",error_count);

	fclose(logFile);
	fclose(errorFile);

	return 0;
}
