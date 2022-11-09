solution "pawn"
	configurations { "Debug", "Release" }
	platforms { "x86", "x64" }
	location ( "Build" )
	targetdir "Bin"

	cppdialect "C++17"
	characterset "MBCS"
	pic "On"
	symbols "On"

	defines {
		"_CRT_SECURE_NO_WARNINGS",
		"HAVE_STDINT_H",
	}

	filter "system:windows"
		defines { "WINDOWS", "WIN32" }

	filter "configurations:Debug"
		defines { "DEBUG" }

	filter "configurations:Release"
		optimize "Speed"

	project "ml_base"
		language "C++"
		kind "SharedLib"
		targetname "pawn"

		includedirs { "lua","sqlite","sqlite","amx" }
		libdirs { "lib" }

		vpaths {
			["Headers/*"] = {"*.h", "**/*.h"},
			["Sources/*"] = {"**.cpp"},
			["Resources/*"] = "pawn.rc",

			["*"] = "premake5.lua",
		}

		files {
			"premake5.lua",
			"**.cpp",
			"*.h",
			"**/*.h",
		}

		filter "system:windows"
			files { "pawn.rc" }

		filter "system:linux"
			includedirs { "linux" }

		filter {"system:linux", "platforms:x86" }
			linkoptions { "-Wl,-rpath=mods/deathmatch" }

		filter {"system:linux", "platforms:x64" }
			linkoptions { "-Wl,-rpath=x64" }

		filter "system:linux"
			linkoptions { "-l:lua5.1.so" }

		filter "system:windows"
			links { "lua5.1", "sqlite3" }

		filter {}
			links "amx"

	include "amx"
