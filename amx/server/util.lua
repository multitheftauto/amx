g_ResRoot = getResourceRootElement(getThisResource())

--[[
local function fndebug(...)
	local args = { ... }
	for i,name in ipairs(args) do
		local fn = _G[name]
		_G[name] = function(...)
			local args = { ... }
			local result = fn(...)

			local logstr = 'Server: ' .. name .. '('
			for i,a in ipairs(args) do
				if i > 1 then
					logstr = logstr .. ', '
				end
				if type(a) == 'userdata' then
					if getElementType(a) == 'player' then
						a = getClientName(a)
					else
						a = 'element:' .. getElementType(a)
					end
				elseif type(a) == 'string' then
					a = '"' .. a .. '"'
				else
					a = tostring(a)
				end
				logstr = logstr .. a
			end
			logstr = logstr .. ') = ' .. tostring(result)
			outputConsole(logstr)
			return result
		end
	end
end
fndebug(
--	'setCameraMatrix',
--	'setCameraInterior',
--	'setCameraTarget',
--	'setElementInterior',
--	'spawnPlayer'
	'createObject'
)
--]]

function clientCall(player, fnName, ...)
	triggerClientEvent(player, 'onClientCall', g_ResRoot, fnName, ...)
end

g_Keys = {
	[1] = 'mouse1',
	[2] = 'mouse2',
	[3] = 'mouse3',
	[4] = 'mouse4',
	[5] = 'mouse5',
	[6] = 'mouse_wheel_up',
	[7] = 'mouse_wheel_down',
	[8] = 'arrow_l',
	[9] = 'arrow_u',
	[10] = 'arrow_r',
	[11] = 'arrow_d',
	[12] = '0',
	[13] = '1',
	[14] = '2',
	[15] = '3',
	[16] = '4',
	[17] = '5',
	[18] = '6',
	[19] = '7',
	[20] = '8',
	[21] = '9',
	[22] = 'a',
	[23] = 'b',
	[24] = 'c',
	[25] = 'd',
	[26] = 'e',
	[27] = 'f',
	[28] = 'g',
	[29] = 'h',
	[30] = 'i',
	[31] = 'j',
	[32] = 'k',
	[33] = 'l',
	[34] = 'm',
	[35] = 'n',
	[36] = 'o',
	[37] = 'p',
	[38] = 'q',
	[39] = 'r',
	[40] = 's',
	[41] = 't',
	[42] = 'u',
	[43] = 'v',
	[44] = 'w',
	[45] = 'x',
	[46] = 'y',
	[47] = 'z',
	[48] = 'num_0',
	[49] = 'num_1',
	[50] = 'num_2',
	[51] = 'num_3',
	[52] = 'num_4',
	[53] = 'num_5',
	[54] = 'num_6',
	[55] = 'num_7',
	[56] = 'num_8',
	[57] = 'num_9',
	[58] = 'num_mul',
	[59] = 'num_add',
	[60] = 'num_sep',
	[61] = 'num_sub',
	[62] = 'num_div',
	[63] = 'num_dec',
	[64] = 'F1',
	[65] = 'F2',
	[66] = 'F3',
	[67] = 'F4',
	[68] = 'F5',
	[69] = 'F6',
	[70] = 'F7',
	[71] = 'F8',
	[72] = 'F9',
	[73] = 'F10',
	[74] = 'F11',
	[75] = 'F12',
	[76] = 'backspace',
	[77] = 'tab',
	[78] = 'lalt',
	[79] = 'ralt',
	[80] = 'enter',
	[81] = 'space',
	[82] = 'pgup',
	[83] = 'pgdn',
	[84] = 'end',
	[85] = 'home',
	[86] = 'insert',
	[87] = 'delete',
	[88] = 'lshift',
	[89] = 'rshift',
	[90] = 'lctrl',
	[91] = 'rctrl',
	[92] = '[',
	[93] = ']',
	[94] = 'pause',
	[95] = 'capslock',
	[96] = 'scroll',
	[97] = ';',
	[98] = ',',
	[99] = '-',
	[100] = '.',
	[101] = '/',
	[102] = '#',
	[103] = '\\',
	[104] = '=',
}

g_EventNames = {
	OnPlayerConnect = true,
	OnPlayerDisconnect = true,
	OnPlayerShoot = true,
	OnPlayerEnterCheckpoint = true,
	OnPlayerLeaveCheckpoint = true,
	OnPlayerEnterRaceCheckpoint = true,
	OnPlayerLeaveRaceCheckpoint = true,
	OnVehicleStreamIn = true,
	OnPlayerStreamIn = true,
	OnVehicleStreamOut = true,
	OnPlayerStreamOut = true,
	OnPlayerExitedMenu = true,
	OnPlayerSelectedMenuRow = true,
	OnDialogResponse = true,
	OnGameModeInit = true,
	OnFilterScriptInit = true,
	OnPlayerConnect = true,
	OnGameModeExit = true,
	OnFilterScriptExit = true,
	OnPlayerRequestClass = true,
	OnPlayerUpdate = true,
	OnPlayerConnect = true,
	OnPlayerKeyStateChange = true,
	OnKeyPress = true,
	OnPlayerRequestClass = true,
	OnPlayerRequestSpawn = true,
	OnPlayerSpawn = true,
	OnPlayerText = true,
	OnPlayerShootingPlayer = true,
	OnPlayerWeaponSwitch = true,
	OnPlayerDeath = true,
	OnPlayerDisconnect = true,
	OnVehicleSpawn = true,
	OnBotEnterVehicle = true,
	OnPlayerEnterVehicle = true,
	OnBotExitVehicle = true,
	OnPlayerExitVehicle = true,
	OnVehicleDeath = true,
	OnVehicleDamage = true,
	OnMarkerHit = true,
	OnMarkerLeave = true,
	OnBotDeath = true,
	OnBotPickUpPickup = true,
	OnPlayerPickUpPickup = true,
	OnPlayerCommandText = true,
	OnPlayerClickWorld = true,
	OnPlayerClickWorldPlayer = true,
	OnPlayerClickWorldObject = true,
	OnPlayerClickWorldVehicle = true,
	OnPlayerPickUpPickup = true,
	OnObjectMoved = true,
	OnPlayerObjectMoved = true,
	OnBotConnect = true,
	OnMarkerCreate = true,
	OnPlayerStateChange = true,
	OnBotStateChange = true,
}

local allowedRPC = {
	procCallOnAll = true,
	setCameraMatrix = true,
	setCameraInterior = true,
	setElementInterior = true,
	spawnPlayer = true,
	syncPlayerWeapons = true,
	setGarageOpen = true,
	requestClass = true,
	requestSpawn = true
}

addEvent('onCall', true)
addEventHandler('onCall', g_ResRoot,
	function(fnName, ...)
		if allowedRPC[fnName] and _G[fnName] then
			_G[fnName](...)
		end
	end,
	false
)

function isPlayerInACLGroup(player, groupName)
	local account = getPlayerAccount(player)
	local group = aclGetGroup(groupName)
	if not account or not group then
		return false
	end
	local accountName = getAccountName(account)
	for i,obj in ipairs(aclGroupListObjects(group)) do
		if obj == 'user.' .. accountName or obj == 'user.*' then
			return true
		end
	end
	return false
end

local _warpPedIntoVehicle = warpPedIntoVehicle
function warpPedIntoVehicle(player, vehicle, seat)
	removePedFromVehicle(player)
	g_Players[getElemID(player)].vehicle = vehicle
	setTimer(_warpPedIntoVehicle, 500, 1, player, vehicle, seat)
end

local _bindKey = bindKey
function bindKey(player, key, ...)
	if type(key) == 'string' then
		return _bindKey(player, key, ...)
	elseif type(key) == 'table' then
		local result = true
		for i,k in ipairs(key) do
			result = result and _bindKey(player, k, ...)
		end
		return result
	end
end

local _unbindKey = unbindKey
function unbindKey(player, key, ...)
	if type(key) == 'string' then
		return _unbindKey(player, key, ...)
	elseif type(key) == 'table' then
		local result = true
		for i,k in ipairs(key) do
			result = result and _unbindKey(player, k, ...)
		end
		return result
	end
end

local _isPedDead = isPedDead
function isPedDead(player)
	if _isPedDead(player) then
		return true
	end
	local x, y, z = getElementPosition(player)
	return x == 0 and y == 0 and z == 0
end

local _spawnPlayer = spawnPlayer
function spawnPlayer(player, x, y, z, r, skin, interior, ...)
	local result = _spawnPlayer(player, x, y, z, r, skin, interior, ...)
	return result
end

function destroyBlipsAttachedTo(elem)
	table.each(table.filter(getAttachedElements(elem) or {}, getElementType, 'blip'), destroyElement)
end

function giveWeapons(player, weapons, currentslot)
	for slot,weapon in pairs(weapons) do
		giveWeapon(player, weapon.id, weapon.ammo)
	end
	if currentslot then
		setPedWeaponSlot(player, currenslot)
	end
end

function isTimer(timer)
	return timer and table.find(getTimers(), timer) and true
end

function getElemAMX(elem)
	return elem and isElement(elem) and g_LoadedAMXs[getElementData(elem, 'amx.amxfile')]
end

function setElemAMX(elem, amx)
	if elem and isElement(elem) then
		setElementData(elem, 'amx.amxfile', amx and amx.name)
	end
end

-- List functions

function addElem(amx, listname, elem)
	local list
	if not elem then
		list = amx
		elem = listname
		amx = nil
	else
		list = amx[listname]
	end

	local id
	local globList
	local newtable = { elem = elem }
	if amx then
		setElemAMX(elem, amx)
		globList = _G['g_' .. listname:sub(1, 1):upper() .. listname:sub(2)]
		if globList then
			id = 0
			-- vehicles in sa-mp start at ID 1
			if listname == 'vehicles' then
				id = 1
			end
			while globList[id] do
				id = id + 1
			end
			globList[id] = newtable
		end
	end

	if not id then
		id = 0
		while list[id] do
			id = id + 1
		end
	end
	list[id] = newtable
	setElemID(elem, id)
	return id, newtable
end

function removeElem(amx, listname, elem)
	local list
	if not elem then
		list = amx
		elem = listname
		amx = nil
	else
		list = amx[listname]
	end

	local id = table.find(list, 'elem', elem)
	if id then
		list[id] = nil
		setElemID(elem, nil)
		if amx then
			setElemAMX(elem, nil)
			list = _G['g_' .. listname:sub(1, 1):upper() .. listname:sub(2)]
			if list then
				list[id] = nil
			end
		end
		return id
	end
end

function getElemID(elem)
	return elem and isElement(elem) and getElementData(elem, 'amx.id')
end

function setElemID(elem, id)
	if elem and isElement(elem) then
		setElementData(elem, 'amx.id', id)
	end
end

function getPlayerState(player)
	return g_Players[getElemID(player)] and g_Players[getElemID(player)].state or PLAYER_STATE_ONFOOT
end

function getBotState(bot)
	return g_Bots[getElemID(bot)] and g_Bots[getElemID(bot)].state or PLAYER_STATE_ONFOOT
end

function setPlayerState(player, state)
	local playerID = getElemID(player)
	local oldState = g_Players[playerID].state or PLAYER_STATE_ONFOOT
	g_Players[playerID].state = state
	procCallOnAll('OnPlayerStateChange', playerID, state, oldState)
end

function setBotState(bot, state)
	local botID = getElemID(bot)
	local oldState = g_Bots[botID].state or PLAYER_STATE_ONFOOT
	g_Bots[botID].state = state
	procCallOnAll('OnBotStateChange', botID, state, oldState)
end

-- Table extensions

local _table_insert = table.insert
function table.insert(t, i, v)
	if not v then
		local id = #t+1
		t[id] = i
		return id
	else
		_table_insert(t, i, v)
		return i
	end
end

function table.insert0(t, v)
	local id
	if not t[0] then
		id = 0
	else
		id = #t + 1
	end
	t[id] = v
	return id
end

function table.append(t, ...)
	local args = { ... }
	for i,a in ipairs(args) do
		t[#t+1] = a
	end
	return t
end

function table.keys(t)
	local result = {}
	for k,v in pairs(t) do
		result[#result+1] = k
	end
	return result
end

local _table_sort = table.sort
function table.sort(t, ...)
	_table_sort(t, ...)
	return t
end

function table.find(t, ...)
	if type(t) ~= 'table' then
		return false
	end
	local args = { ... }
	if #args == 0 then
		for k,v in pairs(t) do
			if v then
				return k, v
			end
		end
		return false
	end

	local value = table.remove(args)
	if value == '[nil]' then
		value = nil
	end
	for k,v in pairs(t) do
		for i,index in ipairs(args) do
			if type(index) == 'function' then
				v = index(v)
			else
				if index == '[last]' then
					index = #v
				end
				v = v[index]
			end
		end
		if v == value then
			return k, t[k]
		end
	end
	return false
end

function table.findi(t, ...)
	local _pairs = pairs
	pairs = ipairs
	local i = table.find(t, ...)
	pairs = _pairs
	return i
end

function table.deepcopy(t)
	local known = {}
	local function _deepcopy(t)
		local result = {}
		for k,v in pairs(t) do
			if type(v) == 'table' then
				if not known[v] then
					known[v] = _deepcopy(v)
				end
				result[k] = known[v]
			else
				result[k] = v
			end
		end
		return result
	end
	return _deepcopy(t)
end

function table.shallowcopy(t)
	local result = {}
	for k,v in pairs(t) do
		result[k] = v
	end
	return result
end

function table.flatten(t, result)
	if not result then
		result = {}
	end
	for k,v in ipairs(t) do
		if type(v) == 'table' then
			table.flatten(v, result)
		else
			table.insert(result, v)
		end
	end
	return result
end

function table.create(keys, vals)
	local result = {}
	if type(vals) == 'table' then
		for i,k in ipairs(keys) do
			result[k] = vals[i]
		end
	else
		for i,k in ipairs(keys) do
			result[k] = vals
		end
	end
	return result
end

function table.map(t, callback, ...)
	for k,v in ipairs(t) do
		t[k] = callback(v, ...)
	end
	return t
end

function table.each(t, index, callback, ...)
	local args = { ... }
	if type(index) == 'function' then
		table.insert(args, 1, callback)
		callback = index
		index = false
	end
	for k,v in pairs(t) do
		if index then
			v = v[index]
		end
		callback(v, unpack(args))
	end
	return t
end

function table.cmp(t1, t2)
	if not t1 or not t2 or #t1 ~= #t2 then
		return false
	end
	for i,v in ipairs(t1) do
		if v ~= t2[i] then
			return false
		end
	end
	return true
end

function table.removevalue(t, val)
	for i,v in ipairs(t) do
		if v == val then
			table.remove(t, i)
			return i
		end
	end
	return false
end

function table.filter(t, callback, cmpval)
	if cmpval == nil then
		cmpval = true
	end
	for k,v in pairs(t) do
		if callback(v) ~= cmpval then
			t[k] = nil
		end
	end
	return t
end

function table.shadowize(t, ...)
	t.shadow = {}
	local args = { ... }
	for i=1,#args-1 do
		t.shadow[args[i]] = t[args[i]]
		t[args[i]] = nil
	end
	setmetatable(t, args[#args])
end

function table.deshadowize(t, copy)
	local result = copy and table.deepcopy(t) or t
	for k,v in pairs(result.shadow) do
		result[k] = v
	end
	result.shadow = nil
	if not copy then
		setmetatable(result, nil)
	end
	return result
end

function table.dump(t, caption, depth)
	if not depth then
		depth = 1
	end
	if depth == 1 and caption then
		outputConsole(caption .. ':')
	end
	if type(t) ~= 'table' then
		outputConsole(tostring(t))
	else
		local braceIndent = string.rep('  ', depth-1)
		local fieldIndent = braceIndent .. '  '
		outputConsole(braceIndent .. '{')
		for k,v in pairs(t) do
			if type(v) == 'table' and k ~= 'siblings' and k ~= 'parent' then
				outputConsole(fieldIndent .. tostring(k) .. ' = ')
				table.dump(v, nil, depth+1)
			else
				outputConsole(fieldIndent .. tostring(k) .. ' = ' .. tostring(v))
			end
		end
		outputConsole(braceIndent .. '}')
	end
end

-- FILE functions

local string, fileSetPos, fileRead = string, fileSetPos, fileRead

function getResourceAMXFiles(res)
	local result = false

	local meta = xmlLoadFile(':' .. getResourceName(res) .. '/' .. 'meta.xml' )
	if not meta then
		return false
	end
	result = {}
	local i = 0
	local amxNode
	while true do
		amxNode = xmlFindChild(meta, 'amx', i)
		if not amxNode then
			break
		end
		result[#result+1] = xmlNodeGetAttribute(amxNode, 'src')
		i = i + 1
	end
	xmlUnloadFile(meta)
	return result
end

function fileReadLine(hFile)
	local fileRead, fileIsEOF = fileRead, fileIsEOF
	if fileIsEOF(hFile) then
		return false
	end
	local result = ''
	local initFilePos = fileGetPos(hFile)
	local partPosition = 1
	local breakPosition
	while true do
		result = result .. fileRead(hFile, 256)
		breakPosition = result:find('\n', partPosition, true)
		if breakPosition then
			if initFilePos + breakPosition < fileGetSize(hFile) then
				fileSetPos(hFile, initFilePos + breakPosition)
			end
			return result:sub(1, breakPosition - (result:byte(breakPosition - 1) == 13 and 2 or 1))
		end
		if fileIsEOF(hFile) then
			return result
		end
		partPosition = partPosition + 256
	end
end

function readBYTE(hFile)
	local b0 = string.byte(fileRead(hFile, 1))
	return b0
end

function readBYTEAt(hFile, offset)
	fileSetPos(hFile, offset)
	return readBYTE(hFile)
end

function readWORD(hFile)
	local b0, b1 = string.byte(fileRead(hFile, 2), 1, 2)
	return b1*256 + b0
end

function readWORDAt(hFile, offset)
	fileSetPos(hFile, offset)
	return readWORD(hFile)
end

function readDWORD(hFile)
	local b0, b1, b2, b3 = string.byte(fileRead(hFile, 4), 1, 4)
	return b3*16777216 + b2*65536 + b1*256 + b0
end

function readDWORDAt(hFile, offset)
	fileSetPos(hFile, offset)
	return readDWORD(hFile)
end

function readDWORDs(hFile, offset, length)
	local result = {}
	fileSetPos(hFile, offset)
	for i=0,length-4,4 do
		result[i] = readDWORD(amx)
	end
	return result
end

function readString(hFile, offset)
	local result = ""
	fileSetPos(hFile, offset)
	local curByte = readBYTE(hFile)
	while curByte ~= 0 do
		result = result .. string.char(curByte)
		curByte = readBYTE(hFile)
	end
	return result
end

function dumpAMXTable(amx, tableName, chunk)
	if not chunk then
		chunk = Chunk.create(amx.name .. '.amx', 1, 2)
		chunk.rAMX = 0
		chunk.rTemp = 1
	end
	chunk:newtable(chunk.rTemp, 0, 0)
	for k,v in pairs(amx[tableName]) do
		chunk:settable(chunk.rTemp, chunk:K(k), chunk:K(v))
	end
	chunk:settable(chunk.rAMX, chunk:K(tableName), chunk.rTemp)
	return chunk
end

-- MEMORY reading/writing functions

function readMemString(amx, offset, length)
	return amxReadString(amx.cptr, offset, length or 0x7FFFFFFF)
end

function writeMemString(amx, offset, str)
	amxWriteString(amx.cptr, offset, str)
end

function writeMemFloat(amx, offset, float)
	amx.memDAT[offset] = float2cell(float)
end

-- Binary operations

function binand(val1, val2)
	local i, result = 0, 0
	while val1 ~= 0 and val2 ~= 0 do
		result = result + ( ((val1 % 2) == 1 and (val2 % 2) == 1) and (2^i) or 0 )
		val1 = math.floor(val1/2)
		val2 = math.floor(val2/2)
		i = i + 1
	end
	return result
end

function binor(val1, val2)
	local i, result = 0, 0
	while val1 ~= 0 or val2 ~= 0 do
		result = result + ( ((val1 % 2) == 1 or (val2 % 2) == 1) and (2^i) or 0 )
		val1 = math.floor(val1/2)
		val2 = math.floor(val2/2)
		i = i + 1
	end
	return result
end

function binxor(val1, val2)
	local i, result = 0, 0
	local b1, b2
	while val1 ~= 0 or val2 ~= 0 do
		b1 = val1 % 2
		b2 = val2 % 2
		result = result + ( ((b1 == 1 and b2 == 0) or (b1 == 0 and b2 == 1)) and (2^i) or 0 )
		val1 = math.floor(val1/2)
		val2 = math.floor(val2/2)
		i = i + 1
	end
	return result
end

function binnot(num)
	local result = 0
	local bit = 1
	local nextbit
	for i=0,31 do
		nextbit = bit * 2
		if num % nextbit < bit then
			result = result + bit
		end
		bit = nextbit
	end
	return result
end

function binshl(val, dist)
	return val * (2^dist)
end

function binshr(val, dist)
	return math.floor(val / (2^dist))
end

function binsar(val, dist)
	local signext = 0
	if val >= 0x80000000 then
		for i=31,31-dist,-1 do
			signext = signext + 2^i
		end
	end
	return signext + math.floor(val / (2^dist))
end

function sgn(val)
	if val >= 0x80000000 then
		val = -(binnot(val) + 1)
	end
	return val
end

function unsgn(val)
	if val < 0 then
		val = binnot(-val) + 1
	end
	return val
end

--[[
function cell2float(cell)
	if cell == 0 then
		return 0
	end

	local sign = cell >= 0x80000000 and -1 or 1
	local exp = (math.floor(cell / (2^23)) % (2^8)) - 127
	local mantissa = (cell % (2^23)) / (2^23)
	return sign * (2^exp) * (1 + mantissa)
end

function float2cell(float)
	if float == 0 then
		return 0
	end
	local ldexp = math.ldexp

	-- sign bit
	local sign = 0
	if float < 0 then
		sign = 2^31
		float = -float
	end
	local ipart, fpart = math.modf(float)
	-- exponent
	local exp = 0
	while ipart > 2^exp do
		exp = exp + 1
	end
	if 2^exp > ipart then
		exp = exp - 1
	end
	-- mantissa
	local numFPartBits = 0
	local fpartBits = 0
	while fpart ~= 0 and numFPartBits < 23 do
		fpart = 2*fpart
		if fpart >= 1 then
			fpart = fpart - 1
			fpartBits = fpartBits*2 + 1
		else
			fpartBits = fpartBits*2
		end
		numFPartBits = numFPartBits + 1
	end
	ipart = ipart - 2^exp
	local mantissa = ldexp(ipart, numFPartBits) + fpartBits

	-- build
	return sign + ldexp(exp+127, 23) + ldexp(mantissa, 23 - (exp+numFPartBits))
end
--]]

function string.dword(num)
	local floor = math.floor
	return string.char(num % 256, floor(num/256) % 256, floor(num/65536) % 256, floor(num/16777216) % 256)
end

function string.double(dbl)
	if dbl == 0 then
		return ('\0'):rep(8)
	end

	local floor, ldexp = math.floor, math.ldexp

	-- sign bit
	local sign = 0
	if dbl < 0 then
		sign = 2^63
		dbl = -dbl
	end
	local ipart, fpart = math.modf(dbl)
	-- exponent
	local exp = 0
	while ipart > 2^exp do
		exp = exp + 1
	end
	if 2^exp > ipart then
		exp = exp - 1
	end
	-- mantissa
	local numFPartBits = 0
	local fpartBits = 0
	while fpart ~= 0 and numFPartBits < 52 do
		fpart = 2*fpart
		if fpart >= 1 then
			fpart = fpart - 1
			fpartBits = fpartBits*2 + 1
		else
			fpartBits = fpartBits*2
		end
		numFPartBits = numFPartBits + 1
	end
	ipart = ipart - 2^exp
	local mantissa = ldexp(ipart, numFPartBits) + fpartBits

	-- build
	local num = sign + ldexp(exp+1023, 52) + ldexp(mantissa, 52 - (exp+numFPartBits))
	local result = ''
	for i=0,7 do
		result = result .. string.char(floor(num/(2^(i*8))) % 256)
	end
	return result
end

function string:split(sep)
	if #self == 0 then
		return {}
	end
	sep = sep or ' '
	local result = {}
	local from = 1
	local to
	repeat
		to = self:find(sep, from, true) or (#self + 1)
		result[#result+1] = self:sub(from, to - 1)
		from = to + 1
	until from == #self + 2
	return result
end

function cell2color(val)
	local binshr = binshr
	return binshr(val, 24), binshr(val, 16) % 0x100, binshr(val, 8) % 0x100, val % 0x1000
end

function color2cell(r, g, b, a)
	local binshl = binshl
	return binshl(r, 24) + binshl(g, 16) + binshl(b, 8) + (a or 255)
end

function isPed(elem)
	if getElementType(elem) == "ped" then
		return true
	end
	return false
end

function isCustomPickup(elem)
	local model = getElementModel(elem)
	if model == 1272 or model == 1273 or model == 1239 then
		return true
	end
	return false
end
