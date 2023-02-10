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
FILE *errorout;

int line_count = 1;
int error_count = 0;

bool FuncInfo::matchParamType(int idx, string type) {
    assert(idx < params.size());
    return (params[idx]->getDataType() == type);
}

bool FuncInfo::checkParam(string name) {
    for (int i = 0; i < paramSize(); i++) {
        if (name == params[i]->getName()) {
            return true;
        }
    }
    return false;
}

int SymbolTable::table_no = 0;
const int NUM_BUCKETS = 11;
SymbolTable st(NUM_BUCKETS);

vector<SymbolInfo*> currentVars;
vector<SymbolInfo*> currentParams;
vector<SymbolInfo*> currentArgs;
bool scopeStarted = false;
bool paramAdd = false;
bool paramOn = false;
bool currFuncReturn; // true if sth is returned i.e. non-void
int returnStartLine;

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
%right */

%nonassoc THEN
%nonassoc ELSE


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
        $$->destroyTree();
        delete $$;
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
                
                st.exit_scope();
                SymbolTable::table_no--;
                
                int table_no, idx, pos;
                bool ret = st.insert($2, idx, pos, table_no);
                if (!ret) {
                    // found 
                    fprintf(logout, "\t%s already exists in the current ScopeTable\n", $2->getName().c_str());
                }

                for (int i = 0; i < currentParams.size(); i++) {
                    if ($2->checkFuncParam(currentParams[i]->getName())) {
                        fprintf(errorout,"Line# %d: Redefinition of parameter \'%s\'\n",currentParams[i]->getStartLine(),currentParams[i]->getName().c_str());
                        error_count++;
                        break;
                    }
                    $2->addFuncParam(currentParams[i]);
                }
                currentParams.clear();
                paramOn = false;
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
                if (!ret) {
                    // found 
                    SymbolInfo *symInfo = st.look_up($2->getName(), idx, pos, table_no);
                    if (symInfo != nullptr) {
                        if (symInfo->getFunction()) {
                            if ($2->getFuncReturnType() != symInfo->getFuncReturnType() || int(currentParams.size()) != symInfo->getFuncParamCount()) {
                                fprintf(errorout,"Line# %d: Conflicting types for \'%s\'\n",$2->getStartLine(),$2->getName().c_str());
                                error_count++;
                            }
                        }
                        else {
                            fprintf(errorout,"Line# %d: \'%s\' redeclared as different kind of symbol\n",$2->getStartLine(),$2->getName().c_str());
                            error_count++;
                        }
                    }
                    // fprintf(logout, "\t%s already exists in the current ScopeTable\n", $2->getName().c_str());
                }

                for (int i = 0;  i < currentParams.size(); i++) {
                    if ($2->checkFuncParam(currentParams[i]->getName())) {
                        fprintf(errorout,"Line# %d: Redefinition of parameter \'%s\'\n",currentParams[i]->getStartLine(),currentParams[i]->getName().c_str());
                        error_count++;
                        break;
                    }
                    $2->addFuncParam(currentParams[i]);
                }
                currentParams.clear();

                if (currFuncReturn && $1->getType() == "VOID") {
                    fprintf(errorout,"Line# %d: Return from a void function\n",returnStartLine);
                    error_count++;
                } 
                currFuncReturn = false;
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
                if (!ret) {
                    // found 
                    SymbolInfo *symInfo = st.look_up($2->getName(), idx, pos, table_no);
                    if (symInfo != nullptr) {
                        if (symInfo->getFunction()) {
                            if ($2->getFuncReturnType() != symInfo->getFuncReturnType() || int(currentParams.size()) != symInfo->getFuncParamCount()) {
                                fprintf(errorout,"Line# %d: Conflicting types for \'%s\'\n",$2->getStartLine(),$2->getName().c_str());
                                error_count++;
                            }
                        }
                        else {
                            fprintf(errorout,"Line# %d: \'%s\' redeclared as different kind of symbol\n",$2->getStartLine(),$2->getName().c_str());
                            error_count++;
                        }
                    }
                    // fprintf(logout, "\t%s already exists in the current ScopeTable\n", $2->getName().c_str());
                }
                if (currFuncReturn && $1->getType() == "VOID") {
                    fprintf(errorout,"Line# %d: Return from a void function\n",returnStartLine);
                    error_count++;
                } 
                currFuncReturn = false;
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
            if (paramAdd) {
                int table_no, idx, pos;
                bool ret = st.insert(new SymbolInfo($4), idx, pos, table_no);
                if (!ret) {
                    // found 
                    paramAdd = false;
                    // fprintf(logout, "\t%s already exists in the current ScopeTable\n", $4->getName().c_str());
                }
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
            if (paramAdd) {
                int table_no, idx, pos;
                bool ret = st.insert(new SymbolInfo($3), idx, pos, table_no);
                if (!ret) {
                    // found 
                    paramAdd = false;
                    // fprintf(logout, "\t%s already exists in the current ScopeTable\n", $3->getName().c_str());
                }
            }
            currentParams.push_back($3);
            
        }
 		| type_specifier ID {
            st.enter_scope();
            scopeStarted = true;
            paramAdd = true;
            $$ = new SymbolInfo("parameter_list : type_specifier ID ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($2->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            
            $2->setDataType($1->getType());

            if (paramAdd) {
                int table_no, idx, pos;
                bool ret = st.insert(new SymbolInfo($2), idx, pos, table_no);
                if (!ret) {
                    // found 
                    paramAdd = false;
                    // fprintf(logout, "\t%s already exists in the current ScopeTable\n", $2->getName().c_str());
                }
            }
            
            currentParams.push_back($2);
            paramOn = true;
        }
		| type_specifier {
            st.enter_scope();
            scopeStarted = true;
            paramAdd = true;
            $$ = new SymbolInfo("parameter_list : type_specifier ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
            
            $1->setDataType($1->getType());
            
            if (paramAdd) {
                int table_no, idx, pos;
                bool ret = st.insert(new SymbolInfo($1), idx, pos, table_no);
                if (!ret) {
                    // found 
                    paramAdd = false;
                    // fprintf(logout, "\t%s already exists in the current ScopeTable\n", $1->getName().c_str());
                }
            }
            currentParams.push_back($1);
            paramOn = true;
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
                paramAdd = false;
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
                paramAdd = false;
            }
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON {
                $$ = new SymbolInfo("var_declaration : type_specifier declaration_list SEMICOLON ", "");
                fprintf(logout, "%s\n", $$->getName().c_str());
                
                int table_no, idx, pos;
                for (int i = 0; i < int(currentVars.size()); i++) {
                    if ($1->getType() == "VOID") {
                        fprintf(errorout,"Line# %d: Variable or field \'%s\' declared void\n",currentVars[i]->getStartLine(),currentVars[i]->getName().c_str());
                        error_count++;
                    }
                    else {
                        currentVars[i]->setDataType($1->getType());
                    
                        bool ret = st.insert(new SymbolInfo(currentVars[i]), idx, pos, table_no);
                        if (!ret) {
                            // found 
                            SymbolInfo* symInfo = st.look_up(currentVars[i]->getName(), idx, pos, table_no);
                            if (symInfo != nullptr) {
                                if (symInfo->getDataType() != currentVars[i]->getDataType()) {
                                    fprintf(errorout,"Line# %d: Conflicting types for\'%s\'\n",currentVars[i]->getStartLine(),currentVars[i]->getName().c_str());
                                    error_count++;
                                }
                                else {
                                    fprintf(errorout,"Line# %d: Redeclaration of variable \'%s\'\n",currentVars[i]->getStartLine(),currentVars[i]->getName().c_str());
                                    error_count++;
                                }
                            }
                            // fprintf(logout, "\t%s already exists in the current ScopeTable\n", currentVars[i]->getName().c_str());
                        }
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
	  | compound_statement {
            $$ = new SymbolInfo("statement : compound_statement ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);
        }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement {
            $$ = new SymbolInfo("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($7->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
            $$->addTreeChild($4);
            $$->addTreeChild($5);
            $$->addTreeChild($6);
            $$->addTreeChild($7);
        }
	  | IF LPAREN expression RPAREN statement %prec THEN {
            $$ = new SymbolInfo("statement : IF LPAREN expression RPAREN statement ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($5->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
            $$->addTreeChild($4);
            $$->addTreeChild($5);
        }
	  | IF LPAREN expression RPAREN statement ELSE statement {
            $$ = new SymbolInfo("statement : IF LPAREN expression RPAREN statement ELSE statement ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($7->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
            $$->addTreeChild($4);
            $$->addTreeChild($5);
            $$->addTreeChild($6);
            $$->addTreeChild($7);
        }
	  | WHILE LPAREN expression RPAREN statement {
            $$ = new SymbolInfo("statement : WHILE LPAREN expression RPAREN statement ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($5->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
            $$->addTreeChild($4);
            $$->addTreeChild($5);
        }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON {
            $$ = new SymbolInfo("statement : PRINTLN LPAREN ID RPAREN SEMICOLON ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($5->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
            $$->addTreeChild($4);
            $$->addTreeChild($5);
            
            int table_no, pos, idx;
            SymbolInfo* symInfo = st.look_up($3->getName(), idx, pos, table_no);
            if (symInfo == nullptr) {
                fprintf(errorout,"Line# %d: Undeclared variable \'%s\'\n",$3->getStartLine(),$3->getName().c_str());
                error_count++;
            }
        }
	  | RETURN expression SEMICOLON {
            $$ = new SymbolInfo("statement : RETURN expression SEMICOLON ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($3->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);

            if ($2->getDataType() == "VOID") {
                fprintf(errorout,"Line# %d: Void cannot be used in expression \n",$2->getStartLine());
                error_count++;
            }

            currFuncReturn = true;
            returnStartLine = $1->getStartLine();
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

        int table_no, pos, idx;
        SymbolInfo* symInfo = st.look_up($1->getName(), idx, pos, table_no);
        if (symInfo == nullptr) {
            fprintf(errorout,"Line# %d: Undeclared variable \'%s\'\n",$1->getStartLine(),$1->getName().c_str());
            error_count++;
        }
        else {
            if (symInfo->getArray()) {
                fprintf(errorout,"Line# %d: No index associated with variable \'%s\'\n",$1->getStartLine(),$1->getName().c_str());
                error_count++;
            }
            $$->setDataType(symInfo->getDataType());
        }
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

        int table_no, pos, idx;
        SymbolInfo* symInfo = st.look_up($1->getName(), idx, pos, table_no);
        if (symInfo == nullptr) {
            fprintf(errorout,"Line# %d: Undeclared variable \'%s\'\n",$1->getStartLine(),$1->getName().c_str());
            error_count++;
        }
        else {
            if (!symInfo->getArray()) {
                fprintf(errorout,"Line# %d: \'%s\' is not an array\n",$1->getStartLine(),$1->getName().c_str());
                error_count++;
            }
            else {
                // ID is an array
                if ($3->getDataType() != "INT") {
                    fprintf(errorout,"Line# %d: Array subscript is not an integer\n",$1->getStartLine(),$1->getName().c_str());
                    error_count++;
                }
            }
            $$->setDataType(symInfo->getDataType());
        }
     }
	 ;
	 
expression : logic_expression	{
            $$ = new SymbolInfo("expression : logic_expression ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);

            $$->setDataType($1->getDataType());
            // if ($$->getDataType() == "VOID") {
            //     fprintf(errorout,"Line# %d: Void cannot be used in expression \n",$1->getStartLine());
            //     error_count++;
            // }
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

            $$->setDataType($1->getDataType());
            if ($3->getDataType() == "VOID") {
                fprintf(errorout,"Line# %d: Void cannot be used in expression \n",$3->getStartLine());
                error_count++;
            }
            else if ($1->getDataType() == "INT" && $3->getDataType() == "FLOAT") {
                fprintf(errorout,"Line# %d: Warning: possible loss of data in assignment of FLOAT to INT\n",$1->getStartLine());
                error_count++;
            }
        }	
	   ;
			
logic_expression : rel_expression {
            $$ = new SymbolInfo("logic_expression : rel_expression ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);

            $$->setDataType($1->getDataType());
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

            if ($1->getDataType() == "VOID") {
                fprintf(errorout,"Line# %d: Void cannot be used in expression \n",$1->getStartLine());
                error_count++;
            }
            else if ($3->getDataType() == "VOID") {
                fprintf(errorout,"Line# %d: Void cannot be used in expression \n",$3->getStartLine());
                error_count++;
            }
            $$->setDataType("INT");
         }	
		 ;
			
rel_expression	: simple_expression {
            $$ = new SymbolInfo("rel_expression : simple_expression ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);

            $$->setDataType($1->getDataType());
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

            if ($1->getDataType() == "VOID") {
                fprintf(errorout,"Line# %d: Void cannot be used in expression \n",$1->getStartLine());
                error_count++;
            }
            else if ($3->getDataType() == "VOID") {
                fprintf(errorout,"Line# %d: Void cannot be used in expression \n",$3->getStartLine());
                error_count++;
            }
            
            $$->setDataType("INT");
        }
		;
				
simple_expression : term {
            $$ = new SymbolInfo("simple_expression : term ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);

            $$->setDataType($1->getDataType());
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

            if ($1->getDataType() == "VOID") {
                fprintf(errorout,"Line# %d: Void cannot be used in expression \n",$1->getStartLine());
                error_count++;
            }
            else if ($3->getDataType() == "VOID") {
                fprintf(errorout,"Line# %d: Void cannot be used in expression \n",$3->getStartLine());
                error_count++;
            }
            $$->setDataType($1->getDataType());
          }
		  ;
					
term :	unary_expression {
            $$ = new SymbolInfo("term : unary_expression ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);

            $$->setDataType($1->getDataType());
            $$->setConstVal($1->getConstVal());
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

            if ($1->getDataType() == "VOID") {
                fprintf(errorout,"Line# %d: Void cannot be used in expression \n",$1->getStartLine());
                error_count++;
            }
            else if ($3->getDataType() == "VOID") {
                fprintf(errorout,"Line# %d: Void cannot be used in expression \n",$3->getStartLine());
                error_count++;
            }
            else if ($2->getName() == "%" && ($1->getDataType() != "INT" || $3->getDataType() != "INT")) {
                fprintf(errorout,"Line# %d: Operands of modulus must be integers \n",$3->getStartLine());
                error_count++;
            }
            else if (($2->getName() == "/" || $2->getName() == "%") && $3->getConstVal() == "0") {
                fprintf(errorout,"Line# %d: Warning: division by zero\n",$1->getStartLine());
                error_count++;
            }
            $$->setDataType($1->getDataType());

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

            if ($2->getDataType() == "VOID") {
                fprintf(errorout,"Line# %d: Void cannot be used in expression \n",$2->getStartLine());
                error_count++;
            }

            $$->setDataType($2->getDataType());
        }
		 | NOT unary_expression {
            $$ = new SymbolInfo("unary_expression : NOT unary_expression ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($2->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);

            if ($2->getDataType() == "VOID") {
                fprintf(errorout,"Line# %d: Void cannot be used in expression \n",$2->getStartLine());
                error_count++;
            }

            $$->setDataType($2->getDataType());
         }
		 | factor {
            $$ = new SymbolInfo("unary_expression : factor ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($1->getEndLine());
            $$->addTreeChild($1);

            $$->setDataType($1->getDataType());
            $$->setConstVal($1->getConstVal());
         }
		 ;
	
factor	: variable {
        $$ = new SymbolInfo("factor : variable ", "");
        fprintf(logout, "%s\n", $$->getName().c_str());
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($1->getEndLine());
        $$->addTreeChild($1);

        $$->setDataType($1->getDataType());
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

        int table_no, idx, pos;
        SymbolInfo* symInfo = st.look_up($1->getName(), idx, pos, table_no);
        if (symInfo == nullptr) {
            // not found
            fprintf(errorout,"Line# %d: Undeclared function \'%s\'\n",$1->getStartLine(),$1->getName().c_str());
            error_count++;
        }
        else {
            // check if it's even a function
            if (!symInfo->getFunction()) {
                fprintf(errorout,"Line# %d: \'%s\' is not a function\n",$1->getStartLine(),$1->getName().c_str());
                error_count++;
            }
            else {
                // check if argument count match
                int argCount = symInfo->getFuncParamCount();
                if (argCount > int(currentArgs.size())) {
                    fprintf(errorout,"Line# %d: Too few arguments to function \'%s\'\n",$1->getStartLine(),$1->getName().c_str());
                    error_count++;
                }
                else if (argCount < int(currentArgs.size())) {
                    fprintf(errorout,"Line# %d: Too many arguments to function \'%s\'\n",$1->getStartLine(),$1->getName().c_str());
                    error_count++;
                }
                else {
                    // argument count matches
                    // check if the types are compatible
                    for (int i = 0; i < int(currentArgs.size()); i++) {
                        if (!symInfo->matchFuncParamType(i, currentArgs[i]->getDataType())) {
                            fprintf(errorout,"Line# %d: Type mismatch for argument %d of \'%s\'\n",$1->getStartLine(), i+1, $1->getName().c_str());
                            error_count++;
                        }
                    }
                }
            }
            $$->setDataType(symInfo->getFuncReturnType());
        }
        currentArgs.clear();
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

        if ($2->getDataType() == "VOID") {
            fprintf(errorout,"Line# %d: Void cannot be used in expression \n",$2->getStartLine());
            error_count++;
        }
        else {
            $$->setDataType($2->getDataType());
        }
    }
	| CONST_INT {
        $$ = new SymbolInfo("factor : CONST_INT ", "");
        fprintf(logout, "%s\n", $$->getName().c_str());
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($1->getEndLine());
        $$->addTreeChild($1);

        $$->setDataType("INT");
        $$->setConstVal($1->getName());
    }
	| CONST_FLOAT {
        $$ = new SymbolInfo("factor : CONST_FLOAT ", "");
        fprintf(logout, "%s\n", $$->getName().c_str());
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($1->getEndLine());
        $$->addTreeChild($1);

        $$->setDataType("FLOAT");
        $$->setConstVal($1->getName());
    }
	| variable INCOP {
        $$ = new SymbolInfo("factor : variable INCOP ", "");
        fprintf(logout, "%s\n", $$->getName().c_str());
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($2->getEndLine());
        $$->addTreeChild($1);
        $$->addTreeChild($2);

        $$->setDataType($1->getDataType());
    }
	| variable DECOP {
        $$ = new SymbolInfo("factor : variable DECOP ", "");
        fprintf(logout, "%s\n", $$->getName().c_str());
        $$->setRule(true);
        $$->setStartLine($1->getStartLine());
        $$->setEndLine($2->getEndLine());
        $$->addTreeChild($1);
        $$->addTreeChild($2);

        $$->setDataType($1->getDataType());
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

                currentArgs.push_back($3);
            }
	      | logic_expression {
                $$ = new SymbolInfo("arguments : logic_expression ", "");
                fprintf(logout, "%s\n", $$->getName().c_str());
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($1->getEndLine());
                $$->addTreeChild($1);

                currentArgs.push_back($1);
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
    errorout= fopen(argv[3],"w");
	fclose(errorout);
	logout= fopen(argv[4],"w");
	fclose(logout);
	
	parseout= fopen(argv[2],"a");
    errorout= fopen(argv[3],"a");
	logout= fopen(argv[4],"a");

	yyin=fp;
	yyparse();
	
    fprintf(logout, "Total Lines: %d\n", line_count);
    fprintf(logout, "Total Errors: %d\n", error_count);

	fclose(parseout);
    fclose(errorout);
	fclose(logout);
    fclose(fp);
	
	return 0;
}
