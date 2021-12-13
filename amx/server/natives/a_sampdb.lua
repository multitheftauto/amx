function db_close(amx, db)
	sqlite3CloseDB(amx.cptr, db)
end

function db_free_result(amx, dbResultID)
	g_DBResults[dbResultID] = nil
end

function db_field_name(amx, dbresult, fieldIndex, outbuf, maxlength)
	local colname = dbresult.columns[fieldIndex+1]
	if #colname < maxlength then
		writeMemString(amx, outbuf, colname)
		return true
	end
	return false
end

function db_get_field(amx, dbresult, fieldIndex, outbuf, maxlength)
	if dbresult[dbresult.row] then
		local data = dbresult[dbresult.row][fieldIndex+1]
		if #data < maxlength then
			writeMemString(amx, outbuf, data)
			return true
		end
	end
	return false
end

function db_get_field_assoc(amx, dbresult, fieldName, outbuf, maxlength)
	local fieldIndex = table.find(dbresult.columns, fieldName)
	return fieldIndex and db_get_field(amx, dbresult, fieldIndex-1, outbuf, maxlength)
end

function db_next_row(amx, dbresult)
	dbresult.row = dbresult.row + 1
end

function db_num_fields(amx, dbresult)
	return #dbresult.columns
end

function db_num_rows(amx, dbresult)
	return #dbresult
end

function db_open(amx, dbName)
	return sqlite3OpenDB(amx.cptr, dbName)
end

function db_query(amx, db, query)
	local dbresult = sqlite3Query(amx.cptr, db, query)
	if type(dbresult) == 'table' then
		dbresult.row = 1
		return table.insert(g_DBResults, dbresult)
	end
	return 0
end
