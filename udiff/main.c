#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <math.h>

#include "opts.h"
#include "hash.h"

typedef struct 
{
	char *key;
	double val1;
	double val2;
	double vd_abs;
	double vd_ratio;
	double tol;
	bool is_diff;
} compare_result_pair_t;

void diff_two_dict( int *dict_id1, int *dict_id2, FILE *fout, double rtol, double atol, unsigned int diff_report_format, bool debug );
void read_two_column ( FILE *fin1, FILE *fin2, int *dict_id1, int *dict_id2, bool debug );
void read_spice_ic ( FILE *fin1, FILE *fin2, int *dict_id1, int *dict_id2, bool debug );
void read_sparse_matrix ( FILE *fin1, FILE *fin2, int *dict_id1, int *dict_id2, bool debug );
extern int read_two_column_yylex (void);
extern int read_spice_ic_yylex (void);
extern int read_sparse_matrix_yylex (void);
extern FILE *read_two_column_yyin;
extern FILE *read_spice_ic_yyin;
extern FILE *read_sparse_matrix_yyin;
static int qsort_result_compare_descending ( const void *p, const void *q ); // called in qsort

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
		g_debug = debug;
		char *in_format_name = g_opts.input_format_name;
		file_format input_format  = g_opts.input_format;
		unsigned int diff_report_format= g_opts.diff_format;
		double rtol = g_opts.reltol;
		double atol = g_opts.abstol;
		int dict_id1;
		int dict_id2;
		switch ( input_format )
		{
			case TWO_COLUMN:
				read_two_column( fin1, fin2, &dict_id1, &dict_id2, debug );
				break;

			case SPICE_IC:
				read_spice_ic( fin1, fin2, &dict_id1, &dict_id2, debug );
				break;

			case SPARSE_MATRIX:
				read_sparse_matrix( fin1, fin2, &dict_id1, &dict_id2, debug );
				break;

			default:
				fprintf( stderr, "[Error] unknown input format %s\n", in_format_name );
				abort();
				break;
		}

		// diff file
		diff_two_dict( &dict_id1, &dict_id2, fout, rtol, atol, diff_report_format, debug );

		// release system usage
		fclose( fin1 );
		fclose( fin2 );
		fclose( fout );
	}

	return EXIT_SUCCESS;

}

void diff_two_dict ( int *dict_id1, int *dict_id2, FILE *fout, double rtol, double atol, unsigned int diff_report_format, bool debug )
{
	// check dictionary size are equal
	int id1 = *dict_id1;
	int id2 = *dict_id2;
	int size1 = hash_s_d_size( id1 );
	int size2 = hash_s_d_size( id2 );
	if ( size1 != size2 )
	{
		fprintf( stderr, "[Error] dictionary size does not match %d != %d\n", size1, size2 );
		abort();
	}

	// compare value
	int i;
	int size = size1;
	int nan_count = 0;
	int diff_count = 0;
	size_t max_key_length = 0;
	char **keys1 = hash_s_d_get_keys( id1 );
	char *key;
	double val1;
	double val2;
	double vd_abs;
	double vd_ratio;
	double tol;
	double sum = 0.0;
	bool is_diff;
	compare_result_pair_t *results = (compare_result_pair_t *) malloc ( sizeof(compare_result_pair_t) * size );

	for ( i = 0; i < size; ++i )
	{
		if ( !hash_s_d_has_key( id2, keys1[i] ) )
		{
			fprintf( stderr, "[Error] there is no key '%s' in file %s\n", keys1[i], g_opts.input_file2 );
			abort();
		}

		key = keys1[i];
		val1 = hash_s_d_find( id1, key );
		val2 = hash_s_d_find( id2, key );
		vd_abs = fabs(val1 - val2);
		tol = rtol * fabs(val1);
		if ( vd_abs <= atol )
		{
			// there is no diff if difference lower than absolute tolerance
			is_diff = false;
			vd_ratio = 0.0;
		}
		else
		{
			if ( 0.0 == val1 )
			{
				// handle divide 0 
				is_diff = true;
				vd_ratio = NAN;
			}
			else if ( vd_abs <= tol )
			{
				// no diff
				is_diff = false;
				vd_ratio = (vd_abs / fabs(val1)) * 100.0;
			}
			else
			{
				// there is diff
				is_diff = true;
				vd_ratio = (vd_abs / fabs(val1)) * 100.0;
			}
		}

		results[i].key = strdup( key );
		results[i].val1 = val1;
		results[i].val2 = val2;
		results[i].vd_abs = vd_abs;
		results[i].vd_ratio = vd_ratio;
		results[i].tol = tol;
		results[i].is_diff = is_diff;

		// use in format print
		if ( strlen(key) > max_key_length )
		{
			max_key_length = strlen( key );
		}

		// use in summary
		if ( isnan(vd_ratio) )
		{
			++nan_count;
		}
		else
		{
			sum += vd_ratio;
		}
		if ( is_diff )
		{
			++diff_count;
		}

		if ( debug )
		{
			fprintf( stderr, "[Debug] diff %s %c: %.10e %.10e tol=%.10e vd_abs=%.10e vd_ratio=%.5lf%%\n", key, (is_diff ? 'Y' : 'N'), val1, val2, tol, vd_abs, vd_ratio );
		}
	}

	// sort descending according to difference ratio
	if ( diff_report_format & DIFF_SORT )
	{
		qsort( results, size, sizeof(compare_result_pair_t), qsort_result_compare_descending );
	}

	if ( diff_report_format & DIFF_SHOW_SUMMARY )
	{
		fprintf( fout, "* Diff Count (%%) = %.5lf (%d/%d)\n", (diff_count / (double)size) * 100, diff_count, size );
		if ( sum / (double)size > 1e3 )
		{
			fprintf( fout, "* Avg  Ratio (%%) = %.5e\n", sum / (double)size );
		}
		else
		{
			fprintf( fout, "* Avg  Ratio (%%) = %.5lf\n", sum / (double)size );
		}
		fprintf( fout, "* NAN  Count (%%) = %.5lf (%d/%d)\n", (nan_count / (double)size) * 100, nan_count, size );
		fprintf( fout, "-----------------------------------------------------\n" );
	}
	for ( i = 0; i < size; ++i )
	{
		if ( results[i].is_diff || (diff_report_format & DIFF_SHOW_ALL) )
		{
			fprintf( fout, "%-*s", (int) max_key_length, results[i].key );
			if ( diff_report_format & DIFF_SHOW_VALUE )
			{
				fprintf( fout, "  %.10e  %.10e", results[i].val1, results[i].val2 );
			}
			if ( diff_report_format & DIFF_SHOW_VD )
			{
				fprintf( fout, "  %.10e", results[i].vd_abs );
			}
			if ( diff_report_format & DIFF_SHOW_RATIO )
			{
				if ( results[i].vd_abs > 1e3 )
				{
					fprintf( fout, "  %5e", results[i].vd_ratio );
				}
				else
				{
					fprintf( fout, "  %8.5lf", results[i].vd_ratio );
				}
			}
			fprintf( fout, "\n" );
		}
	}
}

void read_two_column ( FILE *fin1, FILE *fin2, int *dict_id1, int *dict_id2, bool debug )
{
	read_two_column_yyin  = fin1;
	*dict_id1 = read_two_column_yylex ();
	if ( debug )
	{
		printf( "dict id1=%d:\n", *dict_id1 );
		hash_s_d_dump( *dict_id1 );

	}

	read_two_column_yyin  = fin2;
	*dict_id2 = read_two_column_yylex ();
	if ( debug )
	{
		printf( "dict id2=%d:\n", *dict_id2 );
		hash_s_d_dump( *dict_id2 );
	}
}

void read_spice_ic ( FILE *fin1, FILE *fin2, int *dict_id1, int *dict_id2, bool debug )
{
	read_spice_ic_yyin  = fin1;
	*dict_id1 = read_spice_ic_yylex ();
	if ( debug )
	{
		printf( "dict id1=%d:\n", *dict_id1 );
		hash_s_d_dump( *dict_id1 );

	}

	read_spice_ic_yyin  = fin2;
	*dict_id2 = read_spice_ic_yylex ();
	if ( debug )
	{
		printf( "dict id2=%d:\n", *dict_id2 );
		hash_s_d_dump( *dict_id2 );
	}
}

void read_sparse_matrix ( FILE *fin1, FILE *fin2, int *dict_id1, int *dict_id2, bool debug )
{
	read_sparse_matrix_yyin  = fin1;
	*dict_id1 = read_sparse_matrix_yylex ();
	if ( debug )
	{
		printf( "dict id1=%d:\n", *dict_id1 );
		hash_s_d_dump( *dict_id1 );

	}

	read_sparse_matrix_yyin  = fin2;
	*dict_id2 = read_sparse_matrix_yylex ();
	if ( debug )
	{
		printf( "dict id2=%d:\n", *dict_id2 );
		hash_s_d_dump( *dict_id2 );
	}
}

static int qsort_result_compare_descending ( const void *p, const void *q )
{
	compare_result_pair_t *pair_p = (compare_result_pair_t *) p;
	compare_result_pair_t *pair_q = (compare_result_pair_t *) q;

	if ( isnan(pair_p->vd_ratio) || isnan(pair_q->vd_ratio) )
	{
		// regard nan is smallest
		return 1;
	}
	else if ( pair_p->vd_ratio < pair_q->vd_ratio )
	{
		return 1;
	}
	else if ( pair_p->vd_ratio > pair_q->vd_ratio )
	{
		return -1;
	}
	else
	{
		return 0;
	}
}
