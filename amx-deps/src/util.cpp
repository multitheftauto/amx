#include "StdInc.h"
#include "UTF8.h"
#include <cstdlib>
#include <filesystem>

using namespace std;
namespace fs = std::filesystem;

extern map < AMX *, AMXPROPS > loadedAMXs;

int setenv_portable(const char* name, const char* value, int overwrite) {
#if defined(_WIN32) || defined(WIN32) || defined(__WIN32__) || defined(_WIN64)
	if (!overwrite) {
		const char* envvar = getenv_portable(name);
		if (envvar != NULL) {
			return 1; //It's not null, we succeeded, don't set it
		}
	} //Otherwise continue and set it anyway
	return _putenv_s(name, value);
#elif defined(LINUX) || defined(FREEBSD) || defined(__FreeBSD__) || defined(__OpenBSD__)
	return setenv(name, value, overwrite);
#endif
}

//Credit: https://stackoverflow.com/questions/4130180/how-to-use-vs-c-getenvironmentvariable-as-cleanly-as-possible
const char* getenv_portable(const char* name)
{
#if defined(_WIN32) || defined(WIN32) || defined(__WIN32__) || defined(_WIN64)
	const DWORD buffSize = 65535;
	static char buffer[buffSize];
	if (GetEnvironmentVariableA(name, buffer, buffSize))
	{
		return buffer;
	}
	else
	{
		return 0;
	}
#elif defined(LINUX) || defined(FREEBSD) || defined(__FreeBSD__) || defined(__OpenBSD__)
	return getenv(name);
#endif
}

#ifndef WIN32
	void *getProcAddr ( HMODULE hModule, const char *szProcName )
	{
		char *szError = NULL;
		dlerror ();
		void *pFunc = dlsym ( hModule, szProcName );
		if ( ( szError = dlerror () ) != NULL )
			return NULL;
		return pFunc;
	}
#endif

std::string ToUTF8(const char * str)
{
	int strLen = strlen(str);
	int newstrLen = mbstowcs(NULL, str, strLen);
	wchar_t *dest = new wchar_t[newstrLen+1];

	mbstowcs(dest, str, strLen);
	dest[newstrLen] = 0;
	std::string newstr = utf8_wcstombs(dest);
	delete[] dest;
	return newstr;
}

std::string ToOriginalCP(const char * str)
{
    /*iconv_t conv = iconv_open("CP1251","UTF-8");
    iconv(conv, (const char**)&str, (size_t*)&strLen, &pOut, (size_t*)&newstrLen);
    iconv_close(conv);*/

	std::wstring newstr = utf8_mbstowcs(str);

	int strLen = strlen(str);
	int newstrLen = wcstombs(NULL, newstr.c_str(), newstr.length());
	char *dest = new char[newstr.length()+1];

	wcstombs(dest, newstr.c_str(), newstr.length());
	dest[newstr.length()] = 0;

	std::string retstr = dest;
    delete[] dest;
	return retstr;
}

void lua_pushamxstring(lua_State* luaVM, AMX* amx, cell *physaddr) {
	if(!physaddr) {
		lua_pushnil(luaVM);
		return;
	}

	int strLen;
	amx_StrLen(physaddr, &strLen);

	char *str = new char[strLen+1];
	amx_GetString(str, physaddr, 0, strLen+1);

	std::string newstr = ToUTF8(str);

	lua_pushlstring(luaVM, newstr.c_str(), newstr.length());
	delete[] str;
}



void lua_pushamxstring(lua_State *luaVM, AMX *amx, cell addr) {
	cell *physaddr;

	amx_GetAddr(amx, addr, &physaddr);
	lua_pushamxstring(luaVM, amx, physaddr);
}

void lua_pushremotevalue(lua_State *localVM, lua_State *remoteVM, int index, bool toplevel) {
	bool seenTableList = false;

	switch(lua_type(remoteVM, index)) {
		case LUA_TNIL: {
			lua_pushnil(localVM);
			break;
		}
		case LUA_TBOOLEAN: {
			lua_pushboolean(localVM, lua_toboolean(remoteVM, index));
			break;
		}
		case LUA_TNUMBER: {
			lua_pushnumber(localVM, lua_tonumber(remoteVM, index));
			break;
		}
		case LUA_TSTRING: {
			size_t len;
			const char *str = lua_tolstring(remoteVM, index, &len);
			std::string newstr = ToUTF8(str);
			lua_pushlstring(localVM, newstr.c_str(), newstr.length());
			break;
		}
		case LUA_TTABLE: {
			if(toplevel && !seenTableList) {
				lua_newtable(localVM);
				lua_setfield(localVM, LUA_REGISTRYINDEX, "_dstSeenTables");
				lua_newtable(remoteVM);
				lua_setfield(remoteVM, LUA_REGISTRYINDEX, "_srcSeenTables");
				seenTableList = true;
			}

			if(index < 0)
				index = lua_gettop(remoteVM) + index + 1;

			lua_getfield(remoteVM, LUA_REGISTRYINDEX, "_srcSeenTables");

			lua_pushvalue(remoteVM, index);
			lua_gettable(remoteVM, -2);
			if(!lua_isnil(remoteVM, -1)) {
				lua_Number tblNum = lua_tonumber(remoteVM, -1);
				lua_pop(remoteVM, 2);
				lua_getfield(localVM, LUA_REGISTRYINDEX, "_dstSeenTables");
				lua_pushnumber(localVM, tblNum);
				lua_gettable(localVM, -2);
				lua_remove(localVM, -2);
				break;
			}
			lua_pop(remoteVM, 1);

			lua_newtable(localVM);
			lua_getfield(localVM, LUA_REGISTRYINDEX, "_dstSeenTables");
			lua_Number tblNum = lua_objlen(localVM, -1) + 1;
			lua_pushnumber(localVM, tblNum);
			lua_pushvalue(localVM, -3);
			lua_settable(localVM, -3);
			lua_pop(localVM, 1);

			lua_pushvalue(remoteVM, index);
			lua_pushnumber(remoteVM, tblNum);
			lua_settable(remoteVM, -3);
			lua_pop(remoteVM, 1);

			lua_pushnil(remoteVM);
			while(lua_next(remoteVM, index)) {
				lua_pushremotevalue(localVM, remoteVM, -2, false);
				lua_pushremotevalue(localVM, remoteVM, -1, false);
				lua_settable(localVM, -3);
				lua_pop(remoteVM, 1);
			}
			break;
		}
		case LUA_TUSERDATA:
		case LUA_TLIGHTUSERDATA: {
			lua_pushlightuserdata(localVM, lua_touserdata(remoteVM, index));
			break;
		}
		default: {
			lua_pushboolean(localVM, 0);
			break;
		}
	}
	if(toplevel && seenTableList) {
		lua_pushnil(localVM);
		lua_setfield(localVM, LUA_REGISTRYINDEX, "_dstSeenTables");
		lua_pushnil(remoteVM);
		lua_setfield(remoteVM, LUA_REGISTRYINDEX, "_srcSeenTables");
	}
}

void lua_pushremotevalues(lua_State *localVM, lua_State *remoteVM, int num) {
	for(int i = -num; i < 0; i++) {
		lua_pushremotevalue(localVM, remoteVM, i);
	}
}

vector<AMX *> getResourceAMXs(lua_State *luaVM) {
	vector<AMX *> amxs;
	for (const auto& it : loadedAMXs) {
		if (it.second.resourceVM == luaVM)
			amxs.push_back(it.first);
	}
	return amxs;
}

string getScriptFilePath(AMX *amx, const char *filename) {
	if(!isSafePath(filename) || loadedAMXs.find(amx) == loadedAMXs.end())
		return string();

	// First check if it exists in the resource folder
	fs::path respath = loadedAMXs[amx].filePath;
	respath = respath.remove_filename() / filename;
	if(exists(respath))
		return respath.string();

	// Then check if it exists in the main scriptfiles folder
	fs::path scriptfilespath = fs::path(std::format("{}/resources/scriptfiles", RESOURCE_PATH)) / filename;
	if(exists(scriptfilespath))
	{
		return scriptfilespath.string();
	}

	// Otherwise default to amx's resource folder - make sure the folder
	// where the file is expected exists
	fs::path folder = respath;
	folder.remove_filename();
	create_directories(folder);
	return respath.string();
}

extern "C" char* getScriptFilePath(AMX *amx, char *dest, const char *filename, size_t destsize) {
	if(!isSafePath(filename))
		return 0;

	string path = getScriptFilePath(amx, filename);
	if(!path.empty() && path.size() < destsize) {
		strcpy(dest, path.c_str());
		return dest;
	} else {
		return 0;
	}
}

bool isSafePath(const char *path) {
	return path && !strstr(path, "..") && !strchr(path, ':') && !strchr(path, '|') && path[0] != '\\' && path[0] != '/';
}

extern "C" int set_amxstring(AMX *amx,cell amx_addr,const char *source,int max)
{
  cell* dest = (cell *)(amx->base + (int)(((AMX_HEADER *)amx->base)->dat + amx_addr));
  cell* start = dest;
  while (max--&&*source)
    *dest++=(cell)*source++;
  *dest = 0;
  return dest-start;
}

#define CHECK_PARAMS(num,func) if (params[0] != (num * sizeof(cell))) { logprintf("%s: Bad parameter count (Count is %d, Should be %d)", func, params[0] / sizeof(cell), num); return 0; }
