%{
#include <math.h>

void yyerror ( const char *msg )
{
	fprintf( stderr, "[Error] invalid syntax\n" );
}

int yyget_debug ();
extern int yylex ();
%}

%union
{
	double dval;
	int ival;
	char *sval;
}

%token<dval> NUMBER
%token<sval> MATH_FUNCTION
%token<sval> OP_PLUS
%token<sval> OP_MINUS
%token<sval> OP_MUL
%token<sval> OP_DIV
%token<sval> OP_POW
%token<sval> START_LINE_COMMENT
%token<sval> LINE_COMMENT_CONTEXT
%token<sval> END_LINE_COMMENT

%type<dval> expression
%type<dval> oprand

 /* assign precedence, later declare has higher precedence */
%left OP_MINUS OP_PLUS
%left OP_DIV OP_MUL
%right OP_POW
%nonassoc OP_UMINUS

%%
all_syntax 
	: syntax
	| all_syntax syntax
	;

syntax
	: /* empty */
	| comment
	| expression comment
	| expression '\n' { printf(" = %lf\n", $1); }
	;

comment
	: START_LINE_COMMENT LINE_COMMENT_CONTEXT END_LINE_COMMENT {
		if ( yyget_debug() )
		{
			fprintf( stderr, "skip comment '%s'\n", $2 );
		}
	}
	;

expression
	: oprand { $$ = $1; }
	| expression OP_PLUS  expression { $$ = $1 + $3; }
	| expression OP_MINUS expression { $$ = $1 - $3; }
	| expression OP_MUL   expression { $$ = $1 * $3; }
	| expression OP_DIV   expression { $$ = $1 - $3; }
	| expression OP_POW   expression { $$ = pow( $1, $3); }
	| '(' expression ')' { $$ = $2; }
	| MATH_FUNCTION '(' expression ')' {
		if ( 0 == strcmp( $1, "exp" ) )
		{
			$$ = exp($3);
		}
		else if ( 0 == strcmp( $1, "sqrt" ) )
		{
			$$ = sqrt($3);
		}
		else if ( 0 == strcmp( $1, "log" ) )
		{
			$$ = log($3);
		}
	}
	;

oprand
    : NUMBER { $$ = $1; }
    | OP_MINUS oprand %prec OP_UMINUS { $$ = -$2; }

%%
