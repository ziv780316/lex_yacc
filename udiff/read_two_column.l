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
%x S_IGNORE_REAMIN_COLUMN

 /* pattern varialbles (use '()' for portable, ?i: for case in-sensitive )*/
identifier ([^ \t\r\n=]+)
number (-?[0-9]*"."?[0-9]+)
exp_posfix ([eE][+-]?0?[0-9]+)
science_posfix (?i:[tgxkmunpfa]) 
white_space ([ \t])
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
{white_space}|{eol} {
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

<S_READ_VALUE>{number}{science_posfix} {
	char postfix = yytext[strlen(yytext) - 1];
	yytext[strlen(yytext) - 1] = '\0'; /* remove postfix */
	sscanf( yytext, "%lf", &dval ); 
	switch ( postfix )
	{
		case 't': dval *= 1e12; break;
		case 'g': dval *= 1e9; break;
		case 'x': dval *= 1e6; break;
		case 'k': dval *= 1e3; break;
		case 'm': dval *= 1e-3; break;
		case 'u': dval *= 1e-6; break;
		case 'n': dval *= 1e-9; break;
		case 'p': dval *= 1e-12; break;
		case 'f': dval *= 1e-15; break;
		case 'a': dval *= 1e-18; break;
	}
	hash_s_d_insert( dict_id, sval, dval );
	if ( g_debug )
	{
		fprintf( stderr, "[Debug] insert key=%s value=%lf\n", sval, dval );
	}
	yy_pop_state();
	yy_push_state( S_IGNORE_REAMIN_COLUMN );
}

<S_READ_VALUE>{number}{exp_posfix}? {
	sscanf( yytext, "%lf", &dval ); 
	hash_s_d_insert( dict_id, sval, dval );
	if ( g_debug )
	{
		fprintf( stderr, "[Debug] insert key=%s value=%lf\n", sval, dval );
	}
	yy_pop_state();
	yy_push_state( S_IGNORE_REAMIN_COLUMN );
}

<S_READ_VALUE>{white_space}|= {
	/* ignore */
}

 /* exception */
<S_READ_VALUE>. {
	fprintf( stderr, "[Error] S_READ_VALUE unknown token='%s' line=%d\n", yytext, yylineno );
	abort();
}

<S_IGNORE_REAMIN_COLUMN>.+ {
	if ( g_debug )
	{
		fprintf( stderr, "[Debug] ignore remain column '%s'\n", yytext );
	}
}

<S_IGNORE_REAMIN_COLUMN>{eol} {
	yy_pop_state();
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
