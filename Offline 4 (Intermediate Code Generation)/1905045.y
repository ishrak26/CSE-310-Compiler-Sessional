%{
#include<cstdio>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<vector>
#include<map>
#include "1905045_symbol_table.cpp"

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;

FILE *fp;
FILE *logout;
FILE *parseout;
FILE *errorout;
FILE *tmpasmout;
FILE *asmout;
FILE *optasmout;

int line_count = 1;
int error_count = 0;
int currLabel = 1;
int tmpLineCnt = 0;

bool FuncInfo::matchParamType(int idx, string type) {
    assert(idx < params.size());
    return (params[idx]->getDataType() == type);
}

bool FuncInfo::checkParam(string name) {
    for (int i = 0; i < paramSize(); i++) {
        if (name == params[i]->getName() && !params[i]->getFuncParamNoName()) {
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
vector<SymbolInfo*> globalVars;
vector<int> returnLineList;
bool scopeStarted = false;
bool paramAdd = false;
bool paramOn = false;
bool currFuncReturn; // true if sth is returned i.e. non-void
int returnStartLine;
int currStackOffset = -1;

vector<string> backpatchLabels(10000);

void write_final_assembly() {
    fprintf(asmout, ".MODEL SMALL\n");
    fprintf(asmout, ".STACK 1000H\n");
    fprintf(asmout, ".DATA\n");
    fprintf(asmout, "\tCR EQU 0DH\n");
    fprintf(asmout, "\tLF EQU 0AH\n");
    fprintf(asmout, "\tnumber DB \"00000$\"\n");

    // insert the global variables
    for (int i = 0; i < globalVars.size(); i++) {
        SymbolInfo* symInfo = globalVars[i];
        fprintf(asmout, "\t%s DW 1 (0000H)\n", symInfo->getName().c_str());
    }

    fprintf(asmout, ".CODE\n");

    fclose(tmpasmout);
    tmpasmout = fopen("tmp_test_i_code.asm","r");
    char cstr[100];
    int line_no = 1;
    while (fgets(cstr, 95, tmpasmout)) {
        string str(cstr);
        str.pop_back();
        str += backpatchLabels[line_no];
        fprintf(asmout, "%s\n", str.c_str());
        line_no++;
    }

    fprintf(asmout, "new_line proc\n\tpush ax\n\tpush dx\n\tmov ah,2\n\tmov dl,cr\n\tint 21h\n\tmov ah,2\n\tmov dl,lf\n\tint 21h\n\tpop dx\n\tpop ax\n\tret\nnew_line endp\n");
    
    fprintf(asmout, "print_output proc  ;print what is in ax\n\tpush ax\n\tpush bx\n\tpush cx\n\tpush dx\n\tpush si\n\tlea si,number\n\tmov bx,10\n\tadd si,4\n\tcmp ax,0\n\tjnge negate\n\tprint:\n\txor dx,dx\n\tdiv bx\n\tmov [si],dl\n\tadd [si],\'0\'\n\tdec si\n\tcmp ax,0\n\tjne print\n\tinc si\n\tlea dx,si\n\tmov ah,9\n\tint 21h\n\tpop si\n\tpop dx\n\tpop cx\n\tpop bx\n\tpop ax\n\tret\n\tnegate:\n\tpush ax\n\tmov ah,2\n\tmov dl,\'-\'\n\tint 21h\n\tpop ax\n\tneg ax\n\tjmp print\nprint_output endp\nEND main\n");

}

void write_optimized_assembly(char *filename) {
    fclose(asmout);
    asmout = fopen(filename,"r");
    char cstr[100], cstr2[100], cstr3[100];
    pair<string, bool> str3, str2, str;
    
    fgets(cstr3, 95, asmout);
    fgets(cstr2, 95, asmout);
    
    str3.first.assign(cstr3);
    str3.second = true;

    str2.first.assign(cstr2);
    str2.second = true;

    int pos;
    
    while (fgets(cstr, 95, asmout)) {
        if (str3.second) {
            fprintf(optasmout, "%s", str3.first.c_str());
        }
        str.first.assign(cstr);
        str.second = true;
        pos = str.first.find("POP");
        if (pos != string::npos) {
            // pop found
            // find the register
            string reg = str.first.substr(pos+4, 2);
            // check if previous line was push reg
            string cmd = "PUSH " + reg;
            int pos2 = str2.first.find(cmd);
            if (pos2 != string::npos) {
                // consecutive push pop found
                str2.second = false;
                str.second = false;
            }
        }
        
        str3 = str2;
        str2 = str;
        
    }
    if (str3.second) {
        fprintf(optasmout, "%s", str3.first.c_str());
    }
    if (str2.second) {
        fprintf(optasmout, "%s", str2.first.c_str());
    }
}

void printNewLabel() {
    fprintf(tmpasmout, "L%d:\n", currLabel);
    tmpLineCnt++;
    currLabel++;
}

void backpatch(vector<int> list, int label_no) {
    string label = "L" + to_string(label_no);
    // cerr << "label is " << label << '\n';
    for (int i = 0; i < list.size(); i++) {
        int line = list[i];
        backpatchLabels[line] = label;
        // cerr << i << ' ' << list[i] << ' ' << backpatchLabels[i] << '\n';
    }
}

void yyerror(char *s)
{
	//write your code
}


%}

%union {
    SymbolInfo* symInfo;
}

%token<symInfo> IF ELSE FOR WHILE INT FLOAT VOID RETURN CONST_INT CONST_FLOAT ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LSQUARE RSQUARE COMMA SEMICOLON ID PRINTLN

%type<symInfo> start program unit var_declaration func_declaration func_definition type_specifier parameter_list compound_statement statements declaration_list statement expression_statement expression logic_expression M N variable rel_expression simple_expression term unary_expression factor argument_list arguments 

%left ADDOP
%left MULOP
/* %right */

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

        write_final_assembly();
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
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN {
                    currStackOffset = 0;
                    fprintf(tmpasmout, "%s PROC\n", $2->getName().c_str());
                    tmpLineCnt++;
                    fprintf(tmpasmout, "\tPUSH BP\n");
                    fprintf(tmpasmout, "\tMOV BP, SP\n");
                    tmpLineCnt += 2;

                    int table_no, idx, pos;
                    for (int i = (int)(currentParams.size())-1, j = 4; i >= 0; i--, j += 2) {
                        SymbolInfo* symInfo = st.look_up(currentParams[i]->getName(), idx, pos, table_no);
                        string varName = "[BP+" + to_string(j) + "]";
                        symInfo->setVarName(varName);
                    }
                } compound_statement {
                $$ = new SymbolInfo("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement ", "");
                fprintf(logout, "%s\n", $$->getName().c_str());
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($7->getEndLine());
                $$->addTreeChild($1);
                $$->addTreeChild($2);
                $$->addTreeChild($3);
                $$->addTreeChild($4);
                $$->addTreeChild($5);
                $$->addTreeChild($7);

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

                

                if (currFuncReturn && $1->getType() == "VOID") {
                    fprintf(errorout,"Line# %d: Return from a void function\n",returnStartLine);
                    error_count++;
                } 
                currFuncReturn = false;
                
                backpatch(returnLineList, currLabel);
                printNewLabel();
                returnLineList.clear();
                fprintf(tmpasmout, "\tADD SP, %d\n", currStackOffset);
                fprintf(tmpasmout, "\tPOP BP\n");
                fprintf(tmpasmout, "\tRET %d\n", (int)(currentParams.size())*2);
                
                currentParams.clear();
                
                tmpLineCnt += 3;
                
                currStackOffset = -1;
                
                fprintf(tmpasmout, "%s ENDP\n", $2->getName().c_str());
                tmpLineCnt++;
        }
		| type_specifier ID LPAREN RPAREN {
            currStackOffset = 0;
            fprintf(tmpasmout, "%s PROC\n", $2->getName().c_str());
            tmpLineCnt++;
            if ($2->getName() == "main") {
                fprintf(tmpasmout, "\tMOV AX, @DATA\n\tMOV DS, AX\n");
                tmpLineCnt += 2;
            }
            fprintf(tmpasmout, "\tPUSH BP\n");
            fprintf(tmpasmout, "\tMOV BP, SP\n");
            tmpLineCnt += 2;
            
        } compound_statement {
                $$ = new SymbolInfo("func_definition : type_specifier ID LPAREN RPAREN compound_statement ", "");
                fprintf(logout, "%s\n", $$->getName().c_str());
                $$->setRule(true);
                $$->setStartLine($1->getStartLine());
                $$->setEndLine($6->getEndLine());
                $$->addTreeChild($1);
                $$->addTreeChild($2);
                $$->addTreeChild($3);
                $$->addTreeChild($4);
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
                if (currFuncReturn && $1->getType() == "VOID") {
                    fprintf(errorout,"Line# %d: Return from a void function\n",returnStartLine);
                    error_count++;
                } 
                currFuncReturn = false;

                backpatch(returnLineList, currLabel);
                printNewLabel();
                returnLineList.clear();
                fprintf(tmpasmout, "\tADD SP, %d\n", currStackOffset);
                fprintf(tmpasmout, "\tPOP BP\n");

                tmpLineCnt += 2;
                currStackOffset = -1;
                if ($2->getName() == "main") {
                    fprintf(tmpasmout, "\tMOV AX,4CH\n");
                    fprintf(tmpasmout, "\tINT 21H\n");
                    tmpLineCnt += 2;
                }
                else {
                    fprintf(tmpasmout, "\tRET \n");
                    tmpLineCnt++;
                }
                fprintf(tmpasmout, "%s ENDP\n", $2->getName().c_str());
                tmpLineCnt++;
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
            $3->setFuncParamNoName(true);
            // if (paramAdd) {
            //     int table_no, idx, pos;
            //     bool ret = st.insert(new SymbolInfo($3), idx, pos, table_no);
            //     if (!ret) {
            //         // found 
            //         paramAdd = false;
            //         // fprintf(logout, "\t%s already exists in the current ScopeTable\n", $3->getName().c_str());
            //     }
            // }
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
            $1->setFuncParamNoName(true);
            
            // if (paramAdd) {
            //     int table_no, idx, pos;
            //     bool ret = st.insert(new SymbolInfo($1), idx, pos, table_no);
            //     if (!ret) {
            //         // found 
            //         paramAdd = false;
            //         // fprintf(logout, "\t%s already exists in the current ScopeTable\n", $1->getName().c_str());
            //     }
            // }
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

                $$->insertIntoNextlist($2->getNextlist());
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
                        else {
                            SymbolInfo* symInfo = st.look_up(currentVars[i]->getName(), idx, pos, table_no);
                            if (currStackOffset == -1) {
                                // global variable
                                symInfo->setGlobal(true);
                                symInfo->setVarName(symInfo->getName());
                                globalVars.push_back(symInfo);
                            }
                            else {
                                symInfo->setGlobal(false);
                                currStackOffset += 2;
                                symInfo->setStackOffset(currStackOffset);
                                fprintf(tmpasmout, "\tSUB SP, 2\n");
                                tmpLineCnt++;
                                string varName = "[BP-" + to_string(currStackOffset) + "]";
                                symInfo->setVarName(varName);
                            }
                            

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
            printNewLabel();

            $$->insertIntoNextlist($1->getNextlist());
        }
	   | statements M statement {
            $$ = new SymbolInfo("statements : statements statement ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($3->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($3);
            printNewLabel();

            backpatch($1->getNextlist(), $2->getLabel());
            $$->insertIntoNextlist($3->getNextlist());
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

            $$->insertIntoNextlist($1->getNextlist());
        }
	  | FOR LPAREN expression_statement M expression_statement M expression {
            fprintf(tmpasmout, "\tPOP AX\n");
            tmpLineCnt++;
            fprintf(tmpasmout, "\tJMP L%d\n", $4->getLabel());
            tmpLineCnt++;
      } RPAREN M statement {
            $$ = new SymbolInfo("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($11->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
            $$->addTreeChild($5);
            $$->addTreeChild($7);
            $$->addTreeChild($9);
            $$->addTreeChild($11);

            backpatch($11->getNextlist(), $6->getLabel());
            backpatch($5->getTruelist(), $10->getLabel());
            $$->insertIntoNextlist($5->getFalselist());
            fprintf(tmpasmout, "\tJMP L%d\n", $6->getLabel());
            tmpLineCnt++;
        }
	  | IF LPAREN expression RPAREN M statement %prec THEN {
            $$ = new SymbolInfo("statement : IF LPAREN expression RPAREN statement ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($6->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
            $$->addTreeChild($4);
            $$->addTreeChild($6);

            backpatch($3->getTruelist(), $5->getLabel());
            $$->insertIntoNextlist($3->getFalselist());
            $$->insertIntoNextlist($6->getNextlist());
        }
	  | IF LPAREN expression RPAREN M statement ELSE N M statement {
            $$ = new SymbolInfo("statement : IF LPAREN expression RPAREN statement ELSE statement ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($10->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($2);
            $$->addTreeChild($3);
            $$->addTreeChild($4);
            $$->addTreeChild($6);
            $$->addTreeChild($7);
            $$->addTreeChild($10);

            backpatch($3->getTruelist(), $5->getLabel());
            backpatch($3->getFalselist(), $9->getLabel());
            $$->insertIntoNextlist($6->getNextlist());
            $$->insertIntoNextlist($8->getNextlist());
            $$->insertIntoNextlist($10->getNextlist());
        }
	  | WHILE M LPAREN expression {
            if (!($4->getBool())) {
                fprintf(tmpasmout, "\tPOP AX\n");
                fprintf(tmpasmout, "\tCMP AX, 0\n");
                tmpLineCnt += 2;
                fprintf(tmpasmout, "\tJNE \n");
                tmpLineCnt++;
                $4->insertIntoTruelist(tmpLineCnt);
                fprintf(tmpasmout, "\tJMP \n");
                tmpLineCnt++;
                $4->insertIntoFalselist(tmpLineCnt);
            }

      } RPAREN M statement {
            $$ = new SymbolInfo("statement : WHILE LPAREN expression RPAREN statement ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($7->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($3);
            $$->addTreeChild($4);
            $$->addTreeChild($6);
            $$->addTreeChild($8);

            backpatch($8->getNextlist(), $2->getLabel());
            backpatch($4->getTruelist(), $7->getLabel());
            $$->insertIntoNextlist($4->getFalselist());
            fprintf(tmpasmout, "\tJMP L%d\n", $2->getLabel());
            tmpLineCnt++;
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
            else {
                fprintf(tmpasmout, "\tMOV AX, %s\n", symInfo->getVarName().c_str());
                fprintf(tmpasmout, "\tCALL print_output\n");
                fprintf(tmpasmout, "\tCALL new_line\n");
                tmpLineCnt += 3;
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
            fprintf(tmpasmout, "\tPOP AX\n");
            tmpLineCnt++;
            fprintf(tmpasmout, "\tJMP \n");
            tmpLineCnt++;
            returnLineList.push_back(tmpLineCnt);
        }
	  ;

N : {
    $$ = new SymbolInfo();
    fprintf(tmpasmout, "\tJMP \n");
    tmpLineCnt++;
    $$->insertIntoNextlist(tmpLineCnt);
    // printNewLabel();
} ;
	  
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
                fprintf(tmpasmout, "\tPOP AX\n");
                tmpLineCnt++;

                $$->insertIntoTruelist($1->getTruelist());
                $$->insertIntoFalselist($1->getFalselist());
                $$->insertIntoNextlist($1->getNextlist());
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
            $$->setVarName(symInfo->getVarName());
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

            $$->setBool($1->getBool());
            $$->insertIntoTruelist($1->getTruelist());
            $$->insertIntoFalselist($1->getFalselist());

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
            else {
                if ($3->getBool()) {
                    // backpatch
                    backpatch($3->getTruelist(), currLabel);
                    printNewLabel();
                    fprintf(tmpasmout, "\tMOV AX, 1\n");
                    fprintf(tmpasmout, "\tJMP L%d\n", currLabel+1);
                    tmpLineCnt += 2;
                    backpatch($3->getFalselist(), currLabel);
                    printNewLabel();
                    fprintf(tmpasmout, "\tMOV AX, 0\n");
                    tmpLineCnt++;
                    printNewLabel();
                    fprintf(tmpasmout, "\tPUSH AX\n");
                    tmpLineCnt++;
                }
                
                fprintf(tmpasmout, "\tPOP AX\n");
                fprintf(tmpasmout, "\tMOV %s, AX\n", $1->getVarName().c_str());
                fprintf(tmpasmout, "\tPUSH AX\n");
                tmpLineCnt += 3;
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

            $$->setBool($1->getBool());
            $$->insertIntoTruelist($1->getTruelist());
            $$->insertIntoFalselist($1->getFalselist());
        }	
		 | rel_expression {
            if (!($1->getBool())) {
                // make it bool
                $1->setBool(true);
                fprintf(tmpasmout, "\tPOP AX\n");
                fprintf(tmpasmout, "\tCMP AX, 0\n");
                fprintf(tmpasmout, "\tJNE \n");
                tmpLineCnt += 3;
                $1->insertIntoTruelist(tmpLineCnt);
                fprintf(tmpasmout, "\tJMP \n");
                tmpLineCnt++;
                $1->insertIntoFalselist(tmpLineCnt);

            }
         } LOGICOP M rel_expression {
            if (!($5->getBool())) {
                // make it bool
                $5->setBool(true);
                fprintf(tmpasmout, "\tPOP AX\n");
                fprintf(tmpasmout, "\tCMP AX, 0\n");
                fprintf(tmpasmout, "\tJNE \n");
                tmpLineCnt += 3;
                $5->insertIntoTruelist(tmpLineCnt);
                fprintf(tmpasmout, "\tJMP \n");
                tmpLineCnt++;
                $5->insertIntoFalselist(tmpLineCnt);

            }
            
            $$ = new SymbolInfo("logic_expression : rel_expression LOGICOP rel_expression ", "");
            fprintf(logout, "%s\n", $$->getName().c_str());
            $$->setRule(true);
            $$->setStartLine($1->getStartLine());
            $$->setEndLine($5->getEndLine());
            $$->addTreeChild($1);
            $$->addTreeChild($3);
            $$->addTreeChild($5);

            if ($1->getDataType() == "VOID") {
                fprintf(errorout,"Line# %d: Void cannot be used in expression \n",$1->getStartLine());
                error_count++;
            }
            else if ($5->getDataType() == "VOID") {
                fprintf(errorout,"Line# %d: Void cannot be used in expression \n",$5->getStartLine());
                error_count++;
            }
            $$->setDataType("INT");

            if ($3->getName() == "||") {
                backpatch($1->getFalselist(), $4->getLabel());
                $$->insertIntoTruelist($1->getTruelist());
                $$->insertIntoTruelist($5->getTruelist());
                $$->insertIntoFalselist($5->getFalselist());
            }
            else if ($3->getName() == "&&") {
                backpatch($1->getTruelist(), $4->getLabel());
                $$->insertIntoTruelist($5->getTruelist());
                $$->insertIntoFalselist($1->getFalselist());
                $$->insertIntoFalselist($5->getFalselist());
            }
            
            $$->setBool(true);
         }	
		 ;

M : {
    $$ = new SymbolInfo();
    $$->setLabel(currLabel);
    printNewLabel();
} ;
			
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

            $$->setBool(true);
            fprintf(tmpasmout, "\tPOP BX\n");
            fprintf(tmpasmout, "\tPOP AX\n");
            fprintf(tmpasmout, "\tCMP AX, BX\n");
            tmpLineCnt += 3;
            if ($2->getName() == "<") {
                fprintf(tmpasmout, "\tJL \n");
            }
            else if ($2->getName() == "<=") {
                fprintf(tmpasmout, "\tJLE \n");
            }
            else if ($2->getName() == ">") {
                fprintf(tmpasmout, "\tJG \n");
            }
            else if ($2->getName() == ">=") {
                fprintf(tmpasmout, "\tJGE \n");
            }
            else if ($2->getName() == "==") {
                fprintf(tmpasmout, "\tJE \n");
            }
            else if ($2->getName() == "!=") {
                fprintf(tmpasmout, "\tJNE \n");
            }
            tmpLineCnt++;
            $$->insertIntoTruelist(tmpLineCnt);
            fprintf(tmpasmout, "\tJMP \n");
            tmpLineCnt++;
            $$->insertIntoFalselist(tmpLineCnt);
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
            fprintf(tmpasmout, "\tPOP BX\n"); // term
            fprintf(tmpasmout, "\tPOP AX\n"); // simple expression
            tmpLineCnt += 2;
            if ($2->getName() == "+") {
                fprintf(tmpasmout, "\tADD ");
            }
            else {
                fprintf(tmpasmout, "\tSUB ");
            }
            fprintf(tmpasmout, "AX, BX\n");
            fprintf(tmpasmout, "\tPUSH AX\n");
            tmpLineCnt += 2;
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
            
            fprintf(tmpasmout, "\tPOP BX\n"); // unary expression
            fprintf(tmpasmout, "\tPOP AX\n"); // term
            fprintf(tmpasmout, "\tCWD\n");
            tmpLineCnt += 3;
            if ($2->getName() == "*") {
                fprintf(tmpasmout, "\tIMUL BX\n");
                fprintf(tmpasmout, "\tPUSH AX\n");
                tmpLineCnt += 2;
            }
            else {
                fprintf(tmpasmout, "\tIDIV BX\n");
                if ($2->getName() == "/") {
                    fprintf(tmpasmout, "\tPUSH AX\n");
                }
                else {
                    fprintf(tmpasmout, "\tPUSH DX\n");
                }
                tmpLineCnt += 2;
            }
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
            fprintf(tmpasmout, "\tPOP AX\n");
            tmpLineCnt++;
            if ($1->getName() == "-") {
                fprintf(tmpasmout, "\tNEG AX\n");
                tmpLineCnt++;
            }
            fprintf(tmpasmout, "\tPUSH AX\n");
            tmpLineCnt++;
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

        fprintf(tmpasmout, "\tMOV AX, %s\n", $1->getVarName().c_str());
        fprintf(tmpasmout, "\tPUSH AX\n");
        tmpLineCnt += 2;

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

        fprintf(tmpasmout, "\tCALL %s\n", $1->getName().c_str());
        fprintf(tmpasmout, "\tPUSH AX\n");
        tmpLineCnt += 2;
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

        fprintf(tmpasmout, "\tMOV AX, %s\n", $1->getName().c_str());
        fprintf(tmpasmout, "\tPUSH AX\n");
        tmpLineCnt += 2;
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

        fprintf(tmpasmout, "\tMOV AX, %s\n", $1->getVarName().c_str());
        fprintf(tmpasmout, "\tPUSH AX\n");
        fprintf(tmpasmout, "\tINC AX\n");
        fprintf(tmpasmout, "\tMOV %s, AX\n", $1->getVarName().c_str());
        tmpLineCnt += 4;
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

        fprintf(tmpasmout, "\tMOV AX, %s\n", $1->getVarName().c_str());
        fprintf(tmpasmout, "\tPUSH AX\n");
        fprintf(tmpasmout, "\tDEC AX\n");
        fprintf(tmpasmout, "\tMOV %s, AX\n", $1->getVarName().c_str());
        tmpLineCnt += 4;
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
    asmout= fopen(argv[5],"w");
    fclose(asmout);
    optasmout= fopen(argv[6],"w");
    fclose(optasmout);
    tmpasmout= fopen("tmp_test_i_code.asm","w");
	fclose(tmpasmout);
	
	parseout= fopen(argv[2],"a");
    errorout= fopen(argv[3],"a");
	logout= fopen(argv[4],"a");
    asmout= fopen(argv[5],"a");
    optasmout= fopen(argv[6],"a");
    tmpasmout = fopen("tmp_test_i_code.asm","a");

	yyin=fp;
	yyparse();

    write_optimized_assembly(argv[5]);
	
    fprintf(logout, "Total Lines: %d\n", line_count);
    fprintf(logout, "Total Errors: %d\n", error_count);

	fclose(parseout);
    fclose(errorout);
	fclose(logout);
    fclose(tmpasmout);
    fclose(asmout);
    fclose(optasmout);

    fclose(fp);
	
	return 0;
}
