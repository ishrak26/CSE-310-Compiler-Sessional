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
vector<SymbolInfo*> currentParams;
bool scopeStarted = false;

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
        $$ = new SymbolInfo("start : program ", "");
        fprintf(logout, "%s\n", $$->getName().c_str());
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($1->getEndLine());
        $$->addTreeChild($1);
        $$->printTree(parseout, 0);
	}
	;

program : program unit {
            $$ = new SymbolInfo("program : program unit ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($2->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
        }
	| unit {
        $$ = new SymbolInfo("program : unit ", "");
        fprintf(logout, "%s\n", $$->getName().c_str());
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($1->getEndLine());
        $$->addTreeChild($1);
    }
	;
	
unit : var_declaration {
            $$ = new SymbolInfo("unit : var_declaration ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
     | func_declaration {
            $$ = new SymbolInfo("unit : func_declaration ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
     | func_definition {
            $$ = new SymbolInfo("unit : func_definition ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON {
                $$ = new SymbolInfo("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON ", "");
                fprintf(logout, "%s\n", $$->getName().c_str());
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($6->getEndLine());
                $$->addTreeChild($1);
                $$->addTreeChild($2);
                $$->addTreeChild($3);
                $$->addTreeChild($4);
                $$->addTreeChild($5);
                $$->addTreeChild($6);

                $2->setFunction(true);
                $2->setFuncReturnType($1->getType());
                int table_no, idx, pos;
                bool ret = st.insert($2, idx, pos, table_no);
                if (!ret) {
                    // found 
                    fprintf(logout, "\t%s already exists in the current ScopeTable\n", $2->getName().c_str());
                }

                for (int i = 0; i < currentParams.size(); i++) {
                    $2->addFuncParam(currentParams[i]);
                }
                currentParams.clear();
            }
		| type_specifier ID LPAREN RPAREN SEMICOLON {
                $$ = new SymbolInfo("func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON ", "");
                fprintf(logout, "%s\n", $$->getName().c_str());
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
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement {
                $$ = new SymbolInfo("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement ", "");
                fprintf(logout, "%s\n", $$->getName().c_str());
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($6->getEndLine());
                $$->addTreeChild($1);
                $$->addTreeChild($2);
                $$->addTreeChild($3);
                $$->addTreeChild($4);
                $$->addTreeChild($5);
                $$->addTreeChild($6);

                $2->setFunction(true);
                $2->setFuncReturnType($1->getType());
                int table_no, idx, pos;
                bool ret = st.insert($2, idx, pos, table_no);
                // if (!ret) {
                //     // found 
                //     fprintf(logout, "\t%s already exists in the current ScopeTable\n", $2->getName().c_str());
                // }

                for (int i = 0;  i < currentParams.size(); i++) {
                    $2->addFuncParam(currentParams[i]);
                }
                currentParams.clear();
        }
		| type_specifier ID LPAREN RPAREN compound_statement {
                $$ = new SymbolInfo("func_definition : type_specifier ID LPAREN RPAREN compound_statement ", "");
                fprintf(logout, "%s\n", $$->getName().c_str());
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
                // if (!ret) {
                //     // found 
                //     fprintf(logout, "\t%s already exists in the current ScopeTable\n", $2->getName().c_str());
                // }
        }
 		;				


parameter_list  : parameter_list COMMA type_specifier ID {
            $$ = new SymbolInfo("parameter_list : parameter_list COMMA type_specifier ID ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($4->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
            $$->addTreeChild($4);
            
            $4->setDataType($3->getType());
            int table_no, idx, pos;
            bool ret = st.insert(new SymbolInfo($4), idx, pos, table_no);
            if (!ret) {
                // found 
                fprintf(logout, "\t%s already exists in the current ScopeTable\n", $4->getName().c_str());
            }
            currentParams.push_back($4);
        }
		| parameter_list COMMA type_specifier {
            $$ = new SymbolInfo("parameter_list : parameter_list COMMA type_specifier ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($3->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
            
            $3->setDataType($3->getType());
            int table_no, idx, pos;
            bool ret = st.insert(new SymbolInfo($3), idx, pos, table_no);
            if (!ret) {
                // found 
                fprintf(logout, "\t%s already exists in the current ScopeTable\n", $3->getName().c_str());
            }
            currentParams.push_back($3);
        }
 		| type_specifier ID {
            st.enter_scope();
            scopeStarted = true;
            $$ = new SymbolInfo("parameter_list : type_specifier ID ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($2->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            
            $2->setDataType($1->getType());

            int table_no, idx, pos;
            bool ret = st.insert(new SymbolInfo($2), idx, pos, table_no);
            if (!ret) {
                // found 
                fprintf(logout, "\t%s already exists in the current ScopeTable\n", $2->getName().c_str());
            }
            currentParams.push_back($2);
        }
		| type_specifier {
            st.enter_scope();
            scopeStarted = true;
            $$ = new SymbolInfo("parameter_list : type_specifier ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
            
            $1->setDataType($1->getType());
            
            int table_no, idx, pos;
            bool ret = st.insert(new SymbolInfo($1), idx, pos, table_no);
            if (!ret) {
                // found 
                fprintf(logout, "\t%s already exists in the current ScopeTable\n", $1->getName().c_str());
            }
            currentParams.push_back($1);
        }
 		;

 		
compound_statement : LCURL statements RCURL {
                $$ = new SymbolInfo("compound_statement : LCURL statements RCURL ", "");
                fprintf(logout, "%s\n", $$->getName().c_str());
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($3->getEndLine());
                $$->addTreeChild($1);
                $$->addTreeChild($2);
                $$->addTreeChild($3);
                st.print_all_scope_table(logout);
                st.exit_scope();
                scopeStarted = false;
            }
 		    | LCURL RCURL {
                $$ = new SymbolInfo("compound_statement : LCURL RCURL ", "");
                fprintf(logout, "%s\n", $$->getName().c_str());
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($2->getEndLine());
                $$->addTreeChild($1);
                $$->addTreeChild($2);
                st.print_all_scope_table(logout);
                st.exit_scope();
                scopeStarted = false;
            }
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON {
                $$ = new SymbolInfo("var_declaration : type_specifier declaration_list SEMICOLON ", "");
                fprintf(logout, "%s\n", $$->getName().c_str());
                int table_no, idx, pos;
                for (int i = 0; i < currentVars.size(); i++) {
                    currentVars[i]->setDataType($1->getType());
                    
                    bool ret = st.insert(new SymbolInfo(currentVars[i]), idx, pos, table_no);
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
                $$ = new SymbolInfo("type_specifier : INT ", "INT");
                fprintf(logout, "%s\n", $$->getName().c_str());
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($1->getEndLine());
                $$->addTreeChild($1);
            }
 		| FLOAT {
            $$ = new SymbolInfo("type_specifier : FLOAT ", "FLOAT");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
 		| VOID {
            $$ = new SymbolInfo("type_specifier : VOID ", "VOID");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
 		;
 		
declaration_list : declaration_list COMMA ID {
                $$ = new SymbolInfo("declaration_list : declaration_list COMMA ID ", "");
                fprintf(logout, "%s\n", $$->getName().c_str());
                currentVars.push_back($3);
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($3->getEndLine());
                $$->addTreeChild($1);
                $$->addTreeChild($2);
                $$->addTreeChild($3);
            }
 		  | declaration_list COMMA ID LSQUARE CONST_INT RSQUARE {
            $$ = new SymbolInfo("declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
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
            $$ = new SymbolInfo("declaration_list : ID ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            currentVars.push_back($1);
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
          }
 		  | ID LSQUARE CONST_INT RSQUARE {
            $$ = new SymbolInfo("declaration_list : ID LSQUARE CONST_INT RSQUARE ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
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
            $$ = new SymbolInfo("statements : statement ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
	   | statements statement {
            $$ = new SymbolInfo("statements : statements statement ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($2->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
       }
	   ;
	   
statement : var_declaration {
            $$ = new SymbolInfo("statement : var_declaration ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
	  | expression_statement {
            $$ = new SymbolInfo("statement : expression_statement ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
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
            $$ = new SymbolInfo("statement : RETURN expression SEMICOLON ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($3->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
        }
	  ;
	  
expression_statement 	: SEMICOLON	{
                $$ = new SymbolInfo("expression_statement : SEMICOLON ", "");
                fprintf(logout, "%s\n", $$->getName().c_str());
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($1->getEndLine());
                $$->addTreeChild($1);
            }	
			| expression SEMICOLON {
                $$ = new SymbolInfo("expression_statement : expression SEMICOLON ", "");
                fprintf(logout, "%s\n", $$->getName().c_str());
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($2->getEndLine());
                $$->addTreeChild($1);
                $$->addTreeChild($2);
            }
			;
	  
variable : ID {
        $$ = new SymbolInfo("variable : ID ", "");
        fprintf(logout, "%s\n", $$->getName().c_str());
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($1->getEndLine());
        $$->addTreeChild($1);
    }	
	 | ID LSQUARE expression RSQUARE {
        $$ = new SymbolInfo("variable : ID LSQUARE expression RSQUARE ", "");
        fprintf(logout, "%s\n", $$->getName().c_str());
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
            $$ = new SymbolInfo("expression : logic_expression ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
	   | variable ASSIGNOP logic_expression {
            $$ = new SymbolInfo("expression : variable ASSIGNOP logic_expression ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($3->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
        }	
	   ;
			
logic_expression : rel_expression {
            $$ = new SymbolInfo("logic_expression : rel_expression ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }	
		 | rel_expression LOGICOP rel_expression {
            $$ = new SymbolInfo("logic_expression : rel_expression LOGICOP rel_expression ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($3->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
         }	
		 ;
			
rel_expression	: simple_expression {
            $$ = new SymbolInfo("rel_expression : simple_expression ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
		| simple_expression RELOP simple_expression	{
            $$ = new SymbolInfo("rel_expression : simple_expression RELOP simple_expression ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($3->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
        }
		;
				
simple_expression : term {
            $$ = new SymbolInfo("simple_expression : term ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
		  | simple_expression ADDOP term {
            $$ = new SymbolInfo("simple_expression : simple_expression ADDOP term ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($3->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
          }
		  ;
					
term :	unary_expression {
            $$ = new SymbolInfo("term : unary_expression ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
     |  term MULOP unary_expression {
            $$ = new SymbolInfo("term : term MULOP unary_expression ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($3->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
        }
     ;

unary_expression : ADDOP unary_expression {
            $$ = new SymbolInfo("unary_expression : ADDOP unary_expression ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($2->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
        }
		 | NOT unary_expression {
            $$ = new SymbolInfo("unary_expression : NOT unary_expression ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($2->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
         }
		 | factor {
            $$ = new SymbolInfo("unary_expression : factor ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
         }
		 ;
	
factor	: variable {
        $$ = new SymbolInfo("factor : variable ", "");
        fprintf(logout, "%s\n", $$->getName().c_str());
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($1->getEndLine());
        $$->addTreeChild($1);
    }
	| ID LPAREN argument_list RPAREN {
        $$ = new SymbolInfo("factor : ID LPAREN argument_list RPAREN ", "");
        fprintf(logout, "%s\n", $$->getName().c_str());
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($4->getEndLine());
        $$->addTreeChild($1);
        $$->addTreeChild($2);
        $$->addTreeChild($3);
        $$->addTreeChild($4);
    }
	| LPAREN expression RPAREN {
        $$ = new SymbolInfo("factor : LPAREN expression RPAREN ", "");
        fprintf(logout, "%s\n", $$->getName().c_str());
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($3->getEndLine());
        $$->addTreeChild($1);
        $$->addTreeChild($2);
        $$->addTreeChild($3);
    }
	| CONST_INT {
        $$ = new SymbolInfo("factor : CONST_INT ", "");
        fprintf(logout, "%s\n", $$->getName().c_str());
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($1->getEndLine());
        $$->addTreeChild($1);
    }
	| CONST_FLOAT {
        $$ = new SymbolInfo("factor : CONST_FLOAT ", "");
        fprintf(logout, "%s\n", $$->getName().c_str());
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($1->getEndLine());
        $$->addTreeChild($1);
    }
	| variable INCOP {
        $$ = new SymbolInfo("factor : variable INCOP ", "");
        fprintf(logout, "%s\n", $$->getName().c_str());
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($2->getEndLine());
        $$->addTreeChild($1);
        $$->addTreeChild($2);
    }
	| variable DECOP {
        $$ = new SymbolInfo("factor : variable DECOP ", "");
        fprintf(logout, "%s\n", $$->getName().c_str());
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($2->getEndLine());
        $$->addTreeChild($1);
        $$->addTreeChild($2);
    }
	;
	
argument_list : arguments {
                $$ = new SymbolInfo("argument_list : arguments ", "");
                fprintf(logout, "%s\n", $$->getName().c_str());
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($1->getEndLine());
                $$->addTreeChild($1);
            }
			  | {
                $$ = new SymbolInfo("argument_list : arguments ", "");
                fprintf(logout, "%s\n", $$->getName().c_str());
                $$->setRule(true);
                $$->setStartLine(line_count);
                $$->setEndLine(line_count);
            }
			  ;
	
arguments : arguments COMMA logic_expression {
                $$ = new SymbolInfo("arguments : arguments COMMA logic_expression ", "");
                fprintf(logout, "%s\n", $$->getName().c_str());
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($3->getEndLine());
                $$->addTreeChild($1);
                $$->addTreeChild($2);
                $$->addTreeChild($3);
            }
	      | logic_expression {
                $$ = new SymbolInfo("arguments : logic_expression ", "");
                fprintf(logout, "%s\n", $$->getName().c_str());
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($1->getEndLine());
                $$->addTreeChild($1);
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

	parseout= fopen(argv[2],"w");
	fclose(parseout);
	logout= fopen(argv[3],"w");
	fclose(logout);
	
	parseout= fopen(argv[2],"a");
	logout= fopen(argv[3],"a");
	

	yyin=fp;
	yyparse();
	
    fprintf(logout, "Total Lines: %d\n", line_count);
    fprintf(logout, "Total Errors: %d\n", error_count);

	fclose(parseout);
	fclose(logout);
    fclose(fp);
	
	return 0;
}
