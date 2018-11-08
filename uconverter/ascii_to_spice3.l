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

/* user defined local functions */
static void dump_spice3_waveform_header ();

/* user defined static varialbles */
static char **node_names = NULL;
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
%x S_COUNT_NODE
%x S_COUNT_DATA
%x S_READ_NODE
%x S_READ_DATA

 /* pattern varialbles (use '()' for portable)*/
identifier ([a-zA-Z0-9_\.:#]+)
number (-?[0-9]*"."?[0-9]+([eE][+-]?0?[0-9]+)?)
white_space ([ \t])
configure_start (#)
eol (\r?\n)

%%
 /* local varialbe in yylex */
 int ival = 0;
 double dval;

 /****************************************************************/
 /*                count varialbles and points                   */
 /****************************************************************/
{configure_start} {
	yy_push_state( S_COUNT_NODE );
}

{white_space} {
	/* ignore */
}

 /* exception */
. {
	fprintf( stderr, "[Error] INITIAL unknown token='%s' line=%d\n", yytext, yylineno );
	abort();
}

<S_COUNT_NODE>{identifier} {
	++node_count;
}

<S_COUNT_NODE>{white_space} {
	/* ignore */
}

<S_COUNT_NODE>{eol} {
	yy_pop_state();
	yy_push_state( S_COUNT_DATA );
}

 /* exception */
<S_COUNT_NODE>. {
	fprintf( stderr, "[Error] S_COUNT_NODE unknown token='%s' line=%d\n", yytext, yylineno );
	abort();
}

<S_COUNT_DATA>{number} {
	/* ignore */
}

<S_COUNT_DATA>{number}{white_space}*{eol} {
	++data_length;
}

<S_COUNT_DATA>{white_space}|{eol} {
	/* ignore */
}

 /* exception */
<S_COUNT_DATA>. {
	fprintf( stderr, "[Error] S_COUNT_DATA unknown token='%s' line=%d\n", yytext, yylineno );
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

<S_READ_DATA>{white_space}|{eol} {
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

<S_READ_NODE>{white_space} {
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
	if ( S_COUNT_DATA == YYSTATE )
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

		yyrestart( yyin ); /* clear additional characters in buffer */

		return 0;
	}
	return 1;
}

static void dump_spice3_waveform_header ()
{
	int i;
	
	fprintf( yyout, "Title: spice3 waveform format\n" );
	fprintf( yyout, "Date: N/A\n" );
	fprintf( yyout, "Plotname: N/A\n" );
	fprintf( yyout, "Flags: real\n" );
	fprintf( yyout, "No. Variables: %d\n", node_count );
	fprintf( yyout, "No. Points: %d\n", data_length );
	fprintf( yyout, "Variables:\n" );
	for ( i = 0; i < node_count; ++i )
	{
		fprintf( yyout, "\t\t%d\t%s\t%s\n", i, node_names[i], "data" );
	}
	fprintf( yyout, "Binary:\n" );
}
