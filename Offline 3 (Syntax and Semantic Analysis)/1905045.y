%{
#include<cstdio>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<vector>
#include "1905045_symbol_table.cpp"

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;

FILE *fp;
FILE *logout;
FILE *parseout;

int line_count = 1;
int error_count = 0;

bool FuncInfo::matchParamType(int idx, string type) {
    assert(idx < params.size());
    return (params[idx]->getType() == type);
}

int SymbolTable::table_no = 0;
const int NUM_BUCKETS = 11;
SymbolTable st(NUM_BUCKETS);

vector<SymbolInfo*> currentVars;

void yyerror(char *s)
{
	//write your code
}


%}

%union {
    SymbolInfo* symInfo;
}

%token<symInfo> IF ELSE FOR WHILE INT FLOAT VOID RETURN CONST_INT CONST_FLOAT ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LSQUARE RSQUARE COMMA SEMICOLON ID PRINTLN

%type<symInfo> start program unit var_declaration func_declaration func_definition type_specifier parameter_list compound_statement statements declaration_list statement expression_statement expression logic_expression variable rel_expression simple_expression term unary_expression factor argument_list arguments 

/* %left 
%right

%nonassoc  */


%%

start : program
	{
		//write your code in this block in all the similar blocks below
        $$ = new SymbolInfo("start : program", "");
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($1->getEndLine());
        $$->addTreeChild($1);

        $$->printTree(parseout, 0);
        st.print_all_scope_table(logout);
	}
	;

program : program unit 
	| unit {
        $$ = new SymbolInfo("program : unit", "");
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($1->getEndLine());
        $$->addTreeChild($1);
    }
	;
	
unit : var_declaration {
            $$ = new SymbolInfo("unit : var_declaration", "");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
     | func_declaration
     | func_definition
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		| type_specifier ID LPAREN RPAREN SEMICOLON
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
		| type_specifier ID LPAREN RPAREN compound_statement
 		;				


parameter_list  : parameter_list COMMA type_specifier ID
		| parameter_list COMMA type_specifier
 		| type_specifier ID
		| type_specifier
 		;

 		
compound_statement : LCURL statements RCURL
 		    | LCURL RCURL
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON {
                $$ = new SymbolInfo("var_declaration : type_specifier declaration_list SEMICOLON", "");
                int table_no, idx, pos;
                for (int i = 0; i < currentVars.size(); i++) {
                    currentVars[i]->setDataType($1->getType());
                    
                    bool ret = st.insert(currentVars[i], idx, pos, table_no);
                    if (!ret) {
                        // found 
                        fprintf(logout, "\t%s already exists in the current ScopeTable\n", currentVars[i]->getName().c_str());
                    }
                    
                }
                currentVars.clear();
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($3->getEndLine());
                $$->addTreeChild($1);
                $$->addTreeChild($2);
                $$->addTreeChild($3);
            }
 		 ;
 		 
type_specifier	: INT {
                $$ = new SymbolInfo("type_specifier : INT", "INT");
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($1->getEndLine());
                $$->addTreeChild($1);
            }
 		| FLOAT
 		| VOID
 		;
 		
declaration_list : declaration_list COMMA ID {
                $$ = new SymbolInfo("declaration_list : declaration_list COMMA ID", "");
                currentVars.push_back($3);
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($3->getEndLine());
                $$->addTreeChild($1);
                $$->addTreeChild($2);
                $$->addTreeChild($3);
            }
 		  | declaration_list COMMA ID LSQUARE CONST_INT RSQUARE {
            $$ = new SymbolInfo("declaration_list COMMA ID LSQUARE CONST_INT RSQUARE", "");
            $3->setArray(true);
            $3->setArraySize(atoi($5->getName().c_str()));
            currentVars.push_back($3);
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($6->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
            $$->addTreeChild($4);
            $$->addTreeChild($5);
            $$->addTreeChild($6);
          }
 		  | ID {
            $$ = new SymbolInfo("declaration_list : ID", "");
            currentVars.push_back($1);
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
          }
 		  | ID LSQUARE CONST_INT RSQUARE {
            $$ = new SymbolInfo("declaration_list : ID LSQUARE CONST_INT RSQUARE", "");
            $1->setArray(true);
            $1->setArraySize(atoi($3->getName().c_str()));
            currentVars.push_back($1);
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($4->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
            $$->addTreeChild($4);
          }
 		  ;
 		  
statements : statement
	   | statements statement
	   ;
	   
statement : var_declaration
	  | expression_statement
	  | compound_statement
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  | IF LPAREN expression RPAREN statement
	  | IF LPAREN expression RPAREN statement ELSE statement
	  | WHILE LPAREN expression RPAREN statement
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  | RETURN expression SEMICOLON
	  ;
	  
expression_statement 	: SEMICOLON			
			| expression SEMICOLON 
			;
	  
variable : ID 		
	 | ID LSQUARE expression RSQUARE
	 ;
	 
 expression : logic_expression	
	   | variable ASSIGNOP logic_expression 	
	   ;
			
logic_expression : rel_expression 	
		 | rel_expression LOGICOP rel_expression 	
		 ;
			
rel_expression	: simple_expression 
		| simple_expression RELOP simple_expression	
		;
				
simple_expression : term 
		  | simple_expression ADDOP term 
		  ;
					
term :	unary_expression
     |  term MULOP unary_expression
     ;

unary_expression : ADDOP unary_expression  
		 | NOT unary_expression 
		 | factor 
		 ;
	
factor	: variable 
	| ID LPAREN argument_list RPAREN
	| LPAREN expression RPAREN
	| CONST_INT 
	| CONST_FLOAT
	| variable INCOP 
	| variable DECOP
	;
	
argument_list : arguments
			  |
			  ;
	
arguments : arguments COMMA logic_expression
	      | logic_expression
	      ;
 

%%
int main(int argc,char *argv[])
{
    
	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	parseout= fopen(argv[2],"w");
	fclose(parseout);
	logout= fopen(argv[3],"w");
	fclose(logout);
	
	parseout= fopen(argv[2],"a");
	logout= fopen(argv[3],"a");
	

	yyin=fp;
	yyparse();
	

	fclose(parseout);
	fclose(logout);
    fclose(fp);
	
	return 0;
}

