%{
/****************************************************************/
/*                    global varialbles and header              */
/****************************************************************/
#include <errno.h>
#include <assert.h>
#include <stdbool.h>

#include "hash.h"
extern bool g_debug;

/* executed prior before each rule */
/* #define YY_USER_ACTION ++rule_count[yy_act]; */ 

/* prior action before first scan */
 /* #define YY_USER_INIT */

/* user defined local functions */

/* user defined static varialbles */
static int dict_id = -1;
static int *permutations = NULL;
static int mat_size = 0;
static int count = 0;
static char **node_names = NULL;
static char **perm_lines = NULL;

%}
 /****************************************************************/
 /*                         lex codes                            */
 /****************************************************************/

 /* determine yytext data type (array or pointer) */
%array

 /* suppress unmatchd rule default echo */
 /* %option nodefault */

 /* use yyget_debug() to check debug flag, equal to flex option -d */ 
 /* %option debug */

 /* change prefix */
%option prefix="mm_sparse_reorder_yy"

 /* enable yy_push_state, yy_pop_state and yy_top_state */
 /* %option stack */

 /* enable automatic compute '\n' count */
%option yylineno

 /* start condition */

 /* exclusive start condition */
%x S_COUNT_SIZE
%x S_READ_PERMULATION
%x S_READ_COMMENT
%x S_READ_NODE
%x S_DUMP

 /* pattern varialbles (use '()' for portable)*/
identifier ([a-zA-Z0-9_\.:#]+)
index ([0-9]+)
number (-?[0-9]*"."?[0-9]+([eE][+-]?0?[0-9]+)?)
white_space ([ \t])
comment_start ([#%"]|\/\/)
eol (\r?\n)

%%
 /* local varialbe in yylex */
 char *str;
 int row;
 int col;
 double dval;
 bool skip_size = false;

 /* initialize dictionary */
 dict_id = hash_s_d_create();

 /* initial state */
 BEGIN S_COUNT_SIZE;

 /****************************************************************/
 /*                count varialbles and points                   */
 /****************************************************************/
 /****************************************************************/
<S_COUNT_SIZE>permr={index} {
	++mat_size;
}

<S_COUNT_SIZE>.|{eol} {
	/* ignore */
}

<S_READ_PERMULATION>permr={index} {
	str = strstr( yytext, "=" );
	++str;
	permutations[count] = atoi( str );
	++count;
}

<S_READ_PERMULATION>.|{eol} {
	/* ignore */
}

<S_READ_COMMENT>^{white_space}*{comment_start}.*permr=.+ {
	perm_lines[ permutations[count] ] = strdup( yytext );
	BEGIN S_READ_NODE;
}

<S_READ_COMMENT>.|{eol} {
	/* ignore */
}

<S_READ_NODE>node_name={identifier} {
	str = strstr( yytext, "=" );
	++str;
	node_names[ permutations[count] ] = strdup( str );
}

<S_READ_NODE>{eol} {
	++count;
	BEGIN S_READ_COMMENT;
}

<S_DUMP>^{white_space}*{comment_start}.*permr=.+ {
	fprintf( yyout, "%s", perm_lines[count] );
	++count;
}

<S_DUMP>^{white_space}*{index}{white_space}+{index}{white_space}+{number} {
	if ( !skip_size )
	{
		// skip first line matrix size
		skip_size = true;
		fprintf( yyout, "%s", yytext );
	}
	else
	{
		sscanf( yytext, "%d %d %lf", &row, &col, &dval ); 
		fprintf( yyout, "%d %d %17.10e", permutations[row - 1], col, dval ); 
	}
}

<S_DUMP>.|{eol} {
	fputc( yytext[0], yyout );
}
 /* this token will be read after return 1 of yywrap */
<<EOF>> {
	return 0;
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
	if ( S_COUNT_SIZE == YYSTATE )
	{
		permutations = (int *) malloc ( sizeof(int) * mat_size );
		node_names = (char **) malloc ( sizeof(char *) * (mat_size + 1) );
		perm_lines = (char **) malloc ( sizeof(char *) * (mat_size + 1) );

		count = 0;
		if ( -1 == fseek( yyin, 0, SEEK_SET ) )
		{
			fprintf( stderr, "[Error] fseek yyin fail --> %s\n", strerror(errno) );
			abort();
		}
		yyrestart( yyin );

		BEGIN S_READ_PERMULATION;
		return 0;
	}
	else if ( S_READ_PERMULATION == YYSTATE )
	{
		count = 0;
		if ( -1 == fseek( yyin, 0, SEEK_SET ) )
		{
			fprintf( stderr, "[Error] fseek yyin fail --> %s\n", strerror(errno) );
			abort();
		}
		yyrestart( yyin );
		BEGIN S_READ_COMMENT;
		return 0;
	}
	else if ( S_READ_COMMENT == YYSTATE )
	{
		count = 1; /* print start from 1 */
		if ( -1 == fseek( yyin, 0, SEEK_SET ) )
		{
			fprintf( stderr, "[Error] fseek yyin fail --> %s\n", strerror(errno) );
			abort();
		}
		yyrestart( yyin );
		BEGIN S_DUMP;
		return 0;
	}
	return 1;
}

