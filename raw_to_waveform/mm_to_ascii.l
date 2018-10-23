%{
/****************************************************************/
/*                    global varialbles and header              */
/****************************************************************/
#include <errno.h>
#include <assert.h>

/* executed prior before each rule */
/* #define YY_USER_ACTION ++rule_count[yy_act]; */ 

/* prior action before first scan */
/* #define YY_USER_INIT */

/* user defined static varialbles */
static char **node_names = NULL;
static int node_count = 0; 
static int data_length = 0; 

static FILE **fin_stack = NULL;
static int fin_top = 0;

%}
 /****************************************************************/
 /*                         lex codes                            */
 /****************************************************************/

 /* determine yytext data type (array or pointer) */
%array

 /* use yyget_debug() to check debug flag, equal to flex option -d */ 
 /* %option debug */

 /* change prefix */
%option prefix="mm_to_ascii_yy"

 /* enable yy_push_state, yy_pop_state and yy_top_state */
%option stack

 /* enable automatic compute '\n' count */
%option yylineno

 /* start condition */

 /* exclusive start condition */
%x S_COUNT_NODE
%x S_COUNT_DATA
%x S_READ_NODE
%x S_READ_DATA

 /* pattern varialbles (use '()' for portable)*/
identifier ([a-zA-Z][a-zA-Z0-9_\.:#]*)
file_name ([a-zA-Z0-9_\.:#@\-]+)
number (-?[0-9]+("."[0-9]+)?([eE][+-]?0?[0-9]+)?)
while_space ([ \t]+)
configure_start (%)
eol (\r?\n)

%%
 /* local varialbe in yylex */
 int ival = 0;
 double dval;

 /****************************************************************/
 /*                count varialbles and points                   */
 /****************************************************************/
{while_space}*{file_name}{while_space}*{eol} {
	++data_length;
}

 /* exception */
. {
	fprintf( stderr, "[Error] INITIAL unknown token='%s' line=%d\n", yytext, yylineno );
	abort();
}

<S_COUNT_NODE>{file_name} {
	++node_count;

		fin_stack = (FILE **) malloc ( sizeof(FILE *) * data_length );
		fin_top = 0;
}

<S_COUNT_NODE>{identifier} {
	++node_count;

		fin_stack = (FILE **) malloc ( sizeof(FILE *) * data_length );
		fin_top = 0;
}

<S_COUNT_NODE>{while_space} {
	/* ignore */
}

<S_COUNT_NODE>{eol} {
	yy_pop_state();
}

 /* exception */
<S_COUNT_NODE>. {
	fprintf( stderr, "[Error] S_COUNT_NODE unknown token='%s' line=%d\n", yytext, yylineno );
	abort();
}

 /****************************************************************/
 /*                      read raw data                           */
 /****************************************************************/
<S_READ_DATA>{configure_start} {
	yy_push_state( S_READ_NODE );
	node_names = (char *) malloc ( sizeof(char *) * node_count );
	ival = 0;
}

<S_READ_DATA>{number} {
	sscanf( yytext, "%lf", &dval ); 
	fwrite( (void *)&dval, sizeof(double), 1, yyout );
}

<S_READ_DATA>{while_space}|{eol} {
	/* ignore */
}

 /* exception */
<S_READ_DATA>. {
	fprintf( stderr, "[Error] S_READ_DATA unknown token='%s' line=%d\n", yytext, yylineno );
	abort();
}

<S_READ_NODE>{identifier} {
	node_names[ival] = strdup( yytext );
	++ival;
}

<S_READ_NODE>{while_space} {
	/* ignore */
}

<S_READ_NODE>{eol} {
	assert( (ival == node_count) && "node_count inconsistent" );
	dump_spice3_waveform_header();

	yy_pop_state();
	yy_push_state( S_READ_DATA );
}

 /* exception */
<S_READ_NODE>. {
	fprintf( stderr, "[Error] S_READ_NODE unknown token='%s' line=%d\n", yytext, yylineno );
	abort();
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
	if ( INITIAL == YYSTATE )
	{
		yylineno = 0;
		BEGIN S_COUNT_NODE;

		yyrestart( yyin );
		return 0;
	}
	else if ( S_COUNT_NODE == YYSTATE )
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

