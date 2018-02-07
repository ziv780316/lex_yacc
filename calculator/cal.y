%{
#include <math.h>

void yyerror ( const char *msg );
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
%token<sval> START_BLOCK_COMMENT
%token<sval> BLOCK_COMMENT_CONTEXT
%token<sval> END_BLOCK_COMMENT

%type<dval> expression
%type<dval> oprand
%type<sval> line_comment_text
%type<sval> block_comment_text

 /* assign precedence, later declare has higher precedence */
%left OP_MINUS OP_PLUS
%left OP_DIV OP_MUL
%right OP_POW
%precedence OP_UMINUS

%%
all_syntax 
	: syntax
	| all_syntax syntax
	;

syntax
	: '\n'
	| comment
	| expression comment { printf(" = %lf\n", $1); }
	| expression '\n' { printf(" = %lf\n", $1); }
	;

comment
	: START_LINE_COMMENT line_comment_text END_LINE_COMMENT {
		fprintf( stderr, "skip line comment '%s'\n", $2 );
	}
	| START_BLOCK_COMMENT block_comment_text END_BLOCK_COMMENT {
		fprintf( stderr, "skip block comment '%s'\n", $2 );
	}
	;

line_comment_text
	: /* empty */ { $$ = ""; }
	| LINE_COMMENT_CONTEXT { $$ = $1; }
	;

block_comment_text
	: /* empty */ { $$ = ""; }
	| BLOCK_COMMENT_CONTEXT { $$ = $1; }
	;


expression
	: oprand { $$ = $1; }
	| expression OP_PLUS  expression { $$ = $1 + $3; }
	| expression OP_MINUS expression { $$ = $1 - $3; }
	| expression OP_MUL   expression { $$ = $1 * $3; }
	| expression OP_DIV   expression { $$ = $1 / $3; }
	| expression OP_POW   expression { $$ = pow( $1, $3); }
	| OP_MINUS expression %prec OP_UMINUS { $$ = -$2; }
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

%%

void yyerror ( const char *msg )
{
	fprintf( stderr, "[Error] invalid syntax\n" );
}

