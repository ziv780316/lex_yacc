#ifndef OPTS_H
#define OPTS_H

typedef enum {
	TWO_COLUMN,
	RAW_ASCII,
	HSPICE_IC,
	DENSSE_MATRIX,
	SPARSE_MATRIX
} file_format;

#define DIFF_FORMAT_BITS 6
#define DIFF_TURN_ON_ALL 0x2f  // 111111
#define DIFF_SHOW_SUMMARY 0x20 // 100000
#define DIFF_SHOW_VALUE 0x10   // 010000
#define DIFF_SHOW_VD 0x8       // 001000
#define DIFF_SHOW_RATIO 0x4    // 000100
#define DIFF_SORT 0x2          // 000010
#define DIFF_SHOW_ALL 0x1      // 000001

typedef struct
{
	char *input_file1;
	char *input_file2;
	char *output_file;
	char *input_format_name;
	file_format input_format;
	unsigned int diff_format;
	double reltol;
	double abstol;
	bool debug;
} opt_t;

extern void show_help ();
extern void parse_cmd_options ( int argc, char **argv );
extern opt_t g_opts;

#endif
