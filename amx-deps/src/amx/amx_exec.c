/*  AMX bytecode (P-Code) interpreter core.
 *
 *  Portions copyright (c) Stanislav Gromov, 2016-2022
 *
 *  This code was derived from code carrying the following copyright notice:
 *
 *  Copyright (c) ITB CompuPhase, 1997-2009
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

#if defined AMX_USE_NEW_AMXEXEC

#include "amx.h"
#include "amx_internal.h"

#include <assert.h>
#include <string.h>


#if defined AMX_EXEC || defined AMX_INIT

#if !defined NDEBUG
  static int check_endian(void)
  {
    uint16_t val=0x00ff;
    unsigned char *ptr=(unsigned char *)&val;
    /* "ptr" points to the starting address of "val". If that address
     * holds the byte "0xff", the computer stored the low byte of "val"
     * at the lower address, and so the memory lay out is Little Endian.
     */
    assert(*ptr==0xff || *ptr==0x00);
    #if BYTE_ORDER==BIG_ENDIAN
      return *ptr==0x00;  /* return "true" if big endian */
    #else
      return *ptr==0xff;  /* return "true" if little endian */
    #endif
  }
#endif

/* It is assumed that the abstract machine can simply access the memory area
 * for the global data and the stack. If this is not the case, you need to
 * define the macro sets _R() and _W(), for reading and writing to memory.
 */
#if !defined _R
  #define _R_DEFAULT            /* mark default memory access */
  #define _R(base,addr)         (* (cell *)(void *)((unsigned char*)(base)+(size_t)(addr)))
  #define _R8(base,addr)        (* (unsigned char *)(void *)((unsigned char*)(base)+(size_t)(addr)))
  #define _R16(base,addr)       (* (uint16_t *)(void *)((unsigned char*)(base)+(size_t)(addr)))
  #define _R32(base,addr)       (* (uint32_t *)(void *)((unsigned char*)(base)+(size_t)(addr)))
#endif
#if !defined _W
  #define _W_DEFAULT            /* mark default memory access */
  #define _W(base,addr,value)   ((*(cell *)(void *)((unsigned char*)(base)+(size_t)(addr)))=(cell)(value))
  #define _W8(base,addr,value)  ((*(unsigned char *)(void *)((unsigned char*)(base)+(size_t)(addr)))=(unsigned char)(value))
  #define _W16(base,addr,value) ((*(uint16_t *)(void *)((unsigned char*)(base)+(size_t)(addr)))=(uint16_t)(value))
  #define _W32(base,addr,value) ((*(uint32_t *)(void *)((unsigned char*)(base)+(size_t)(addr)))=(uint32_t)(value))
#endif

#if -8/3==-2 && 8/-3==-2
  #define TRUNC_SDIV    /* signed divisions are truncated on this platform */
#else
  #define IABS(a)       ((a)>=0 ? (a) : (-a))
#endif

/* The pseudo-instructions come from the code stream. Normally, these are just
 * accessed from memory. When the instructions must be fetched in some other
 * way, the definition below must be pre-defined.
 * N.B.:
 *   - reading from a code address should increment the instruction pointer
 *     (called "cip")
 *   - only cell-sized accesses occur in code memory
 */
#if !defined _RCODE
  #define _RCODE()      ( *cip++ )
#endif

#if !defined GETPARAM
  #define GETPARAM(n)   *(cip+(n)-1) /* read a parameter from the opcode stream */
#endif

#define ABORT(v)        do { num=(v); goto abort_exec; } while (0)
#if defined _MSC_VER && _MSC_VER>=1800
  #define ERR_STACKERR()    ABORT(AMX_ERR_STACKERR)
  #define ERR_BOUNDS()      ABORT(AMX_ERR_BOUNDS)
  #define ERR_MEMACCESS()   ABORT(AMX_ERR_MEMACCESS)
  #define ERR_INVINSTR()    ABORT(AMX_ERR_INVINSTR)
  #define ERR_STACKLOW()    ABORT(AMX_ERR_STACKLOW)
  #define ERR_HEAPLOW()     ABORT(AMX_ERR_HEAPLOW)
  #define ERR_DIVIDE()      ABORT(AMX_ERR_DIVIDE)
#else
  #define ERR_STACKERR()    goto err_stackerr
  #define ERR_BOUNDS()      goto err_bounds
  #define ERR_MEMACCESS()   goto err_memaccess
  #define ERR_INVINSTR()    goto err_invinstr
  #define ERR_STACKLOW()    goto err_stacklow
  #define ERR_HEAPLOW()     goto err_heaplow
  #define ERR_DIVIDE()      goto err_divide
#endif

#define CHKMARGIN()     do { if (AMX_UNLIKELY(hea+STKMARGIN>stk)) ERR_STACKERR(); } while (0)
#define CHKPUSH()       do { if (AMX_UNLIKELY(hea>stk)) ERR_STACKERR(); } while (0)
#define CHKSTACK()      do { if (AMX_UNLIKELY(stk>stp)) ERR_STACKLOW(); } while (0)
#define CHKHEAP()       do { if (AMX_UNLIKELY(hea<hlw)) ERR_HEAPLOW(); } while (0)

#define PUSH(v)         do {                                        \
                          stk-=(cell)sizeof(cell);                  \
                          CHKPUSH();                              \
                          _W(data,stk,(v));                         \
                        } while (0)
#define POP(v)          do {                                        \
                          v=_R(data,stk);                           \
                          stk+=(cell)sizeof(cell);                  \
                          CHKSTACK();                               \
                        } while (0)
#define ALLOCSTACK(n)   do {                                        \
                          cptr=(cell *)(void *)(data+(size_t)stk);  \
                          stk-=(cell)(n)*(cell)sizeof(cell);        \
                          CHKPUSH();                              \
                        } while (0)
#define FREESTACK(n)    do {                                        \
                          cptr=(cell *)(void *)(data+(size_t)stk);  \
                          stk+=(cell)(n)*(cell)sizeof(cell);        \
                          CHKSTACK();                               \
                        } while (0)

#define JUMP_NORELOC(offs) \
                        cip=(cell *)(void *)(code+(size_t)offs)
#if defined AMX_DONT_RELOCATE
  #define JUMP(offs)    JUMP_NORELOC(offs)
#else
  #define JUMP(offs)    cip=(cell *)(void *)((size_t)offs)
#endif

#if defined AMX_DONT_RELOCATE && defined _R_DEFAULT
  #define _R_DATA_RELOC(data,offs) \
                        _R(data,offs)
  #define _W_DATA_RELOC(data,offs,value) \
                        _W(data,offs,value)
#else
  #define _R_DATA_RELOC(data,offs) \
                        ((void)data,*(cell *)(size_t)(offs))
  #define _W_DATA_RELOC(data,offs,value) \
                        ((void)data,(*(cell *)(size_t)(offs))=(value))
#endif

#if defined __GNUC__
  #define AMXEXEC_COLD_CODE(x)  lbl_cold_##x: __attribute__((cold, unused))
#else
  #define AMXEXEC_COLD_CODE(x)  (void)0
#endif

#ifndef NDEBUG
  #define AMXEXEC_UNREACHABLE() assert(0)
#elif defined __clang__ && __has_builtin(__builtin_unreachable) || \
      defined __GNUC__ && !defined __clang__ && (__GNUC__>4 || __GNUC__==4 && __GNUC_MINOR__>=5)
  #define AMXEXEC_UNREACHABLE() __builtin_unreachable()
#elif defined _MSC_VER && (defined _M_IX86 || defined _M_X64 || defined _M_ARM)
  #define AMXEXEC_UNREACHABLE() __assume(0)
#else
  #define AMXEXEC_UNREACHABLE() (void)0
#endif

#if defined AMX_EXEC_USE_JUMP_TABLE_GCC
  #if defined AMX_DONT_RELOCATE
    #define OPHND_NEXT_()       do { goto *handlers[(size_t)(unsigned char)_RCODE()]; } while (0)
  #else
    #define OPHND_NEXT_()       do { goto **cip++; } while (0)
  #endif
  #define OPHND_SWITCH()        OPHND_NEXT_();
  #define OPHND_CASE(x)         HND_##x
  #define OPHND_DEFAULT()       (void)0
  #define OPHND_NEXT(n)         do { cip+=(size_t)(n); OPHND_NEXT_(); } while (0)
#else
  #define OPHND_SWITCH()        next:op=(OPCODE)_RCODE(); switch (op)
  #define OPHND_CASE(name)      case name
  #define OPHND_DEFAULT()       default: ERR_INVINSTR();
  #define OPHND_NEXT(n)         do { cip+=(size_t)(n); goto next; } while (0)
#endif

int AMXAPI amx_Exec(AMX *amx, cell *retval, int index)
{
  AMX_HEADER *hdr;
  AMX_FUNCSTUB *func;
  unsigned char *code,*data;
  ucell codesize;
  AMX_REGISTER_VAR cell *cip;
  AMX_REGISTER_VAR cell pri,alt;
  cell stk,frm,hea;
  cell reset_stk,reset_hea;

#if defined AMX_EXEC_USE_JUMP_TABLE_GCC
  static const void * const handlers[] = {
    &&HND_OP_NONE,        &&HND_OP_LOAD_PRI,    &&HND_OP_LOAD_ALT,    &&HND_OP_LOAD_S_PRI,  &&HND_OP_LOAD_S_ALT,
    &&HND_OP_LREF_PRI,    &&HND_OP_LREF_ALT,    &&HND_OP_LREF_S_PRI,  &&HND_OP_LREF_S_ALT,  &&HND_OP_LOAD_I,
    &&HND_OP_LODB_I,      &&HND_OP_CONST_PRI,   &&HND_OP_CONST_ALT,   &&HND_OP_ADDR_PRI,    &&HND_OP_ADDR_ALT,
    &&HND_OP_STOR_PRI,    &&HND_OP_STOR_ALT,    &&HND_OP_STOR_S_PRI,  &&HND_OP_STOR_S_ALT,  &&HND_OP_SREF_PRI,
    &&HND_OP_SREF_ALT,    &&HND_OP_SREF_S_PRI,  &&HND_OP_SREF_S_ALT,  &&HND_OP_STOR_I,      &&HND_OP_STRB_I,
    &&HND_OP_LIDX,        &&HND_OP_LIDX_B,      &&HND_OP_IDXADDR,     &&HND_OP_IDXADDR_B,   &&HND_OP_ALIGN_PRI,
    &&HND_OP_ALIGN_ALT,   &&HND_OP_LCTRL,       &&HND_OP_SCTRL,       &&HND_OP_MOVE_PRI,    &&HND_OP_MOVE_ALT,
    &&HND_OP_XCHG,        &&HND_OP_PUSH_PRI,    &&HND_OP_PUSH_ALT,    &&HND_OP_PUSH_R,      &&HND_OP_PUSH_C,
    &&HND_OP_PUSH,        &&HND_OP_PUSH_S,      &&HND_OP_POP_PRI,     &&HND_OP_POP_ALT,     &&HND_OP_STACK,
    &&HND_OP_HEAP,        &&HND_OP_PROC,        &&HND_OP_RET,         &&HND_OP_RETN,        &&HND_OP_CALL,
    &&HND_OP_CALL_PRI,    &&HND_OP_JUMP,        &&HND_OP_JREL,        &&HND_OP_JZER,        &&HND_OP_JNZ,
    &&HND_OP_JEQ,         &&HND_OP_JNEQ,        &&HND_OP_JLESS,       &&HND_OP_JLEQ,        &&HND_OP_JGRTR,
    &&HND_OP_JGEQ,        &&HND_OP_JSLESS,      &&HND_OP_JSLEQ,       &&HND_OP_JSGRTR,      &&HND_OP_JSGEQ,
    &&HND_OP_SHL,         &&HND_OP_SHR,         &&HND_OP_SSHR,        &&HND_OP_SHL_C_PRI,   &&HND_OP_SHL_C_ALT,
    &&HND_OP_SHR_C_PRI,   &&HND_OP_SHR_C_ALT,   &&HND_OP_SMUL,        &&HND_OP_SDIV,        &&HND_OP_SDIV_ALT,
    &&HND_OP_UMUL,        &&HND_OP_UDIV,        &&HND_OP_UDIV_ALT,    &&HND_OP_ADD,         &&HND_OP_SUB,
    &&HND_OP_SUB_ALT,     &&HND_OP_AND,         &&HND_OP_OR,          &&HND_OP_XOR,         &&HND_OP_NOT,
    &&HND_OP_NEG,         &&HND_OP_INVERT,      &&HND_OP_ADD_C,       &&HND_OP_SMUL_C,      &&HND_OP_ZERO_PRI,
    &&HND_OP_ZERO_ALT,    &&HND_OP_ZERO,        &&HND_OP_ZERO_S,      &&HND_OP_SIGN_PRI,    &&HND_OP_SIGN_ALT,
    &&HND_OP_EQ,          &&HND_OP_NEQ,         &&HND_OP_LESS,        &&HND_OP_LEQ,         &&HND_OP_GRTR,
    &&HND_OP_GEQ,         &&HND_OP_SLESS,       &&HND_OP_SLEQ,        &&HND_OP_SGRTR,       &&HND_OP_SGEQ,
    &&HND_OP_EQ_C_PRI,    &&HND_OP_EQ_C_ALT,    &&HND_OP_INC_PRI,     &&HND_OP_INC_ALT,     &&HND_OP_INC,
    &&HND_OP_INC_S,       &&HND_OP_INC_I,       &&HND_OP_DEC_PRI,     &&HND_OP_DEC_ALT,     &&HND_OP_DEC,
    &&HND_OP_DEC_S,       &&HND_OP_DEC_I,       &&HND_OP_MOVS,        &&HND_OP_CMPS,        &&HND_OP_FILL,
    &&HND_OP_HALT,        &&HND_OP_BOUNDS,      &&HND_OP_SYSREQ_PRI,  &&HND_OP_SYSREQ_C,    &&HND_OP_FILE,
    &&HND_OP_LINE,        &&HND_OP_SYMBOL,      &&HND_OP_SRANGE,      &&HND_OP_JUMP_PRI,    &&HND_OP_SWITCH,
    &&HND_OP_CASETBL,     &&HND_OP_SWAP_PRI,    &&HND_OP_SWAP_ALT,    &&HND_OP_PUSH_ADR,    &&HND_OP_NOP,
    &&HND_OP_SYSREQ_N,    &&HND_OP_SYMTAG,      &&HND_OP_BREAK,       &&HND_OP_PUSH2_C,     &&HND_OP_PUSH2,
    &&HND_OP_PUSH2_S,     &&HND_OP_PUSH2_ADR,   &&HND_OP_PUSH3_C,     &&HND_OP_PUSH3,       &&HND_OP_PUSH3_S,
    &&HND_OP_PUSH3_ADR,   &&HND_OP_PUSH4_C,     &&HND_OP_PUSH4,       &&HND_OP_PUSH4_S,     &&HND_OP_PUSH4_ADR,
    &&HND_OP_PUSH5_C,     &&HND_OP_PUSH5,       &&HND_OP_PUSH5_S,     &&HND_OP_PUSH5_ADR,   &&HND_OP_LOAD_BOTH,
    &&HND_OP_LOAD_S_BOTH, &&HND_OP_CONST,       &&HND_OP_CONST_S,     &&HND_OP_SYSREQ_D,    &&HND_OP_SYSREQ_ND
  #if defined AMX_DONT_RELOCATE
    ,
    &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,
    &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,
    &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,
    &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,
    &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,
    &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,
    &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,
    &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,
    &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,
    &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,
    &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,
    &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,
    &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,
    &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,
    &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,
    &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,
    &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,
    &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,
    &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,        &&HND_OP_NONE,
    &&HND_OP_NONE
  #endif
  };
#else
  #if defined ASM32 || defined JIT
    cell  parms[9];     /* registers and parameters for assembler AMX */
  #else
    OPCODE op;
  #endif
#endif

#if defined AMX_EXEC_USE_JUMP_TABLE || !(defined ASM32 || defined JIT)
  cell stp,hlw;
  cell val;
  int num=0;
  #if !defined _R_DEFAULT
    int i;
  #endif
  ucell datasize;
#endif

  assert(amx!=NULL);

#if defined AMX_EXEC_USE_JUMP_TABLE
  /* HACK: return label table (for amx_VerifyRelocateBytecode) if amx structure
   * has the AMX_FLAG_BROWSE flag set.
   */
  if (AMX_UNLIKELY((amx->flags & AMX_FLAG_BROWSE)==AMX_FLAG_BROWSE)) {
    #if defined AMX_EXEC_USE_JUMP_TABLE_GCC
      #if defined AMX_DONT_RELOCATE
        assert_static((size_t)1<<(sizeof(unsigned char)*8)==sizeof(handlers)/sizeof(handlers[0]));
      #else
        assert_static(sizeof(cell)==sizeof(void *));
      #endif
    #endif
    #if defined AMX_EXEC_USE_JUMP_TABLE_GCC && !defined AMX_DONT_RELOCATE
      assert(retval!=NULL);
      *retval=(cell)handlers;
      return 0;
    #endif
  } /* if */
#endif /* defined AMX_EXEC_USE_JUMP_TABLE */

  if (AMX_UNLIKELY(amx->callback==NULL))
    return AMX_ERR_CALLBACK;
  if (AMX_UNLIKELY((amx->flags & AMX_FLAG_RELOC)==0))
    return AMX_ERR_INIT;
  if (AMX_UNLIKELY((amx->flags & AMX_FLAG_NTVREG)==0)) {
    if ((num=amx_Register(amx,NULL,0))!=AMX_ERR_NONE)
      return num;
  } /* if */
  assert((amx->flags & AMX_FLAG_BROWSE)==0);

  /* set up the registers */
  hdr=(AMX_HEADER *)amx->base;
  assert(hdr->magic==AMX_MAGIC);
  codesize=(ucell)(hdr->dat-hdr->cod);
  code=amx->base+(int)hdr->cod;
  data=(amx->data!=NULL) ? amx->data : amx->base+(int)hdr->dat;
  hea=amx->hea;
  stk=amx->stk;
  stp=amx->stp;
  hlw=amx->hlw;
  reset_stk=stk;
  reset_hea=hea;
  alt=frm=pri=0;/* just to avoid compiler warnings */
#if defined AMX_EXEC_USE_JUMP_TABLE || !(defined ASM32 || defined JIT)
  datasize = (ucell)(hdr->hea - hdr->dat);
#endif

  /* get the start address */
  if (AMX_UNLIKELY(index==AMX_EXEC_MAIN)) {
    if (hdr->cip<0)
      return AMX_ERR_INDEX;
    cip=(cell *)(code + (int)hdr->cip);
  } else if (AMX_UNLIKELY(index==AMX_EXEC_CONT)) {
    /* all registers: pri, alt, frm, cip, hea, stk, stp, hlw, reset_stk, reset_hea
     * (NOTE: hea, stk, stp and hlw are already initialized a few lines above)
     */
    frm=amx->frm;
    pri=amx->pri;
    alt=amx->alt;
    reset_stk=amx->reset_stk;
    reset_hea=amx->reset_hea;
    cip=(cell *)(code + (int)amx->cip);
  } else if (AMX_UNLIKELY(index<0)) {
    return AMX_ERR_INDEX;
  } else {
    if (AMX_UNLIKELY(index>=(cell)NUMPUBLICS(hdr)))
      return AMX_ERR_INDEX;
    func=GETENTRY(hdr,publics,index);
    cip=(cell *)(code + (int)func->address);
  } /* if */
  /* check values just copied */
  CHKSTACK();
  CHKHEAP();
  assert(check_endian());

  /* sanity checks */
  assert_static(OP_PUSH_PRI==36);
  assert_static(OP_PROC==46);
  assert_static(OP_SHL==65);
  assert_static(OP_SMUL==72);
  assert_static(OP_EQ==95);
  assert_static(OP_INC_PRI==107);
  assert_static(OP_MOVS==117);
  assert_static(OP_SYMBOL==126);
  assert_static(OP_PUSH2_C==138);
  assert_static(OP_LOAD_BOTH==154);
  assert_static(sizeof(cell)==(PAWN_CELL_SIZE/8));

  if (index!=AMX_EXEC_CONT) {
    reset_stk+=(cell)amx->paramcount*(cell)sizeof(cell);
    PUSH((cell)amx->paramcount*(cell)sizeof(cell));
    amx->paramcount=0;          /* push the parameter count to the stack & reset */
    #if defined ASM32 || defined JIT
      PUSH(RELOC_VALUE(code,0));/* relocated zero return address */
    #else
      PUSH(0);                  /* zero return address */
    #endif
  } /* if */
  /* check stack/heap before starting to run */
  CHKMARGIN();

  /* start running */
#if defined ASM32 || defined JIT
  /* either the assembler abstract machine or the JIT; both by Marc Peter */

  parms[0] = pri;
  parms[1] = alt;
  parms[2] = (cell)cip;
  parms[3] = (cell)data;
  parms[4] = stk;
  parms[5] = frm;
  parms[6] = (cell)amx;
  parms[7] = (cell)code;
  parms[8] = (cell)codesize;

  #if defined ASM32 && defined JIT
    if ((amx->flags & AMX_FLAG_JITC)!=0)
      num = amx_exec_jit(parms,retval,amx->stp,hea);
    else
      num = amx_exec_asm(parms,retval,amx->stp,hea);
  #elif defined ASM32
    num = amx_exec_asm(parms,retval,amx->stp,hea);
  #else
    num = amx_exec_jit(parms,retval,amx->stp,hea);
  #endif
  if (i == AMX_ERR_SLEEP) {
    amx->reset_stk=reset_stk;
    amx->reset_hea=reset_hea;
  } else {
    /* remove parameters from the stack; do this the "hard" way, because
     * the assembler version has no internal knowledge of the local
     * variables, so any "clean" way would be a kludge anyway.
     */
    amx->stk=reset_stk;
    amx->hea=reset_hea;
  } /* if */
  amx->cip=(cell)((size_t)cip-(size_t)code-sizeof(cell));
  return num;

#else

  OPHND_SWITCH()
  {
    OPHND_CASE(OP_NONE):
      ERR_INVINSTR();

    OPHND_CASE(OP_LOAD_PRI):
      /* the address is already verified in VerifyRelocateBytecode */
      pri=_R_DATA_RELOC(data,GETPARAM(1));
    OPHND_NEXT(1);

    OPHND_CASE(OP_LOAD_ALT):
      /* the address is already verified in VerifyRelocateBytecode */
      alt=_R_DATA_RELOC(data,GETPARAM(1));
    OPHND_NEXT(1);

    OPHND_CASE(OP_LOAD_S_PRI): {
      AMX_REGISTER_VAR cell offs;
      offs=GETPARAM(1);
      if (IS_INVALID_STACK_OFFS(offs))
        ERR_MEMACCESS();
      pri=_R(data,frm+offs);
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_LOAD_S_ALT): {
      AMX_REGISTER_VAR cell offs;
      offs=GETPARAM(1);
      if (IS_INVALID_STACK_OFFS(offs))
        ERR_MEMACCESS();
      alt=_R(data,frm+offs);
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_LREF_PRI): {
      AMX_REGISTER_VAR cell offs;
      /* the address is already verified in VerifyRelocateBytecode */
      offs=_R_DATA_RELOC(data,GETPARAM(1));
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(offs))
        ERR_MEMACCESS();
      pri=_R(data,offs);
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_LREF_ALT): {
      AMX_REGISTER_VAR cell offs;
      /* the address is already verified in VerifyRelocateBytecode */
      offs=_R_DATA_RELOC(data,GETPARAM(1));
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(offs))
        ERR_MEMACCESS();
      alt=_R(data,offs);
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_LREF_S_PRI): {
      AMX_REGISTER_VAR cell offs;
      offs=GETPARAM(1);
      if (IS_INVALID_STACK_OFFS(offs))
        ERR_MEMACCESS();
      offs=_R(data,frm+offs);
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(offs))
        ERR_MEMACCESS();
      pri=_R(data,offs);
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_LREF_S_ALT): {
      AMX_REGISTER_VAR cell offs;
      offs=GETPARAM(1);
      if (IS_INVALID_STACK_OFFS(offs))
        ERR_MEMACCESS();
      offs=_R(data,frm+offs);
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(offs))
        ERR_MEMACCESS();
      alt=_R(data,offs);
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_LOAD_I):
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(pri))
        ERR_MEMACCESS();
      pri=_R(data,pri);
    OPHND_NEXT(0);

    OPHND_CASE(OP_LODB_I):
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(pri))
        ERR_MEMACCESS();
      switch (GETPARAM(1)) {
      case 1:
        pri=(cell)_R8(data,pri);
        break;
      case 2:
        pri=(cell)_R16(data,pri);
        break;
      case 4:
        pri=(cell)_R32(data,pri);
        break;
      default:
        AMXEXEC_UNREACHABLE();
      } /* switch */
    OPHND_NEXT(1);

    OPHND_CASE(OP_CONST_PRI):
      pri=GETPARAM(1);
    OPHND_NEXT(1);

    OPHND_CASE(OP_CONST_ALT):
      alt=GETPARAM(1);
    OPHND_NEXT(1);

    OPHND_CASE(OP_ADDR_PRI):
      pri=frm+GETPARAM(1);
    OPHND_NEXT(1);

    OPHND_CASE(OP_ADDR_ALT):
      alt=frm+GETPARAM(1);
    OPHND_NEXT(1);

    OPHND_CASE(OP_STOR_PRI):
      /* the address is already verified in VerifyRelocateBytecode */
      _W_DATA_RELOC(data,GETPARAM(1),pri);
    OPHND_NEXT(1);

    OPHND_CASE(OP_STOR_ALT):
      /* the address is already verified in VerifyRelocateBytecode */
      _W_DATA_RELOC(data,GETPARAM(1),alt);
    OPHND_NEXT(1);

    OPHND_CASE(OP_STOR_S_PRI): {
      AMX_REGISTER_VAR cell offs;
      offs=GETPARAM(1);
      if (IS_INVALID_STACK_OFFS(offs))
        ERR_MEMACCESS();
      _W(data,frm+offs,pri);
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_STOR_S_ALT): {
      AMX_REGISTER_VAR cell offs;
      offs=GETPARAM(1);
      if (IS_INVALID_STACK_OFFS(offs))
        ERR_MEMACCESS();
      _W(data,frm+offs,alt);
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_SREF_PRI): {
      AMX_REGISTER_VAR cell offs;
      /* the address is already verified in VerifyRelocateBytecode */
      offs=_R_DATA_RELOC(data,GETPARAM(1));
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(offs))
        ERR_MEMACCESS();
      _W(data,offs,pri);
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_SREF_ALT): {
      AMX_REGISTER_VAR cell offs;
      /* the address is already verified in VerifyRelocateBytecode */
      offs=_R_DATA_RELOC(data,GETPARAM(1));
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(offs))
        ERR_MEMACCESS();
      _W(data,offs,alt);
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_SREF_S_PRI): {
      AMX_REGISTER_VAR cell offs;
      offs=GETPARAM(1);
      if (IS_INVALID_STACK_OFFS(offs))
        ERR_MEMACCESS();
      offs=_R(data,frm+offs);
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(offs))
        ERR_MEMACCESS();
      _W(data,offs,pri);
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_SREF_S_ALT): {
      AMX_REGISTER_VAR cell offs;
      offs=GETPARAM(1);
      if (IS_INVALID_STACK_OFFS(offs))
        ERR_MEMACCESS();
      offs=_R(data,frm+offs);
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(offs))
        ERR_MEMACCESS();
      _W(data,offs,alt);
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_STOR_I):
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(alt))
        ERR_MEMACCESS();
      _W(data,alt,pri);
    OPHND_NEXT(0);

    OPHND_CASE(OP_STRB_I):
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(alt))
        ERR_MEMACCESS();
      switch (GETPARAM(1)) {
      case 1:
        _W8(data,alt,pri);
        break;
      case 2:
        _W16(data,alt,pri);
        break;
      case 4:
        _W32(data,alt,pri);
        break;
      default:
        AMXEXEC_UNREACHABLE();
      } /* switch */
    OPHND_NEXT(1);

    OPHND_CASE(OP_LIDX): {
      AMX_REGISTER_VAR cell offs;
      offs=pri*(cell)sizeof(cell)+alt;  /* implicit shift value for a cell */
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(offs))
        ERR_MEMACCESS();
      pri=_R(data,offs);
    } /* OPHND_CASE */
    OPHND_NEXT(0);

    OPHND_CASE(OP_LIDX_B): {
      AMX_REGISTER_VAR cell offs;
      offs=(pri << (int)GETPARAM(1))+alt;
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(offs))
        ERR_MEMACCESS();
      pri=_R(data,offs);
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_IDXADDR):
      pri=pri*(cell)sizeof(cell)+alt;
    OPHND_NEXT(0);

    OPHND_CASE(OP_IDXADDR_B):
      pri=(pri << (int)GETPARAM(1))+alt;
    OPHND_NEXT(1);

    OPHND_CASE(OP_ALIGN_PRI): {
      #if BYTE_ORDER==LITTLE_ENDIAN
        AMX_REGISTER_VAR cell offs;
        offs=GETPARAM(1);
        if (AMX_LIKELY(offs<(cell)sizeof(cell)))
          pri ^= (cell)sizeof(cell)-offs;
      #endif /* BYTE_ORDER==LITTLE_ENDIAN */
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_ALIGN_ALT): {
      #if BYTE_ORDER==LITTLE_ENDIAN
        AMX_REGISTER_VAR cell offs;
        offs=GETPARAM(1);
        if (AMX_LIKELY(offs<(cell)sizeof(cell)))
          alt ^= (cell)sizeof(cell)-offs;
      #endif /* BYTE_ORDER==LITTLE_ENDIAN */
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_LCTRL):
      switch (GETPARAM(1)) {
      case -1:
        /* this is for unknown IDs (replaced by -1 at P-code verification) */
        break;
      case 0:
        pri=hdr->cod;
        break;
      case 1:
        pri=hdr->dat;
        break;
      case 2:
        pri=hea;
        break;
      case 3:
        pri=stp;
        break;
      case 4:
        pri=stk;
        break;
      case 5:
        pri=frm;
        break;
      case 6:
        pri=(cell)((size_t)cip - (size_t)code);
        break;
      case 7:
        /* PRI is unchanged if JIT isn't present */
        break;
      case 8:
        /* no JIT => no address translation => no actions required */
        break;
      default:
        AMXEXEC_UNREACHABLE();
      } /* switch */
    OPHND_NEXT(1);

    OPHND_CASE(OP_SCTRL):
      switch (GETPARAM(1)) {
      case -1:
        /* this is for unknown/read-only IDs (replaced by -1 at P-code verification) */
        break;
      case 2:
        hea=pri;
        CHKMARGIN();
        CHKHEAP();
        break;
      case 4:
        stk=pri;
        CHKMARGIN();
        CHKSTACK();
        break;
      case 5:
        frm=pri;
        if (AMX_UNLIKELY(frm<hea+STKMARGIN) || AMX_UNLIKELY((ucell)frm>=(ucell)stp))
          ERR_STACKERR();
        break;
      case 6:
      sctrl_6: {
        AMX_REGISTER_VAR ucell index;
        /* verify address */
        if (IS_INVALID_CODE_OFFS_NORELOC(pri,codesize))
          ERR_MEMACCESS();
        index=(ucell)pri/sizeof(cell);
        if ((amx->instr_addresses[index/8] & (unsigned char)1 << (index % 8))==0)
          ERR_MEMACCESS();
        JUMP_NORELOC(pri);
        break;
      } /* case */
      case 8:
        /* without the address translation this should be equal to 'sctrl 6' */
        goto sctrl_6;
      default:
        AMXEXEC_UNREACHABLE();
      } /* switch */
    OPHND_NEXT(1);

    OPHND_CASE(OP_MOVE_PRI):
      pri=alt;
    OPHND_NEXT(0);

    OPHND_CASE(OP_MOVE_ALT):
      alt=pri;
    OPHND_NEXT(0);

    OPHND_CASE(OP_XCHG): {
      AMX_REGISTER_VAR cell offs;
      offs=pri;
      pri=alt;
      alt=offs;
    } /* OPHND_CASE */
    OPHND_NEXT(0);

    OPHND_CASE(OP_PUSH_PRI):
      PUSH(pri);
    OPHND_NEXT(0);

    OPHND_CASE(OP_PUSH_ALT):
      PUSH(alt);
    OPHND_NEXT(0);

    OPHND_CASE(OP_PUSH_R): {
      AMX_REGISTER_VAR cell offs;
      AMX_REGISTER_VAR cell *cptr,*cptr2;
      offs=GETPARAM(1);
      ALLOCSTACK(offs);
      cptr2=cptr-(size_t)offs;
      while (cptr2<cptr)
        *(cptr2++) = pri;
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_PUSH_C):
      PUSH(GETPARAM(1));
    OPHND_NEXT(1);

    OPHND_CASE(OP_PUSH): {
      AMX_REGISTER_VAR cell offs;
      offs=GETPARAM(1);
      /* the address is already verified in VerifyRelocateBytecode */
      PUSH(_R_DATA_RELOC(data,offs));
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_PUSH_S): {
      AMX_REGISTER_VAR cell offs;
      offs=GETPARAM(1);
      if (IS_INVALID_STACK_OFFS(offs))
        ERR_MEMACCESS();
      PUSH(_R(data,frm+offs));
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_POP_PRI):
      POP(pri);
    OPHND_NEXT(0);

    OPHND_CASE(OP_POP_ALT):
      POP(alt);
    OPHND_NEXT(0);

    OPHND_CASE(OP_STACK):
      alt=stk;
      stk+=GETPARAM(1);
      CHKMARGIN();
      CHKSTACK();
    OPHND_NEXT(1);

    OPHND_CASE(OP_HEAP):
      alt=hea;
      hea+=GETPARAM(1);
      CHKMARGIN();
      CHKHEAP();
    OPHND_NEXT(1);

    OPHND_CASE(OP_PROC):
      PUSH(frm);
      frm=stk;
    OPHND_NEXT(0);

    OPHND_CASE(OP_RET): {
      AMX_REGISTER_VAR cell offs;
      AMX_REGISTER_VAR cell *cptr;
      AMX_REGISTER_VAR ucell index;
      FREESTACK(2);
      frm=*cptr;
      offs=*(cptr+1);
      /* verify the return address */
      if (IS_INVALID_CODE_OFFS_NORELOC(offs,codesize))
        ERR_MEMACCESS();
      index=(ucell)offs/sizeof(cell);
      if ((amx->instr_addresses[index/8] & (unsigned char)1 << (index % 8))==0)
        ERR_MEMACCESS();
      JUMP_NORELOC(offs);
    } /* OPHND_CASE */
    OPHND_NEXT(0);

    OPHND_CASE(OP_RETN): {
      AMX_REGISTER_VAR cell offs;
      AMX_REGISTER_VAR cell *cptr;
      AMX_REGISTER_VAR ucell index;
      FREESTACK(2);
      frm=*cptr;
      offs=*(cptr+1);
      /* verify the return address */
      if (IS_INVALID_CODE_OFFS_NORELOC(offs,codesize))
        ERR_MEMACCESS();
      index=(ucell)offs/sizeof(cell);
      if ((amx->instr_addresses[index/8] & (unsigned char)1 << (index % 8))==0)
        ERR_MEMACCESS();
      stk+=_R(data,stk)+(cell)sizeof(cell); /* remove parameters from the stack */
      CHKSTACK();
      JUMP_NORELOC(offs);
    } /* OPHND_CASE */
    OPHND_NEXT(0);

    OPHND_CASE(OP_CALL):
      /* push address behind instruction */
      PUSH((cell)((size_t)cip-(size_t)code+sizeof(cell)));
      /* the address is already verified in VerifyRelocateBytecode */
      JUMP(GETPARAM(1)); /* jump to the address */
    OPHND_NEXT(0);

    OPHND_CASE(OP_CALL_PRI):
      if (IS_INVALID_CODE_OFFS_NORELOC(pri,codesize))
        ERR_MEMACCESS();
      PUSH((cell)((size_t)cip-(size_t)code));
      JUMP_NORELOC(pri);
    OPHND_NEXT(0);

    OPHND_CASE(OP_JUMP):
      /* the address is already verified in VerifyRelocateBytecode */
      JUMP(GETPARAM(1));
    OPHND_NEXT(0);

    OPHND_CASE(OP_JREL):
      /* the address is already verified in VerifyRelocateBytecode */
      cip=(cell *)(void *)((unsigned char *)(void *)cip+(size_t)GETPARAM(1)+sizeof(cell));
    OPHND_NEXT(0);

    OPHND_CASE(OP_JZER):
      /* the address is already verified in VerifyRelocateBytecode */
      if (pri==0) {
        JUMP(GETPARAM(1));
        OPHND_NEXT(0);
      }
    OPHND_NEXT(1);

    OPHND_CASE(OP_JNZ):
      /* the address is already verified in VerifyRelocateBytecode */
      if (pri!=0) {
        JUMP(GETPARAM(1));
        OPHND_NEXT(0);
      }
    OPHND_NEXT(1);

    OPHND_CASE(OP_JEQ):
      /* the address is already verified in VerifyRelocateBytecode */
      if (pri==alt) {
        JUMP(GETPARAM(1));
        OPHND_NEXT(0);
      }
    OPHND_NEXT(1);

    OPHND_CASE(OP_JNEQ):
      /* the address is already verified in VerifyRelocateBytecode */
      if (pri!=alt) {
        JUMP(GETPARAM(1));
        OPHND_NEXT(0);
      }
    OPHND_NEXT(1);

    OPHND_CASE(OP_JLESS):
      /* the address is already verified in VerifyRelocateBytecode */
      if ((ucell)pri<(ucell)alt) {
        JUMP(GETPARAM(1));
        OPHND_NEXT(0);
      }
    OPHND_NEXT(1);

    OPHND_CASE(OP_JLEQ):
      /* the address is already verified in VerifyRelocateBytecode */
      if ((ucell)pri<=(ucell)alt) {
        JUMP(GETPARAM(1));
        OPHND_NEXT(0);
      }
    OPHND_NEXT(1);

    OPHND_CASE(OP_JGRTR):
      /* the address is already verified in VerifyRelocateBytecode */
      if ((ucell)pri>(ucell)alt) {
        JUMP(GETPARAM(1));
        OPHND_NEXT(0);
      }
    OPHND_NEXT(1);

    OPHND_CASE(OP_JGEQ):
      /* the address is already verified in VerifyRelocateBytecode */
      if ((ucell)pri>=(ucell)alt) {
        JUMP(GETPARAM(1));
        OPHND_NEXT(0);
      }
    OPHND_NEXT(1);

    OPHND_CASE(OP_JSLESS):
      /* the address is already verified in VerifyRelocateBytecode */
      if (pri<alt) {
        JUMP(GETPARAM(1));
        OPHND_NEXT(0);
      }
    OPHND_NEXT(1);

    OPHND_CASE(OP_JSLEQ):
      /* the address is already verified in VerifyRelocateBytecode */
      if (pri<=alt) {
        JUMP(GETPARAM(1));
        OPHND_NEXT(0);
      }
    OPHND_NEXT(1);

    OPHND_CASE(OP_JSGRTR):
      /* the address is already verified in VerifyRelocateBytecode */
      if (pri>alt) {
        JUMP(GETPARAM(1));
        OPHND_NEXT(0);
      }
    OPHND_NEXT(1);

    OPHND_CASE(OP_JSGEQ):
      /* the address is already verified in VerifyRelocateBytecode */
      if (pri>=alt) {
        JUMP(GETPARAM(1));
        OPHND_NEXT(0);
      }
    OPHND_NEXT(1);

    OPHND_CASE(OP_SHL):
      pri<<=alt;
    OPHND_NEXT(0);

    OPHND_CASE(OP_SHR):
      pri=(cell)((ucell)pri>>(ucell)alt);
    OPHND_NEXT(0);

    OPHND_CASE(OP_SSHR):
      pri>>=alt;
    OPHND_NEXT(0);

    OPHND_CASE(OP_SHL_C_PRI):
      pri<<=GETPARAM(1);
    OPHND_NEXT(1);

    OPHND_CASE(OP_SHL_C_ALT):
      alt<<=GETPARAM(1);
    OPHND_NEXT(1);

    OPHND_CASE(OP_SHR_C_PRI):
      pri=(cell)((ucell)pri>>(ucell)GETPARAM(1));
    OPHND_NEXT(1);

    OPHND_CASE(OP_SHR_C_ALT):
      alt=(cell)((ucell)alt>>(ucell)GETPARAM(1));
    OPHND_NEXT(1);

    OPHND_CASE(OP_SMUL):
      pri*=alt;
    OPHND_NEXT(0);

    OPHND_CASE(OP_SDIV): {
      AMX_REGISTER_VAR cell offs;
      if (AMX_UNLIKELY(alt==0))
        ERR_DIVIDE();
      /* use floored division and matching remainder */
      offs=alt;
      #if defined TRUNC_SDIV
        pri=pri/offs;
        alt=pri%offs;
      #else
        val=pri;                  /* portable routine for truncated division */
        pri=IABS(pri)/IABS(offs);
        if ((cell)(val ^ offs)<0)
          pri=-pri;
        alt=val-pri*offs;         /* calculate the matching remainder */
      #endif
      /* now "fiddle" with the values to get floored division */
      if (alt!=0 && (cell)(alt ^ offs)<0) {
        pri--;
        alt+=offs;
      } /* if */
    } /* OPHND_CASE */
    OPHND_NEXT(0);

    OPHND_CASE(OP_SDIV_ALT): {
      AMX_REGISTER_VAR cell offs;
      if (AMX_UNLIKELY(pri==0))
        ERR_DIVIDE();
      /* use floored division and matching remainder */
      offs=pri;
      #if defined TRUNC_SDIV
        pri=alt/offs;
        alt=alt%offs;
      #else
        val=alt;                  /* portable routine for truncated division */
        pri=IABS(alt)/IABS(offs);
        if ((cell)(val ^ offs)<0)
          pri=-pri;
        alt=val-pri*offs;         /* calculate the matching remainder */
      #endif
      /* now "fiddle" with the values to get floored division */
      if (alt!=0 && (cell)(alt ^ offs)<0) {
        pri--;
        alt+=offs;
      } /* if */
    } /* OPHND_CASE */
    OPHND_NEXT(0);

    OPHND_CASE(OP_UMUL):
      pri=(cell)((ucell)pri * (ucell)alt);
    OPHND_NEXT(0);

    OPHND_CASE(OP_UDIV): {
      AMX_REGISTER_VAR cell offs;
      if (AMX_UNLIKELY(alt==0))
        ERR_DIVIDE();
      offs=(cell)((ucell)pri % (ucell)alt); /* temporary storage */
      pri=(cell)((ucell)pri / (ucell)alt);
      alt=offs;
    } /* OPHND_CASE */
    OPHND_NEXT(0);

    OPHND_CASE(OP_UDIV_ALT): {
      AMX_REGISTER_VAR cell offs;
      if (AMX_UNLIKELY(pri==0))
        ERR_DIVIDE();
      offs=(cell)((ucell)alt % (ucell)pri);     /* temporary storage */
      pri=(cell)((ucell)alt / (ucell)pri);
      alt=offs;
    } /* OPHND_CASE */
    OPHND_NEXT(0);

    OPHND_CASE(OP_ADD):
      pri+=alt;
    OPHND_NEXT(0);

    OPHND_CASE(OP_SUB):
      pri-=alt;
    OPHND_NEXT(0);

    OPHND_CASE(OP_SUB_ALT):
      pri=alt-pri;
    OPHND_NEXT(0);

    OPHND_CASE(OP_AND):
      pri&=alt;
    OPHND_NEXT(0);

    OPHND_CASE(OP_OR):
      pri|=alt;
    OPHND_NEXT(0);

    OPHND_CASE(OP_XOR):
      pri^=alt;
    OPHND_NEXT(0);

    OPHND_CASE(OP_NOT):
      pri=!pri;
    OPHND_NEXT(0);

    OPHND_CASE(OP_NEG):
      pri=-pri;
    OPHND_NEXT(0);

    OPHND_CASE(OP_INVERT):
      pri=~pri;
    OPHND_NEXT(0);

    OPHND_CASE(OP_ADD_C):
      pri+=GETPARAM(1);
    OPHND_NEXT(1);

    OPHND_CASE(OP_SMUL_C):
      pri*=GETPARAM(1);
    OPHND_NEXT(1);

    OPHND_CASE(OP_ZERO_PRI):
      pri=0;
    OPHND_NEXT(0);

    OPHND_CASE(OP_ZERO_ALT):
      alt=0;
    OPHND_NEXT(0);

    OPHND_CASE(OP_ZERO):
      /* the address is already verified in VerifyRelocateBytecode */
      _W_DATA_RELOC(data,GETPARAM(1),0);
    OPHND_NEXT(1);

    OPHND_CASE(OP_ZERO_S): {
      AMX_REGISTER_VAR cell offs;
      offs=GETPARAM(1);
      if (IS_INVALID_STACK_OFFS(offs))
        ERR_MEMACCESS();
      _W(data,frm+offs,0);
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_SIGN_PRI):
      if ((pri & 0xff)>=0x80)
        pri|= ~(ucell)0xff;
    OPHND_NEXT(0);

    OPHND_CASE(OP_SIGN_ALT):
      if ((alt & 0xff)>=0x80)
        alt|= ~(ucell)0xff;
    OPHND_NEXT(0);

    OPHND_CASE(OP_EQ):
      pri=(pri==alt) ? 1 : 0;
    OPHND_NEXT(0);

    OPHND_CASE(OP_NEQ):
      pri=(pri!=alt) ? 1 : 0;
    OPHND_NEXT(0);

    OPHND_CASE(OP_LESS):
      pri=((ucell)pri<(ucell)alt) ? 1 : 0;
    OPHND_NEXT(0);

    OPHND_CASE(OP_LEQ):
      pri=((ucell)pri<=(ucell)alt) ? 1 : 0;
    OPHND_NEXT(0);

    OPHND_CASE(OP_GRTR):
      pri=((ucell)pri>(ucell)alt) ? 1 : 0;
    OPHND_NEXT(0);

    OPHND_CASE(OP_GEQ):
      pri=((ucell)pri>=(ucell)alt) ? 1 : 0;
    OPHND_NEXT(0);

    OPHND_CASE(OP_SLESS):
      pri=(pri<alt) ? 1 : 0;
    OPHND_NEXT(0);

    OPHND_CASE(OP_SLEQ):
      pri=(pri<=alt) ? 1 : 0;
    OPHND_NEXT(0);

    OPHND_CASE(OP_SGRTR):
      pri=(pri>alt) ? 1 : 0;
    OPHND_NEXT(0);

    OPHND_CASE(OP_SGEQ):
      pri=(pri>=alt) ? 1 : 0;
    OPHND_NEXT(0);

    OPHND_CASE(OP_EQ_C_PRI):
      pri=(pri==GETPARAM(1)) ? 1 : 0;
    OPHND_NEXT(1);

    OPHND_CASE(OP_EQ_C_ALT):
      pri=(alt==GETPARAM(1)) ? 1 : 0;
    OPHND_NEXT(1);

    OPHND_CASE(OP_INC_PRI):
      pri++;
    OPHND_NEXT(0);

    OPHND_CASE(OP_INC_ALT):
      alt++;
    OPHND_NEXT(0);

    OPHND_CASE(OP_INC): {
      /* the address is already verified in VerifyRelocateBytecode */
      #if defined _R_DEFAULT
        #if defined AMX_DONT_RELOCATE
          *(cell *)(void *)(data+(size_t)GETPARAM(1)) += 1;
        #else
          *(cell *)(size_t)GETPARAM(1) += 1;
        #endif
      #else
        AMX_REGISTER_VAR cell offs;
        offs=GETPARAM(1);
        val=_R(data,offs);
        _W(data,offs,val+1);
      #endif
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_INC_S): {
      AMX_REGISTER_VAR cell offs;
      offs=GETPARAM(1);
      if (IS_INVALID_STACK_OFFS(offs))
        ERR_MEMACCESS();
      #if defined _R_DEFAULT
        *(cell *)(data+(size_t)(frm+offs)) += 1;
      #else
        val=_R(data,frm+offs);
        _W(data,frm+offs,val+1);
      #endif
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_INC_I):
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(pri))
        ERR_MEMACCESS();
      #if defined _R_DEFAULT
        *(cell *)(data+(size_t)pri) += 1;
      #else
        val=_R(data,pri);
        _W(data,pri,val+1);
      #endif
    OPHND_NEXT(1);

    OPHND_CASE(OP_DEC_PRI):
      pri--;
    OPHND_NEXT(0);

    OPHND_CASE(OP_DEC_ALT):
      alt--;
    OPHND_NEXT(0);

    OPHND_CASE(OP_DEC): {
      /* the address is already verified in VerifyRelocateBytecode */
      #if defined _R_DEFAULT
        #if defined AMX_DONT_RELOCATE
          *(cell *)(void *)(data+(size_t)GETPARAM(1)) -= 1;
        #else
          *(cell *)(size_t)GETPARAM(1) -= 1;
        #endif
      #else
        AMX_REGISTER_VAR cell offs;
        offs=GETPARAM(1);
        val=_R(data,offs);
        _W(data,offs,val-1);
      #endif
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_DEC_S): {
      AMX_REGISTER_VAR cell offs;
      offs=GETPARAM(1);
      if (IS_INVALID_STACK_OFFS(offs))
        ERR_MEMACCESS();
      #if defined _R_DEFAULT
        *(cell *)(data+(size_t)(frm+offs)) -= 1;
      #else
        val=_R(data,frm+offs);
        _W(data,frm+offs,val-1);
      #endif
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_DEC_I):
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(pri))
        ERR_MEMACCESS();
      #if defined _R_DEFAULT
        *(cell *)(data+(int)pri) -= 1;
      #else
        val=_R(data,pri);
        _W(data,pri,val-1);
      #endif
    OPHND_NEXT(1);

    OPHND_CASE(OP_MOVS): {
      AMX_REGISTER_VAR cell offs;
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(pri))
        ERR_MEMACCESS();
      offs=GETPARAM(1);
      val=(cell)((ucell)pri+(ucell)offs-(ucell)1);
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(val))
        ERR_MEMACCESS();
      if (AMX_UNLIKELY(pri<=hea && hea<=offs) || AMX_UNLIKELY(pri<=stk && stk<=offs))
        ERR_MEMACCESS();
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(alt))
        ERR_MEMACCESS();
      val=(cell)((ucell)alt+(ucell)offs-(ucell)1);
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(val))
        ERR_MEMACCESS();
      if (AMX_UNLIKELY(alt<=hea && hea<=offs) || AMX_UNLIKELY(alt<=stk && stk<=offs))
        ERR_MEMACCESS();
      #if defined _R_DEFAULT
        memcpy(data+(size_t)alt, data+(size_t)pri, (size_t)offs);
      #else
        for (i=0,num=(int)offs-4; i<num; i+=4) {
          val=_R32(data,pri+i);
          _W32(data,alt+i,val);
        } /* for */
        for (num+=4; i<num; i++) {
          val=_R8(data,pri+i);
          _W8(data,alt+i,val);
        } /* for */
      #endif
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_CMPS): {
      AMX_REGISTER_VAR cell offs;
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(pri))
        ERR_MEMACCESS();
      offs=GETPARAM(1);
      val=(cell)((ucell)pri+(ucell)offs-(ucell)1);
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(val))
        ERR_MEMACCESS();
      if (AMX_UNLIKELY(pri<=hea && hea<=offs) || AMX_UNLIKELY(pri<=stk && stk<=offs))
        ERR_MEMACCESS();
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(alt))
        ERR_MEMACCESS();
      val=(cell)((ucell)alt+(ucell)offs-(ucell)1);
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(val))
        ERR_MEMACCESS();
      if (AMX_UNLIKELY(alt<=hea && hea<=offs) || AMX_UNLIKELY(alt<=stk && stk<=offs))
        ERR_MEMACCESS();
      #if defined _R_DEFAULT
        pri=memcmp(data+(size_t)alt, data+(size_t)pri, (size_t)offs);
      #else
        val=pri;
        for (i=0,num=(int)offs-4; i<num; i+=4)
          if ((pri=_R32(data,alt+i)-_R32(data,val+i))!=0)
            break;
        for (num+=4; i<num && pri==0; i++)
          pri=_R8(data,alt+i)-_R8(data,val+i);
      #endif
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_FILL): {
      AMX_REGISTER_VAR cell offs;
      AMX_REGISTER_VAR cell *cptr,*cptr2;
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(alt))
        ERR_MEMACCESS();
      offs=GETPARAM(1);
      val=(cell)((ucell)alt+(ucell)offs-(ucell)1);
      if (IS_INVALID_DATA_STACK_HEAP_OFFS(val))
        ERR_MEMACCESS();
      if (AMX_UNLIKELY(alt<=hea && hea<=offs) || AMX_UNLIKELY(alt<=stk && stk<=offs))
        ERR_MEMACCESS();
      #if defined _R_DEFAULT
        cptr=(cell *)(void *)(data+(size_t)alt);
        cptr2=(cell *)(void *)((unsigned char *)(void *)cptr+(size_t)offs);
        while (cptr<cptr2)
          *(cptr++)=pri;
      #else
        for (i=(int)alt; offs>=(int)sizeof(cell); i+=sizeof(cell), offs-=sizeof(cell))
          _W(data,i,pri);
      #endif
    } /* OPHND_CASE */
    OPHND_NEXT(1);

    OPHND_CASE(OP_HALT):
      num=GETPARAM(1);
      if (AMX_LIKELY(retval!=NULL))
        *retval=pri;
      /* store complete status
       * (stk, frm, hea and cip are already set at abort_exec)
       */
      amx->pri=pri;
      amx->alt=alt;
      if (num==AMX_ERR_SLEEP) {
        AMXEXEC_COLD_CODE(op_halt_sleep);
        amx->stk=stk;
        amx->hea=hea;
        amx->reset_stk=reset_stk;
        amx->reset_hea=reset_hea;
        amx->cip=(cell)((size_t)cip-(size_t)code+sizeof(cell));
        return num;
      } /* if */
      goto abort_exec;
    OPHND_NEXT(1);

    OPHND_CASE(OP_BOUNDS):
      if (AMX_UNLIKELY((ucell)pri>(ucell)GETPARAM(1)))
        ERR_BOUNDS();
    OPHND_NEXT(1);

    OPHND_CASE(OP_SYSREQ_PRI):
      /* save a few registers */
      amx->cip=(cell)((size_t)cip-(size_t)code-sizeof(cell));
      amx->hea=hea;
      amx->frm=frm;
      amx->stk=stk;
      #if defined AMX_USE_REGISTER_VARIABLES
        num=amx->callback(amx,pri,&val,(cell *)(void *)(data+(size_t)stk));
        pri=val;
      #else
        num=amx->callback(amx,pri,&pri,(cell *)(void *)(data+(size_t)stk));
      #endif
      if (AMX_UNLIKELY(num!=AMX_ERR_NONE)) {
      sysreq_err:
        AMXEXEC_COLD_CODE(op_sysreq_err);
        if (num==AMX_ERR_SLEEP) {
          amx->pri=pri;
          amx->alt=alt;
          amx->reset_stk=reset_stk;
          amx->reset_hea=reset_hea;
          return num;
        } /* if */
        goto abort_exec;
      } /* if */
    OPHND_NEXT(0);

    OPHND_CASE(OP_SYSREQ_C):
      /* save a few registers */
      amx->cip=(cell)((size_t)cip-(size_t)code-sizeof(cell));
      amx->hea=hea;
      amx->frm=frm;
      amx->stk=stk;
      #if defined AMX_USE_REGISTER_VARIABLES
        num=amx->callback(amx,GETPARAM(1),&val,(cell *)(void *)(data+(size_t)stk));
        pri=val;
      #else
        num=amx->callback(amx,GETPARAM(1),&pri,(cell *)(void *)(data+(size_t)stk));
      #endif
      if (AMX_UNLIKELY(num!=AMX_ERR_NONE))
        goto sysreq_err;
    OPHND_NEXT(1);

    OPHND_CASE(OP_FILE):
      /* obsolete */
      assert(0); /* this code should not occur during execution */
      ERR_INVINSTR();

    OPHND_CASE(OP_LINE):
    OPHND_NEXT(2);

    OPHND_CASE(OP_SYMBOL):
      cip=(cell *)(void *)((unsigned char *)cip+(size_t)GETPARAM(1)+sizeof(cell));
    OPHND_NEXT(1);

    OPHND_CASE(OP_SRANGE):
    OPHND_NEXT(2);

    OPHND_CASE(OP_SYMTAG):
    OPHND_NEXT(2);

    OPHND_CASE(OP_JUMP_PRI): {
      AMX_REGISTER_VAR ucell index;
      /* verify address */
      if (IS_INVALID_CODE_OFFS_NORELOC(pri,codesize))
        ERR_MEMACCESS();
      index=(ucell)pri/sizeof(cell);
      if ((amx->instr_addresses[index/8] & (unsigned char)1 << (index % 8))==0)
        ERR_MEMACCESS();
      JUMP_NORELOC(pri);
    } /* OPHND_CASE */
    OPHND_NEXT(0);

    OPHND_CASE(OP_SWITCH): {
      AMX_REGISTER_VAR cell *cptr,*cptr2;
      /* all of the addresses are verified in VerifyRelocateBytecode */
      cptr=JUMPABS(code,&GETPARAM(1))+1; /* +1, to skip the "casetbl" opcode */
      /* now cptr points at the number of records in the case table */
      cptr2=cptr+(size_t)(*cptr)*2;
      JUMP(*(cptr+1));                   /* preset to "none-matched" case */
      if (AMX_LIKELY((*cptr)<=(cell)30)) {
        while (((cptr+=2),cptr)<=cptr2) {
          if (AMX_LIKELY(*cptr!=pri))
            continue;
          JUMP(*(cptr+1));
          break;
        } /* while */
      } else {
        AMX_REGISTER_VAR cell *mid;
        cptr+=2;
        cptr2+=2;
        while (cptr<cptr2) {
          mid=cptr+((size_t)cptr2-(size_t)cptr)/((size_t)2*sizeof(cell));
          if (pri<(*mid)) {
            cptr2=mid;
            continue;
          } /* if */
          if (pri>(*mid)) {
            cptr=mid+2;
            continue;
          } /* if */
          JUMP(*(mid+1));
          break;
        } /* while */
      } /* if */
    } /* OPHND_CASE */
    OPHND_NEXT(0);

    OPHND_CASE(OP_CASETBL):
      assert(0); /* this code should not occur during execution */
      ERR_INVINSTR();

    OPHND_CASE(OP_SWAP_PRI): {
      AMX_REGISTER_VAR cell offs;
      offs=_R(data,stk);
      _W32(data,stk,pri);
      pri=offs;
    } /* OPHND_CASE */
    OPHND_NEXT(0);

    OPHND_CASE(OP_SWAP_ALT): {
      AMX_REGISTER_VAR cell offs;
      offs=_R(data,stk);
      _W32(data,stk,alt);
      alt=offs;
    } /* OPHND_CASE */
    OPHND_NEXT(0);

    OPHND_CASE(OP_PUSH_ADR):
      PUSH(frm+GETPARAM(1));
    OPHND_NEXT(1);

    OPHND_CASE(OP_NOP):
    OPHND_NEXT(0);

    OPHND_CASE(OP_SYSREQ_N): {
      AMX_REGISTER_VAR cell offs;
      offs=GETPARAM(2);
      PUSH(offs);
      /* save a few registers */
      amx->cip=(cell)((size_t)cip-(size_t)code-sizeof(cell));
      amx->hea=hea;
      amx->frm=frm;
      amx->stk=stk;
      #if defined AMX_USE_REGISTER_VARIABLES
        num=amx->callback(amx,GETPARAM(1),&val,(cell *)(void *)(data+(size_t)stk));
        pri=val;
      #else
        num=amx->callback(amx,GETPARAM(1),&pri,(cell *)(void *)(data+(size_t)stk));
      #endif
      stk+=offs+(cell)sizeof(cell);
      if (AMX_UNLIKELY(num!=AMX_ERR_NONE))
        goto sysreq_err;
    } /* OPHND_CASE */
    OPHND_NEXT(2);

    OPHND_CASE(OP_BREAK):
      assert((amx->flags & AMX_FLAG_BROWSE)==0);
      if (AMX_UNLIKELY(amx->debug!=NULL)) {
        AMXEXEC_COLD_CODE(op_break_debug);
        /* store status */
        amx->frm=frm;
        amx->stk=stk;
        amx->hea=hea;
        amx->cip=(cell)((size_t)cip-(size_t)code-sizeof(cell));
        num=amx->debug(amx);
        if (AMX_UNLIKELY(num!=AMX_ERR_NONE)) {
          if (num==AMX_ERR_SLEEP) {
            amx->pri=pri;
            amx->alt=alt;
            amx->reset_stk=reset_stk;
            amx->reset_hea=reset_hea;
            return num;
          } /* if */
          goto abort_exec;
        } /* if */
      } /* if */
    OPHND_NEXT(0);

    OPHND_CASE(OP_PUSH5_C): {
      AMX_REGISTER_VAR cell *cptr;
      ALLOCSTACK(5);
      *(cptr-1)=GETPARAM(1);
      *(cptr-2)=GETPARAM(2);
      *(cptr-3)=GETPARAM(3);
      *(cptr-4)=GETPARAM(4);
      *(cptr-5)=GETPARAM(5);
    } /* OPHND_CASE */
    OPHND_NEXT(5);

    OPHND_CASE(OP_PUSH4_C): {
      AMX_REGISTER_VAR cell *cptr;
      ALLOCSTACK(4);
      *(cptr-1)=GETPARAM(1);
      *(cptr-2)=GETPARAM(2);
      *(cptr-3)=GETPARAM(3);
      *(cptr-4)=GETPARAM(4);
    } /* OPHND_CASE */
    OPHND_NEXT(4);

    OPHND_CASE(OP_PUSH3_C): {
      AMX_REGISTER_VAR cell *cptr;
      ALLOCSTACK(3);
      *(cptr-1)=GETPARAM(1);
      *(cptr-2)=GETPARAM(2);
      *(cptr-3)=GETPARAM(3);
    } /* OPHND_CASE */
    OPHND_NEXT(3);

    OPHND_CASE(OP_PUSH2_C): {
      AMX_REGISTER_VAR cell *cptr;
      ALLOCSTACK(2);
      *(cptr-1)=GETPARAM(1);
      *(cptr-2)=GETPARAM(2);
    } /* OPHND_CASE */
    OPHND_NEXT(2);

    OPHND_CASE(OP_PUSH5): {
      AMX_REGISTER_VAR cell *cptr;
      /* the addresses are already verified in VerifyRelocateBytecode */
      ALLOCSTACK(5);
      *(cptr-1)=_R_DATA_RELOC(data,GETPARAM(1));
      *(cptr-2)=_R_DATA_RELOC(data,GETPARAM(2));
      *(cptr-3)=_R_DATA_RELOC(data,GETPARAM(3));
      *(cptr-4)=_R_DATA_RELOC(data,GETPARAM(4));
      *(cptr-5)=_R_DATA_RELOC(data,GETPARAM(5));
    } /* OPHND_CASE */
    OPHND_NEXT(5);

    OPHND_CASE(OP_PUSH4): {
      AMX_REGISTER_VAR cell *cptr;
      ALLOCSTACK(4);
      *(cptr-1)=_R_DATA_RELOC(data,GETPARAM(1));
      *(cptr-2)=_R_DATA_RELOC(data,GETPARAM(2));
      *(cptr-3)=_R_DATA_RELOC(data,GETPARAM(3));
      *(cptr-4)=_R_DATA_RELOC(data,GETPARAM(4));
    } /* OPHND_CASE */
    OPHND_NEXT(4);

    OPHND_CASE(OP_PUSH3): {
      AMX_REGISTER_VAR cell *cptr;
      ALLOCSTACK(3);
      *(cptr-1)=_R_DATA_RELOC(data,GETPARAM(1));
      *(cptr-2)=_R_DATA_RELOC(data,GETPARAM(2));
      *(cptr-3)=_R_DATA_RELOC(data,GETPARAM(3));
    } /* OPHND_CASE */
    OPHND_NEXT(3);

    OPHND_CASE(OP_PUSH2): {
      AMX_REGISTER_VAR cell *cptr;
      ALLOCSTACK(2);
      *(cptr-1)=_R_DATA_RELOC(data,GETPARAM(1));
      *(cptr-2)=_R_DATA_RELOC(data,GETPARAM(2));
    } /* OPHND_CASE */
    OPHND_NEXT(2);

    OPHND_CASE(OP_PUSH5_S): {
      AMX_REGISTER_VAR cell offs;
      AMX_REGISTER_VAR cell *cptr;
      ALLOCSTACK(5);
      if (((offs=GETPARAM(1)),IS_INVALID_STACK_OFFS(offs)))
        ERR_MEMACCESS();
      *(cptr-1)=_R(data,frm+offs);
      if (((offs=GETPARAM(2)),IS_INVALID_STACK_OFFS(offs)))
        ERR_MEMACCESS();
      *(cptr-2)=_R(data,frm+offs);
      if (((offs=GETPARAM(3)),IS_INVALID_STACK_OFFS(offs)))
        ERR_MEMACCESS();
      *(cptr-3)=_R(data,frm+offs);
      if (((offs=GETPARAM(4)),IS_INVALID_STACK_OFFS(offs)))
        ERR_MEMACCESS();
      *(cptr-4)=_R(data,frm+offs);
      if (((offs=GETPARAM(5)),IS_INVALID_STACK_OFFS(offs)))
        ERR_MEMACCESS();
      *(cptr-5)=_R(data,frm+offs);
    } /* OPHND_CASE */
    OPHND_NEXT(5);

    OPHND_CASE(OP_PUSH4_S): {
      AMX_REGISTER_VAR cell offs;
      AMX_REGISTER_VAR cell *cptr;
      ALLOCSTACK(4);
      if (((offs=GETPARAM(1)),IS_INVALID_STACK_OFFS(offs)))
        ERR_MEMACCESS();
      *(cptr-1)=_R(data,frm+offs);
      if (((offs=GETPARAM(2)),IS_INVALID_STACK_OFFS(offs)))
        ERR_MEMACCESS();
      *(cptr-2)=_R(data,frm+offs);
      if (((offs=GETPARAM(3)),IS_INVALID_STACK_OFFS(offs)))
        ERR_MEMACCESS();
      *(cptr-3)=_R(data,frm+offs);
      if (((offs=GETPARAM(4)),IS_INVALID_STACK_OFFS(offs)))
        ERR_MEMACCESS();
      *(cptr-4)=_R(data,frm+offs);
    } /* OPHND_CASE */
    OPHND_NEXT(4);

    OPHND_CASE(OP_PUSH3_S): {
      AMX_REGISTER_VAR cell offs;
      AMX_REGISTER_VAR cell *cptr;
      ALLOCSTACK(3);
      if (((offs=GETPARAM(1)),IS_INVALID_STACK_OFFS(offs)))
        ERR_MEMACCESS();
      *(cptr-1)=_R(data,frm+offs);
      if (((offs=GETPARAM(2)),IS_INVALID_STACK_OFFS(offs)))
        ERR_MEMACCESS();
      *(cptr-2)=_R(data,frm+offs);
      if (((offs=GETPARAM(3)),IS_INVALID_STACK_OFFS(offs)))
        ERR_MEMACCESS();
      *(cptr-3)=_R(data,frm+offs);
    } /* OPHND_CASE */
    OPHND_NEXT(3);

    OPHND_CASE(OP_PUSH2_S): {
      AMX_REGISTER_VAR cell offs;
      AMX_REGISTER_VAR cell *cptr;
      ALLOCSTACK(2);
      if (((offs=GETPARAM(1)),IS_INVALID_STACK_OFFS(offs)))
        ERR_MEMACCESS();
      *(cptr-1)=_R(data,frm+offs);
      if (((offs=GETPARAM(2)),IS_INVALID_STACK_OFFS(offs)))
        ERR_MEMACCESS();
      *(cptr-2)=_R(data,frm+offs);
    } /* OPHND_CASE */
    OPHND_NEXT(2);

    OPHND_CASE(OP_PUSH5_ADR): {
      AMX_REGISTER_VAR cell *cptr;
      ALLOCSTACK(5);
      *(cptr-1)=frm+GETPARAM(1);
      *(cptr-2)=frm+GETPARAM(2);
      *(cptr-3)=frm+GETPARAM(3);
      *(cptr-4)=frm+GETPARAM(4);
      *(cptr-5)=frm+GETPARAM(5);
    } /* OPHND_CASE */
    OPHND_NEXT(5);

    OPHND_CASE(OP_PUSH4_ADR): {
      AMX_REGISTER_VAR cell *cptr;
      ALLOCSTACK(4);
      *(cptr-1)=frm+GETPARAM(1);
      *(cptr-2)=frm+GETPARAM(2);
      *(cptr-3)=frm+GETPARAM(3);
      *(cptr-4)=frm+GETPARAM(4);
    } /* OPHND_CASE */
    OPHND_NEXT(4);

    OPHND_CASE(OP_PUSH3_ADR): {
      AMX_REGISTER_VAR cell *cptr;
      ALLOCSTACK(3);
      *(cptr-1)=frm+GETPARAM(1);
      *(cptr-2)=frm+GETPARAM(2);
      *(cptr-3)=frm+GETPARAM(3);
    } /* OPHND_CASE */
    OPHND_NEXT(3);

    OPHND_CASE(OP_PUSH2_ADR): {
      AMX_REGISTER_VAR cell *cptr;
      ALLOCSTACK(2);
      *(cptr-1)=frm+GETPARAM(1);
      *(cptr-2)=frm+GETPARAM(2);
    } /* OPHND_CASE */
    OPHND_NEXT(2);

    OPHND_CASE(OP_LOAD_BOTH):
      /* the addresses are already verified in VerifyRelocateBytecode */
      pri=_R_DATA_RELOC(data,GETPARAM(1));
      alt=_R_DATA_RELOC(data,GETPARAM(2));
    OPHND_NEXT(2);

    OPHND_CASE(OP_LOAD_S_BOTH): {
      AMX_REGISTER_VAR cell offs;
      offs=GETPARAM(1);
      val=GETPARAM(2);
      if (IS_INVALID_STACK_OFFS(offs))
        ERR_MEMACCESS();
      if (IS_INVALID_STACK_OFFS(val))
        ERR_MEMACCESS();
      pri=_R(data,frm+offs);
      alt=_R(data,frm+val);
    } /* OPHND_CASE */
    OPHND_NEXT(2);

    OPHND_CASE(OP_CONST):
      /* the address is already verified in VerifyRelocateBytecode */
      _W_DATA_RELOC(data,GETPARAM(1),GETPARAM(2));
    OPHND_NEXT(2);

    OPHND_CASE(OP_CONST_S): {
      AMX_REGISTER_VAR cell offs;
      offs=GETPARAM(1);
      if (IS_INVALID_STACK_OFFS(offs))
        ERR_MEMACCESS();
      _W(data,frm+offs,GETPARAM(2));
    } /* OPHND_CASE */
    OPHND_NEXT(2);

    OPHND_CASE(OP_SYSREQ_D):
    #if defined AMX_DONT_RELOCATE
      assert(0); /* this code should not occur if relocation is disabled */
      ERR_INVINSTR();
    #else
      /* save a few registers */
      amx->cip=(cell)((size_t)cip-(size_t)code-sizeof(cell));
      amx->hea=hea;
      amx->frm=frm;
      amx->stk=stk;
      pri=((AMX_NATIVE)(size_t)GETPARAM(1))(amx,(cell *)(void *)(data+(size_t)stk));
      if (AMX_UNLIKELY(amx->error!=AMX_ERR_NONE)) {
      sysreq_d_err:
        AMXEXEC_COLD_CODE(sysreq_d_err);
        num=amx->error;
        goto sysreq_err;
      }
    OPHND_NEXT(1);
    #endif

    OPHND_CASE(OP_SYSREQ_ND): {
      #if defined AMX_DONT_RELOCATE
        assert(0); /* this code should not occur if relocation is disabled */
        ERR_INVINSTR();
      #else
        AMX_REGISTER_VAR cell offs;
        offs=GETPARAM(2);
        PUSH(offs);
        /* save a few registers */
        amx->cip=(cell)((size_t)cip-(size_t)code-sizeof(cell));
        amx->hea=hea;
        amx->frm=frm;
        amx->stk=stk;
        pri=((AMX_NATIVE)(size_t)GETPARAM(1))(amx,(cell *)(void *)(data+(size_t)stk));
        stk+=offs+(cell)sizeof(cell);
        if (AMX_UNLIKELY(amx->error!=AMX_ERR_NONE))
          goto sysreq_d_err;
        OPHND_NEXT(2);
      #endif
    } /* OPHND_CASE */

    OPHND_DEFAULT();
  }

#if !(defined _MSC_VER && _MSC_VER>=1800)
err_stackerr:
  AMXEXEC_COLD_CODE(err_stackerr);
  ABORT(AMX_ERR_STACKERR);
err_bounds:
  AMXEXEC_COLD_CODE(err_bounds);
  ABORT(AMX_ERR_BOUNDS);
err_memaccess:
  AMXEXEC_COLD_CODE(err_memaccess);
  ABORT(AMX_ERR_MEMACCESS);
err_stacklow:
  AMXEXEC_COLD_CODE(err_stacklow);
  ABORT(AMX_ERR_STACKLOW);
err_heaplow:
  AMXEXEC_COLD_CODE(err_heaplow);
  ABORT(AMX_ERR_HEAPLOW);
err_divide:
  AMXEXEC_COLD_CODE(err_divide);
  ABORT(AMX_ERR_DIVIDE);
err_invinstr:
  AMXEXEC_COLD_CODE(err_invinstr);
  ABORT(AMX_ERR_INVINSTR);
#endif

abort_exec:
  amx->stk=reset_stk;
  amx->hea=reset_hea;
  amx->frm=frm;
  amx->cip=(cell)((size_t)cip-(size_t)code-sizeof(cell));
  return num;

#endif /* defined ASM32 || defined JIT */
}

#endif /* defined AMX_EXEC || defined AMX_INIT */

#endif /* defined AMX_USE_NEW_AMXEXEC */
