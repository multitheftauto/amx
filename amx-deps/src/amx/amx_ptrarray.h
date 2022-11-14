/*  Dynamic pointer array implementation for use in AMX extension modules
 *
 *  Copyright (c) Stanislav Gromov, 2018-2022
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

#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "amx.h"

#if !defined AMX_PTRARRAY_DEFAULT_SIZE || (AMX_PTRARRAY_DEFAULT_SIZE-1)<0
  #error Please define AMX_PTRARRAY_DEFAULT_SIZE before the inclusion of amx_dynarray.h
#endif


typedef struct _amx_ptrarray {
#if defined AMX_PTRARRAY_NOALLOC
  void *data[AMX_PTRARRAY_DEFAULT_SIZE];
#else
  cell size;
  void **data;
#endif
  void(*cleanup_func)(struct _amx_ptrarray *ptrarray);
  size_t num_acquisitions;
  cell least_free_index;
} amx_ptrarray;

static int   ptrarray_acquire(amx_ptrarray *ptrarray);
static void  ptrarray_release(amx_ptrarray *ptrarray);
static cell  ptrarray_insert(amx_ptrarray *ptrarray,void *value);
static int   ptrarray_remove(amx_ptrarray *ptrarray,cell index);
static void *ptrarray_get(amx_ptrarray *ptrarray,cell index);
static int   ptrarray_set(amx_ptrarray *ptrarray,cell index,void *value);
static void  ptrarray_foreach(amx_ptrarray *ptrarray,void (*func)(void *ptr));
#if defined AMX_PTRARRAY_NOALLOC
  #define    ptrarray_getsize(ptrarray) AMX_PTRARRAY_DEFAULT_SIZE
#else
  #define    ptrarray_getsize(ptrarray) ptrarray->size
#endif


#if !defined AMX_PTRARRAY_GROWTH
  #define AMX_PTRARRAY_GROWTH 4
#endif

#if defined AMX_PTRARRAY_NOALLOC
  #define DEFINE_PTRARRAY(name,cleanup_func) \
    static amx_ptrarray name = { (cell)0, { NULL }, cleanup_func, (size_t)0, (cell)0 }
#else
  #define DEFINE_PTRARRAY(name,cleanup_func) \
    static amx_ptrarray name = { (cell)0, NULL, cleanup_func, (size_t)0, (cell)0 }
#endif


static int __ptrarray_grow(amx_ptrarray *ptrarray)
{
  #if defined AMX_PTRARRAY_NOALLOC
    return 0;
  #else
    const cell old_size=ptrarray->size;
    /* integer overflow is UB, so treat the values as unsigned */
    const cell new_size=(cell)((ucell)old_size+(ucell)AMX_PTRARRAY_GROWTH);
    void **new_data;

    if (new_size<old_size)
      return 0;
    if ((new_data=(void **)realloc(ptrarray->data,sizeof(void *)*(size_t)new_size))==NULL)
      return 0;
    memcpy(new_data,ptrarray->data,sizeof(void *)*old_size);
    memset(&new_data[old_size],0,sizeof(void *)*AMX_PTRARRAY_GROWTH);
    ptrarray->data=new_data;
    ptrarray->size=new_size;
    return 1;
  #endif
}


static int ptrarray_acquire(amx_ptrarray *ptrarray)
{
  if (ptrarray->num_acquisitions==(size_t)0) {
    #if !defined AMX_PTRARRAY_NOALLOC
      ptrarray->data=(void **)malloc(sizeof(void *)*(size_t)AMX_PTRARRAY_DEFAULT_SIZE);
      if (ptrarray->data==NULL)
        return 0;
      ptrarray->size=(cell)AMX_PTRARRAY_DEFAULT_SIZE;
    #endif
    ptrarray->least_free_index=(cell)0;
    memset(ptrarray->data,0,sizeof(void *)*(size_t)AMX_PTRARRAY_DEFAULT_SIZE);
  } /* if */
  ptrarray->num_acquisitions++;
  return 1;
}

static void ptrarray_release(amx_ptrarray *ptrarray)
{
  assert(ptrarray->num_acquisitions!=(size_t)0);
  if (--ptrarray->num_acquisitions==(size_t)0) {
    if (ptrarray->cleanup_func!=NULL)
      ptrarray->cleanup_func(ptrarray);
    #if !defined AMX_PTRARRAY_NOALLOC
      free(ptrarray->data);
      ptrarray->size=(cell)0;
    #endif
  } /* if */
}

static cell ptrarray_insert(amx_ptrarray *ptrarray,void *value)
{
  cell result,index;
  assert(value!=NULL);
  index=ptrarray->least_free_index;
  if (index>=ptrarray_getsize(ptrarray)) {
    if (!__ptrarray_grow(ptrarray))
      return (cell)0;
  } /* if */
  assert(ptrarray->data[index]==NULL);
  ptrarray->data[index]=value;
  result=index;
  while (++index<ptrarray_getsize(ptrarray) && ptrarray->data[index]!=NULL) {}
  ptrarray->least_free_index=index;
  return result+(cell)1;
}

static int ptrarray_remove(amx_ptrarray *ptrarray,cell index)
{
  if ((ucell)--index>=(ucell)ptrarray_getsize(ptrarray) || ptrarray->data[index]==NULL)
    return 0;
  ptrarray->data[index]=NULL;
  if (index<ptrarray->least_free_index)
    ptrarray->least_free_index=index;
  return 1;
}

static void *ptrarray_get(amx_ptrarray *ptrarray,cell index)
{
  if ((ucell)--index>=(ucell)ptrarray_getsize(ptrarray))
    return NULL;
  return ptrarray->data[index];
}

static int ptrarray_set(amx_ptrarray *ptrarray,cell index,void *value)
{
  assert(value!=NULL);
  if ((ucell)--index>=(ucell)ptrarray_getsize(ptrarray))
    return 0;
  ptrarray->data[index]=value;
  return 1;
}

static void ptrarray_foreach(amx_ptrarray *ptrarray, void (*func)(void *ptr))
{
  cell i;
  assert(func!=NULL);
  for (i=0; i<ptrarray_getsize(ptrarray); ++i)
    if (ptrarray->data[i]!=NULL)
      func(ptrarray->data[i]);
}
