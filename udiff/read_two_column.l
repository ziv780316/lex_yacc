%{
/****************************************************************/
/*                    global varialbles and header              */
/****************************************************************/
#include <errno.h>
#include <assert.h>

#include "hash.h"

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
%option prefix="read_two_column_yy"

 /* enable yy_push_state, yy_pop_state and yy_top_state */
%option stack

 /* enable automatic compute '\n' count */
%option yylineno

 /* start condition */

 /* exclusive start condition */
%x S_READ_VALUE

 /* pattern varialbles (use '()' for portable)*/
identifier ([^ \t\r\n]+)
number (-?[0-9]+("."[0-9]+)?([eE][+-]?0?[0-9]+)?)
white_space ([ \t]+)
eol (\r?\n)

%%
 /* local varialbe in yylex */
 char sval[BUFSIZ];
 double dval;

 /* initialize dictionary */
 dict_id = hash_s_d_create();

 /****************************************************************/
 /*                count varialbles and points                   */
 /****************************************************************/
^{white_space}*{eol} {
	/* ignore empty line */
}

{white_space}+|{eol} {
	/* ignore */
}

{identifier} {
	strcpy( sval, yytext );
	yy_push_state( S_READ_VALUE );
}

 /* exception */
. {
	fprintf( stderr, "[Error] INITIAL unknown token='%s' line=%d\n", yytext, yylineno );
	abort();
}

<S_READ_VALUE>{number} {
	sscanf( yytext, "%lf", &dval ); 
	hash_s_d_insert( dict_id, sval, dval );
	yy_pop_state();
}

<S_READ_VALUE>{white_space}+ {
	/* ignore */
}

 /* exception */
<S_READ_VALUE>. {
	fprintf( stderr, "[Error] S_READ_VALUE unknown token='%s' line=%d\n", yytext, yylineno );
	abort();
}

<<EOF>> {
	fprintf( stderr, "return %d\n", dict_id );
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
