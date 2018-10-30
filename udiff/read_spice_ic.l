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
%option prefix="read_spice_ic_yy"

 /* enable yy_push_state, yy_pop_state and yy_top_state */
%option stack

 /* enable automatic compute '\n' count */
%option yylineno

 /* start condition */

 /* exclusive start condition */
%x S_READ_NODE
%x S_READ_VALUE
%x S_READ_VALUE_WITH_SCALE

 /* pattern varialbles (use '()' for portable)*/
identifier ([^ +\t\r\n=()]+)
number (-?[0-9]+("."[0-9]+)?([eE][+-]?0?[0-9]+)?)
scale_char ([gxkmunpfaGXKMUNPFA])
white_space ([ \t]+)
eol (\r?\n)

%%
 /* local varialbe in yylex */
 char sval[BUFSIZ];
 char cval;
 double dval;

 /* initialize dictionary */
 dict_id = hash_s_d_create();

 /****************************************************************/
 /*                count varialbles and points                   */
 /****************************************************************/
^{white_space}*\.(nodeset|ic){white_space}*{eol} {
	yy_push_state( S_READ_NODE );
}

.|{eol} {
	/* ignore */
}

<S_READ_NODE>^{white_space}*\+{white_space}* {
	/* ignore + */
}

<S_READ_NODE>{white_space}+|{eol} {
	/* ignore eol */
}

<S_READ_NODE>[vViI]{white_space}*"(" {
	/* ignore v( i( */
}

<S_READ_NODE>{identifier} {
	strcpy( sval, yytext );
	yy_push_state( S_READ_VALUE );
}

<S_READ_NODE>^[^+\n]*{eol} {
	yy_pop_state();
}

 /* exception */
<S_READ_NODE>. {
	fprintf( stderr, "[Error] S_READ_NODE unknown token='%s' line=%d\n", yytext, yylineno );
	abort();
}

<S_READ_VALUE>{number}/{scale_char} {
	sscanf( yytext, "%lf", &dval ); 
	yy_push_state( S_READ_VALUE_WITH_SCALE );
}

<S_READ_VALUE>{number} {
	sscanf( yytext, "%lf", &dval ); 
	hash_s_d_insert( dict_id, sval, dval );
	if ( g_debug )
	{
		fprintf( stderr, "[Debug] insert key=%s value=%lf\n", sval, dval );
	}
	yy_pop_state();
}

<S_READ_VALUE>{white_space}+|=|")" {
	/* ignore */
}

<S_READ_VALUE_WITH_SCALE>{scale_char} {
	cval = yytext[0];
	switch ( cval )
	{
		case 'g': dval *= 1e+9; break;
		case 'x': dval *= 1e+6; break;
		case 'k': dval *= 1e+3; break;
		case 'm': dval *= 1e-3; break;
		case 'u': dval *= 1e-6; break;
		case 'n': dval *= 1e-9; break;
		case 'p': dval *= 1e-12; break;
		case 'f': dval *= 1e-15; break;
		case 'a': dval *= 1e-18; break;
		default :
			fprintf( stderr, "[Error] unknown scale character '%c'\n", cval );
			abort();
	}
	yy_pop_state(); // up to S_READ_VALUE
	hash_s_d_insert( dict_id, sval, dval );
	if ( g_debug )
	{
		fprintf( stderr, "[Debug] insert key=%s value=%lf\n", sval, dval );
	}
	yy_pop_state(); // up tp S_READ_NODE
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
