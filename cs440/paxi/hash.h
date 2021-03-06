/* Author: Jon Morton */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


struct symbol {
	// Required symbol table symbol values
	char *name;
	int type;
	int size;
	int location;

	// Enable separate chaining in symbol table
	struct symbol* next;
};

unsigned int key(char*);

extern struct symbol** setupSymbolTable();

extern int insert(struct symbol**, char*, int type, int size, int location);

extern struct symbol* lookup(struct symbol**, char*);
