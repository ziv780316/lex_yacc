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
	.input_file = NULL,
	.output_file = NULL,
	.input_format = RAW_ASCII,
	.output_format = WAVEFORM_SPICE3
};

void show_help ()
{
	printf( "*------------------------------------*\n" 
		"*      universal file converter      *\n"
		"*------------------------------------*\n" 
		"[Options]\n"
		"  -h  =>  show help\n"
		"  -d  =>  enable debug information\n"
		"  -i | --input  =>  specify input file name\n"
		"  -o | --output =>  specify converted file name\n"
		"  -r | --input_format  =>  specify input file format\n"
		"  -f | --output_format =>  specify converted file format\n"
		"\n"
		"* support format:\n"
		"   raw_ascii\n"
		"   mm_rhs_list\n"
		"   mm_sparse\n"
		"   mm_sparse_reorder\n"
		"   sparse_triplet\n"
		"   sparse_csc\n"
		"   matrix_dense_ascii\n"
		"   waveform_spice3\n"
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
			{"input_file", required_argument, 0, 'i'},
			{"output_file", required_argument, 0, 'o'},
			{"input_format", required_argument, 0, 'r'},
			{"output_format", required_argument, 0, 'f'},
			{0, 0, 0, 0}
		};

		// getopt_long stores the option index here
		int option_index = 0;

		c = getopt_long( argc, argv, "hdi:o:r:f:", long_options, &option_index );

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

			case 'i':
				g_opts.input_file = optarg;
				break;

			case 'o':
				g_opts.output_file = optarg;
				break;

			case 'r':
				g_opts.input_format_name = optarg;
				if ( is_str_nocase_match( "raw_ascii", optarg ) )
				{
					g_opts.input_format = RAW_ASCII;
				}
				else if ( is_str_nocase_match( "mm_rhs_list", optarg ) )
				{
					g_opts.input_format = MM_RHS_LIST;
				}
				else if ( is_str_nocase_match( "mm_sparse", optarg ) )
				{
					g_opts.input_format = MM_SPARSE;
				}
				else if ( is_str_nocase_match( "sparse_triplet", optarg ) )
				{
					g_opts.input_format = SPARSE_TRIPLET;
				}
				else if ( is_str_nocase_match( "sparse_csc", optarg ) )
				{
					g_opts.input_format = SPARSE_CSC;
				}
				else
				{
					fprintf( stderr, "[Error] unknown input format %s\n", optarg );
					abort();
				}
				break;

			case 'f':
				g_opts.output_format_name = optarg;
				if ( is_str_nocase_match( "raw_ascii", optarg ) )
				{
					g_opts.output_format = RAW_ASCII;
				}
				else if ( is_str_nocase_match( "mm_sparse_reorder", optarg ) )
				{
					g_opts.output_format = MM_SPARSE_REORDER;
				}
				else if ( is_str_nocase_match( "sparse_triplet", optarg ) )
				{
					g_opts.output_format = SPARSE_TRIPLET;
				}
				else if ( is_str_nocase_match( "matrix_dense_ascii", optarg ) )
				{
					g_opts.output_format = MATRIX_DENSE_ASCII;
				}
				else if ( is_str_nocase_match( "waveform_spice3", optarg ) )
				{
					g_opts.output_format = WAVEFORM_SPICE3;
				}
				else
				{
					fprintf( stderr, "[Error] unknown converted format %s\n", optarg );
					abort();
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

