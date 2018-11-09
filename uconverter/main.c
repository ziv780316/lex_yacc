#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "opts.h"

bool ascii_to_spice3 ( FILE *fin, FILE *fout, bool debug );
bool mm_rhs_to_ascii ( FILE *fin, FILE *fout, bool debug );
bool mm_sparse_reorder ( FILE *fin, FILE *fout, bool debug );
extern int ascii_to_spice3_yylex (void);
extern int mm_rhs_to_ascii_yylex (void);
extern int mm_sparse_reorder_yylex (void);
extern FILE *ascii_to_spice3_yyin;
extern FILE *mm_rhs_to_ascii_yyin;
extern FILE *mm_sparse_reorder_yyin;
extern FILE *ascii_to_spice3_yyout;
extern FILE *mm_rhs_to_ascii_yyout;
extern FILE *mm_sparse_reorder_yyout;

bool g_debug = false;

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
			fprintf( stderr, "[Error] please specify input file by '-i <input file>'\n" );
			abort();
		}
		FILE *fin = fopen( g_opts.input_file, "r" );
		if ( !fin )
		{
			fprintf( stderr, "[Error] open input file '%s' fail -> %s\n", g_opts.input_file, strerror(errno) );
			abort();
		}

		// open output file
		FILE *fout = fopen( g_opts.output_file, "w" );
		if ( !fout )
		{
			fprintf( stderr, "[Error] create output file '%s' fail -> %s\n", g_opts.output_file, strerror(errno) );
			abort();
		}

		// convert input file
		FILE *ftmp;
		bool debug = g_opts.debug;
		bool convert_success;
		char *in_format_name = g_opts.input_format_name;
		char *out_format_name = g_opts.output_format_name;
		file_format input_format  = g_opts.input_format;
		file_format output_format = g_opts.output_format;
		g_debug = debug;
		switch ( input_format )
		{
			case RAW_ASCII:
				switch ( output_format )
				{
					case WAVEFORM_SPICE3:
						convert_success = ascii_to_spice3 ( fin, fout, debug );
						break;

					default:
						fprintf( stderr, "[Error] cannot support conversion %s -> %s\n", in_format_name, out_format_name );
						abort();
						break;
				}
				break;

			case MM_RHS_LIST:
				switch ( output_format )
				{
					case RAW_ASCII:
						convert_success = mm_rhs_to_ascii ( fin, fout, debug );
						break;

					case WAVEFORM_SPICE3:
						ftmp = tmpfile();
						if ( !ftmp )
						{
							fprintf( stderr, "[Error] create tmp file fail --> %s\n", strerror(errno) );
							abort();
						}
						convert_success = mm_rhs_to_ascii ( fin, ftmp, debug );
						fflush( ftmp ); 
						fseek( ftmp, 0, SEEK_SET ); 
						if ( convert_success )
						{
							convert_success = ascii_to_spice3 ( ftmp, fout, debug );
						}
						break;

					default:
						fprintf( stderr, "[Error] cannot support conversion %s -> %s\n", in_format_name, out_format_name );
						abort();
						break;
				}
				break;

			case MM_SPARSE:
				switch ( output_format )
				{
					case MM_SPARSE_REORDER:
						convert_success = mm_sparse_reorder ( fin, fout, debug );
						break;

					default:
						fprintf( stderr, "[Error] cannot support conversion %s -> %s\n", in_format_name, out_format_name );
						abort();
						break;
				}
				break;

			default:
				fprintf( stderr, "[Error] unknown input format %s\n", in_format_name );
				abort();
				break;
		}
		if ( !convert_success )
		{
			fprintf( stderr, "[Error] convert waveform %s -> %s fail\n", in_format_name, out_format_name );
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
	bool convert_success = true;

	ascii_to_spice3_yyin  = fin;
	ascii_to_spice3_yyout = fout;

	ascii_to_spice3_yylex ();

	return convert_success;
}

bool mm_rhs_to_ascii ( FILE *fin, FILE *fout, bool debug )
{
	bool convert_success = true;

	mm_rhs_to_ascii_yyin  = fin;
	mm_rhs_to_ascii_yyout = fout;

	mm_rhs_to_ascii_yylex ();

	return convert_success;
}

bool mm_sparse_reorder ( FILE *fin, FILE *fout, bool debug )
{
	bool convert_success = true;

	mm_sparse_reorder_yyin  = fin;
	mm_sparse_reorder_yyout = fout;

	mm_sparse_reorder_yylex ();

	return convert_success;
}
