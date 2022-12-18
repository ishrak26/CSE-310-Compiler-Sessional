%option noyywrap

%x MULTI_LINE_COMMENT
%x STRING
%x MULTI_LINE_STRING
%x IFILE

%{
#include<cstdio>
#include<cstdlib>
#include<string>
#include<vector>

#include "1905045_symbol_table.cpp"

using namespace std;

const int NUM_BUCKETS = 10;
int line_count = 1;
int error_count = 0;

FILE *logout;
FILE *tokenout;

SymbolTable st(NUM_BUCKETS);

// shift all characters starting from pos+1 to 1 index left
void shift_string_to_left(string &str, int pos) {
	for (int i = pos+1; i < str.length(); i++) {
		str[i-1] = str[i];
	}
	str.pop_back();
}

// convert s[idx] according to escape
// str[idx] = '\'
// str[idx+1] exists
void convert_to_escape(string &str, int idx) {
	switch(str[idx+1]) {
		case 'a':
			str[idx] = '\a';
			break;
		case 'b':
			str[idx] = '\b';
			break;
		case 'f':
			str[idx] = '\f';
			break;
		case 'n':
			str[idx] = '\n';
			break;
		case 'r':
			str[idx] = '\r';
			break;
		case 't':
			str[idx] = '\t';
			break;
		case 'v':
			str[idx] = '\v';
			break;
		case '0':
			str[idx] = '\0';
			break;
		case '\'':
		case '\"':
		case '\\':
			str[idx] = str[idx+1];
			break;
		default:
			return;
	}	
	shift_string_to_left(str, idx+1);
}

void handle_escape_string(string &str) {
	for (int i = str.length()-1; i > 0; i--) {
		if (str[i-1] == '\\') {
			convert_to_escape(str, i-1);
			i--;
		}
	}
}

void handle_multiline_backslash(string &str) {
	for (int i = str.length()-1; i > 0; i--) {
		if (str[i] == '\n' && str[i-1] == '\\') {
			// str[i] = ' ';
			shift_string_to_left(str, i);
			shift_string_to_left(str, i-1);
			i--;
			line_count++;
		}
	}
}

void handle_newlines(string &str) {
	for (int i = 0; i < str.length(); i++) {
		if (str[i] == '\n') {
			line_count++;
		}
	}
}

%}

WHITESPACE [ \t\f\r\v]+ 
LETTER [a-zA-Z]
DIGIT [0-9]
CHAR [^'"\\\n]|\\['"\\abfnrtv0]
NEWLINE \n

%%

{NEWLINE} {line_count++;}

{WHITESPACE} {}

 /* single-line comment */
\/\/[^\n]*|\/\/([^\n]*\\{NEWLINE})+[^\n]* {
			fprintf(logout,"Line# %d: Token <SINGLE LINE COMMENT> Lexeme %s found\n",line_count,yytext);
			string str = string(yytext);
			handle_newlines(str);
        }

 /* multi-line comment */
\/\*[ -~\n\r\t\b\v\\]*\*\/ {
			fprintf(logout,"Line# %d: Token <MULTI LINE COMMENT> Lexeme %s found\n",line_count,yytext);
			string str = string(yytext);
			handle_newlines(str);
        }

\/\* {
			BEGIN(MULTI_LINE_COMMENT);
			// cerr << __LINE__ << ' ' << __FILE__ << '\n';
		}

<MULTI_LINE_COMMENT><<EOF>> {
			fprintf(logout,"Error at line# %d: UNFINISHED COMMENT %s\n",line_count,yytext);
			error_count++;
			string str = string(yytext);
			handle_newlines(str);
			// yyterminate();
			BEGIN(INITIAL);
		}

<MULTI_LINE_COMMENT>[ -~\n\r\t\b\v\\] {
			// cerr << "multi line comment ongoing\n";
			string str = string(yytext);
			if (str[0] == '\n') {
				line_count++;
			}
		}

 /* keywords */
"if"	{
			fprintf(tokenout,"<IF, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <IF> Lexeme %s found\n",line_count,yytext);
		}
		
"else"	{
			fprintf(tokenout,"<ELSE, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <ELSE> Lexeme %s found\n",line_count,yytext);
		}

"for"	{
			fprintf(tokenout,"<FOR, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <FOR> Lexeme %s found\n",line_count,yytext);
		}
		
"while"	{
			fprintf(tokenout,"<WHILE, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <WHILE> Lexeme %s found\n",line_count,yytext);
		}
		
"do"	{
			fprintf(tokenout,"<DO, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <DO> Lexeme %s found\n",line_count,yytext);
		}
		
"break"	{
			fprintf(tokenout,"<BREAK, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <BREAK> Lexeme %s found\n",line_count,yytext);
		}
		
"int"	{
			fprintf(tokenout,"<INT, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <INT> Lexeme %s found\n",line_count,yytext);
		}
		
"char"	{
			fprintf(tokenout,"<CHAR, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <CHAR> Lexeme %s found\n",line_count,yytext);
		}
		
"float"	{
			fprintf(tokenout,"<FLOAT, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <FLOAT> Lexeme %s found\n",line_count,yytext);
		}
		
"double"	{
			fprintf(tokenout,"<DOUBLE, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <DOUBLE> Lexeme %s found\n",line_count,yytext);
		}
		
"void"	{
			fprintf(tokenout,"<VOID, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <VOID> Lexeme %s found\n",line_count,yytext);
		}
		
"return"	{
			fprintf(tokenout,"<RETURN, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <RETURN> Lexeme %s found\n",line_count,yytext);
		}
		
"switch"	{
			fprintf(tokenout,"<SWITCH, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <SWITCH> Lexeme %s found\n",line_count,yytext);
		}
		
"case"	{
			fprintf(tokenout,"<CASE, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <CASE> Lexeme %s found\n",line_count,yytext);
		}
		
"default"	{
			fprintf(tokenout,"<DEFAULT, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <DEFAULT> Lexeme %s found\n",line_count,yytext);
		}
		
"continue"	{
			fprintf(tokenout,"<CONTINUE, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <CONTINUE> Lexeme %s found\n",line_count,yytext);
		}

 /* integer literal */
{DIGIT}+ 	{
				fprintf(tokenout,"<CONST_INT, %s>\n",yytext);
				fprintf(logout,"Line# %d: Token <CONST_INT> Lexeme %s found\n",line_count,yytext);
        }

 /* floating point literal that must include sth after the decimal point */
 /* floating point literal that has no decimal point */
({DIGIT}*\.{DIGIT}+("E"("-")?{DIGIT}+)?)|({DIGIT}+"E"("-")?{DIGIT}+) {
                fprintf(tokenout,"<CONST_FLOAT, %s>\n",yytext);
				fprintf(logout,"Line# %d: Token <CONST_FLOAT> Lexeme %s found\n",line_count,yytext);
        }

 /* empty const char */
\'\' {
			fprintf(logout,"Error at line# %d: EMPTY_CONST_CHAR %s\n",line_count,yytext);
			error_count++;
        }

 /* character literal */
\'{CHAR}\' 	{
				string str = string(yytext);
				str = str.substr(1, str.length()-2);
				char c[str.length()+1];
				strcpy(c, str.c_str());
				c[str.length()] = 0;

				if (c[0] == '\\') {
					switch(c[1]) {
						case 'a':
							c[0] = '\a';
							break;
						case 'b':
							c[0] = '\b';
							break;
						case 'f':
							c[0] = '\f';
							break;
						case 'n':
							c[0] = '\n';
							break;
						case 'r':
							c[0] = '\r';
							break;
						case 't':
							c[0] = '\t';
							break;
						case 'v':
							c[0] = '\v';
							break;
						case '0':
							c[0] = '\0';
							break;
						case '\'':
						case '\"':
						case '\\':
							c[0] = c[1];
							break;
						default:
							;
					}
					c[1] = 0;
				}

				fprintf(tokenout,"<CONST_CHAR, %s>\n",c);
				fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme %s found\n",line_count,c);
		}

 /* multichar const char */
\'{CHAR}{CHAR}+\' {
				fprintf(logout,"Error at line# %d: MULTICHAR_CONST_CHAR %s\n",line_count,yytext);
				error_count++;
}

 /* unfinished const char */
\'{NEWLINE} {
				line_count++;
				fprintf(logout,"Error at line# %d: UNFINISHED_CONST_CHAR %s",line_count,yytext);
				error_count++;
}

\'{CHAR}|\'\\\' {
				fprintf(logout,"Error at line# %d: UNFINISHED_CONST_CHAR %s\n",line_count,yytext);
				error_count++;
}

 /* operators and punctuators */
\+|\-	{
			fprintf(tokenout,"<ADDOP, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <ADDOP> Lexeme %s found\n",line_count,yytext);
		}

\*|\/|%	{
			fprintf(tokenout,"<MULOP, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <MULOP> Lexeme %s found\n",line_count,yytext);
		}

\+\+|\-\-	{
			fprintf(tokenout,"<INCOP, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <INCOP> Lexeme %s found\n",line_count,yytext);
		}

\<=?|>=?|==|!=	{
			fprintf(tokenout,"<RELOP, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <RELOP> Lexeme %s found\n",line_count,yytext);
		}

=	{
			fprintf(tokenout,"<ASSIGNOP, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <ASSIGNOP> Lexeme %s found\n",line_count,yytext);
		}

&&|\|\|	{
			fprintf(tokenout,"<LOGICOP, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <LOGICOP> Lexeme %s found\n",line_count,yytext);
		}

&|\||\^|<<|>>	{
			fprintf(tokenout,"<BITOP, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <BITOP> Lexeme %s found\n",line_count,yytext);
		}

!	{
			fprintf(tokenout,"<NOT, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <NOT> Lexeme %s found\n",line_count,yytext);
		}

\(	{
			fprintf(tokenout,"<LPAREN, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <LPAREN> Lexeme %s found\n",line_count,yytext);
		}

\)	{
			fprintf(tokenout,"<RPAREN, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <RPAREN> Lexeme %s found\n",line_count,yytext);
		}

\{	{
			st.enter_scope();
            fprintf(tokenout,"<LCURL, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <LCURL> Lexeme %s found\n",line_count,yytext);
		}

\}	{
			st.exit_scope();
            fprintf(tokenout,"<RCURL, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <RCURL> Lexeme %s found\n",line_count,yytext);
		}

\[	{
			fprintf(tokenout,"<LSQUARE, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <LSQUARE> Lexeme %s found\n",line_count,yytext);
		}

\]	{
			fprintf(tokenout,"<RSQUARE, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <RSQUARE> Lexeme %s found\n",line_count,yytext);
		}

\,	{
			fprintf(tokenout,"<COMMA, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <COMMA> Lexeme %s found\n",line_count,yytext);
		}

\;	{
			fprintf(tokenout,"<SEMICOLON, %s>\n", yytext);
			fprintf(logout,"Line# %d: Token <SEMICOLON> Lexeme %s found\n",line_count,yytext);
		} 

 /* identifiers */
[_A-Za-z][_0-9A-Za-z]* {
            fprintf(tokenout,"<ID, %s>\n", yytext);
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
        }

 /* single-line string literal */
\"{CHAR}+\" {
            
			fprintf(logout,"Line# %d: Token <SINGLE LINE STRING> Lexeme %s found\n",line_count,yytext);
			string str = string(yytext);
			handle_escape_string(str);
			str = str.substr(1);
			str.pop_back(); // to eliminate the double quotes from front and back
			char c[str.length()+1] = {0};
			strcpy(c, str.c_str());
			fprintf(tokenout,"<SINGLE LINE STRING, %s>\n", c);
        }

 /* multi-line string literal */
\"({CHAR}*\\{NEWLINE})+{CHAR}*\" {
            string str = string(yytext);
			
			char c[str.length()+1] = {0};
			strcpy(c, str.c_str());
			
			fprintf(logout,"Line# %d: Token <MULTI LINE STRING> Lexeme %s found\n",line_count,c);
			// string str2 = str;
			str = str.substr(1);
			str.pop_back(); // to eliminate the double quotes from front and back
			handle_multiline_backslash(str);
			handle_escape_string(str);
			char c2[str.length()+1] = {0};
			strcpy(c2, str.c_str());
			fprintf(tokenout,"<MULTI LINE STRING, %s>\n", c2);
			// handle_newlines(str2);
        }

\" {
			BEGIN(STRING);
			fprintf(logout,"Error at line# %d: UNFINISHED_STRING %s",line_count,yytext);
			error_count++;
		}

<STRING>{NEWLINE} {
			fprintf(logout,"%s",yytext);
			BEGIN(INITIAL);
			line_count++;
		}

<STRING><<EOF>> {
			fprintf(logout,"%s\n",yytext);
			error_count++;
			BEGIN(INITIAL);
		}

<STRING>({CHAR}|\\{NEWLINE})* {
			string str = string(yytext);
			
			fprintf(logout,"%s\n",yytext);
			error_count++;
			BEGIN(INITIAL);
			handle_newlines(str);
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


%%

int main(int argc, char** argv) {
	freopen("my_output.txt", "w", stdout);
    
    if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	logout= fopen("log.txt","w");
	tokenout= fopen("token.txt","w");

	yyin= fin;
    
	// cout << "hello here\n";
    yylex();
	st.print_all_scope_table(logout);
	fprintf(logout, "Total lines: %d\nTotal errors: %d\n", line_count, error_count);
    // cout << "hello there\n";
	
	fclose(yyin);
	fclose(tokenout);
	fclose(logout);
	return 0;
}
