#include<stdio.h>
#include<stdlib.h>

int yyparse (void);
void initialize_readline ();


int main ( int argc, char **argv ) 
{
	initialize_readline();

	yyparse();

	return EXIT_SUCCESS;
}



