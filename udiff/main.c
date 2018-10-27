#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "opts.h"
#include "hash.h"

extern bool two_column_diff ( FILE *fin1, FILE *fin2, FILE *fout, unsigned diff_report_format, bool debug );
extern int read_two_column_yylex (void);
extern FILE *read_two_column_yyin;

int main ( int argc, char **argv )
{
	if ( 1 == argc )
	{
		hash_s_d_unit_test();
		show_help();
	}
	else
	{
		// getopt parse command line arguments
		parse_cmd_options ( argc, argv );

		// open input file 
		if ( !g_opts.input_file1 )
		{
			fprintf( stderr, "[Error] please specify input file by '-a <input file1>'\n" );
			abort();
		}
		if ( !g_opts.input_file2 )
		{
			fprintf( stderr, "[Error] please specify input file by '-b <input file2>'\n" );
			abort();
		}
		FILE *fin1 = fopen( g_opts.input_file1, "r" );
		FILE *fin2 = fopen( g_opts.input_file2, "r" );
		if ( !fin1 )
		{
			fprintf( stderr, "[Error] open input file '%s' fail -> %s\n", g_opts.input_file1, strerror(errno) );
			abort();
		}
		if ( !fin2 )
		{
			fprintf( stderr, "[Error] open input file '%s' fail -> %s\n", g_opts.input_file1, strerror(errno) );
			abort();
		}

		// open output file
		FILE *fout = fopen( g_opts.output_file, "w" );
		if ( !fout )
		{
			fprintf( stderr, "[Error] create output file '%s' fail -> %s\n", g_opts.output_file, strerror(errno) );
			abort();
		}

		// diff input file
		bool debug = g_opts.debug;
		bool diff_success;
		char *in_format_name = g_opts.input_format_name;
		file_format input_format  = g_opts.input_format;
		int diff_report_format= g_opts.diff_format;
		switch ( input_format )
		{
			case TWO_COLUMN:
				diff_success = two_column_diff( fin1, fin2, fout, diff_report_format, debug );
				break;

			default:
				fprintf( stderr, "[Error] unknown input format %s\n", in_format_name );
				abort();
				break;
		}
		if ( !diff_success )
		{
			fprintf( stderr, "[Error] diff file fail\n" );
			abort();
		}

		// release system usage
		fclose( fin1 );
		fclose( fin2 );
		fclose( fout );
	}

	return EXIT_SUCCESS;

}

bool two_column_diff ( FILE *fin1, FILE *fin2, FILE *fout, unsigned diff_report_format, bool debug )
{
	bool diff_success = true;
	int dict_id1;
	int dict_id2;

	read_two_column_yyin  = fin1;
	dict_id1 = read_two_column_yylex ();
	printf( "id1=%d\n", dict_id1 );

	read_two_column_yyin  = fin2;
	dict_id2 = read_two_column_yylex ();
	printf( "id2=%d\n", dict_id2 );

	return diff_success;
}

