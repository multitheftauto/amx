#include "../amx/amx.h"

static cell AMX_NATIVE_CALL n_VectorSize(AMX *amx, cell *params)
{
	CHECK_PARAMS(3, "VectorSize");
	VECTOR v;

	v.X = amx_ctof(params[1]);
	v.Y = amx_ctof(params[2]);
	v.Z = amx_ctof(params[3]);

	float fResult = VectorSize(&v);

	return amx_ftoc(fResult);
}

static cell AMX_NATIVE_CALL n_asin(AMX *amx, cell *params)
{
	CHECK_PARAMS(1, "asin");
	float fResult = (float)(asin(amx_ctof(params[1])) * 180 / PI);
	return amx_ftoc(fResult);
}

static cell AMX_NATIVE_CALL n_acos(AMX *amx, cell *params)
{
	CHECK_PARAMS(1, "acos");
	float fResult = (float)(acos(amx_ctof(params[1])) * 180 / PI);
	return amx_ftoc(fResult);
}

static cell AMX_NATIVE_CALL n_atan(AMX *amx, cell *params)
{
	CHECK_PARAMS(1, "atan");
	float fResult = (float)(atan(amx_ctof(params[1])) * 180 / PI);
	return amx_ftoc(fResult);
}

static cell AMX_NATIVE_CALL n_atan2(AMX *amx, cell *params)
{
	CHECK_PARAMS(2, "atan2");
	float fResult = (float)(atan2(amx_ctof(params[1]), amx_ctof(params[2])) * 180 / PI);
	return amx_ftoc(fResult);
}

//----------------------------------------------------------------------------------
AMX_NATIVE_INFO sampMaths_Natives[] = {
  { "VectorSize",  n_VectorSize },
  { "asin",  n_asin },
  { "acos",  n_acos },
  { "atan",  n_atan },
  { "atan2",  n_atan2 },
  { NULL, NULL }        /* terminator */
};

int AMXEXPORT amx_sampMathsInit(AMX *amx)
{
	return amx_Register(amx, sampMaths_Natives, -1);
}

int AMXEXPORT amx_sampMathsCleanup(AMX *amx)
{
	return AMX_ERR_NONE;
}
