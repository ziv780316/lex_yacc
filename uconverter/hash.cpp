#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <vector>
#include <map>

#include "hash.h"

using std::vector;
using std::map;
using std::pair;

// avoid C++ compiler name decoration
extern "C" 
{

// define key compar in map<char *, double>
struct cmp_s_d_dict
{
	// map functor needs to return true on less-than and false otherwise
	bool operator() ( char const *a, char const *b ) const
	{
		return strcmp(a, b) < 0;
	}
};

static vector< map<char *, double, cmp_s_d_dict> > s_d_dict_vector;

static int qsort_s_d_compare_descending ( const void *p, const void *q ); // called in qsort
static int qsort_s_d_compare_ascending ( const void *p, const void *q ); 

static int qsort_s_d_compare_descending ( const void *p, const void *q )
{
	s_d_pair_t *pair_p = (s_d_pair_t *) p;
	s_d_pair_t *pair_q = (s_d_pair_t *) q;

	if ( pair_p->value < pair_q->value )
	{
		return 1;
	}
	else if ( pair_p->value > pair_q->value )
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

static int qsort_s_d_compare_ascending ( const void *p, const void *q )
{
	s_d_pair_t *pair_p = (s_d_pair_t *) p;
	s_d_pair_t *pair_q = (s_d_pair_t *) q;

	if ( pair_p->value < pair_q->value )
	{
		return -1;
	}
	else if ( pair_p->value > pair_q->value )
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

void sort_s_d_pairs ( s_d_pair_t *pairs, int size, bool descending )
{
	if ( descending )
	{
		qsort( pairs, size, sizeof(s_d_pair_t), qsort_s_d_compare_descending );
	}
	else
	{
		qsort( pairs, size, sizeof(s_d_pair_t), qsort_s_d_compare_ascending );
	}
}

void hash_s_d_check_id ( int id )
{
	if ( (id >= (int)s_d_dict_vector.size()) || (id < 0) )
	{
		fprintf( stderr, "[Error] invalid dictionary id %d (size=%zd)\n", id, s_d_dict_vector.size() );
		abort();
	}
}

int hash_s_d_create ()
{
	map<char *, double, cmp_s_d_dict> dict;
	s_d_dict_vector.push_back( dict );

	return s_d_dict_vector.size() - 1;
}

int hash_s_d_size ( int id )
{
	return s_d_dict_vector[id].size();
}

void hash_s_d_insert ( int id, char *key, double dval )
{
	s_d_dict_vector[id].insert( pair<char *, double>( strdup(key), dval ) );
}

bool hash_s_d_has_key ( int id, char *key )
{
	map<char *, double, cmp_s_d_dict> &dict = s_d_dict_vector[id];
	if ( dict.find( key ) == dict.end() )
	{
		return false;
	}
	else
	{
		return true;
	}
}

double hash_s_d_find ( int id, char *key )
{
	map<char *, double, cmp_s_d_dict> &dict = s_d_dict_vector[id];
	if ( dict.find( key ) == dict.end() )
	{
		fprintf( stderr, "[Error] there is no key '%s' in dict %d\n", key, id );
		abort();
	}
	else
	{
		return dict[key];
	}
}

char **hash_s_d_get_keys ( int id )
{
	int i = 0;
	map<char *, double, cmp_s_d_dict> &dict = s_d_dict_vector[id];
	int size = dict.size();
	char **keys = (char **) malloc ( sizeof(char*) * size );

	for( map<char *, double, cmp_s_d_dict>::iterator it = dict.begin(); it != dict.end(); ++it )
	{
		keys[i] = strdup( it->first );
		++i;
	}
	return keys;
}

double *hash_s_d_get_values ( int id )
{
	int i = 0;
	map<char *, double, cmp_s_d_dict> &dict = s_d_dict_vector[id];
	int size = dict.size();
	double *values = (double *) malloc ( sizeof(double) * size );

	for( map<char *, double, cmp_s_d_dict>::iterator it = dict.begin(); it != dict.end(); ++it )
	{
		values[i] = it->second;
		++i;
	}
	return values;
}

s_d_pair_t *hash_s_d_get_pairs ( int id )
{
	int i = 0;
	map<char *, double, cmp_s_d_dict> &dict = s_d_dict_vector[id];
	int size = dict.size();
	s_d_pair_t *pairs = (s_d_pair_t *) malloc ( sizeof(s_d_pair_t) * size );

	for( map<char *, double, cmp_s_d_dict>::iterator it = dict.begin(); it != dict.end(); ++it )
	{
		pairs[i].key = it->first;
		pairs[i].value = it->second;
		++i;
	}

	return pairs;
}

void hash_s_d_dump ( int id )
{
	int i;
	int size = hash_s_d_size( id );
	s_d_pair_t *pairs = hash_s_d_get_pairs( id );
	printf( "dict %d (size=%d):\n", id, size );
	for ( i = 0; i < size; ++i )
	{
		printf( "%s => %lf\n", pairs[i].key, pairs[i].value );
	}
}

void hash_s_d_unit_test ()
{
	char *s1 = strdup("abc");
	char *s2 = strdup("xxx");
	char *s3 = strdup("ddd");
	char *s4 = strdup("ziv");
	int id = hash_s_d_create();
	hash_s_d_insert( id, s1, 5.2 );
	hash_s_d_insert( id, s3, 6.33 );
	hash_s_d_insert( id, s4, -1.33 );
	printf( "size=%d\n", hash_s_d_size(id) );
	printf( "has_key(%s)=%d\n", s1, hash_s_d_has_key( id, strdup(s1) ) ); // if there is no self-defined cmp, this will fail on char * compare
	printf( "has_key(%s)=%d\n", s2, hash_s_d_has_key( id, s2 ) );
	printf( "has_key(%s)=%d\n", s3, hash_s_d_has_key( id, s3 ) );
	printf( "map[%s]=%lf\n", s1, hash_s_d_find( id, s1) );
	printf( "map[%s]=%lf\n", s3, hash_s_d_find( id, s3) );

	int i;
	int size = hash_s_d_size( id );
	char **keys = hash_s_d_get_keys( id );
	double *values = hash_s_d_get_values( id );
	for ( i = 0; i < size; ++i )
	{
		printf( "keys %s => %lf\n", keys[i], values[i] );
	}

	bool descending = true;
	s_d_pair_t *pairs = hash_s_d_get_pairs( id );
	sort_s_d_pairs( pairs, size, descending );
	printf( "descending sorted by values pairs:\n" );
	for ( i = 0; i < size; ++i )
	{
		printf( "(%s,%lf)\n", pairs[i].key, pairs[i].value );
	}

}

}; // end of extern "C"
