%{
/****************************************************************/
/*                    global varialbles and header              */
/****************************************************************/
#include <errno.h>

/* executed prior before each rule */
/* #define YY_USER_ACTION ++rule_count[yy_act]; */ 

/* prior action before first scan */
/* #define YY_USER_INIT */

static int node_count = 0; 
static int data_length = 0; 

%}
 /****************************************************************/
 /*                         lex codes                            */
 /****************************************************************/

 /* determine yytext data type (array or pointer) */
%array

 /* use yyget_debug() to check debug flag, equal to flex option -d */ 
 /* %option debug */

 /* change prefix */
%option prefix="ascii_to_spice3_yy"

 /* enable yy_push_state, yy_pop_state and yy_top_state */
%option stack

 /* enable automatic compute '\n' count */
%option yylineno

 /* start condition */

 /* exclusive start condition */
%x S_CONFIGURE
%x S_READ_DATA
%x S_COUNT_DATA

 /* pattern varialbles (use '()' for portable)*/
identifier ([a-zA-Z][a-zA-Z0-9_]*)
number (-?[0-9]+("."[0-9]+)?([eE][+-]?0?[0-9]+)?)
while_space ([ \t]+)
configure_start (#)
eol (\r?\n)

%%
 /* local varialbe in yylex */
 double dval;

 /****************************************************************/
 /*                      handle configure                        */
 /****************************************************************/
{configure_start} {
	yy_push_state( S_CONFIGURE );
}

<S_CONFIGURE>{identifier} {
	++node_count;
}

<S_CONFIGURE>{while_space} {
	/* ignore */
}

<S_CONFIGURE>{eol} {
	yy_pop_state();
	yy_push_state( S_COUNT_DATA );
}

 /****************************************************************/
 /*                count line for allocate memory                */
 /****************************************************************/
<S_COUNT_DATA>{number}{while_space}*{eol} {
	++data_length;
}

<S_COUNT_DATA>.|{eol} {
	/* ignore when count line for allocate buffer size */
}

 /****************************************************************/
 /*                      read raw data                           */
 /****************************************************************/
<S_READ_DATA>{configure_start} {
	/* discard configure line */
	while ( '\n' != input() )
	{
		;
	}
	yylineno += 1; /* if use input() to read eol, then need add yylineno by self */
}

<S_READ_DATA>{number} {
	sscanf( yytext, "%lf", &dval ); 
}

<S_READ_DATA>{while_space}|{eol} {
	/* ignore */
}

<S_READ_DATA>. {
	/* invalid words */
	fprintf( stderr , "[Warning] illegal token=%s at line=%d\n", yytext, yylineno );
}

%%

/****************************************************************/
/*                      user C codes                            */
/****************************************************************/

/* 
   enter here when yyin read EOF
   return 0 means continue parsing (need assign new FILE pointer to yyin)
   return 1 means stop parsing and yylex will return 0 
*/
int yywrap ()
{
	if ( S_COUNT_DATA == YYSTATE)
	{
		printf( "* lex information:\n" );
		printf( " + number of nodes = %d\n", node_count );
		printf( " + number of data  = %d\n", data_length );


		/* rewind file pointer */
		if ( -1 == fseek( yyin, 0, SEEK_SET ) )
		{
			fprintf( stderr, "[Error] fseek yyin fail --> %s\n", strerror(errno) );
			abort();
		}

		yylineno = 0;
		BEGIN S_READ_DATA;

		yyrestart( yyin );

		return 0;
	}
	return 1;
}

/* yy function */
void yyerror ( const char *msg )
{
	fprintf( stdout, "[Error] line %d: %s\n", yylineno - 1, msg );
}
