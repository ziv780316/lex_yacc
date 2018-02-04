%{
#include "cal.y.c"
%}

 /* use yyget_debug() to check debug flag, equal to flex option -d */ 
 /* %option debug */

 /* enable yy_push_state, yy_pop_state and yy_top_state */
%option stack

 /* exclusive condition state */
%x S_LINE_COMMENT
%x S_BLOCK_COMMENT

number [0-9]+("."[0-9])?
while_space [ \t]+
op_plus \+
op_minus \-
op_mul \*
op_div \/
op_pow \^
line_comment \/\/
block_comment_start \/\*
block_comment_end \*\/

 /* ?i: means case insensitive */
math_function (?i:(exp|sqrt|log))

%%
{number} {
	sscanf( yytext, "%lf", &(yylval.dval) ); 
	return NUMBER;
}

{while_space} {
	/* ignore */
}

{math_function} {
	yylval.sval = strdup( yytext );
	return MATH_FUNCTION;
}

<INITIAL,S_BLOCK_COMMENT>"\n" {
	return '\n';
}

[()] {
	return yytext[0];
}

{op_plus} {
	return OP_PLUS;
}

{op_minus} {
	return OP_MINUS;
}

{op_mul} {
	return OP_MUL;
}

{op_div} {
	return OP_DIV;
}

{op_pow} {
	return OP_POW;
}

 /* handle comment */
{line_comment} {
	yy_push_state( S_LINE_COMMENT );
	return START_LINE_COMMENT;
}

<S_LINE_COMMENT>[^\n]* {
	yylval.sval = strdup( yytext );
	return LINE_COMMENT_CONTEXT;
}

<S_LINE_COMMENT>"\n" {
	yy_pop_state();
	return END_LINE_COMMENT;
}

{block_comment_start} {
	yy_push_state( S_BLOCK_COMMENT );
	return START_BLOCK_COMMENT;
}

<S_BLOCK_COMMENT>{block_comment_end} {
	yy_pop_state();
	return END_BLOCK_COMMENT;
}

<S_BLOCK_COMMENT>.+ {
	char *neddle_addr = strstr( yytext, "*/" );
	if ( neddle_addr )
	{
		int pos = (neddle_addr - yytext);
		if ( 0 == pos )
		{
			// pattern --> */ ...
			REJECT;
		}
		else
		{
			// pattern --> .. */ ...
			yylval.sval = strndup( yytext, pos );
			yyless( pos );
		}
	}
	else
	{
		yylval.sval = strdup( yytext );
	}
	return BLOCK_COMMENT_CONTEXT;
}

<<EOF>> {
	yyterminate();
}
%%

int yywrap ()
{
	return 1;
}
