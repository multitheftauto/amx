#ifndef _STDINC_H
#define _STDINC_H

#if defined(_WIN32) || defined(WIN32) || defined(__WIN32__) || defined(_WIN64)
    #define WIN32_LEAN_AND_MEAN
	#include <windows.h>
#elif defined(LINUX) || defined(FREEBSD) || defined(__FreeBSD__) || defined(__OpenBSD__)
	#include <dlfcn.h>
#endif

#include <stdio.h>
#include <cstdarg>
#include <cstring>
#include <list>
#include <map>
#include <set>
#include <string>
#include <vector>
#include <variant>

#include "Common.h"
#include "lua/ILuaModuleManager.h"
#include "sqlite/sqlite3.h"
#include "sha256/sha256.h"

extern "C"
{
    #include "amx/amx.h"
    #include "amx/amxaux.h"

    int AMXEXPORT amx_CoreInit(AMX *amx);
	int AMXEXPORT amx_ConsoleInit(AMX *amx);
	int AMXEXPORT amx_FloatInit(AMX *amx);
	int AMXEXPORT amx_StringInit(AMX *amx);
	int AMXEXPORT amx_TimeInit(AMX *amx);
	int AMXEXPORT amx_FileInit(AMX *amx);

	int AMXEXPORT amx_CoreCleanup(AMX *amx);
	int AMXEXPORT amx_ConsoleCleanup(AMX *amx);
	int AMXEXPORT amx_FloatCleanup(AMX *amx);
	int AMXEXPORT amx_StringCleanup(AMX *amx);
	int AMXEXPORT amx_TimeCleanup(AMX *amx);
	int AMXEXPORT amx_FileCleanup(AMX *amx);

    #include "lua/lua.h"
    #include "lua/lualib.h"
    #include "lua/lauxlib.h"
	#include "lua/lobject.h"
};

#include "ml_base.h"
#include "util.h"

extern "C"
{
	#include "natives/sqlite.c"
	int AMXEXPORT amx_sampDbInit(AMX *amx);
	int AMXEXPORT amx_sampDbCleanup(AMX *amx);

    #include "natives/misc.c"
	int AMXEXPORT amx_sampMiscInit(AMX *amx);
	int AMXEXPORT amx_sampMiscCleanup(AMX *amx);
}

#include "CFunctions.h"

#endif
