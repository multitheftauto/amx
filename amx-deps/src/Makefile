#### Start of system configuration section ####

ASM = nasm
CC = gcc
LD = gcc
PROG = pawn.so
CXX = gcc
CPP = gcc

# Compiler flags
# NOTE: add -g for debug, remove for release!
ASMFLAGS = -O1 -f elf -I./amx/
CPPFLAGS = -MD -O2 -Wall -I./ -l./lua -l./sqlite -I./amx -I./sha256 -I./linux -DAMX_DONT_RELOCATE -DFLOATPOINT
LDFLAGS = -fPIC -s -shared -Wl,-soname,$(PROG).1,-R./
LIBS = -lpthread -lstdc++ -llua5.1 -lsqlite3

#### End of system configuration section ####

#### Source and object files

SRC_AMXASM = ./amx/amxexecn.asm
OBJ_AMXASM = $(patsubst %.asm,%.o,$(SRC_AMXASM))

SRC_AMX =  ./amx/amxargs.c  ./amx/amxaux.c  ./amx/amx.c  ./amx/amxcons.c  ./amx/amxcore.c  ./amx/amxdbg.c  ./amx/amxdgram.c  ./amx/amx_exec.c  ./amx/amxexec_gcc.c  ./amx/amxfile.c  ./amx/amxfixed.c  ./amx/amxfloat.c  ./amx/amxgc.c  ./amx/amxpool.c  ./amx/amxprocess.c  ./amx/amxstring.c  ./amx/amxtime.c  ./amx/amx_verifier.c  ./amx/dllmain.c  ./amx/fixed.c  ./amx/float.c  ./amx/fpattern.c  ./amx/keeloq.c  ./amx/minIni.c  ./amx/pawndbg.c  ./amx/pawnrun.c  ./amx/term_ga.c  ./amx/termwin.c
SRC_LUA = ./lua/lapi.c  ./lua/lauxlib.c  ./lua/lbaselib.c  ./lua/lcode.c  ./lua/ldblib.c  ./lua/ldebug.c  ./lua/ldo.c  ./lua/ldump.c  ./lua/lfunc.c  ./lua/lgc.c  ./lua/linit.c  ./lua/liolib.c  ./lua/llex.c  ./lua/lmathlib.c  ./lua/lmem.c  ./lua/loadlib.c  ./lua/lobject.c  ./lua/lopcodes.c  ./lua/loslib.c  ./lua/lparser.c  ./lua/lstate.c  ./lua/lstring.c  ./lua/lstrlib.c  ./lua/ltable.c  ./lua/ltablib.c  ./lua/ltm.c  ./lua/lundump.c  ./lua/lutf8lib.c  ./lua/lvm.c  ./lua/lzio.c  ./lua/print.c
SRC_SQLITE =  ./sqlite/sqlite3.c  ./sqlite/sqlite_amx.c
SRC_SHA256 = ./sha256/sha256.cpp
OBJ_AMX = $(patsubst %.c,%.o,$(SRC_AMX))

SRC_LOCAL =	$(wildcard ./*.cpp) $(wildcard ./linux/*.c)
OBJ_LOCAL =	$(patsubst %.cpp,%.o,$(patsubst %.c,%.o,$(SRC_LOCAL)))

CPPSRCS	= $(SRC_LOCAL) $(SRC_AMX) $(SRC_LUA) $(SRC_SQLITE) $(SRC_SHA256)
CPPOBJS	= $(OBJ_AMX) $(OBJ_LOCAL)
ASMSRCS = $(SRC_AMXASM)
ASMOBJS = $(OBJ_AMXASM)
DEPS	= $(patsubst %.o,%.d,$(OBJS))

#### Make rules

all : pawnasm pawn

pawnasm :
	$(ASM) $(ASMFLAGS) $(ASMSRCS)

pawn : $(CPPOBJS)
	$(CC) $(CPPFLAGS) $(LDFLAGS) -o $(PROG) $(CPPOBJS) $(ASMOBJS) $(LIBS)

clean :
	-rm *.d
	-rm *.o
	-rm ./amx/*.o
	-rm ./amx/*.d
	-rm ./linux/*.o
	-rm ./linux/*.d
	-rm ./lua/*.o
	-rm ./lua/*.d
	-rm ./sqlite/*.o
	-rm ./sqlite/*.d
	-rm $(PROG)

-include $(DEPS)
