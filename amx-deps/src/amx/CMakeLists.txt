project(pawnamx C)
cmake_minimum_required(VERSION 2.8.11 FATAL_ERROR)


option(PAWN_USE_64BIT_CELLS "Use 64-bit cells (default: 32)" OFF)

# Allow the user to choose between the new interpreter core and the old ones.
option(PAWN_USE_NEW_AMXEXEC "Use the new interpreter core (amx_Exec)" ON)

# Add an option to build AMX extensions as static libraries
option(PAWN_AMX_EXTS_STATIC "Build AMX extension modules as static libraries" ON)
if(PAWN_AMX_EXTS_STATIC)
  set(PAWNAMX_PRIVATE_COMPILE_DEFINITIONS ${PAWNAMX_PRIVATE_COMPILE_DEFINITIONS} "-DAMX_NODYNALOAD")
endif()

include("${CMAKE_CURRENT_SOURCE_DIR}/../cmake/shared-properties.cmake")

# Only relocate P-Code on supported compilers
set(PAWNAMX_RELOCATE_PCODE FALSE)
foreach(COMPILER_ID "GNU" "Clang" "Intel")
  if(CMAKE_CC_COMPILER_ID MATCHES COMPILER_ID)
    set(PAWNAMX_RELOCATE_PCODE TRUE)
  endif()
endforeach()
# Also disable relocation if Pawn cell can't fit a pointer
if(PAWNAMX_RELOCATE_PCODE)
  math(EXPR PAWNAMX_POINTER_SIZE "${CMAKE_SIZEOF_VOID_P} * 8")
  if(PAWNAMX_POINTER_SIZE GREATER PAWNAMX_CELL_SIZE)
    set(PAWNAMX_RELOCATE_PCODE FALSE)
  endif()
endif()
if(NOT PAWNAMX_RELOCATE_PCODE)
  set(PAWNAMX_PRIVATE_COMPILE_DEFINITIONS ${PAWNAMX_PRIVATE_COMPILE_DEFINITIONS} "-DAMX_DONT_RELOCATE")
endif()

# Get rid of some useless warning messages
if(WIN32 AND MSVC)
  add_definitions("/D_CRT_SECURE_NO_WARNINGS")
  set(PAWNAMX_PRIVATE_COMPILE_OPTIONS ${PAWNAMX_PRIVATE_COMPILE_OPTIONS} "/wd4996")
endif()
if(CMAKE_C_COMPILER_ID MATCHES "Clang")
  set(PAWNAMX_PRIVATE_COMPILE_OPTIONS ${PAWNAMX_PRIVATE_COMPILE_OPTIONS} "-w")
endif()

if(MINGW)
  set(PAWNAMX_PRIVATE_COMPILE_OPTIONS ${PAWNAMX_PRIVATE_COMPILE_OPTIONS} "-std=gnu90")
endif()

# Set shared include paths
set(PAWNAMX_PUBLIC_INCLUDE_DIRECTORIES ${PAWNAMX_PUBLIC_INCLUDE_DIRECTORIES} "${CMAKE_CURRENT_SOURCE_DIR}")

# Include "source/linux" on Unix-like systems
if(UNIX)
  set(PAWNAMX_PUBLIC_INCLUDE_DIRECTORIES ${PAWNAMX_PUBLIC_INCLUDE_DIRECTORIES} "${CMAKE_CURRENT_SOURCE_DIR}/../linux")
endif()

if(WIN32)
  if(NOT BORLAND)
    link_libraries(winmm)
  endif()
endif()

set(PAWNAMX_PUBLIC_COMPILE_DEFINITIONS ${SHARED_COMPILE_DEFINITIONS} "-DFLOATPOINT")

# Check include files availability
set(REQUIRED_INCLUDE_FILES
  "float.h"
  "tchar.h"
  "utime.h"
  "sys/unistd.h"
  "fcntl.h"
  "sys/fcntl.h"
  "sys/sendfile.h"
)
foreach(INCLUDE_FILE ${REQUIRED_INCLUDE_FILES})
  string(REGEX REPLACE "\\.|/" "_" DEFINITION_NAME "HAVE_${INCLUDE_FILE}")
  string(TOUPPER ${DEFINITION_NAME} DEFINITION_NAME)
  check_include_file("${INCLUDE_FILE}" ${DEFINITION_NAME})
  if(${DEFINITION_NAME})
    set(PAWNAMX_PUBLIC_COMPILE_DEFINITIONS ${PAWNAMX_PUBLIC_COMPILE_DEFINITIONS} "-D${DEFINITION_NAME}")
  endif()
endforeach()

# --------------------------------------------------------------------------
# AMX static library
set(PAWNAMX_SRCS
  "amx.h"
  "amx_internal.h"
  "amx_opcodes.h"
  "amx.c"
  "amx_exec.c"
  "amx_verifier.c"
  "amxaux.h"
  "amxaux.c"
  "amxdbg.h"
  "amxdbg.c"
  "osdefs.h"
)
if(UNIX)
  set(PAWNAMX_SRCS "${PAWNAMX_SRCS}"
    "../linux/binreloc.h"
    "../linux/binreloc.c"
    "../linux/getch.h"
    "../linux/getch.c"
  )
  set(PAWNAMX_PRIVATE_COMPILE_DEFINITIONS ${PAWNAMX_PRIVATE_COMPILE_DEFINITIONS} "-DENABLE_BINRELOC")
endif()
if(NOT PAWN_AMX_EXTS_STATIC OR WIN32)
  add_library(pawnamx STATIC ${PAWNAMX_SRCS})
else()
  add_library(pawnamx SHARED ${PAWNAMX_SRCS})
endif()
if(UNIX AND NOT APPLE AND NOT PAWN_AMX_EXTS_STATIC)
  target_link_libraries(pawnamx dl)
  target_link_libraries(amxDGram ws2_32)
  set(PAWNAMX_PRIVATE_COMPILE_OPTIONS ${PAWNAMX_PRIVATE_COMPILE_OPTIONS} "-fPIC")
endif()
target_compile_options(pawnamx PRIVATE ${PAWNAMX_PRIVATE_COMPILE_OPTIONS})
target_compile_definitions(pawnamx PRIVATE ${PAWNAMX_PRIVATE_COMPILE_DEFINITIONS})
target_compile_definitions(pawnamx PUBLIC ${PAWNAMX_PUBLIC_COMPILE_DEFINITIONS})
target_include_directories(pawnamx PUBLIC ${PAWNAMX_PUBLIC_INCLUDE_DIRECTORIES})


# --------------------------------------------------------------------------
# Extension modules
set(AMX_STATIC_EXTS_LIST "")

function(pawnamx_find_curses)
  if(NOT PAWNAMX_SEEKED_CURSES)
    set(PAWNAMX_SEEKED_CURSES TRUE CACHE INTERNAL "")
    if(NOT WIN32)
      include("FindCurses")
      set(CURSES_FOUND ${CURSES_FOUND} PARENT_SCOPE)
      if(CURSES_FOUND)
        set(COMPILE_FLAGS "-DUSE_CURSES")
        if(CURSES_HAVE_CURSES_H)
          set(COMPILE_FLAGS "${COMPILE_FLAGS} -DHAVE_CURSES_H")
        elseif(CURSES_HAVE_NCURSES_H)
          set(COMPILE_FLAGS "${COMPILE_FLAGS} -DHAVE_NCURSES_H")
        elseif(CURSES_HAVE_NCURSES_NCURSES_H)
          set(COMPILE_FLAGS "${COMPILE_FLAGS} -DHAVE_NCURSES_NCURSES_H")
        elseif(CURSES_HAVE_NCURSES_CURSES_H)
          set(COMPILE_FLAGS "${COMPILE_FLAGS} -DHAVE_NCURSES_CURSES_H")
        endif()
        set(CURSES_COMPILE_FLAGS ${COMPILE_FLAGS})
        set(CURSES_INCLUDE_DIR ${CURSES_INCLUDE_DIR})
        set(CURSES_LIBRARIES ${CURSES_LIBRARIES})
      endif()
    endif()
  endif()
endfunction()

function(add_amx_ext_module NAME ENABLED SOURCES)
  string(TOUPPER ${NAME} UPPERCASE_NAME)
  if(${NAME} STREQUAL "Core" OR ${NAME} STREQUAL "Console")
    # Modules Core and Console are neither shared nor optional
    set(PAWN_AMX_EXT_${UPPERCASE_NAME} ON)
  else()
    option(PAWN_AMX_EXT_${UPPERCASE_NAME} "Enable AMX extension module ${NAME}" ${ENABLED})
  endif()
  if(PAWN_AMX_EXT_${UPPERCASE_NAME})
    string(TOLOWER ${NAME} LOWERCASE_NAME)
    set(SOURCES ${SOURCES} "amx.h")
    set(MODULE_STATIC ${PAWN_AMX_EXTS_STATIC})
    if(NOT MODULE_STATIC)
      if(${NAME} STREQUAL "Core" OR ${NAME} STREQUAL "Console")
        set(MODULE_STATIC ON)
      endif()
    endif()
    if(MODULE_STATIC)
      add_library(amx${NAME} STATIC ${SOURCES})
      set(AMX_STATIC_EXTS_LIST "${AMX_STATIC_EXTS_LIST}" "amx${NAME}" PARENT_SCOPE)
    else() # MODULE_STATIC
      if(WIN32)
        set(SOURCES ${SOURCES} "dllmain.c")
        file(GLOB FILE_VAR "amx${LOWERCASE_NAME}.rc")
        if(FILE_VAR)
          set(SOURCES ${SOURCES} "amx${LOWERCASE_NAME}.rc")
        endif()
      endif() # WIN32
      add_library(amx${NAME} SHARED ${SOURCES})
      if(WIN32)
        if(BORLAND)
          # Borland linker uses a DEF file if one is in the output directory
          configure_file("${CMAKE_CURRENT_SOURCE_DIR}/amx${LOWERCASE_NAME}.def"
                         "${CMAKE_BINARY_DIR}/amx${LOWERCASE_NAME}.def"
                         COPYONLY
          )
        elseif(MSVC)
          # For Microsoft Visual C/C++ we can set explicit flags for exports
          set(EXPORT_FLAGS "/export:amx_${NAME}Init /export:amx_${NAME}Cleanup")
          if(${NAME} STREQUAL "Args")
            set(EXPORT_FLAGS "${EXPORT_FLAGS} /export:amx_ArgsSetCmdLine")
          endif()
          set_property(TARGET amx${NAME} APPEND_STRING
            PROPERTY LINK_FLAGS "${EXPORT_FLAGS}")
        elseif(MINGW)
          set_property(TARGET amx${NAME} APPEND_STRING
            PROPERTY LINK_FLAGS "-Wl,-k")
        endif()
      endif() # WIN32
    endif() # MODULE_STATIC
    if(${NAME} STREQUAL "DGram")
      if(WIN32)
        target_link_libraries(amx${NAME} wsock32)
      endif()
    elseif(${NAME} STREQUAL "Console")
      pawnamx_find_curses()
      if(CURSES_FOUND)
        set_property(TARGET amx${NAME} APPEND_STRING
          PROPERTY COMPILE_FLAGS " ${CURSES_COMPILE_FLAGS}")
        target_include_directories(amx${NAME} PRIVATE ${CURSES_INCLUDE_DIR})
        target_link_libraries(amx${NAME} ${CURSES_LIBRARIES})
      endif()
    endif()
    target_link_libraries(amx${NAME} pawnamx)
    set_property(TARGET amx${NAME} PROPERTY PREFIX "")
  endif() # PAWN_AMX_EXT_${UPPERCASE_NAME}
endfunction()

add_amx_ext_module("Core" ON "amxcore.c")
add_amx_ext_module("Float" ON "float.c")
add_amx_ext_module("Args" ON "amxargs.c")
add_amx_ext_module("DGram" ON "amxdgram.c")
add_amx_ext_module("Console" ON "amxcons.h;amxcons.c")
add_amx_ext_module("String" ON "amxcons.h;amxcons.c;amxstring.c")
add_amx_ext_module("Time" ON "amxtime.c")
add_amx_ext_module("File" ON "amxfile.c;minini/dev/minGlue.h;minini/dev/minIni.h;minini/dev/minIni.c;amx_ptrarray.h")
#add_amx_ext_module("Process" OFF "amxprocess.c")

option(PAWN_AMX_EXT_CONSOLE_IDLE "Enable @keypressed() callback in AMX extension module Console" ON)
if(NOT PAWN_AMX_EXT_CONSOLE_IDLE)
  set_property(TARGET amxConsole APPEND_STRING PROPERTY COMPILE_FLAGS " -DAMXCONSOLE_NOIDLE")
endif()
option(PAWN_AMX_EXT_TIME_IDLE "Enable @timer() callback in AMX extension module Time" ON)
if(PAWN_AMX_EXT_TIME)
  if(NOT PAWN_AMX_EXT_TIME_IDLE)
    set_property(TARGET amxTime APPEND_STRING PROPERTY COMPILE_FLAGS " -DAMXTIME_NOIDLE")
  endif()
endif()


option(PAWN_BUILD_PAWNRUN "Build the example run-time program and the debugger" ON)
if(PAWN_BUILD_PAWNRUN)
# --------------------------------------------------------------------------
# Simple run-time (example program)
  set(PAWNRUN_SRCS "pawnrun.c")
  add_executable(pawnrun ${PAWNRUN_SRCS})
  set_property(TARGET pawnrun APPEND_STRING PROPERTY COMPILE_FLAGS "-DAMXDBG")
  target_link_libraries(pawnrun pawnamx ${AMX_STATIC_EXTS_LIST})

# --------------------------------------------------------------------------
# Simple console debugger
  set(PAWNDBG_SRCS "pawndbg.c")
  add_executable(pawndbg ${PAWNDBG_SRCS})
  target_link_libraries(pawndbg pawnamx ${AMX_STATIC_EXTS_LIST})
  pawnamx_find_curses()
  if(CURSES_FOUND)
    set_property(TARGET pawndbg APPEND_STRING
      PROPERTY COMPILE_FLAGS " ${CURSES_COMPILE_FLAGS}")
    target_include_directories(pawndbg PRIVATE ${CURSES_INCLUDE_DIR})
    target_link_libraries(pawndbg ${CURSES_LIBRARIES})
  endif()
endif()
