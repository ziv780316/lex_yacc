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
		"*   raw-data to waveform converter   *\n"
		"*------------------------------------*\n" 
		"[Options]\n"
		"  -h  =>  show help\n"
		"  -d  =>  enable debug information\n"
		"  -i | --input =>  specify input raw-data file name\n"
		"  -o | --output=>  specify output output waveform file name\n"
		"  -r | --raw_data_format =>  specify raw-data file format\n"
		"  -w | --waveform_format =>  specify waveform file format\n"
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
			{"raw_data_format", required_argument, 0, 'r'},
			{"waveform_format", required_argument, 0, 'w'},
			{0, 0, 0, 0}
		};

		// getopt_long stores the option index here
		int option_index = 0;

		c = getopt_long( argc, argv, "hdi:o:r:w:", long_options, &option_index );

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
				if ( is_str_nocase_match( "ascii", optarg ) )
				{
					g_opts.input_format = RAW_ASCII;
				}
				else if ( is_str_nocase_match( "mm", optarg ) )
				{
					g_opts.input_format = MM_ASCII;
				}
				else
				{
					fprintf( stderr, "[Error] unknown raw-data format %s\n", optarg );
					abort();
				}
				break;

			case 'w':
				if ( is_str_nocase_match( "ascii", optarg ) )
				{
					g_opts.output_format = RAW_ASCII;
				}
				else if ( is_str_nocase_match( "spice3", optarg ) )
				{
					g_opts.output_format = WAVEFORM_SPICE3;
				}
				else
				{
					fprintf( stderr, "[Error] unknown waveform format %s\n", optarg );
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

