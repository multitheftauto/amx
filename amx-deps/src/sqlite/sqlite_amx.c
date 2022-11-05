#include <stdio.h>
#include <malloc.h>
#include <string.h>

#include "../amx/amx.h"
#include "sqlite3.h"

//--------------------------------------------------------------------------------------

typedef struct _SQLiteResult
{
	int nRows;
	int nColumns;
	char **pResults;
	char *szErrMsg;
	int nCurrentRow;

} SQLiteResult;

//--------------------------------------------------------------------------------------

int set_amxstring(AMX *amx,cell amx_addr,const char *source,int max)
{
  cell* dest = (cell *)(amx->base + (int)(((AMX_HEADER *)amx->base)->dat + amx_addr));
  cell* start = dest;
  while (max--&&*source)
    *dest++=(cell)*source++;
  *dest = 0;
  return dest-start;
}

//--------------------------------------------------------------------------------------

// native SQLiteDB:sqlite_open(name[]);
static cell AMX_NATIVE_CALL n_open(AMX* amx, cell* params)
{
	char *szDBName, szPathName[260];
	int errorCode, i;
	sqlite3 *sqlite;

	// Get the db filename
	amx_StrParam(amx, params[1], szDBName);
	
	// ensure the name doesn't start with a '/' or '\\' on win32
	if (szDBName[0] == '\\' || szDBName[0] == '/')
	{
		//logprintf(NATIVE_PREFIX "open - Warning: Database name can not start with %c", szDBName[0]);
		return 0;
	}

	// ensure there are no ".." in dbname, and no :
	for(i=1; szDBName[i]!=0; i++)
	{
		if (szDBName[i-1] == '.' && szDBName[i] == '.')
		{
			//logprintf(NATIVE_PREFIX "open - Warning: Database name can not contain '..'");
			return 0;
		}
	}

	// ensure there are no : in the file
	for(i=0; szDBName[i]!=0; i++)
	{
		if (szDBName[i] == ':')
		{
			//logprintf(NATIVE_PREFIX "open - Warning: Database name can not contain ':'");
			return 0;
		}
	}

	// Create the pathname string
	sprintf(szPathName, "scriptfiles/%s", szDBName);

	// Open the database
	errorCode = sqlite3_open(szPathName, &sqlite);

	if (errorCode != SQLITE_OK)
	{
		sqlite3_close(sqlite);
		return 0;
	}

	return (cell) sqlite;
}

// native sqlite_close(SQLiteDB:db);
static cell AMX_NATIVE_CALL n_close(AMX* amx, cell* params)
{
	int errorCode;
	sqlite3 *sqlite;

	sqlite = (sqlite3 *)params[1];

	errorCode = sqlite3_close(sqlite);

	if (errorCode != SQLITE_OK)
		return 0;

	sqlite = NULL;

	return 1;
}


// native SQLiteResult:sqlite_query(SQLiteDB:db, query[]);
static cell AMX_NATIVE_CALL n_query(AMX* amx, cell* params)
{
	char *szQuery;
	SQLiteResult *result;
	int errorCode;
	sqlite3 *sqlite;

	sqlite = (sqlite3 *)params[1];

	if (!sqlite)
	{
		//logprintf(NATIVE_PREFIX "query() - Warning: Invalid database handle provided.\n");
		return 0;
	}

	// Get the query
	amx_StrParam(amx, params[2], szQuery);

	// Create a result struct
	result = (SQLiteResult *)malloc(sizeof(SQLiteResult));
	result->nCurrentRow = 0;

	// Execute the query and grab the results
	errorCode = sqlite3_get_table(sqlite, szQuery, &(result->pResults), &(result->nRows), &(result->nColumns), &(result->szErrMsg));

	// Check to make sure we succeeded
	if (errorCode != SQLITE_OK)
	{
		//logprintf(NATIVE_PREFIX "query() - Warning: Query failed: %s\n", result->szErrMsg);
		free(result);
		return 0;
	}

	// If we suceeded, return the result
	return (cell) result;
}

// native sqlite_free_result(SQLiteResult:result)
static cell AMX_NATIVE_CALL n_free_result(AMX* amx, cell* params)
{
	SQLiteResult *result;

	result = (SQLiteResult *)params[1];
	
	if (!result)
	{
		//logprintf(NATIVE_PREFIX "free_result() - Warning: Invalid result set\n");
		return 0;
	}

	if (result->pResults)
		sqlite3_free_table(result->pResults);
	
	if (result->szErrMsg)
		sqlite3_free(result->szErrMsg);

	free(result);

	return 1;
}


// native sqlite_num_rows(SQLiteResult:result)
static cell AMX_NATIVE_CALL n_num_rows(AMX* amx, cell* params)
{
	SQLiteResult *result;

	result = (SQLiteResult *)params[1];
	
	if (!result)
	{
		//logprintf(NATIVE_PREFIX "num_rows() - Warning: Invalid result set\n");
		return 0;
	}

	return result->nRows;
}

// native sqlite_next_row(SQLiteResult:result)
static cell AMX_NATIVE_CALL n_next_row(AMX* amx, cell* params)
{
	SQLiteResult *result;
	
	result = (SQLiteResult *)params[1];
	
	if (!result)
	{
		//logprintf(NATIVE_PREFIX "next_row() - Warning: Invalid result set\n");
		return 0;
	}

	// Are we on the last row?
	if (result->nCurrentRow == (result->nRows - 1))
	{
		return 0;
	}

	// Increment to the next row
	result->nCurrentRow++;

	return 1;
}

// native sqlite_num_fields(SQLiteResult:result)
static cell AMX_NATIVE_CALL n_num_fields(AMX* amx, cell* params)
{
	SQLiteResult *result;
	
	result = (SQLiteResult *)params[1];

	if (!result)
	{
		//logprintf(NATIVE_PREFIX "num_fields() - Warning: Invalid result set\n");
		return 0;
	}

	return result->nColumns;
}

// native sqlite_field_name(SQLiteResult:result, field, fieldname[], maxlength = sizeof fieldname );
static cell AMX_NATIVE_CALL n_field_name(AMX* amx, cell* params)
{
	SQLiteResult *result;
	int field;
	
	result = (SQLiteResult *)params[1];

	if (!result)
	{
		//logprintf(NATIVE_PREFIX "field_name() - invalid result set\n");
		return 0;
	}

	field = (int) params[2];
	if (field < 0 || field >= result->nColumns)
	{
		// exceeds the number of columns
		set_amxstring(amx, params[3], "", params[4]);
		return 0;
	}

	set_amxstring(amx, params[3], result->pResults[field], params[4]);

	return 1;
}

// native sqlite_get_field(SQLiteResult:result, field, fieldvalue[], maxlength = sizeof fieldvalue );
static cell AMX_NATIVE_CALL n_get_field(AMX* amx, cell* params)
{
	SQLiteResult *result;
	int field;
	
	result = (SQLiteResult *)params[1];

	if (!result)
	{
		//logprintf(NATIVE_PREFIX "get_field() - Warning: Invalid result set\n");
		return 0;
	}

	field = (int) params[2];
	if (field < 0 || field >= result->nColumns)
	{
		// exceeds the number of columns
		set_amxstring(amx, params[3], "", params[4]);
		return 0;
	}

	set_amxstring(amx, params[3], result->pResults[result->nColumns * (result->nCurrentRow+1) + field], params[4]);

	return 1;
}

// native sqlite_get_field_assoc(SQLiteResult:result, const field[], fieldvalue[], maxlength = sizeof fieldvalue );
static cell AMX_NATIVE_CALL n_get_field_assoc(AMX* amx, cell* params)
{
	SQLiteResult *result;
	int field, i;
	char *szFieldName;
	
	result = (SQLiteResult *)params[1];

	if (!result)
	{
		//logprintf(NATIVE_PREFIX "get_field_assoc() - Warning: Invalid result set\n");
		return 0;
	}

	// Figure out the field index
	amx_StrParam(amx, params[2], szFieldName);

	field = -1;
	for(i = 0; i<result->nColumns; i++)
	{
		if (strcmp(szFieldName, result->pResults[i]) == 0)
		{
			field = i;
			break;
		}
	}

	if (field < 0 || field >= result->nColumns)
	{
		set_amxstring(amx, params[3], "", params[4]);
		return 0;
	}

	set_amxstring(amx, params[3], result->pResults[result->nColumns * (result->nCurrentRow+1) + field], params[4]);

	return 1;
}


/*
 native DB:db_open(name[]);
 native db_close(DB:db);
 native DBResult:db_query(DB:db,query[]);
 native db_free_result(DBResult:result);
 native db_num_rows(DBResult:result);
 native db_next_row(DBResult:result);
 native db_num_fields(DBResult:result);
 native db_field_name(DBResult:result, field, result[], maxlength);
 native db_get_field(DBResult:result, field, result[], maxlength);
 native db_get_field_assoc(DBResult:result, const field[], result[], maxlength);
*/

#if defined __cplusplus
  extern "C"
#endif
AMX_NATIVE_INFO sampDb_Natives[] = {
  { "db_open",			n_open },
  { "db_close",			n_close },
  { "db_query",			n_query },
  { "db_free_result",	n_free_result },
  { "db_num_rows",		n_num_rows },
  { "db_next_row",      n_next_row },
  { "db_num_fields",    n_num_fields },
  { "db_field_name",    n_field_name },
  { "db_get_field",		n_get_field },
  { "db_get_field_assoc", n_get_field_assoc },
  { NULL, NULL }        /* terminator */
};

int AMXEXPORT amx_sampDbInit(AMX *amx)
{
	return amx_Register(amx, sampDb_Natives, -1);
}

int AMXEXPORT amx_sampDbCleanup(AMX *amx)
{
	return AMX_ERR_NONE;
}
