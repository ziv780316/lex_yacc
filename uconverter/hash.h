#ifndef HASH_H
#define HASH_H

#include <stdbool.h>

// avoid C++ compiler name decoration
#ifdef __cplusplus
extern "C" 
{
#endif

typedef struct 
{
	char *key;
	double value;
} s_d_pair_t;

void sort_s_d_pairs ( s_d_pair_t *, int size, bool descending );

int hash_s_d_create (); // return dictionary id
void hash_s_d_check_id ( int id );
int hash_s_d_size ( int id ); // return dictionary size
void hash_s_d_insert ( int id, char *key, double value ); 
bool hash_s_d_has_key ( int id, char *key );
double hash_s_d_find ( int id, char *key );
char **hash_s_d_get_keys ( int id );
double *hash_s_d_get_values ( int id );
void hash_s_d_dump ( int id );
void hash_s_d_unit_test ();
s_d_pair_t *hash_s_d_get_pairs ( int i );

#ifdef __cplusplus
}; // end of extern "C"
#endif


#endif

