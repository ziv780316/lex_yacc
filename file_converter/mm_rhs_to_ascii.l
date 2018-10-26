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
static int count = 0;

%}
 /****************************************************************/
 /*                         lex codes                            */
 /****************************************************************/

 /* determine yytext data type (array or pointer) */
%array

 /* use yyget_debug() to check debug flag, equal to flex option -d */ 
 /* %option debug */

 /* suppress unmatchd rule default echo */
%option nodefault

 /* change prefix */
%option prefix="mm_rhs_to_ascii_yy"

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
%x S_READ_FILE

 /* pattern varialbles (use '()' for portable)*/
identifier ([a-zA-Z0-9_\.:#]+)
file_name ([a-zA-Z0-9_\.:#@\-]+)
number (-?[0-9]+("."[0-9]+)?([eE][+-]?0?[0-9]+)?)
while_space ([ \t]+)
configure_start (%)
eol (\r?\n)

%%
 /* local varialbe in yylex */
 int ival;
 double dval;
 char *sval;
 YY_BUFFER_STATE buf_st;

 /****************************************************************/
 /*                count varialbles and points                   */
 /****************************************************************/
{file_name} {
	if ( 0 == data_length )
	{
		FILE *fin = fopen( yytext, "r" );;
		if ( !fin )
		{
			fprintf( stderr, "[Error] open input file '%s' fail -> %s\n", yytext, strerror(errno) );
			abort();
		}

		buf_st = yy_create_buffer( fin, YY_BUF_SIZE );
		yypush_buffer_state( buf_st );
		BEGIN S_COUNT_NODE;
	}
	++data_length;
}

{while_space}|{eol} {
	/* ignore */
}

 /* exception */
. {
	fprintf( stderr, "[Error] INITIAL unknown token='%s' line=%d\n", yytext, yylineno );
	abort();
}

<S_COUNT_NODE>{while_space}+node_name={identifier} {
	++node_count;
}

<S_COUNT_NODE>.|{eol} {
	/* ignore */
}

 /****************************************************************/
 /*                      read raw data                           */
 /****************************************************************/
<S_READ_FILE>{file_name} {
	FILE *fin = fopen( yytext, "r" );;
	if ( !fin )
	{
		fprintf( stderr, "[Error] open input file '%s' fail -> %s\n", yytext, strerror(errno) );
		abort();
	}

	buf_st = yy_create_buffer( fin, YY_BUF_SIZE );
	yypush_buffer_state( buf_st );
	BEGIN S_READ_DATA;

	fprintf( yyout, "%d ", count );
}

<S_READ_FILE>{while_space}|{eol} {
	/* ignore */
}

 /* exception */
<S_READ_FILE>. {
	fprintf( stderr, "[Error] INITIAL unknown token='%s' line=%d\n", yytext, yylineno );
	abort();
}

<S_READ_NODE>{while_space}+node_name={identifier} {
	sval = strstr( yytext, "=" );
	++sval;
	node_names[count] = strdup( sval );
	++count;
}

<S_READ_NODE>.|{eol} {
	/* ignore */
}

<S_READ_DATA>{while_space}+xcur={number} {
	sval = strstr( yytext, "=" );
	++sval;
	sscanf( sval, "%lf", &dval ); 
	fprintf( yyout, "%.10e ", dval );
}

<S_READ_DATA>.|{eol} {
	/* ignore */
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
		printf( "* lex information:\n" );
		printf( " + number of nodes = %d\n", node_count );
		printf( " + number of data  = %d\n", data_length );

		if ( -1 == fseek( yyin, 0, SEEK_SET ) )
		{
			fprintf( stderr, "[Error] fseek yyin fail --> %s\n", strerror(errno) );
			abort();
		}
		BEGIN S_READ_FILE;
		yyrestart( yyin ); /* clear buffer */
		count = 0;
		return 0;
	}
	else if ( S_COUNT_NODE == YYSTATE )
	{
		node_names = (char *) malloc ( sizeof(char *) * node_count );
		count = 0;
		if ( -1 == fseek( yyin, 0, SEEK_SET ) )
		{
			fprintf( stderr, "[Error] fseek yyin fail --> %s\n", strerror(errno) );
			abort();
		}
		BEGIN S_READ_NODE;
		return 0;
	}
	else if ( S_READ_NODE == YYSTATE )
	{
		/* output raw ascii title */
		fprintf( yyout, "#" );
		for ( count = 0; count < node_count; ++count )
		{
			fprintf( yyout, " %s", node_names[count] );
		}
		fprintf( yyout, "\n" );

		yypop_buffer_state();
		BEGIN INITIAL;

		return 0;
	}
	else if ( S_READ_DATA == YYSTATE )
	{
		fprintf( yyout, "\n" );
		yypop_buffer_state();
		BEGIN S_READ_FILE;
		return 0;
	}

	return 1;
}

