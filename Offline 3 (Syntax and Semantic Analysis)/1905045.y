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

program : program unit {
            $$ = new SymbolInfo("program : program unit", "");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($2->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
        }
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
     | func_declaration {
            $$ = new SymbolInfo("unit : func_declaration", "");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
     | func_definition {
            $$ = new SymbolInfo("unit : func_definition", "");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		| type_specifier ID LPAREN RPAREN SEMICOLON {
                $$ = new SymbolInfo("func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON", "");
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($5->getEndLine());
                $$->addTreeChild($1);
                $$->addTreeChild($2);
                $$->addTreeChild($3);
                $$->addTreeChild($4);
                $$->addTreeChild($5);

                $2->setFunction(true);
                $2->setFuncReturnType($1->getType());
                int table_no, idx, pos;
                bool ret = st.insert($2, idx, pos, table_no);
                if (!ret) {
                    // found 
                    fprintf(logout, "\t%s already exists in the current ScopeTable\n", $2->getName().c_str());
                }
            }
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
		| type_specifier ID LPAREN RPAREN compound_statement {
                $$ = new SymbolInfo("func_definition : type_specifier ID LPAREN RPAREN compound_statement", "");
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($5->getEndLine());
                $$->addTreeChild($1);
                $$->addTreeChild($2);
                $$->addTreeChild($3);
                $$->addTreeChild($4);
                $$->addTreeChild($5);

                $2->setFunction(true);
                $2->setFuncReturnType($1->getType());
                int table_no, idx, pos;
                bool ret = st.insert($2, idx, pos, table_no);
                if (!ret) {
                    // found 
                    fprintf(logout, "\t%s already exists in the current ScopeTable\n", $2->getName().c_str());
                }
        }
 		;				


parameter_list  : parameter_list COMMA type_specifier ID
		| parameter_list COMMA type_specifier
 		| type_specifier ID
		| type_specifier
 		;

 		
compound_statement : LCURL statements RCURL {
                $$ = new SymbolInfo("compound_statement : LCURL statements RCURL", "");
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($3->getEndLine());
                $$->addTreeChild($1);
                $$->addTreeChild($2);
                $$->addTreeChild($3);
            }
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
 		| FLOAT {
            $$ = new SymbolInfo("type_specifier : FLOAT", "FLOAT");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
 		| VOID {
            $$ = new SymbolInfo("type_specifier : VOID", "VOID");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
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
 		  
statements : statement {
            $$ = new SymbolInfo("statements : statement", "");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
	   | statements statement {
            $$ = new SymbolInfo("statements : statements statement", "");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($2->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
       }
	   ;
	   
statement : var_declaration {
            $$ = new SymbolInfo("statement : var_declaration", "");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
	  | expression_statement {
            $$ = new SymbolInfo("statement : expression_statement", "");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
	  | compound_statement
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  | IF LPAREN expression RPAREN statement
	  | IF LPAREN expression RPAREN statement ELSE statement
	  | WHILE LPAREN expression RPAREN statement
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  | RETURN expression SEMICOLON {
            $$ = new SymbolInfo("statement : RETURN expression SEMICOLON", "");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($3->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
        }
	  ;
	  
expression_statement 	: SEMICOLON			
			| expression SEMICOLON {
                $$ = new SymbolInfo("expression_statement : expression SEMICOLON", "");
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($2->getEndLine());
                $$->addTreeChild($1);
                $$->addTreeChild($2);
            }
			;
	  
variable : ID {
        $$ = new SymbolInfo("variable : ID", "");
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($1->getEndLine());
        $$->addTreeChild($1);
    }	
	 | ID LSQUARE expression RSQUARE {
        $$ = new SymbolInfo("variable : ID LSQUARE expression RSQUARE", "");
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($4->getEndLine());
        $$->addTreeChild($1);
        $$->addTreeChild($2);
        $$->addTreeChild($3);
        $$->addTreeChild($4);
     }
	 ;
	 
expression : logic_expression	{
            $$ = new SymbolInfo("expression : logic_expression", "");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
	   | variable ASSIGNOP logic_expression {
            $$ = new SymbolInfo("expression : variable ASSIGNOP logic_expression", "");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($3->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
        }	
	   ;
			
logic_expression : rel_expression {
            $$ = new SymbolInfo("logic_expression : rel_expression", "");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }	
		 | rel_expression LOGICOP rel_expression {
            $$ = new SymbolInfo("logic_expression : rel_expression LOGICOP rel_expression", "");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($3->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
         }	
		 ;
			
rel_expression	: simple_expression {
            $$ = new SymbolInfo("rel_expression	: simple_expression", "");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
		| simple_expression RELOP simple_expression	{
            $$ = new SymbolInfo("rel_expression	: simple_expression RELOP simple_expression", "");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($3->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
        }
		;
				
simple_expression : term {
            $$ = new SymbolInfo("simple_expression : term", "");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
		  | simple_expression ADDOP term {
            $$ = new SymbolInfo("simple_expression : simple_expression ADDOP term", "");
            $$->setRule(true);
            $$->setStartLine($3->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
          }
		  ;
					
term :	unary_expression {
            $$ = new SymbolInfo("term :	unary_expression", "");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
     |  term MULOP unary_expression {
            $$ = new SymbolInfo("term :	term MULOP unary_expression", "");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($3->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
        }
     ;

unary_expression : ADDOP unary_expression  
		 | NOT unary_expression 
		 | factor {
            $$ = new SymbolInfo("unary_expression : factor", "");
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
         }
		 ;
	
factor	: variable 
	| ID LPAREN argument_list RPAREN
	| LPAREN expression RPAREN {
        $$ = new SymbolInfo("factor	: LPAREN expression RPAREN", "");
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($3->getEndLine());
        $$->addTreeChild($1);
        $$->addTreeChild($2);
        $$->addTreeChild($3);
    }
	| CONST_INT {
        $$ = new SymbolInfo("factor	: CONST_INT", "");
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($1->getEndLine());
        $$->addTreeChild($1);
    }
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

