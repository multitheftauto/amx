-- Now we have all of RESTful types of requests. Our function is better!
-- The SAMP documentation said about 'url' - "The URL you want to request. (Without 'http://')"
-- I made a check. The state without a protocol is called as 'default'.
-- HTTP and HTTPS you can put into URL if you want. It works fine.
-- TODO: An "index" argument only for compatibility.
function HTTP(amx, index, type, url, data, callback)

	local protomatch = pregMatch(url,'^(\\w+):\\/\\/')
	local proto = protomatch[1] or 'default'
	-- if somebody will try to put here ftp:// ssh:// etc...
	if proto ~= 'http' and proto ~= 'https' and proto ~= 'default' then
		print('Current protocol is not supported')
		return 0
	end
	local typesToText = {
		'GET',
		'POST',
		'HEAD',
		[-4] = 'PUT',
		[-5] = 'PATCH',
		[-6] = 'DELETE',
		[-7] = 'COPY',
		[-8] = 'OPTIONS',
		[-9] = 'LINK',
		[-10] = 'UNLINK',
		[-11] = 'PURGE',
		[-12] = 'LOCK',
		[-13] = 'UNLOCK',
		[-14] = 'PROPFIND',
		[-15] = 'VIEW'
	}
	local sendOptions = {
		queueName = "amx." .. getResourceName(amx.res) .. "." .. amx.name,
		postData = data,
		method = typesToText[tonumber(type)],
	}
	local successRemote = fetchRemote(url, sendOptions,
	function (responseData, responseInfo)
		local error = responseInfo.statusCode
		if error == 0 then
			procCallInternal(amx, callback, index, 200, responseData)
		elseif error >= 1 and error <= 89 then
			procCallInternal(amx, callback, index, 3, responseData)
		elseif error == 1006 or error == 1005 then
			procCallInternal(amx, callback, index, 1, responseData)
		elseif error == 1007 then
			procCallInternal(amx, callback, index, 5, responseData)
		else
			procCallInternal(amx, callback, index, error, responseData)
		end
	end)
	if not successRemote then
		return 0
	end
	return 1
end
