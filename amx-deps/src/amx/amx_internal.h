/*  Pawn Abstract Machine (for the Pawn language)
 *  Declarations and definitions for internal use in the Abstract Machine.
 *
 *  Portions copyright (c) Stanislav Gromov, 2016-2022
 *
 *  This code was derived from code carrying the following copyright notice:
 *
 *  Copyright (c) ITB CompuPhase, 1997-2008
 *
 *  This software is provided "as-is", without any express or implied warranty.
 *  In no event will the authors be held liable for any damages arising from
 *  the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, subject to the following restrictions:
 *
 *  1.  The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software. If you use this software in
 *      a product, an acknowledgment in the product documentation would be
 *      appreciated but is not required.
 *  2.  Altered source versions must be plainly marked as such, and must not be
 *      misrepresented as being the original software.
 *  3.  This notice may not be removed or altered from any source distribution.
 */

#ifndef AMX_INTERNAL_H_INCLUDED
#define AMX_INTERNAL_H_INCLUDED


#include "amx_opcodes.h"

#if !defined AMX_DONT_RELOCATE
  #if (!defined AMX_PTR_SIZE) || (AMX_PTR_SIZE>PAWN_CELL_SIZE)
    #define AMX_DONT_RELOCATE
  #endif
#endif

/* When one or more of the AMX_funcname macros are defined, we want
 * to compile only those functions. However, when none of these macros
 * is present, we want to compile everything.
 */
#if defined AMX_ALIGN       || defined AMX_ALLOT        || defined AMX_CLEANUP
  #define AMX_EXPLIT_FUNCTIONS
#endif
#if defined AMX_CLONE        || defined AMX_DEFCALLBACK || defined AMX_EXEC
  #define AMX_EXPLIT_FUNCTIONS
#endif
#if defined AMX_FLAGS       || defined AMX_GETADDR      || defined AMX_INIT
  #define AMX_EXPLIT_FUNCTIONS
#endif
#if defined AMX_MEMINFO     || defined AMX_NAMELENGTH   || defined AMX_NATIVEINFO
  #define AMX_EXPLIT_FUNCTIONS
#endif
#if defined AMX_PUSHXXX     || defined AMX_RAISEERROR   || defined AMX_REGISTER
  #define AMX_EXPLIT_FUNCTIONS
#endif
#if defined AMX_SETCALLBACK || defined AMX_SETDEBUGHOOK || defined AMX_XXXNATIVES
  #define AMX_EXPLIT_FUNCTIONS
#endif
#if defined AMX_XXXPUBLICS  || defined AMX_XXXPUBVARS   || defined AMX_XXXSTRING
  #define AMX_EXPLIT_FUNCTIONS
#endif
#if defined AMX_XXXTAGS     || defined AMX_XXXUSERDATA  || defined AMX_UTF8XXX
  #define AMX_EXPLIT_FUNCTIONS
#endif
#if !defined AMX_EXPLIT_FUNCTIONS
  /* no constant set, set them all */
  #define AMX_ALIGN             /* amx_Align16(), amx_Align32() and amx_Align64() */
  #define AMX_ALLOT             /* amx_Allot() and amx_Release() */
  #define AMX_DEFCALLBACK       /* amx_Callback() */
  #define AMX_CLEANUP           /* amx_Cleanup() */
  #define AMX_CLONE             /* amx_Clone() */
  #define AMX_EXEC              /* amx_Exec() */
  #define AMX_FLAGS             /* amx_Flags() */
  #define AMX_GETADDR           /* amx_GetAddr() */
  #define AMX_INIT              /* amx_Init() and amx_InitJIT() */
  #define AMX_MEMINFO           /* amx_MemInfo() */
  #define AMX_NAMELENGTH        /* amx_NameLength() */
  #define AMX_NATIVEINFO        /* amx_NativeInfo() */
  #define AMX_PUSHXXX           /* amx_Push(), amx_PushArray() and amx_PushString() */
  #define AMX_RAISEERROR        /* amx_RaiseError() */
  #define AMX_REGISTER          /* amx_Register() */
  #define AMX_SETCALLBACK       /* amx_SetCallback() */
  #define AMX_SETDEBUGHOOK      /* amx_SetDebugHook() */
  #define AMX_XXXNATIVES        /* amx_NumNatives(), amx_GetNative() and amx_FindNative() */
  #define AMX_XXXPUBLICS        /* amx_NumPublics(), amx_GetPublic() and amx_FindPublic() */
  #define AMX_XXXPUBVARS        /* amx_NumPubVars(), amx_GetPubVar() and amx_FindPubVar() */
  #define AMX_XXXSTRING         /* amx_StrLen(), amx_GetString() and amx_SetString() */
  #define AMX_XXXTAGS           /* amx_NumTags(), amx_GetTag() and amx_FindTagId() */
  #define AMX_XXXUSERDATA       /* amx_GetUserData() and amx_SetUserData() */
  #define AMX_UTF8XXX           /* amx_UTF8Get(), amx_UTF8Put(), amx_UTF8Check() */
#endif
#undef AMX_EXPLIT_FUNCTIONS
#if defined AMX_ANSIONLY
  #undef AMX_UTF8XXX            /* no UTF-8 support in ANSI/ASCII-only version */
#endif
#if defined AMX_NO_NATIVEINFO
  #undef AMX_NATIVEINFO
#endif
#if AMX_USERNUM <= 0
  #undef AMX_XXXUSERDATA
#endif
#if defined JIT
  #define AMX_NO_MACRO_INSTR    /* JIT is incompatible with macro instructions */
#endif

#define USENAMETABLE(hdr) \
                        ((hdr)->defsize==sizeof(AMX_FUNCSTUBNT))
#define NUMENTRIES(hdr,field,nextfield) \
                        (unsigned)(((hdr)->nextfield - (hdr)->field) / (hdr)->defsize)
#define GETENTRY(hdr,table,index) \
                        (AMX_FUNCSTUB *)((unsigned char*)(hdr) + (unsigned)(hdr)->table + (unsigned)index*(hdr)->defsize)
#define GETENTRYNAME(hdr,entry) \
                        ( USENAMETABLE(hdr) \
                           ? (char *)((unsigned char*)(hdr) + (unsigned)((AMX_FUNCSTUBNT*)(entry))->nameofs) \
                           : ((AMX_FUNCSTUB*)(entry))->name )

#define NUMPUBLICS(hdr)         NUMENTRIES((hdr),publics,natives)
#define NUMNATIVES(hdr)         NUMENTRIES((hdr),natives,libraries)
#define NUMLIBRARIES(hdr)       NUMENTRIES((hdr),libraries,pubvars)
#define NUMPUBVARS(hdr)         NUMENTRIES((hdr),pubvars,tags)
#define NUMTAGS(hdr)            NUMENTRIES((hdr),tags,nametable)

#if defined AMX_DONT_RELOCATE
  #define JUMPABS(base,ip)      ((cell *)((base) + *(ip)))
  #define RELOC_VALUE(base,v)   ((void)(base),(cell)(v))
#else
  #define JUMPABS(base,ip)      ((cell *)*((void)(base),(ip)))
  #define RELOC_VALUE(base,v)   (cell)((ucell)(v)+(ucell)(base))
#endif

#define STKMARGIN       ((cell)(16*sizeof(cell)))

#if defined _MSC_VER
  #define AMX_FASTCALL __fastcall
#elif defined __GNUC__
  #if defined __clang__
    #define AMX_FASTCALL __attribute__((fastcall))
  #elif (defined __i386__ || defined __x86_64__ || defined __amd64__)
    #if !defined __x86_64__ && !defined __amd64__ && (__GNUC__>=4 || __GNUC__==3 && __GNUC_MINOR__>=4)
      #define AMX_FASTCALL __attribute__((fastcall))
    #else
      #define AMX_FASTCALL __attribute__((regparm(3)))
    #endif
  #else
    #define AMX_FASTCALL
  #endif
#else
  #define AMX_FASTCALL
#endif

#define AMX_EXEC_USE_JUMP_TABLE
#if (defined __GNUC__ && !defined __STRICT_ANSI__ || defined __ICC || defined __clang__) && \
    !(defined ASM32 || defined JIT)
  #define AMX_EXEC_USE_JUMP_TABLE_GCC
#else
  #undef AMX_EXEC_USE_JUMP_TABLE
#endif

#if !defined __clang__ && !defined __has_builtin
  #define __has_builtin(x)      0
#endif
#if defined __clang__ && __has_builtin(__builtin_expect) || \
    defined __GNUC__ && !defined __clang__ && __GNUC__>2
  #define AMX_LIKELY(x)         __builtin_expect(!!(x), 1)
  #define AMX_UNLIKELY(x)       __builtin_expect((x), 0)
#else
  #define AMX_LIKELY(x)         (x)
  #define AMX_UNLIKELY(x)       (x)
#endif

#define AMX_USE_REGISTER_VARIABLES (1)
#if defined __GNUC__
  #define AMX_REGISTER_VAR register
#else
  #undef AMX_USE_REGISTER_VARIABLES
  #define AMX_REGISTER_VAR
#endif

#define IS_INVALID_CODE_OFFS_NORELOC(offs,codesize)                             \
                        AMX_UNLIKELY(                                           \
                          ((ucell)(offs)>=(codesize)) ||                        \
                          (((ucell)(offs)&(ucell)(sizeof(cell)-1))!=0) )
#define IS_INVALID_DATA_OFFS(offs,datasize)                                     \
                        AMX_UNLIKELY(                                           \
                          (ucell)(offs)>=(datasize) )
#define IS_INVALID_STACK_OFFS(offs)                                             \
                        AMX_UNLIKELY(                                           \
                          (frm+(cell)(offs)>=stp) ||                            \
                          (frm+(cell)(offs)<stk) )
#define IS_INVALID_DATA_STACK_HEAP_OFFS(offs)                                   \
                        AMX_UNLIKELY(                                           \
                          ((cell)(offs)>=hea) && ((cell)(offs)<stk) ||          \
                          ((ucell)(offs)>=(ucell)stp) )

#if defined AMX_DONT_RELOCATE
  #define IS_INVALID_CODE_OFFS(offs,code,codesize)                              \
                        IS_INVALID_CODE_OFFS_NORELOC(offs,codesize)
#else
  #define IS_INVALID_CODE_OFFS(offs,code,codesize)                              \
                        AMX_UNLIKELY(                                           \
                          ((ucell)(offs)<(ucell)PTR_TO_CELL(code)) ||           \
                          ((ucell)(offs)>=(ucell)PTR_TO_CELL(code+(size_t)codesize)) || \
                          (((ucell)(offs)&(ucell)(sizeof(cell)-1))!=0) )
#endif

#endif /* AMX_INTERNAL_H_INCLUDED */
