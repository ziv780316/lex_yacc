#ifndef OPTS_H
#define OPTS_H

typedef enum {
	RAW_ASCII
} raw_type;

typedef enum {
	WAVEFORM_SPICE3
} waveform_type;

typedef struct
{
	char *input_file;
	char *output_file;
	raw_type input_format;
	waveform_type output_format;
	bool debug;
} opt_t;

extern void show_help ();
extern void parse_cmd_options ( int argc, char **argv );
extern opt_t g_opts;

#endif
