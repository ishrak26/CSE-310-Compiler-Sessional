%option noyywrap

%{
#include<cstdio>
#include<cstdlib>
#include<string>
#include<vector>

#include "1905045_symbol_table.cpp"
#include "y.tab.h"

using namespace std;

const int NUM_BUCKETS = 11;
int line_count = 1;
int error_count = 0;

extern FILE *logout;

extern SymbolTable st(NUM_BUCKETS);

extern YYSTYPE yylval;
void yyerror(char *);

%}

WHITESPACE [ \t\f\r\v]+ 
DIGIT [0-9]
NEWLINE \n

%%

{NEWLINE} 	{
			line_count++;
			return PRINTLN;
}

{WHITESPACE} {}

 /* keywords */
"if"	{
			fprintf(logout,"Line# %d: Token <IF> Lexeme %s found\n",line_count,yytext);
			return IF;
		}
		
"else"	{
			fprintf(logout,"Line# %d: Token <ELSE> Lexeme %s found\n",line_count,yytext);
			return ELSE;
		}

"for"	{
			fprintf(logout,"Line# %d: Token <FOR> Lexeme %s found\n",line_count,yytext);
			return FOR;
		}
		
"while"	{
			fprintf(logout,"Line# %d: Token <WHILE> Lexeme %s found\n",line_count,yytext);
			return WHILE;
		}
		
"int"	{
			fprintf(logout,"Line# %d: Token <INT> Lexeme %s found\n",line_count,yytext);
			return INT;
		}
		
"float"	{
			fprintf(logout,"Line# %d: Token <FLOAT> Lexeme %s found\n",line_count,yytext);
			return FLOAT;
		}
		
"void"	{
			fprintf(logout,"Line# %d: Token <VOID> Lexeme %s found\n",line_count,yytext);
			return VOID;
		}
		
"return"	{
			fprintf(logout,"Line# %d: Token <RETURN> Lexeme %s found\n",line_count,yytext);
			return RETURN;
		}

 /* integer literal */
{DIGIT}+ 	{
				fprintf(logout,"Line# %d: Token <CONST_INT> Lexeme %s found\n",line_count,yytext);
				return CONST_INT;
        }

 /* floating point literal that must include sth after the decimal point */
 /* floating point literal that has no decimal point */
({DIGIT}*\.{DIGIT}+("E"("-")?{DIGIT}+)?)|({DIGIT}+"E"("-")?{DIGIT}+) {
				fprintf(logout,"Line# %d: Token <CONST_FLOAT> Lexeme %s found\n",line_count,yytext);
				return CONST_FLOAT;
        }

 /* operators and punctuators */
\+|\-	{
			fprintf(logout,"Line# %d: Token <ADDOP> Lexeme %s found\n",line_count,yytext);
			return ADDOP;
		}

\*|\/|%	{
			fprintf(logout,"Line# %d: Token <MULOP> Lexeme %s found\n",line_count,yytext);
			return MULOP;
		}

\+\+	{
			fprintf(logout,"Line# %d: Token <INCOP> Lexeme %s found\n",line_count,yytext);
			return INCOP;
		}

\-\-	{
			fprintf(logout,"Line# %d: Token <DECOP> Lexeme %s found\n",line_count,yytext);
			return DECOP;
		}

\<=?|>=?|==|!=	{
			fprintf(logout,"Line# %d: Token <RELOP> Lexeme %s found\n",line_count,yytext);
			return RELOP;
		}

=	{
			fprintf(logout,"Line# %d: Token <ASSIGNOP> Lexeme %s found\n",line_count,yytext);
			return ASSIGNOP;
		}

&&|\|\|	{
			fprintf(logout,"Line# %d: Token <LOGICOP> Lexeme %s found\n",line_count,yytext);
			return LOGICOP;
		}

!	{
			fprintf(logout,"Line# %d: Token <NOT> Lexeme %s found\n",line_count,yytext);
			return NOT;
		}

\(	{
			fprintf(logout,"Line# %d: Token <LPAREN> Lexeme %s found\n",line_count,yytext);
			return LPAREN;
		}

\)	{
			fprintf(logout,"Line# %d: Token <RPAREN> Lexeme %s found\n",line_count,yytext);
			return RPAREN;
		}

\{	{
			st.enter_scope();
			fprintf(logout,"Line# %d: Token <LCURL> Lexeme %s found\n",line_count,yytext);
			return LCURL;
		}

\}	{
			st.exit_scope();
			fprintf(logout,"Line# %d: Token <RCURL> Lexeme %s found\n",line_count,yytext);
			return RCURL;
		}

\[	{
			fprintf(logout,"Line# %d: Token <LSQUARE> Lexeme %s found\n",line_count,yytext);
			return LSQUARE;
		}

\]	{
			fprintf(logout,"Line# %d: Token <RSQUARE> Lexeme %s found\n",line_count,yytext);
			return RSQUARE;
		}

\,	{
			fprintf(logout,"Line# %d: Token <COMMA> Lexeme %s found\n",line_count,yytext);
			return COMMA;
		}

\;	{
			fprintf(logout,"Line# %d: Token <SEMICOLON> Lexeme %s found\n",line_count,yytext);
			return SEMICOLON;
		} 

 /* identifiers */
[_A-Za-z][_0-9A-Za-z]* {
			// cerr << "written in token\n";
			fprintf(logout,"Line# %d: Token <ID> Lexeme %s found\n",line_count,yytext);
            int table_no, idx, pos;
            
            bool ret = st.insert(string(yytext), "ID", idx, pos, table_no);
            
            if (!ret) {
                // found 
                fprintf(logout, "\t%s already exists in the current ScopeTable\n", yytext);
            }
            else {
                st.print_all_scope_table(logout);
            }
			return ID;
        }

 /* too many decimal points */
[0-9]*\.([0-9]\.)+[0-9]* {
			fprintf(logout,"Error at line# %d: TOO_MANY_DECIMAL_POINTS %s\n",line_count,yytext);
			error_count++;
        }

 /* ill-formed numbers */
[0-9]+E[0-9]*\.[0-9]* {
			fprintf(logout,"Error at line# %d: ILLFORMED_NUMBER %s\n",line_count,yytext);
			error_count++;
        }

 /* invalid suffix/prefix */
[0-9]+[_A-Za-z]+ {
			fprintf(logout,"Error at line# %d: INVALID_ID_SUFFIX_NUM_PREFIX %s\n",line_count,yytext);
			error_count++;
        }

[ -~]{-}[0-9A-Za-z] {
			fprintf(logout,"Error at line# %d: UNRECOGNIZED_CHAR %s\n",line_count,yytext);
			error_count++;
		}

%%
