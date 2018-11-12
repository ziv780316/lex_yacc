%{
/****************************************************************/
/*                    global varialbles and header              */
/****************************************************************/
#include <errno.h>
#include <assert.h>
#include <stdbool.h>

#include "hash.h"
#include "opts.h"

/* executed prior before each rule */
/* #define YY_USER_ACTION ++rule_count[yy_act]; */ 

/* prior action before first scan */
 /* #define YY_USER_INIT */

/* user defined local functions */

/* user defined static varialbles */
static int dict_id = -1;

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
%option prefix="read_sparse_matrix_yy"

 /* enable yy_push_state, yy_pop_state and yy_top_state */
 /* %option stack */

 /* enable automatic compute '\n' count */
%option yylineno

 /* start condition */

 /* exclusive start condition */
%x S_READ_INDEX
%x S_READ_VALUE
%x S_READ_COMMENT

 /* pattern varialbles (use '()' for portable)*/
index ([^ \t\r\n]+)
number (-?[0-9]*"."?[0-9]+([eE][+-]?0?[0-9]+)?)
white_space ([ \t])
comment_start ([#%"]|\/\/)
eol (\r?\n)

%%
 /* local varialbe in yylex */
 bool already_discard_mat_size;
 char key[BUFSIZ];
 char row[BUFSIZ];
 char col[BUFSIZ];
 double dval;

 /* throw mm file first info --> matrix size */
 if ( AUXILIARY_MM_SPARSE == g_opts.aux_format )
 {
 	already_discard_mat_size = false;
 }
 else
 {
 	already_discard_mat_size = true;
 }

 /* initialize dictionary */
 dict_id = hash_s_d_create();

 /****************************************************************/
 /*                count varialbles and points                   */
 /****************************************************************/
{white_space}|{eol} {
	/* ignore */
}

^{white_space}*{comment_start} {
	BEGIN S_READ_COMMENT;
}

<S_READ_COMMENT>. {
	/* ignore */
}

<S_READ_COMMENT>{eol} {
	BEGIN INITIAL;
}

^{white_space}*{index}{white_space}+{index}{white_space}+=?{number} {
	if ( already_discard_mat_size )
	{
		BEGIN S_READ_INDEX;
		yyless(0);
	}
	else
	{
		already_discard_mat_size = true;
	}
}

 /* exception */
. {
	fprintf( stderr, "[Error] INITIAL unknown token='%s' line=%d\n", yytext, yylineno );
	abort();
}

<S_READ_INDEX>{index}{white_space}+{index} {
	sscanf( yytext, "%s %s", row, col ); 
	sprintf( key, "%s,%s", row, col ); /* key is "row,col" */
	BEGIN S_READ_VALUE;
}

<S_READ_INDEX>{index} {
}

<S_READ_VALUE>{number} {
	sscanf( yytext, "%lf", &dval ); 
	hash_s_d_insert( dict_id, key, dval ); 
	if ( g_opts.debug )
	{
		fprintf( stderr, "[Debug] insert key=%s value=%lf\n", key, dval );
	}
	BEGIN INITIAL;
}

<S_READ_VALUE>{white_space}|= {
	/* ignore */
}

 /* exception */
<S_READ_VALUE>. {
	fprintf( stderr, "[Error] S_READ_VALUE unknown token='%s' line=%d\n", yytext, yylineno );
	abort();
}

 /* this token will be read after return of yywrap */
<<EOF>> {
	/* return dictionary id */
	return dict_id;
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
	return 1;
}
