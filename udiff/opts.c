#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <getopt.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include <float.h>

#include "opts.h"

static void str_to_lower ( char *str );
static int is_str_nocase_match ( const char *str_a, const char *str_b );

opt_t g_opts = {
	.input_file1 = NULL,
	.input_file2 = NULL,
	.output_file = "/dev/stdout",
	.input_format = TWO_COLUMN,
	.diff_format = (DIFF_SHOW_SUMMARY | DIFF_SHOW_VALUE | DIFF_SHOW_VD | DIFF_SHOW_RATIO | DIFF_SORT),
	.reltol = 1e-2,
	.abstol = 0.0,
	.debug = false
};

void show_help ()
{
	printf( "*------------------------------------*\n" 
		"*         universal file diff        *\n"
		"*------------------------------------*\n" 
		"[Options]\n"
		"  -h  =>  show help\n"
		"  -d  =>  enable debug information\n"
		"  -a | --input1 =>  specify input file1 name\n"
		"  -b | --input2 =>  specify input file2 name\n"
		"  -o | --output =>  specify diff results file name\n"
		"  -r | --input_format =>  specify input file format\n"
		"  -f | --diff_format  =>  specify report format\n"
		"  -t | --reltol =>  relative tolerance\n"
		"  -s | --abstol =>  absolute tolerance\n"
		"\n"
		"* support input format:\n"
		"   two_column\n"
		"   raw_ascii \n"
		"   spice_ic\n"
		"   dense_matrix\n"
		"   sparse_matrix\n"
		"\n"
		"* diff report format:\n"
		"   000001 => show_all\n"
		"   000010 => sort descending\n"
		"   000100 => show ratio\n"
		"   001000 => show difference\n"
		"   010000 => show value\n"
		"   100000 => show summary\n"
		"   111111 => turn on all\n"
		);
}

static void str_to_lower ( char *str )
{
	for ( int i = 0; '\0' != str[i]; ++i )
	{
		str[i] = tolower( str[i] );
	}
}

static int is_str_nocase_match ( const char *str_a, const char *str_b )
{
	char *a = (char *) calloc ( strlen(str_a) + 1, sizeof(char) );
	char *b = (char *) calloc ( strlen(str_b) + 1, sizeof(char) );
	bool is_same;
	strcpy( a, str_a );
	strcpy( b, str_b );
	str_to_lower( a );
	str_to_lower( b );
	is_same = (0 == strcmp( a, b ));
	free( a );
	free( b );
	return is_same;
}

void parse_cmd_options ( int argc, char **argv )
{
	int c;

	while ( true )
	{
		static struct option long_options[] =
		{
			// flag options
			{"help", no_argument, 0, 'h'},
			{"debug", no_argument, 0, 'd'},

			// setting options
			{"input_file1", required_argument, 0, 'a'},
			{"input_file2", required_argument, 0, 'b'},
			{"output_file", required_argument, 0, 'o'},
			{"input_format", required_argument, 0, 'r'},
			{"diff_format", required_argument, 0, 'f'},
			{"reltol", required_argument, 0, 't'},
			{"abstol", required_argument, 0, 's'},
			{0, 0, 0, 0}
		};

		// getopt_long stores the option index here
		int option_index = 0;

		c = getopt_long( argc, argv, "hda:b:o:r:f:t:s:", long_options, &option_index );

		// detect the end of the options
		if ( -1 == c )
		{
			break;
		}

		switch ( c )
		{
			case 'h':
				show_help();
				exit( EXIT_SUCCESS );
				break;

			case 'd':
				g_opts.debug = true;
				break;

			case 'a':
				g_opts.input_file1 = optarg;
				break;

			case 'b':
				g_opts.input_file2 = optarg;
				break;

			case 'o':
				g_opts.output_file = optarg;
				break;

			case 't':
				g_opts.reltol = atof( optarg );
				break;

			case 's':
				g_opts.abstol = atof( optarg );
				break;

			case 'r':
				g_opts.input_format_name = optarg;
				if ( is_str_nocase_match( "two_column", optarg ) )
				{
					g_opts.input_format = TWO_COLUMN;
				}
				else if ( is_str_nocase_match( "raw_ascii", optarg ) )
				{
					g_opts.input_format = RAW_ASCII;
				}
				else if ( is_str_nocase_match( "spice_ic", optarg ) )
				{
					g_opts.input_format = SPICE_IC;
				}
				else if ( is_str_nocase_match( "dense_matrix", optarg ) )
				{
					g_opts.input_format = DENSSE_MATRIX;
				}
				else if ( is_str_nocase_match( "sparse_matrix", optarg ) )
				{
					g_opts.input_format = SPARSE_MATRIX;
				}
				else
				{
					fprintf( stderr, "[Error] unknown input format %s\n", optarg );
					abort();
				}
				break;

			case 'f':
				if ( DIFF_FORMAT_BITS != strlen(optarg) )
				{
					fprintf( stderr, "[Error] diff format bits size unmatched %d != %zd\n", DIFF_FORMAT_BITS, strlen(optarg) );
					abort();
				}
				g_opts.diff_format = 0;
				if ( '1' == optarg[0] )
				{
					g_opts.diff_format |= DIFF_SHOW_SUMMARY;
				}
				if ( '1' == optarg[1] )
				{
					g_opts.diff_format |= DIFF_SHOW_VALUE;
				}
				if ( '1' == optarg[2] )
				{
					g_opts.diff_format |= DIFF_SHOW_VD;
				}
				if ( '1' == optarg[3] )
				{
					g_opts.diff_format |= DIFF_SHOW_RATIO;
				}
				if ( '1' == optarg[4] )
				{
					g_opts.diff_format |= DIFF_SORT;
				}
				if ( '1' == optarg[5] )
				{
					g_opts.diff_format |= DIFF_SHOW_ALL;
				}
				break;

			case '?':
				// getopt_long already printed an error message 
				break;

			default:
				abort ();
				break;
		}
	}

	// print any remaining command line arguments (not options)
	if (optind < argc)
	{
		fprintf( stderr, "[Warning] non-option ARGV-elements: " );
		while ( optind < argc )
		{
			fprintf( stderr, "%s ", argv[optind++] );
		}
		fprintf( stderr, "\n" );
	}
}

