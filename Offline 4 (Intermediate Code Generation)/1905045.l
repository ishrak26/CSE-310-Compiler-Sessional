%option noyywrap

%{
#include<cstdio>
#include<cstdlib>
#include<string>
#include<vector>

#include "1905045_symbol_table.cpp"
#include "y.tab.h"

using namespace std;

extern int line_count;
extern int error_count;

extern FILE *logout;

extern SymbolTable st;
extern bool scopeStarted;
extern bool paramOn;

extern YYSTYPE yylval;
void yyerror(char *);

%}

WHITESPACE [ \t\f\r\v]+ 
DIGIT [0-9]
NEWLINE \n

%%

{NEWLINE} 	{
			line_count++;
}

{WHITESPACE} {}

 /* keywords */
"if"	{
			fprintf(logout,"Line# %d: Token <IF> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "IF");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return IF;
		}
		
"else"	{
			fprintf(logout,"Line# %d: Token <ELSE> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "ELSE");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return ELSE;
		}

"for"	{
			fprintf(logout,"Line# %d: Token <FOR> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "FOR");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return FOR;
		}
		
"while"	{
			fprintf(logout,"Line# %d: Token <WHILE> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "WHILE");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return WHILE;
		}
		
"int"	{
			fprintf(logout,"Line# %d: Token <INT> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "INT");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return INT;
		}
		
"float"	{
			fprintf(logout,"Line# %d: Token <FLOAT> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "FLOAT");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return FLOAT;
		}
		
"void"	{
			fprintf(logout,"Line# %d: Token <VOID> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "VOID");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return VOID;
		}
		
"return"	{
			fprintf(logout,"Line# %d: Token <RETURN> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "RETURN");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return RETURN;
		}

 /* integer literal */
{DIGIT}+ 	{
				fprintf(logout,"Line# %d: Token <CONST_INT> Lexeme %s found\n",line_count,yytext);
				yylval.symInfo = new SymbolInfo(string(yytext), "CONST_INT");
				yylval.symInfo->setStartLine(line_count);
				yylval.symInfo->setEndLine(line_count);
				return CONST_INT;
        }

 /* floating point literal that must include sth after the decimal point */
 /* floating point literal that has no decimal point */
({DIGIT}*\.{DIGIT}+("E"("-")?{DIGIT}+)?)|({DIGIT}+"E"("-")?{DIGIT}+) {
				fprintf(logout,"Line# %d: Token <CONST_FLOAT> Lexeme %s found\n",line_count,yytext);
				yylval.symInfo = new SymbolInfo(string(yytext), "CONST_FLOAT");
				yylval.symInfo->setStartLine(line_count);
				yylval.symInfo->setEndLine(line_count);
				return CONST_FLOAT;
        }

 /* operators and punctuators */
\+|\-	{
			fprintf(logout,"Line# %d: Token <ADDOP> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "ADDOP");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return ADDOP;
		}

\*|\/|%	{
			fprintf(logout,"Line# %d: Token <MULOP> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "MULOP");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return MULOP;
		}

\+\+	{
			fprintf(logout,"Line# %d: Token <INCOP> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "INCOP");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return INCOP;
		}

\-\-	{
			fprintf(logout,"Line# %d: Token <DECOP> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "DECOP");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return DECOP;
		}

\<=?|>=?|==|!=	{
			fprintf(logout,"Line# %d: Token <RELOP> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "RELOP");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return RELOP;
		}

=	{
			fprintf(logout,"Line# %d: Token <ASSIGNOP> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "ASSIGNOP");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return ASSIGNOP;
		}

&&|\|\|	{
			fprintf(logout,"Line# %d: Token <LOGICOP> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "LOGICOP");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return LOGICOP;
		}

!	{
			fprintf(logout,"Line# %d: Token <NOT> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "NOT");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return NOT;
		}

\(	{
			fprintf(logout,"Line# %d: Token <LPAREN> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "LPAREN");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return LPAREN;
		}

\)	{
			fprintf(logout,"Line# %d: Token <RPAREN> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "RPAREN");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return RPAREN;
		}

\{	{
			// if (!scopeStarted) {
			// 	st.enter_scope(); // for empty parameter case
			// }
			if (paramOn) {
				paramOn = false; // this is the LCURL for function beginning
			}
			else {
				st.enter_scope(); // new scope inside a function
			}
			fprintf(logout,"Line# %d: Token <LCURL> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "LCURL");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return LCURL;
		}

\}	{
			// st.exit_scope();
			fprintf(logout,"Line# %d: Token <RCURL> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "RCURL");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return RCURL;
		}

\[	{
			fprintf(logout,"Line# %d: Token <LSQUARE> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "LSQUARE");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return LSQUARE;
		}

\]	{
			fprintf(logout,"Line# %d: Token <RSQUARE> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "RSQUARE");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return RSQUARE;
		}

\,	{
			fprintf(logout,"Line# %d: Token <COMMA> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "COMMA");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return COMMA;
		}

\;	{
			fprintf(logout,"Line# %d: Token <SEMICOLON> Lexeme %s found\n",line_count,yytext);
			yylval.symInfo = new SymbolInfo(string(yytext), "SEMICOLON");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
			return SEMICOLON;
		} 

 /* identifiers */
[_A-Za-z][_0-9A-Za-z]* {
			fprintf(logout,"Line# %d: Token <ID> Lexeme %s found\n",line_count,yytext);
			if (string(yytext) == "println") {
				yylval.symInfo = new SymbolInfo(string(yytext), "PRINTLN");
				yylval.symInfo->setStartLine(line_count);
				yylval.symInfo->setEndLine(line_count);
				return PRINTLN;
			}
            yylval.symInfo = new SymbolInfo(string(yytext), "ID");
			yylval.symInfo->setStartLine(line_count);
			yylval.symInfo->setEndLine(line_count);
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
