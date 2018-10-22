#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "opts.h"

extern bool ascii_to_spice3 ( FILE *fin, FILE *fout, bool debug );
extern int ascii_to_spice3_yylex (void);
extern FILE *ascii_to_spice3_yyin;

int main ( int argc, char **argv )
{
	if ( 1 == argc )
	{
		show_help();
	}
	else
	{
		// getopt parse command line arguments
		parse_cmd_options ( argc, argv );

		// open input file 
		if ( !g_opts.input_file )
		{
			fprintf( stderr, "[Error] please specify input file by '-i <raw-file>'\n" );
			abort();
		}
		FILE *fin = fopen( g_opts.input_file, "r" );
		if ( !fin )
		{
			fprintf( stderr, "[Error] open input file '%s' fail --> %s\n", g_opts.input_file, strerror(errno) );
			abort();
		}

		// open output file
		FILE *fout = fopen( g_opts.output_file, "w" );
		if ( !fout )
		{
			fprintf( stderr, "[Error] create output file '%s' fail --> %s\n", g_opts.output_file, strerror(errno) );
			abort();
		}

		// convert raw data to waveform
		bool debug = g_opts.debug;
		bool convert_success;
		raw_type input_format  = g_opts.input_format;
		waveform_type output_format = g_opts.output_format;
		switch ( input_format )
		{
			case RAW_ASCII:
				// convert memory raw data into waveform data
				switch ( output_format )
				{
					case WAVEFORM_SPICE3:
						convert_success = ascii_to_spice3 ( fin, fout, debug );
						break;

					default:
						fprintf( stderr, "[Error] unknown output format %d\n", output_format );
						abort();
						break;
				}
				break;

			default:
				fprintf( stderr, "[Error] unknown input format %d\n", input_format );
				abort();
				break;
		}
		if ( !convert_success )
		{
			fprintf( stderr, "[Error] convert waveform fail\n" );
			abort();
		}

		// release system usage
		fclose( fin );
		fclose( fout );
	}

	return EXIT_SUCCESS;

}

bool ascii_to_spice3 ( FILE *fin, FILE *fout, bool debug )
{
	bool continue_parse = true;
	bool convert_success = true;
	ascii_to_spice3_yyin = fin;
	while ( continue_parse )
	{
		continue_parse = ascii_to_spice3_yylex ();
	}

	return convert_success;
}
