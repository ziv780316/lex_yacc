%{
#include <math.h>

void yyerror ( const char *msg )
{
	fprintf( stderr, "[Error] invalid syntax\n" );
}

extern int yylex();
%}

%union
{
	double dval;
	int ival;
	char *sval;
}

%token<dval> NUMBER
%token<sval> WHITE_SPACE
%token<sval> MATH_FUNCTION
%token<sval> OP_PLUS
%token<sval> OP_MINUS
%token<sval> OP_MUL
%token<sval> OP_DIV
%token<sval> OP_POW

%type<dval> expression
%type<dval> term
%type<dval> factor
%type<dval> group

%%
all_syntax 
	: /* empty string */ %empty 
	| all_syntax expression '\n' { printf(" = %lf\n", $2); }

expression
    : term { $$ = $1; }
    | expression OP_PLUS term { $$ = $1 + $3; }
    | expression OP_MINUS term { $$ = $1 - $3; }
    ;

term
    : factor   { $$ = $1; }
    | term OP_MUL factor  { $$ = $1 * $3; }
    | term OP_DIV factor  { $$ = $1 / $3; }
    | term OP_POW factor  { $$ = pow($1, $3); }
    ;

factor
    : NUMBER { $$ = $1; }
    | OP_MINUS NUMBER { $$ = -$2; }
    | factor WHITE_SPACE { $$ = $1; }
    | WHITE_SPACE factor { $$ = $2; }
    | group   { $$ = $1; }
    | MATH_FUNCTION group { 
	if ( 0 == strcmp( $1, "exp" ) )
	{
		$$ = exp($2);
	}
	else if ( 0 == strcmp( $1, "sqrt" ) )
	{
		$$ = sqrt($2);
	}
	else if ( 0 == strcmp( $1, "log" ) )
	{
		$$ = log($2);
	}
}

group
    : '(' expression ')' { $$ = $2; }
    | WHITE_SPACE '(' expression ')' { $$ = $3; }
    ;

%%
