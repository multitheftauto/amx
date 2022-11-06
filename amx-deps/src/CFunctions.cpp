/*********************************************************
*
*  Multi Theft Auto: San Andreas - Deathmatch
*
*  ml_base, External lua add-on module
*
*  Copyright © 2003-2008 MTA.  All Rights Reserved.
*
*  Grand Theft Auto is © 2002-2003 Rockstar North
*
*  THE FOLLOWING SOURCES ARE PART OF THE MULTI THEFT
*  AUTO SOFTWARE DEVELOPMENT KIT AND ARE RELEASED AS
*  OPEN SOURCE FILES. THESE FILES MAY BE USED AS LONG
*  AS THE DEVELOPER AGREES TO THE LICENSE THAT IS
*  PROVIDED WITH THIS PACKAGE.
*
*********************************************************/

#include "StdInc.h"
#include <filesystem>

using namespace std;
namespace fs = std::filesystem;

extern ILuaModuleManager10 *pModuleManager;

int amx_SAMPInit(AMX *amx);

typedef unsigned int (STDCALL Supports_t) ();
typedef int  (STDCALL AmxLoad_t)          (AMX *);
typedef int  (STDCALL AmxUnload_t)        (AMX *);
typedef bool (STDCALL Load_t)             (void**);
typedef void (STDCALL Unload_t)           ();

#define SAMP_PLUGIN_VERSION 0x0200

enum SUPPORTS_FLAGS
{
	SUPPORTS_VERSION = SAMP_PLUGIN_VERSION,
	SUPPORTS_VERSION_MASK = 0xffff,
	SUPPORTS_AMX_NATIVES = 0x10000,
	SUPPORTS_PROCESS_TICK = 0x20000
};

struct SampPlugin
{
	HMODULE pPluginPointer = nullptr;

	SUPPORTS_FLAGS	dwSupportFlags = (SUPPORTS_FLAGS)0;

	Unload_t		*Unload = nullptr;

	AmxLoad_t		*AmxLoad = nullptr;
	AmxUnload_t		*AmxUnload = nullptr;
};

extern void *pluginInitData[];
extern lua_State *mainVM;

map< AMX *, AMXPROPS > loadedAMXs;
map< string, SampPlugin* > loadedPlugins;
vector<ProcessTick_t*> vecPfnProcessTick;

AMX *suspendedAMX = NULL;

// amxLoadPlugin(pluginName)
bool CFunctions::amxLoadPlugin(lua_State *luaVM) {
	if(!luaVM) return;
	static const char *requiredExports[] = { "Load", "Unload", "Supports", 0 };

	const char *pluginName = luaL_checkstring(luaVM, 1);
	if(!pluginName || loadedPlugins.find(pluginName) != loadedPlugins.end() || !isSafePath(pluginName)) {
		lua_pushboolean(luaVM, 0);
		return false;
	}

	string pluginPath = std::format("{}/resources/plugins/", RESOURCE_PATH);
	pluginPath += pluginName;
	#ifdef WIN32
		pluginPath += ".dll";
	#else
		pluginPath += ".so";
	#endif

	HMODULE hPlugin = loadLib(pluginPath.c_str());

	if(hPlugin == NULL) {
		lua_pushboolean(luaVM, 0);
		return false;
	}

	bool hasAllReqFns = true;
	for(const char **fnName = requiredExports; *fnName; fnName++) {
		if(!getProcAddr(hPlugin, *fnName)) {
			pModuleManager->ErrorPrintf("  Plugin \"%s\" does not export required function %s\n", pluginName, *fnName);
			hasAllReqFns = false;
		}
	}
	if(!hasAllReqFns) {
		freeLib(hPlugin);
		lua_pushboolean(luaVM, 0);
		return false;
	}

	printf("  Loading plugin: %s\n", pluginName);

	Load_t* pfnLoad = (Load_t *)getProcAddr(hPlugin, "Load");
	Supports_t* pfnSupports = (Supports_t *)getProcAddr(hPlugin, "Supports");

	if(pfnLoad == NULL || pfnSupports == NULL) {
		print("  Plugin does not conform to architecture.");
		freeLib(hPlugin);
		lua_pushboolean(luaVM, 0);
		return false;
	}

	SampPlugin* pSampPlugin = new SampPlugin;
	pSampPlugin->pPluginPointer = hPlugin;
	pSampPlugin->Unload = (Unload_t*)getProcAddr(pSampPlugin->pPluginPointer, "Unload");
	pSampPlugin->dwSupportFlags = (SUPPORTS_FLAGS)pfnSupports();

	if ((pSampPlugin->dwSupportFlags & SUPPORTS_VERSION_MASK) != SUPPORTS_VERSION)
	{
		printf("  Unsupported version - This plugin requires version %x.", (pSampPlugin->dwSupportFlags & SUPPORTS_VERSION_MASK));
		freeLib(pSampPlugin->pPluginPointer);
		lua_pushboolean(luaVM, 0);
		return false;
	}

	if ((pSampPlugin->dwSupportFlags & SUPPORTS_AMX_NATIVES) != 0)
	{
		pSampPlugin->AmxLoad = (AmxLoad_t *)getProcAddr(pSampPlugin->pPluginPointer, "AmxLoad");
		pSampPlugin->AmxUnload = (AmxUnload_t *)getProcAddr(pSampPlugin->pPluginPointer, "AmxUnload");
	}
	else {
		pSampPlugin->AmxLoad = NULL;
		pSampPlugin->AmxUnload = NULL;
	}

	if ((pSampPlugin->dwSupportFlags & SUPPORTS_PROCESS_TICK) != 0)
	{
		vecPfnProcessTick.push_back((ProcessTick_t *)getProcAddr(pSampPlugin->pPluginPointer, "ProcessTick"));
	}

	if(!pfnLoad(pluginInitData)) {
		freeLib(pSampPlugin->pPluginPointer);
		lua_pushboolean(luaVM, 0);
		return false;
	}

	loadedPlugins[pluginName] = pSampPlugin;
	printf("  Loaded.");

	lua_pushboolean(luaVM, 1);
	return true;
}

// amxIsPluginLoaded(pluginName)
int CFunctions::amxIsPluginLoaded(lua_State *luaVM) {
	if(!luaVM) return;
	const char *pluginName = luaL_checkstring(luaVM, 1);
	if(loadedPlugins.find(pluginName) != loadedPlugins.end())
		lua_pushboolean(luaVM, 1);
	else
		lua_pushboolean(luaVM, 0);
	return 1;
}

// amxLoad(resName, amxName)
int CFunctions::amxLoad(lua_State *luaVM) {
	if(!luaVM) return;
	const char *resName = luaL_checkstring(luaVM, 1);
	const char *amxName = luaL_checkstring(luaVM, 2);
	const int *isGamemode = luaL_checknumber(luaVM, 3);
	if(!resName || !isSafePath(resName) || !amxName || !isSafePath(amxName) || !isGamemode) {
		lua_pushboolean(luaVM, 0);
		return 1;
	}

	lua_State* theirLuaVM = pModuleManager->GetResourceFromName(resName);
	if (theirLuaVM == nullptr) {
		using namespace std::string_literals;
		std::string errMsg = std::format("[Pawn]: resource {} does not exist!", resName);
		lua_pushboolean(luaVM, false);
		lua_pushstring(luaVM, errMsg.c_str());
		return 2;
	}

	char amxPath[256];
	if (!pModuleManager->GetResourceFilePath(theirLuaVM, ((isGamemode == 1 ? 'gamemodes' : 'filterscripts') + '/' + amxName), amxPath, 256))
	{
		lua_pushboolean(luaVM, false);
		lua_pushstring(luaVM, "[Pawn]: File not found");
		return 2;
	}

	// Load .amx
	AMX *amx = new AMX;
	int  err = aux_LoadProgram(amx, amxPath, NULL);
	/*if(err == AMX_ERR_SLEEP) {
		//
	}
	else */if(err != AMX_ERR_NONE) {
		delete amx;
		lua_pushboolean(luaVM, 0);
		pModuleManager->ErrorPrintf("[Pawn]: Failed to load '%s' script.", amxPath);
		return 1;
	}

	// Register sa-mp and plugin natives
	amx_CoreInit(amx);
	amx_ConsoleInit(amx);
	amx_FloatInit(amx);
	amx_StringInit(amx);
	amx_TimeInit(amx);
	amx_FileInit(amx);
	amx_sampDbInit(amx);
	err = amx_SAMPInit(amx);
	for (const auto& plugin : loadedPlugins) {
		AmxLoad_t* pfnAmxLoad = plugin.second->AmxLoad;
		if (pfnAmxLoad) {
			err = pfnAmxLoad(amx);
		}
	}

	if(err != AMX_ERR_NONE) {
		AMX_HEADER *header = (AMX_HEADER *)amx->base;
		AMX_FUNCSTUBNT *func = (AMX_FUNCSTUBNT *)((BYTE *)amx->base + header->natives);
		while( func != ((AMX_FUNCSTUBNT *)((BYTE *)amx->base + header->libraries)) ) {
			if(func->address == NULL || func->address == 0)
				pModuleManager->ErrorPrintf("  Function not registered: '%s'\n", (char *)amx->base + func->nameofs);
			func++;
		}
		aux_FreeProgram(amx);
		amx_sampDbCleanup(amx);
		amx_CoreCleanup(amx);
		amx_TimeCleanup(amx);
		amx_FileCleanup(amx);
		amx_StringCleanup(amx);
		amx_FloatCleanup(amx);
		amx_ConsoleCleanup(amx);
		delete amx;
		lua_pushboolean(luaVM, 0);
		return 1;
	}

	// Save info about the amx
	AMXPROPS props;
	props.filePath = amxPath;
	props.resourceName = resName;
	props.resourceVM = theirLuaVM;

	lua_register(props.resourceVM, "pawn", CFunctions::pawn);
	loadedAMXs[amx] = props;

	lua_getfield(luaVM, LUA_REGISTRYINDEX, "amx");
	lua_getfield(luaVM, -1, resName);
	if(lua_isnil(luaVM, -1)) {
		lua_newtable(luaVM);
		lua_setfield(luaVM, -3, resName);
	}

	// All done
	lua_pushlightuserdata(luaVM, amx);
	return 1;
}

// amxCall(amxptr, fnName|fnIndex, arg1, arg2, ...)
int CFunctions::amxCall(lua_State *luaVM) {
	if(!luaVM) return;
	AMX *amx = (AMX *)lua_touserdata(luaVM, 1);
	if(!amx) {
		pModuleManager->ErrorPrintf("[Pawn]: invalid AMX parameter -> Load\n");
		lua_pushboolean(luaVM, 0);
		return 1;
	}

	// Get the function to call
	int fnIndex;
	if(lua_isnumber(luaVM, 2)) {
		fnIndex = (int)lua_tonumber(luaVM, 2);
	} else if(amx_FindPublic(amx, luaL_checkstring(luaVM, 2), &fnIndex) != AMX_ERR_NONE) {
		lua_pushboolean(luaVM, 0);
		return 1;
	}

	// Collect the arguments
	vector<cell> stringsToRelease;
	for(int i = lua_gettop(luaVM); i > 2; i--) {
		switch(lua_type(luaVM, i)) {
			case LUA_TNIL: {
				amx_Push(amx, 0);
				break;
			}
			case LUA_TBOOLEAN: {
				amx_Push(amx, lua_toboolean(luaVM, i));
				break;
			}
			case LUA_TNUMBER: {
				std::string str = lua_tostring(luaVM, i);
				if(str.find(".")!=std::string::npos)
				{
					float fval = lua_tonumber(luaVM, i);
					cell val = *(cell*)&fval;
					amx_Push(amx, val);
				}
				else
				{
					amx_Push(amx, (cell)lua_tonumber(luaVM, i));
				}
				break;
			}
			case LUA_TSTRING: {
				cell amxStringAddr;
				cell *physStringAddr;
				std::string newstr = ToOriginalCP(lua_tostring(luaVM, i));
				amx_PushString(amx, &amxStringAddr, &physStringAddr, newstr.c_str(), 0, 0);
				stringsToRelease.push_back(amxStringAddr);
				break;
			}
			default: {
				amx_Push(amx, 0);
				break;
			}
		}
	}

	// Do the call
	cell ret;
	int err = amx_Exec(amx, &ret, fnIndex);
	// Release string arguments
	for (const auto& amxStringAddr : stringsToRelease) {
		amx_Release(amx, amxStringAddr);
	}
	if(err != AMX_ERR_NONE) {
		if(err == AMX_ERR_SLEEP)
			lua_pushstring(luaVM, "suspended");
		else
			lua_pushboolean(luaVM, 0);
		return 1;
	}

	// Return value
	lua_pushnumber(luaVM, ret);
	return 1;
}

// amxMTReadDATCell(t, addr)
// __index metamethod
int CFunctions::amxMTReadDATCell(lua_State *luaVM) {
	if(!luaVM) return;
	luaL_checktype(luaVM, 1, LUA_TTABLE);
	cell addr = (cell)luaL_checknumber(luaVM, 2);
	lua_getfield(luaVM, 1, "amx");
	AMX *amx = (AMX *)lua_touserdata(luaVM, -1);
	if(!amx)
		return 0;
	cell *physaddr;
	amx_GetAddr(amx, addr, &physaddr);
	if(!physaddr)
		return 0;
	lua_pushnumber(luaVM, *physaddr);
	return 1;
}

// amxMTWriteCell(t, addr, value)
// __newindex metamethod
int CFunctions::amxMTWriteDATCell(lua_State *luaVM) {
	if(!luaVM) return;
	luaL_checktype(luaVM, 1, LUA_TTABLE);
	cell addr = (cell)luaL_checknumber(luaVM, 2);
	cell value = (cell)luaL_checknumber(luaVM, 3);
	lua_getfield(luaVM, 1, "amx");
	AMX *amx = (AMX *)lua_touserdata(luaVM, -1);
	if(!amx)
		return 0;
	cell *physaddr;
	amx_GetAddr(amx, addr, &physaddr);
	if(!physaddr)
		return 0;
	*physaddr = value;
	return 0;
}

// amxReadString(amxptr, addr, maxlen)
int CFunctions::amxReadString(lua_State *luaVM) {
	if(!luaVM) return;
	AMX *amx = (AMX *)lua_touserdata(luaVM, 1);
	if(!amx)
		return 0;
	const cell addr = (cell)lua_tonumber(luaVM, 2);
	lua_pushamxstring(luaVM, amx, addr);
	return 1;
}

// amxWriteString(amxptr, addr, str)
int CFunctions::amxWriteString(lua_State *luaVM) {
	if(!luaVM) return;
	AMX *amx = (AMX *)lua_touserdata(luaVM, 1);
	if(!amx)
		return 0;
	const cell addr = (cell)lua_tonumber(luaVM, 2);
	const char *str = luaL_checkstring(luaVM, 3);
	std::string newstr = ToOriginalCP(str);
	cell* physaddr;
	amx_GetAddr(amx, addr, &physaddr);
	if(!physaddr)
		return 0;
	amx_SetString(physaddr, newstr.c_str(), 0, 0, UNLIMITED);
	lua_pushboolean(luaVM, 1);
	return 1;
}

// amxUnload(amxptr)
int CFunctions::amxUnload(lua_State *luaVM) {
	if(!luaVM) return;
	AMX *amx = (AMX *)lua_touserdata(luaVM, 1);
	if(!amx) {
		pModuleManager->ErrorPrintf("[Pawn]: invalid AMX parameter -> Unload\n");
		lua_pushboolean(luaVM, 0);
		return 1;
	}
	// Call all plugins' AmxUnload function
	for (const auto& plugin : loadedPlugins) {
		AmxUnload_t *pfnAmxUnload = plugin.second->AmxUnload;
		if (pfnAmxUnload) {
			pfnAmxUnload(amx);
		}
	}

	// Unload
	aux_FreeProgram(amx);
	amx_sampDbCleanup(amx);
	amx_CoreCleanup(amx);
	amx_TimeCleanup(amx);
	amx_FileCleanup(amx);
	amx_StringCleanup(amx);
	amx_FloatCleanup(amx);
	amx_ConsoleCleanup(amx);

	lua_getfield(luaVM, LUA_REGISTRYINDEX, "amx");
	lua_pushnil(luaVM);
	lua_setfield(luaVM, -2, loadedAMXs[amx].resourceName.c_str());
	loadedAMXs.erase(amx);
	delete amx;
	lua_pushboolean(luaVM, 1);
	return 1;
}

// amxUnloadAllPlugins()
int CFunctions::amxUnloadAllPlugins(lua_State *luaVM) {
	if(!luaVM) return;
	for (const auto& plugin : loadedPlugins) {
		Unload_t* Unload = plugin.second->Unload;
		if (Unload) {
			Unload();
		}
		freeLib(plugin.second->pPluginPointer);
		delete plugin.second;
	}
	loadedPlugins.clear();
	vecPfnProcessTick.clear();

	lua_pushboolean(luaVM, 1);
	return 1;
}

// amxRegisterLuaPrototypes({ [fnName] = {'s', 'i', 'f'}, ... })
int CFunctions::amxRegisterLuaPrototypes(lua_State *luaVM) {
	luaL_checktype(luaVM, 1, LUA_TTABLE);
	int mainTop = lua_gettop(mainVM);

	char resName[255];
	pModuleManager->GetResourceName(luaVM, resName, 255);
	lua_getfield(mainVM, LUA_REGISTRYINDEX, "amx");
	lua_getfield(mainVM, -1, resName);
	if(lua_isnil(mainVM, -1)) {
		lua_pop(mainVM, 1);
		lua_newtable(mainVM);
		lua_pushvalue(mainVM, -1);
		lua_setfield(mainVM, -3, resName);
	}

	lua_newtable(mainVM);
	lua_pushnil(luaVM);
	while(lua_next(luaVM, 1)) {
		if(!lua_istable(luaVM, -1)) {
			lua_settop(mainVM, mainTop);
			return luaL_error(luaVM, "[Pawn]: table expected as prototype for \"%s\" -> RegisterLuaPrototypes", lua_tostring(luaVM, -2));
		}

		lua_getglobal(luaVM, "string");
		lua_getfield(luaVM, -1, "match");
		lua_remove(luaVM, -2);
		lua_pushvalue(luaVM, -3);
		lua_pushstring(luaVM, "([^:]+):?(.*)");
		lua_pcall(luaVM, 2, 2, 0);
		if(lua_objlen(luaVM, -1) == 0) {
			// No return type
			lua_insert(luaVM, -2);
		}

		lua_pushvalue(luaVM, -1);
		lua_gettable(luaVM, LUA_GLOBALSINDEX);
		if(!lua_isfunction(luaVM, -1)) {
			lua_settop(mainVM, mainTop);
			return luaL_error(luaVM, "[Pawn]: no function named \"%s\" exists -> RegisterLuaPrototypes", lua_tostring(luaVM, -3));
		}
		lua_pop(luaVM, 1);

		lua_pushremotevalue(mainVM, luaVM, -1);
		lua_pushremotevalue(mainVM, luaVM, -3);
		if(lua_objlen(luaVM, -2) > 0) {
			lua_newtable(mainVM);
			lua_pushnumber(mainVM, 1);
			lua_pushremotevalue(mainVM, luaVM, -2);
			lua_settable(mainVM, -3);
			lua_setfield(mainVM, -2, "ret");
		}
		lua_settable(mainVM, -3);
		lua_pop(luaVM, 3);
	}

	lua_setfield(mainVM, -2, "luaprototypes");
	lua_settop(mainVM, mainTop);
	lua_pushboolean(luaVM, 1);
	return 1;
}

// pawn(fnName, ...)
int CFunctions::pawn(lua_State *luaVM) {
	if(!luaVM) return;
	vector<AMX *> amxs = getResourceAMXs(luaVM);
	if(amxs.empty()) {
		lua_pushboolean(luaVM, 0);
		return 1;
	}

	const char *fnName = luaL_checkstring(luaVM, 1);
	int numFnParams = lua_gettop(luaVM) - 1;

	int fnIndex;
	AMX *amx = NULL;
	for (const auto& it : amxs) {
		if(amx_FindPublic(it, fnName, &fnIndex) == AMX_ERR_NONE) {
			amx = it;
			break;
		}
	}
	if(!amx)
		return luaL_error(luaVM, "[Pawn]: Function \"%s\" doesn't exist", fnName);

	int mainTop = lua_gettop(mainVM);

	char resName[255];
	pModuleManager->GetResourceName(luaVM, resName, 255);
	lua_getfield(mainVM, LUA_REGISTRYINDEX, "amx");
	lua_getfield(mainVM, -1, resName);
	if(lua_isnil(mainVM, -1)) {
		lua_settop(mainVM, mainTop);
		return luaL_error(luaVM, "[Pawn]: resource %s is not an AMX resource", resName);
	}
	lua_getfield(mainVM, -1, "pawnprototypes");
	if(lua_isnil(mainVM, -1)) {
		lua_settop(mainVM, mainTop);
		return luaL_error(luaVM, "[Pawn]: resource %s does not have any registered Pawn functions - see amxRegisterPawnPrototypes", resName);
	}
	lua_getfield(mainVM, -1, fnName);
	if(lua_isnil(mainVM, -1)) {
		lua_settop(mainVM, mainTop);
		return luaL_error(luaVM, "[Pawn]: function %s is not registered", lua_tostring(luaVM, 1));
	}

	lua_remove(mainVM, -2);
	lua_remove(mainVM, -2);
	lua_remove(mainVM, -2);

	lua_pushcfunction(mainVM, CFunctions::amxCall);
	lua_pushlightuserdata(mainVM, amx);
	lua_pushnumber(mainVM, fnIndex);
	lua_getglobal(mainVM, "unpack");
	lua_getglobal(mainVM, "argsToSAMP");
	lua_pushlightuserdata(mainVM, amx);
	lua_pushvalue(mainVM, -7);
	for(int i = 0; i < numFnParams; i++) {
		lua_pushremotevalue(mainVM, luaVM, 2 + i);
	}
	lua_pcall(mainVM, 2 + numFnParams, 1, 0);		// argsToSAMP
	lua_pcall(mainVM, 1, numFnParams, 0);			// unpack
	if(lua_pcall(mainVM, 2 + numFnParams, 1, 0))	// amxCall
		return luaL_error(luaVM, lua_tostring(mainVM, -1));

	lua_getfield(mainVM, -2, "ret");
	if(!lua_isnil(mainVM, -1)) {
		lua_getglobal(mainVM, "argsToMTA");
		lua_pushlightuserdata(mainVM, amx);
		lua_pushvalue(mainVM, -3);
		lua_pushvalue(mainVM, -5);
		lua_pcall(mainVM, 3, 1, 0);
		lua_pushnumber(mainVM, 1);
		lua_gettable(mainVM, -2);
	}

	lua_pushremotevalue(luaVM, mainVM, -1);
	lua_settop(mainVM, mainTop);
	return 1;
}

// amxVersion()
int CFunctions::amxVersion(lua_State *luaVM) {
	if(!luaVM) return;
	lua_pushnumber(luaVM, MODULE_VERSION);
	return 1;
}

// amxVersionString()
int CFunctions::amxVersionString(lua_State *luaVM) {
	if(!luaVM) return;
	lua_pushstring(luaVM, MODULE_VERSIONSTRING);
	return 1;
}

// cell2float(cell)
int CFunctions::cell2float(lua_State *luaVM) {
	if(!luaVM) return;
	cell c = (cell)luaL_checknumber(luaVM, 1);
	lua_pushnumber(luaVM, *(float *)&c);
	return 1;
}

// float2cell(float)
int CFunctions::float2cell(lua_State *luaVM) {
	if(!luaVM) return;
	float f = (float)luaL_checknumber(luaVM, 1);
	lua_pushnumber(luaVM, *(cell *)&f);
	return 1;
}
