#include "hash.hxx"
#include <map>
#include <string>

using std::map;
using std::string;

map<string, Node> sym_table;

Node symbol_table_lookup( char *name )
{
	map<string, Node>::iterator it;

	it = sym_table.find( string(name) );
	if ( sym_table.end() != it )
	{
		return it->second;
	}
	else
	{
		Node tmp_node = { .type = NODE_EMPTY, .val={.sval = NULL} };
		return tmp_node;
	}
}

void symbol_table_insert( char *name, Node node )
{
	sym_table[ string(name) ] = node;
}

void symbol_table_delete( char *name )
{
	if ( NODE_EMPTY != symbol_table_lookup( name ).type )
	{
		sym_table.erase( string(name) );
	}
}
