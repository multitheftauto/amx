function db_open(amx, dbName)
	local db = sqlite3OpenDB(amx.cptr, dbName)
	if db then
		table.insert(g_OpenDBs, db)
	end
	return db
end

function db_close(amx, db)
	if not sqlite3CloseDB(amx.cptr, db) then
		return false
	end
	for id, opendb in ipairs(g_OpenDBs) do
		if opendb == db then
			table.remove(g_OpenDBs, id)
			break
		end
	end
	return true
end

function db_query(amx, db, query)
	local dbresult = sqlite3Query(amx.cptr, db, query)
	if type(dbresult) == 'table' then
		dbresult.row = 1
		return table.insert(g_DBResults, dbresult)
	end
	return 0
end

function db_free_result(amx, dbResultID)
	if not g_DBResults[dbResultID] then
		return false
	end
	g_DBResults[dbResultID] = nil
	return true
end

function db_num_rows(amx, dbResultID)
	local dbresult = g_DBResults[dbResultID]
	if not dbresult then
		return 0
	end
	return #dbresult
end

function db_next_row(amx, dbResultID)
	local dbresult = g_DBResults[dbResultID]
	if not dbresult or dbresult.row >= #dbresult then
		return false
	end
	dbresult.row = dbresult.row + 1
	return true
end

function db_num_fields(amx, dbResultID)
	local dbresult = g_DBResults[dbResultID]
	if not dbresult or not dbresult.columns then
		return 0
	end
	return #dbresult.columns
end

function db_field_name(amx, dbResultID, fieldIndex, outbuf, maxlength)
	local dbresult, idx = g_DBResults[dbResultID], fieldIndex + 1
	if not dbresult or not dbresult.columns then
		return false
	end
	if idx < 1 or idx > #dbresult.columns then
		return false
	end
	local colname = dbresult.columns[idx]
	local len = math.min(#colname, maxlength)
	writeMemString(amx, outbuf, string.sub(colname, 1, len))
	return true
end

function db_get_field(amx, dbResultID, fieldIndex, outbuf, maxlength)
	local dbresult, idx = g_DBResults[dbResultID], fieldIndex + 1
	if not dbresult or not dbresult.columns or not dbresult[dbresult.row] then
		return false
	end
	if idx < 1 or idx > #dbresult.columns then
		return false
	end
	local data = tostring(dbresult[dbresult.row][idx] or '')
	local len = math.min(#data, maxlength)
	writeMemString(amx, outbuf, string.sub(data, 1, len))
	return true
end

function db_get_field_int(amx, dbResultID, fieldIndex)
	local dbresult, idx = g_DBResults[dbResultID], fieldIndex + 1
	if not dbresult or not dbresult.columns or not dbresult[dbresult.row] then
		return 0
	end
	if idx < 1 or idx > #dbresult.columns then
		return 0
	end
	local data = dbresult[dbresult.row][idx]
	return math.floor(tonumber(data) or 0)
end

function db_get_field_float(amx, dbResultID, fieldIndex)
	local dbresult, idx = g_DBResults[dbResultID], fieldIndex + 1
	if not dbresult or not dbresult.columns or not dbresult[dbresult.row] then
		return float2cell(0)
	end
	if idx < 1 or idx > #dbresult.columns then
		return float2cell(0)
	end
	local data = dbresult[dbresult.row][idx]
	return float2cell(tonumber(data) or 0)
end

function db_get_field_assoc(amx, dbResultID, fieldName, outbuf, maxlength)
	local dbresult = g_DBResults[dbResultID]
	if not dbresult or not dbresult.columns then
		return false
	end
	local fieldIndex = table.find(dbresult.columns, fieldName)
	if fieldIndex then
		return db_get_field(amx, dbResultID, fieldIndex - 1, outbuf, maxlength)
	end
	return false
end

function db_get_field_assoc_int(amx, dbResultID, fieldName)
	local dbresult = g_DBResults[dbResultID]
	if not dbresult or not dbresult.columns then
		return 0
	end
	local fieldIndex = table.find(dbresult.columns, fieldName)
	if fieldIndex then
		return db_get_field_int(amx, dbResultID, fieldIndex - 1)
	end
	return 0
end

function db_get_field_assoc_float(amx, dbResultID, fieldName)
	local dbresult = g_DBResults[dbResultID]
	if not dbresult or not dbresult.columns then
		return float2cell(0)
	end
	local fieldIndex = table.find(dbresult.columns, fieldName)
	if fieldIndex then
		return db_get_field_float(amx, dbResultID, fieldIndex - 1)
	end
	return float2cell(0)
end

function db_get_mem_handle(amx, db)
	notImplemented('db_get_mem_handle')
	return 0
end

function db_get_result_mem_handle(amx, dbresult)
	notImplemented('db_get_result_mem_handle')
	return 0
end

function db_debug_openfiles(amx)
	return #g_OpenDBs
end

function db_debug_openresults(amx)
	local results = 0
	for _ in pairs(g_DBResults) do
		results = results + 1
	end
	return results
end
