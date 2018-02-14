%{
#include <readline/readline.h>
#include <readline/history.h>
#undef YY_INPUT
#define YY_INPUT(buf, n_read, max_size) (n_read = input_readline(buf, max_size))
int input_readline ( char *buf, int max_size );

/* for auto-completion */
void initialize_readline ();
char **word_completion ( const char *text, int start, int end );
char *word_generator ( const char *text, int state );
char *get_completion_delimiters ();
char *completion_dict[] = { "exp", "sqrt", "log", "log2", NULL };

#include "cal.y.c"
%}

 /* use yyget_debug() to check debug flag, equal to flex option -d */ 
 /* %option debug */

 /* enable yy_push_state, yy_pop_state and yy_top_state */
%option stack

 /* exclusive condition state */
%x S_LINE_COMMENT
%x S_BLOCK_COMMENT

number [0-9]+("."[0-9])?
while_space [ \t]+
op_plus \+
op_minus \-
op_mul \*
op_div \/
op_pow \^
line_comment \/\/
block_comment_start \/\*
block_comment_end \*\/

 /* ?i: means case insensitive */
math_function (?i:(exp|sqrt|log))

%%
{number} {
	sscanf( yytext, "%lf", &(yylval.dval) ); 
	return NUMBER;
}

{while_space} {
	/* ignore */
}

{math_function} {
	yylval.sval = strdup( yytext );
	return MATH_FUNCTION;
}

<INITIAL>"\n" {
	return '\n';
}

[()] {
	return yytext[0];
}

{op_plus} {
	return OP_PLUS;
}

{op_minus} {
	return OP_MINUS;
}

{op_mul} {
	return OP_MUL;
}

{op_div} {
	return OP_DIV;
}

{op_pow} {
	return OP_POW;
}

 /* handle comment */
{line_comment} {
	yy_push_state( S_LINE_COMMENT );
	return START_LINE_COMMENT;
}

<S_LINE_COMMENT>.* {
	yylval.sval = strdup( yytext );
	return LINE_COMMENT_CONTEXT;
}

<S_LINE_COMMENT>"\n" {
	yy_pop_state();
	return END_LINE_COMMENT;
}

{block_comment_start} {
	yy_push_state( S_BLOCK_COMMENT );
	return START_BLOCK_COMMENT;
}

<S_BLOCK_COMMENT>{block_comment_end} {
	yy_pop_state();
	return END_BLOCK_COMMENT;
}

<S_BLOCK_COMMENT>[^\/]+\/ {
	if ( '*' == yytext[yyleng - 2] )
	{
		yylval.sval = strndup( yytext, yyleng - 2 );
		// return only "*/"
		yyless( yyleng - 2 );
		return BLOCK_COMMENT_CONTEXT;
	}
	else
	{
		// cascate ".../" to next yytext, but next time will not chek ".../" this pattern
		yymore();
	}
}

. {
	fprintf( stderr, "unknown token %s\n", yytext );
 }

<<EOF>> {
	yyterminate();
}
%%

int yywrap ()
{
	return 1;
}

/* gnu readline interface */
int input_readline ( char *buf, int max_size )
{
	if ( feof(yyin) )
	{
		return YY_NULL;
	}	
	char *line = readline( ">" ); // does not return '\n'
	if ( !line )
	{
		return YY_NULL;
	}	

	// add '\n' and '\0' 
	int n_read = strlen( line );
	if ( n_read > max_size - 2 )
	{
		fprintf( stderr, "[Error] read too long line (size=%d)\n", n_read );
		return YY_NULL;
	}
	sprintf( buf, "%s\n", line );
	add_history( line );
	free( line );

	return strlen( buf );
}

void initialize_readline ()
{
	rl_readline_name = "calculator";
	rl_attempted_completion_function = word_completion;
	rl_completion_word_break_hook = get_completion_delimiters;
}

char **word_completion ( const char *text, int start, int end )
{
	char **matches = NULL;

	matches = rl_completion_matches( text, word_generator );

	return matches;
}

char *word_generator ( const char *text, int state )
{
	static int list_index;
	static int len;
	char *name;

	if ( 0 == state )
	{
		/* initialize completion, go to top of list */
		list_index = 0;
		len = strlen( text );
	}

	/* return the next name which partially matches list */
	while ( (name = completion_dict[list_index]) )
	{
		list_index++;

		if ( 0 == strncmp( name, text, len) )
		{
			return strdup( name );
		}
	}

	/* no match */
	return NULL;
}

char *get_completion_delimiters ()
{
	return " \t\n\"\\'`@$><=;|&{(.";
}
