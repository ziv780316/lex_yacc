%{
#ifdef __cplusplus
#include "cal.y.cxx"
#else
#include "cal.y.c"
#endif
%}

%option debug
%option stack

number [0-9]+("."[0-9])?
while_space [ \t]+
op_plus \+
op_minus \-
op_mul \*
op_div \/
op_pow \^

/* ?i: means case insensitive */
math_function (?i:(exp|sqrt|log))

%%
<*>{number} {
	sscanf( yytext, "%lf", &(yylval.dval) ); 
	return NUMBER;
}

<*>{while_space} {
	return WHITE_SPACE;
}

<*>{math_function} {
	yylval.sval = strdup( yytext );
	return MATH_FUNCTION;
}

"\n" {
	return '\n';
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

[()] {
	return yytext[0];
}

<<EOF>> {
	yyterminate();
}
%%

int yywrap ()
{
	return 1;
}
