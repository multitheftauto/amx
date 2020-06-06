local amxfiles = {
	"amx/amx.c",
	"amx/amxaux.c",
	"amx/amxcons.c",
	"amx/amxcore.c",
	"amx/amxfile.c",
	"amx/amxstring.c",
	"amx/amxtime.c",
	"amx/float.c",
}

solution "ml_base"
	configurations { "Debug", "Release" }
	platforms { "x86", "x64" }
	location ( "Build" )
	targetdir "Bin/%{cfg.buildcfg}"

	cppdialect "C++17"
	characterset "MBCS"
	pic "On"
	symbols "On"

	defines {
		"_CRT_SECURE_NO_WARNINGS",
		"HAVE_STDINT_H",

		-- From original project, but causes crashes?
		-- "AMX_DONT_RELOCATE"
	}

	filter "system:windows"
		-- "__WIN32__" needed for amx
		defines { "WINDOWS", "WIN32", "__WIN32__" }

	filter "configurations:Debug"
		defines { "DEBUG" }

	filter "configurations:Release"
		optimize "Speed"

	project "ml_base"
		language "C++"
		kind "SharedLib"
		targetname "ml_base"

		includedirs { "include" }
		libdirs { "lib" }

		vpaths {
			["Headers/*"] = "**.h",
			["Sources/*"] = {"**.cpp", amxfiles},
			["Resources/*"] = "king.rc",

			["*"] = "premake5.lua",
		}

		files {
			"premake5.lua",
			"**.cpp",
			"**.h",
			"king.rc",
			amxfiles
		}

		filter {"system:linux", "platforms:x86" }
			linkoptions { "-Wl,-rpath=mods/deathmatch" }

		filter {"system:linux", "platforms:x64" }
			linkoptions { "-Wl,-rpath=x64" }

		filter "system:linux"
			linkoptions { "-l:lua5.1.so" }

		filter "system:windows"
			links { "lua5.1", "sqlite3" }

			-- for amx
			links { "winmm" }
