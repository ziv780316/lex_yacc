#ifndef OPTS_H
#define OPTS_H

typedef enum {
	RAW_ASCII,
	MM_RHS_LIST,  		// matrix-market format RHS list
	MM_SPARSE,    		// matrix-market format sparse matrix
	MM_SPARSE_REORDER,    
	SPARSE_TRIPLET,
	SPARSE_CSC,
	MATRIX_DENSE_ASCII, 
	WAVEFORM_SPICE3
} file_format;

typedef enum {
	AUXILIARY_NONE,
	AUXILIARY_SORT_SPARSE_BY_ROW,
	AUXILIARY_INDEX_SPARSE_BY_NAME
} auxiliary_format;

typedef struct
{
	char *input_file;
	char *output_file;
	char *input_format_name;
	char *output_format_name;
	file_format input_format;
	file_format output_format;
	auxiliary_format aux_format;
	bool debug;
} opt_t;

extern void show_help ();
extern void parse_cmd_options ( int argc, char **argv );
extern opt_t g_opts;

#endif
