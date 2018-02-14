#ifndef HASH_HXX_H
#define HASH_HXX_H

#ifdef __cplusplus
extern "C" 
{
#endif

#include <stdbool.h>

typedef enum
{
	NODE_EMPTY,
	NODE_DOUBLE,
	NODE_STRING
} NODE_TYPE;

typedef union 
{
	double dval;
	char *sval;
} val_union;

typedef struct 
{
	NODE_TYPE type;
	val_union val;
} Node;

Node symbol_table_lookup( char *name );
void symbol_table_insert( char *name, Node );
void symbol_table_delete( char *name );
	
#ifdef __cplusplus
};
#endif

#endif
