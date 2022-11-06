/*  Float arithmetic for the Pawn Abstract Machine
 *
 *  Copyright (c) Artran, Inc. 1999
 *  Written by Greg Garner (gmg@artran.com)
 *  This file may be freely used. No warranties of any kind.
 *
 * CHANGES -
 * 2002-08-27: Basic conversion of source from C++ to C by Adam D. Moss
 *             <adam@gimp.org> <aspirin@icculus.org>
 * 2003-08-29: Removal of the dynamic memory allocation and replacing two
 *             type conversion functions by macros, by Thiadmer Riemersma
 * 2003-09-22: Moved the type conversion macros to AMX.H, and simplifications
 *             of some routines, by Thiadmer Riemersma
 * 2003-11-24: A few more native functions (geometry), plus minor modifications,
 *             mostly to be compatible with dynamically loadable extension
 *             modules, by Thiadmer Riemersma
 * 2004-01-09: Adaptions for 64-bit cells (using "double precision"), by
 *             Thiadmer Riemersma
 */

#include <stdlib.h>     /* for atof() */
#include <stdio.h>      /* for NULL */
#include <assert.h>
#include <math.h>
#include "amx.h"
#if defined HAVE_FLOAT_H
  #include <float.h>
#endif

#define EXPECT_PARAMS(num) \
  do { \
    if (params[0]!=(num)*sizeof(cell)) \
      return amx_RaiseError(amx,AMX_ERR_PARAMS),0; \
  } while(0)

/*
#if defined __BORLANDC__
    #pragma resource "amxFloat.res"
#endif
*/

#if PAWN_CELL_SIZE==32
    #define REAL              float
    #if defined FLT_EPSILON
        #define REAL_EPSILON    FLT_EPSILON
    #endif
#elif PAWN_CELL_SIZE==64
    #define REAL              double
    #if defined DBL_EPSILON
        #define REAL_EPSILON    DBL_EPSILON
    #endif
#else
    #error Unsupported cell size
#endif

#define PI  3.1415926535897932384626433832795

enum floatround_method {
    floatround_round,
    floatround_floor,
    floatround_ceil,
    floatround_tozero,
    floatround_unbiased
};
enum anglemode {
    radian,
    degrees,
    grades
};

/******************************************************************/
static cell AMX_NATIVE_CALL n_float(AMX *amx,const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = integer value to convert to a float
    */
    REAL fValue;

    EXPECT_PARAMS(1);

    (void)amx;
    /* Convert to a float. Calls the compilers long to float conversion. */
    fValue = (REAL)params[1];

    /* Return the cell. */
    return amx_ftoc(fValue);
}

/******************************************************************/
/* Return integer part of float, truncated (same as floatround
 * with mode 3)
 */
static cell AMX_NATIVE_CALL n_floatint(AMX *amx,const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = float operand
    */
    REAL fA;

    EXPECT_PARAMS(1);

    fA = amx_ctof(params[1]);
    if (fA >= 0.0)
        fA = (REAL)(floor((double)fA));
    else
        fA = (REAL)(ceil((double)fA));
    (void)amx;
    return (cell)fA;
}

/******************************************************************/
static cell AMX_NATIVE_CALL n_strfloat(AMX *amx,const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = virtual string address to convert to a float
    */
    char szSource[60];
    cell *pString;
    REAL fNum;
    int nLen;

    EXPECT_PARAMS(1);

    /* They should have sent us 1 cell. */
    assert(params[0]/sizeof(cell) == 1);

    /* Get the real address of the string. */
    if (amx_GetAddr(amx, params[1], &pString) != AMX_ERR_NONE)
        return amx_RaiseError(amx, AMX_ERR_NATIVE), 0;

    /* Find out how long the string is in characters. */
    amx_StrLen(pString, &nLen);
    if (nLen == 0 || nLen >= sizeof szSource)
        return 0;

    /* Now convert the Pawn string into a C type null terminated string */
    amx_GetString(szSource, pString, 0, sizeof szSource);

    /* Now convert this to a float. */
    fNum = (REAL)atof(szSource);

    return amx_ftoc(fNum);
}

/******************************************************************/
static cell AMX_NATIVE_CALL n_floatmul(AMX *amx,const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = float operand 1
    *   params[2] = float operand 2
    */
    REAL fRes;

    EXPECT_PARAMS(2);

    fRes = amx_ctof(params[1]) * amx_ctof(params[2]);
    (void)amx;
    return amx_ftoc(fRes);
}

/******************************************************************/
static cell AMX_NATIVE_CALL n_floatdiv(AMX *amx,const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = float dividend (top)
    *   params[2] = float divisor (bottom)
    */
    REAL fRes;

    EXPECT_PARAMS(2);

    fRes = amx_ctof(params[1]) / amx_ctof(params[2]);
    (void)amx;
    return amx_ftoc(fRes);
}

/******************************************************************/
static cell AMX_NATIVE_CALL n_floatadd(AMX *amx,const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = float operand 1
    *   params[2] = float operand 2
    */
    REAL fRes;

    EXPECT_PARAMS(2);

    fRes = amx_ctof(params[1]) + amx_ctof(params[2]);
    (void)amx;
    return amx_ftoc(fRes);
}

/******************************************************************/
static cell AMX_NATIVE_CALL n_floatsub(AMX *amx,const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = float operand 1
    *   params[2] = float operand 2
    */
    REAL fRes;

    EXPECT_PARAMS(2);

    fRes = amx_ctof(params[1]) - amx_ctof(params[2]);
    (void)amx;
    return amx_ftoc(fRes);
}

/******************************************************************/
/* Return fractional part of float */
static cell AMX_NATIVE_CALL n_floatfract(AMX *amx,const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = float operand
    */
    REAL fA;

    EXPECT_PARAMS(1);

    fA = amx_ctof(params[1]);
    fA = fA - (REAL)(floor((double)fA));
    (void)amx;
    return amx_ftoc(fA);
}

/******************************************************************/
/* Return integer part of float, rounded */
static cell AMX_NATIVE_CALL n_floatround(AMX *amx,const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = float operand
    *   params[2] = Type of rounding (integer)
    */
    REAL fA;

    EXPECT_PARAMS(2);

    (void)amx;
    fA = amx_ctof(params[1]);
    switch ((int)params[2])
    {
        case floatround_floor:  /* round downwards */
            fA = (REAL)(floor((double)fA));
            break;
        case floatround_ceil:   /* round upwards */
            fA = (REAL)(ceil((double)fA));
            break;
        case floatround_tozero: /* round towards zero (truncate) */
            if (fA >= 0.0)
                fA = (REAL)(floor((double)fA));
            else
                fA = (REAL)(ceil((double)fA));
            break;
        default:      /* standard, round to nearest */
            fA = (REAL)(floor((double)fA + 0.5));
            break;
    } /* switch */

    return (cell)fA;
}

/******************************************************************/
static cell AMX_NATIVE_CALL n_floatcmp(AMX *amx,const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = float operand 1
    *   params[2] = float operand 2
    */
    REAL fA, fB;

    EXPECT_PARAMS(2);

    (void)amx;
    fA = amx_ctof(params[1]);
    fB = amx_ctof(params[2]);
    if (fA > fB)
        return 1;
    if (fA < fB)
        return -1;
    return 0;

}

/******************************************************************/
static cell AMX_NATIVE_CALL n_floatsqroot(AMX *amx,const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = float operand
    */
    REAL fA;

    EXPECT_PARAMS(1);

    fA = amx_ctof(params[1]);
    fA = (REAL)sqrt(fA);
    if (fA < 0.0)
        return amx_RaiseError(amx, AMX_ERR_DOMAIN), 0;
    return amx_ftoc(fA);
}

/******************************************************************/
static cell AMX_NATIVE_CALL n_floatpower(AMX *amx,const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = float operand 1 (base)
    *   params[2] = float operand 2 (exponent)
    */
    REAL fA, fB;

    EXPECT_PARAMS(2);

    fA = amx_ctof(params[1]);
    fB = amx_ctof(params[2]);
    fA = (REAL)pow(fA, fB);
    (void)amx;
    return amx_ftoc(fA);
}

/******************************************************************/
static cell AMX_NATIVE_CALL n_floatlog(AMX *amx,const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = float operand 1 (value)
    *   params[2] = float operand 2 (base)
    */
    REAL fValue, fBase;
#if defined REAL_EPSILON
    REAL fTemp;
#endif
    int base10;

    EXPECT_PARAMS(2);

    fValue = amx_ctof(params[1]);
    fBase = amx_ctof(params[2]);
    if (fValue <= 0.0 || fBase <= 0.0)
        return amx_RaiseError(amx, AMX_ERR_DOMAIN), 0;
#if defined REAL_EPSILON
    fTemp = fBase - (REAL)10.0;
    if (fTemp < 0.0)
        fTemp = -fTemp;
    base10 = (fTemp < REAL_EPSILON);
#else
    base10 = (fBase == 10.0); // ??? epsilon
#endif
    if (base10)
        fValue = (REAL)log10(fValue);
    else
        fValue = (REAL)(log(fValue) / log(fBase));
    return amx_ftoc(fValue);
}

static REAL ToRadians(REAL angle, cell radix)
{
    switch ((int)radix)
    {
        case degrees: /* degrees, sexagesimal system (technically: degrees/minutes/seconds) */
            return (REAL)(angle * PI / 180.0);
        case grades:  /* grades, centesimal system */
            return (REAL)(angle * PI / 200.0);
        default:                /* assume already radian */
            return angle;
    } /* switch */
}

static REAL FromRadians(REAL angle, cell radix)
{
    switch ((int)radix)
    {
        case degrees: /* degrees, sexagesimal system (technically: degrees/minutes/seconds) */
            return (REAL)(angle * 180.0 / PI);
        case grades:  /* grades, centesimal system */
            return (REAL)(angle * 200.0 / PI);
        default:                /* assume already radian */
            return angle;
    } /* switch */
}

/******************************************************************/
static cell AMX_NATIVE_CALL n_floatsin(AMX *amx,const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = float operand 1 (angle)
    *   params[2] = float operand 2 (radix)
    */
    REAL fA;

    EXPECT_PARAMS(2);

    fA = amx_ctof(params[1]);
    fA = ToRadians(fA, params[2]);
    fA = (REAL)sin(fA);
    (void)amx;
    return amx_ftoc(fA);
}

/******************************************************************/
static cell AMX_NATIVE_CALL n_floatcos(AMX *amx,const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = float operand 1 (angle)
    *   params[2] = float operand 2 (radix)
    */
    REAL fA;

    EXPECT_PARAMS(2);

    fA = amx_ctof(params[1]);
    fA = ToRadians(fA, params[2]);
    fA = (REAL)cos(fA);
    (void)amx;
    return amx_ftoc(fA);
}

/******************************************************************/
static cell AMX_NATIVE_CALL n_floattan(AMX *amx,const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = float operand 1 (angle)
    *   params[2] = float operand 2 (radix)
    */
    REAL fA;

    EXPECT_PARAMS(2);

    fA = amx_ctof(params[1]);
    fA = ToRadians(fA, params[2]);
    fA = (REAL)tan(fA);
    (void)amx;
    return amx_ftoc(fA);
}

/******************************************************************/
static cell AMX_NATIVE_CALL n_floatasin(AMX *amx, const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = float operand 1 (value)
    *   params[2] = float operand 2 (radix)
    */
    REAL fA;

    EXPECT_PARAMS(2);

    fA = amx_ctof(params[1]);
    if (fA < -1.0 || fA > 1.0)
        return amx_RaiseError(amx, AMX_ERR_DOMAIN), 0;
    fA = (REAL)asin(fA);
    fA = FromRadians(fA, params[2]);
    return amx_ftoc(fA);
}

/******************************************************************/
static cell AMX_NATIVE_CALL n_floatacos(AMX *amx, const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = float operand 1 (value)
    *   params[2] = float operand 2 (radix)
    */
    REAL fA;

    EXPECT_PARAMS(2);

    fA = amx_ctof(params[1]);
    if (fA < -1.0 || fA > 1.0)
        return amx_RaiseError(amx, AMX_ERR_DOMAIN), 0;
    fA = (REAL)acos(fA);
    fA = FromRadians(fA, params[2]);
    return amx_ftoc(fA);
}

/******************************************************************/
static cell AMX_NATIVE_CALL n_floatatan(AMX *amx, const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = float operand 1 (value)
    *   params[2] = float operand 2 (radix)
    */
    REAL fA;

    EXPECT_PARAMS(2);

    fA = amx_ctof(params[1]);
    fA = (REAL)atan(fA);
    fA = FromRadians(fA, params[2]);
    return amx_ftoc(fA);
}

/******************************************************************/
static cell AMX_NATIVE_CALL n_floatatan2(AMX *amx, const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = float operand 1 (y)
    *   params[2] = float operand 2 (x)
    *   params[3] = float operand 3 (radix)
    */
    REAL fA, fB;

    EXPECT_PARAMS(3);

    fA = amx_ctof(params[1]);
    fB = amx_ctof(params[2]);
    fA = (REAL)atan2(fA, fB);
    fA = FromRadians(fA, params[3]);
    return amx_ftoc(fA);
}

/******************************************************************/
static cell AMX_NATIVE_CALL n_floatabs(AMX *amx,const cell *params)
{
    /*
    *   params[0] = number of bytes
    *   params[1] = float operand
    */
    REAL fA;

    EXPECT_PARAMS(1);

    fA = amx_ctof(params[1]);
    if (fA < 0.0)
        fA = -fA;
    (void)amx;
    return amx_ftoc(fA);
}

static const AMX_NATIVE_INFO natives[] = {
  { "float",       n_float      },
  { "floatint",    n_floatint   },
  { "strfloat",    n_strfloat   },
  { "floatmul",    n_floatmul   },
  { "floatdiv",    n_floatdiv   },
  { "floatadd",    n_floatadd   },
  { "floatsub",    n_floatsub   },
  { "floatfract",  n_floatfract },
  { "floatround",  n_floatround },
  { "floatcmp",    n_floatcmp   },
  { "floatsqroot", n_floatsqroot},
  { "floatpower",  n_floatpower },
  { "floatlog",    n_floatlog   },
  { "floatsin",    n_floatsin   },
  { "floatcos",    n_floatcos   },
  { "floattan",    n_floattan   },
  { "floatasin",   n_floatasin  },
  { "floatacos",   n_floatacos  },
  { "floatatan",   n_floatatan  },
  { "floatatan2",  n_floatatan2 },
  { "floatabs",    n_floatabs   },
  { NULL, NULL }        /* terminator */
};

int AMXEXPORT AMXAPI amx_FloatInit(AMX *amx)
{
  return amx_Register(amx,natives,-1);
}

int AMXEXPORT AMXAPI amx_FloatCleanup(AMX *amx)
{
  (void)amx;
  return AMX_ERR_NONE;
}
