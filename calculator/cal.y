%{
#include <math.h>
#include "hash.hxx"

void yyerror ( const char *msg );
int yyget_debug ();
extern int yylex ();
%}

%union
{
	double dval;
	int ival;
	char *sval;
	Node nval;
}

%token<dval> NUMBER
%token<sval> IDENTIFIER
%token<sval> TYPE
%token<sval> MATH_FUNCTION
%token<sval> STRING
%token<sval> OP_ASSIGN
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

%type<nval> expression
%type<nval> oprand
%type<sval> line_comment_text
%type<sval> block_comment_text

 /* assign precedence, later declare has higher precedence */
%right OP_ASSIGN
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
	: comment
	| declaration comment 
	| expression comment 
	{
		if ( NODE_DOUBLE == $1.type )
		{
			printf( " = %.10lf\n", $1.val.dval ); 
		}
		else
		{
			printf( " = %s\n", $1.val.sval ); 
		}
	}
	;

comment
	: '\n'
	| START_LINE_COMMENT line_comment_text END_LINE_COMMENT 
	{
		/* fprintf( stderr, "skip line comment '%s'\n", $2 ); */
	}
	| START_BLOCK_COMMENT block_comment_text END_BLOCK_COMMENT 
	{
		/* fprintf( stderr, "skip block comment '%s'\n", $2 ); */
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
	| IDENTIFIER OP_ASSIGN expression 
	{ 
		symbol_table_insert( $1, $3 );
		$$ = $3;
	}
	| expression OP_PLUS expression 
	{ 
		if ( (NODE_DOUBLE == $1.type) && (NODE_DOUBLE == $3.type) )
		{
			Node tmp_node = { .type = NODE_DOUBLE, .val = { .dval = ($1.val.dval + $3.val.dval) } };
			$$ = tmp_node;
		}
		else if ( (NODE_STRING == $1.type) && (NODE_STRING == $3.type) )
		{
			Node tmp_node = { .type = NODE_STRING, .val = { .sval = NULL } };
			tmp_node.val.sval = (char *) calloc ( strlen($1.val.sval) + strlen($3.val.sval) + 1, sizeof(char) );
			sprintf( tmp_node.val.sval, "%s%s", $1.val.sval, $3.val.sval );
			$$ = tmp_node;
		}
	}
	| expression OP_MINUS expression 
	{
		if ( (NODE_DOUBLE == $1.type) && (NODE_DOUBLE == $3.type) )
		{
			Node tmp_node = { .type = NODE_DOUBLE, .val = { .dval = ($1.val.dval - $3.val.dval) } };
			$$ = tmp_node;
		}
	}
	| expression OP_MUL expression 
	{
		if ( (NODE_DOUBLE == $1.type) && (NODE_DOUBLE == $3.type) )
		{
			Node tmp_node = { .type = NODE_DOUBLE, .val = { .dval = ($1.val.dval * $3.val.dval) } };
			$$ = tmp_node;
		}
	}
	| expression OP_DIV expression 
	{
		if ( (NODE_DOUBLE == $1.type) && (NODE_DOUBLE == $3.type) )
		{
			Node tmp_node = { .type = NODE_DOUBLE, .val = { .dval = ($1.val.dval / $3.val.dval) } };
			$$ = tmp_node;
		}
	}
	| expression OP_POW expression 
	{ 
		if ( (NODE_DOUBLE == $1.type) && (NODE_DOUBLE == $3.type) )
		{
			Node tmp_node = { .type = NODE_DOUBLE, .val = { .dval = pow( $1.val.dval, $3.val.dval ) } };
			$$ = tmp_node;
		}
	}
	| OP_MINUS expression %prec OP_UMINUS 
	{
		Node tmp_node = { .type = NODE_DOUBLE, .val = { .dval = -$2.val.dval } };
		$$ = tmp_node; 
	}
	| '(' expression ')' { $$ = $2; }
	| MATH_FUNCTION '(' expression ')' {
		if ( 0 == strcmp( $1, "exp" ) )
		{
			Node tmp_node = { .type = NODE_DOUBLE, .val = { .dval = exp($3.val.dval) } };
			$$ = tmp_node;
		}
		else if ( 0 == strcmp( $1, "sqrt" ) )
		{
			Node tmp_node = { .type = NODE_DOUBLE, .val = { .dval = sqrt($3.val.dval) } };
			$$ = tmp_node;
		}
		else if ( 0 == strcmp( $1, "log" ) )
		{
			Node tmp_node = { .type = NODE_DOUBLE, .val = { .dval = log($3.val.dval) } };
			$$ = tmp_node;
		}
		else if ( 0 == strcmp( $1, "log2" ) )
		{
			Node tmp_node = { .type = NODE_DOUBLE, .val = { .dval = log2($3.val.dval) } };
			$$ = tmp_node;
		}
	}
	;

oprand
	: NUMBER 
	{ 
		Node tmp_node = { .type = NODE_DOUBLE, .val = { .dval = $1 } };
		$$ = tmp_node; 
	}
	| STRING 
	{ 
		Node tmp_node = { .type = NODE_STRING, .val = { .sval = $1 } };
		$$ = tmp_node; 
	}
	| IDENTIFIER 
	{
		Node node = symbol_table_lookup( $1 );		
		if ( NODE_EMPTY != node.type )
		{
			$$ = node;
		}
		else
		{
			fprintf( stderr, "[Error] unknown symbol '%s'\n", $1 );
			abort();
		}
	}
	;

declaration
	: TYPE namelist
	;

namelist
	: IDENTIFIER
	{
		if ( 0 == strcmp( "double", $<sval>0 ) )
		{
			Node tmp_node = { .type = NODE_DOUBLE, .val = { .dval = 0 } };
			symbol_table_insert( $1, tmp_node );
		}
		else if ( 0 == strcmp( "string", $<sval>0 ) )
		{
			Node tmp_node = { .type = NODE_STRING, .val = { .sval = "" } };
			symbol_table_insert( $1, tmp_node );
		}
		else
		{
			fprintf( stderr, "[Error] unknown type %s\n", $<sval>0 );
			abort();
		}
	}
	| namelist IDENTIFIER
	{
		if ( 0 == strcmp( "double", $<sval>0 ) )
		{
			Node tmp_node = { .type = NODE_DOUBLE, .val = { .dval = 0 } };
			symbol_table_insert( $2, tmp_node );
		}
		else if ( 0 == strcmp( "string", $<sval>0 ) )
		{
			Node tmp_node = { .type = NODE_STRING, .val = { .sval = "" } };
			symbol_table_insert( $2, tmp_node );
		}
		else
		{
			fprintf( stderr, "[Error] unknown type %s\n", $<sval>0 );
			abort();
		}
	}
	;
%%

