function argsToMTA(amx, prototype, ...)
	if type(amx) == 'userdata' then
		local amxName = table.find(g_LoadedAMXs, 'cptr', amx)
		if not amxName then
			print('argsToMTA: No amx found for provided cptr')
			return 0
		end
		amx = g_LoadedAMXs[amxName]
	end

	local args = { ... }
	local val
	local argMissing = false
	local colorArgs
	for i,val in ipairs(args) do
		vartype = prototype[i]
		if vartype == 'b' then			-- boolean
			val = val ~= 0
		elseif vartype == 'c' then		-- color
			if not colorArgs then
				colorArgs = {}
			end
			colorArgs[i] = { binshr(val, 24) % 0x100, binshr(val, 16) % 0x100, binshr(val, 8) % 0x100 }		-- r, g, b
			val = val % 0x100			-- a
		elseif vartype == 'p' then		-- player
			val = g_Players[val] and g_Players[val].elem
		elseif vartype == 'z' then		-- bot/ped
			val = g_Bots[val] and g_Bots[val].elem
		elseif vartype == 't' then		-- team
			val = val ~= 0 and g_Teams[val]
		elseif vartype == 'v' then		-- vehicle
			val = g_Vehicles[val] and g_Vehicles[val].elem
		elseif vartype == 'o' then		-- object
			val = g_Objects[val] and g_Objects[val].elem
		elseif vartype == 'u' then		-- pickup
			val = g_Pickups[val] and g_Pickups[val].elem
		elseif vartype == 'x' then		-- textdraw
			val = g_TextDraws[val]
		elseif vartype == 'm' then		-- menu
			val = g_Menus[val]
		elseif vartype == 'g' then		-- gang zone
			val = g_GangZones[val] and g_GangZones[val].elem
		elseif vartype == 'k' then		-- native marker
			val = g_Markers[val] and g_Markers[val].elem
		elseif vartype == 'a' then		-- 3D text label
			val = g_TextLabels[val]
		elseif vartype == 'y' then		-- Actor
			val = g_Actors[val] and g_Actors[val].elem
		end
		if val == nil then
			val = false
			argMissing = true
		end
		args[i] = val
	end
	if colorArgs then
		local indexOffset = 0
		for i,colorArg in pairs(colorArgs) do
			for j,color in ipairs(colorArg) do
				table.insert(args, i+j-1 + indexOffset, color)
			end
			indexOffset = indexOffset + 3
		end
	end

	return args, argMissing
end
local argsToMTA = argsToMTA

function argsToSAMP(amx, prototype, ...)
	if type(amx) == 'userdata' then
		local amxName = table.find(g_LoadedAMXs, 'cptr', amx)
		if not amxName then
			print('argsToSAMP: No amx found for provided cptr')
			return 0
		end
		amx = g_LoadedAMXs[amxName]
	end

	local args = { ... }
	for i,v in ipairs(args) do
		if type(v) == 'nil' then
			args[i] = 0
		elseif type(v) == 'boolean' then
			args[i] = v and 1 or 0
		elseif type(v) == 'string' then
			-- keep unmodified
		elseif type(v) == 'number' then
			if prototype[i] == 'f' then
				args[i] = float2cell(v)
			end
		elseif type(v) == 'userdata' then
			args[i] = isElement(v) and getElemID(v)
		else
			args[i] = 0
		end
	end
	return args
end

function syscall(amx, svc, prototype, ...)		-- svc = service number (= index in native functions table) or name of native function
	if type(amx) == 'userdata' then
		local amxName = table.find(g_LoadedAMXs, 'cptr', amx)
		if amxName then
			amx = g_LoadedAMXs[amxName]
		else
			local dynamicAmx = {name = 'dynamicAmx', res = 'dynamicAmx', cptr = amx }
			dynamicAmx.memCOD = setmetatable({ amx = dynamicAmx.cptr }, { __index = amxMTReadCODCell })
			dynamicAmx.memDAT = setmetatable({ amx = dynamicAmx.cptr }, { __index = amxMTReadDATCell, __newindex = amxMTWriteDATCell })

			amx = dynamicAmx
		end
	end
	local fnName = type(svc) == 'number' and amx.natives[svc] or svc
	local fn = prototype.fn or _G[fnName]
	if not fn and not prototype.client then
		outputDebugString('syscall: function ' .. tostring(fn) .. ' (' .. fnName .. ') doesn\'t exist', 1)
		return
	end

	local args, argMissing = argsToMTA(amx, prototype, ...)

	if argMissing then
		return 0
	end
	--[[
	local logstr = fnName .. '('
	for i,argval in ipairs(args) do
		if i > 1 then
			logstr = logstr .. ', '
		end
		logstr = logstr .. tostring(argval)
	end
	logstr = logstr .. ')'
	print(logstr)
	outputConsole(logstr)
	--]]

	local result
	if prototype.client then
		local player = table.remove(args, 1)
		clientCall(player, fnName, unpack(args))
	else
		result = fn(amx, unpack(args))
		if type(result) == 'boolean' then
			result = result and 1 or 0
		end
	end
	--print('syscall returned ' .. tostring(result or 0))
	return result or 0
end

function AddPlayerClothes(amx, player, type, index)
	local texture, model = getClothesByTypeIndex(type, index)
	addPedClothes(player, texture, model, type)
end

local function housePickup()
	procCallOnAll('OnPlayerPickUpPickup', getElemID(player), getElemID(source))
	cancelEvent()
end




function EditPlayerObject(amx, player, object)
	--givePlayerMoney(player, amount)
	notImplemented('EditPlayerObject')
end



function GetPlayerClothes(amx, player, type)
	local texture, model = getPedClothes(player, type)
	if not texture then
		return
	end
	local type, index = getTypeIndexFromClothes(texture, model)
	return index
end



function gpci(amx, player, nameBuf, bufSize)
	local serial = getPlayerSerial(player)
	if #serial <= bufSize then
		writeMemString(amx, nameBuf, serial)
	end
end

local function getPlayerObjectPos(amx, player, objID)
	local obj = g_PlayerObjects[player] and g_PlayerObjects[player][objID]
	if not obj then
		return false
	end

	if obj.moving then
		local curtick = getTickCount()
		if curtick >= obj.moving.starttick + obj.moving.duration then
			obj.x, obj.y, obj.z = obj.moving.x, obj.moving.y, obj.moving.z
			obj.moving = nil
			x, y, z = obj.x, obj.y, obj.z
		else
			local factor = (curtick - obj.moving.starttick)/obj.moving.duration
			x = obj.x + (obj.moving.x - obj.x)*factor
			y = obj.y + (obj.moving.y - obj.y)*factor
			z = obj.z + (obj.moving.z - obj.z)*factor
		end
	else
		x, y, z = obj.x, obj.y, obj.z
	end
	return x, y, z
end

function GetVehicleModel(amx, vehicle)
	return getElementModel(vehicle)
end

function IsPluginLoaded(amx, pluginName)
	return amxIsPluginLoaded(pluginName)
end

function IsValidVehicle(amx, vehicleID)
	return g_Vehicles[vehicleID] ~= nil
end

function RemovePlayerClothes(amx, player, type)
	removePedClothes(player, type)
end

function SetDisabledWeapons(amx, ...)

end

function SetEchoDestination(amx)

end

function SetPlayerDisabledWeapons(amx, player, ...)

end

function SetPlayerGravity(amx, player, gravity)
	setPedGravity(player, gravity)
end

function SetSpawnInfo(amx, player, team, skin, x, y, z, angle, weap1, weap1_ammo, weap2, weap2_ammo, weap3, weap3_ammo)
	g_Players[getElemID(player)].spawninfo = {
		x, y, z, angle, skinReplace[skin] or skin, 0, 0, team,
		weapons={ {weap1, weap1_ammo}, {weap2, weap2_ammo}, {weap3, weap3_ammo} }
	}
end

function SetVehicleModel(amx, vehicle, model)
	setElementModel(vehicle, model)
end

function ShowPlayerMarker(amx, player, show)
	local data = g_Players[getElemID(player)]
	if not show and data.blip then
		destroyElement(data.blip)
		data.blip = nil
	elseif show and not data.blip then
		local r, g, b = getPlayerNametagColor(player)
		data.blip = createBlipAttachedTo(player, 0, 2, r, g, b)
	end
end

function SpawnPlayer(amx, player)
	spawnPlayerBySelectedClass(player)
end

--Mainly just wrappers to the other non-player functions

function IsPlayerTextDrawValid(player, textdrawID)
	local tableType = type(g_PlayerTextDraws[player])
	if tableType ~= "table" then
		outputDebugString("[ERROR_NOT_A_TABLE] IsPlayerTextDrawValid: g_PlayerTextDraws[player] is not a table yet for textdrawID: " .. textdrawID .. " it's actually a " .. tableType)
		return false
	end
	if not g_PlayerTextDraws[player] then
		outputDebugString("[ERROR_NIL_TABLE] IsPlayerTextDrawValid: g_PlayerTextDraws[player] is nil! for textdrawID: " .. textdrawID)
		return false
	end
	local textdraw = g_PlayerTextDraws[player][textdrawID]
	if not textdraw then
		outputDebugString("[ERROR_NOTD_PROPERTIES] IsPlayerTextDrawValid: no textdraw properties for player with textdrawID: " .. textdrawID)
		return false
	end
	return true
end

function TextDrawUseBox(amx, textdraw, usebox)
	textdraw.usebox = usebox
end

-- stub
function GetPlayerCameraTargetActor(amx)
	return INVALID_ACTOR_ID
end

-----------------------------------------------------

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

function floatstr(amx, str)
	return float2cell(tonumber(str) or 0)
end

function format(amx, outBuf, outBufSize, fmt, ...)
	local args = { ... }
	local i = 0

	fmt = fmt:gsub('[^%%]%%$', '%%%%'):gsub('%%i', '%%d')
	for c in fmt:gmatch('%%[%-%d%.]*(%*?%a)') do
		i = i + 1
		if c:match('^%*') then
			c = c:sub(2)
			table.remove(args, i)
		end
		if c == 'd' then
			args[i] = amx.memDAT[args[i]]
		elseif c == 'f' then
			args[i] = cell2float(amx.memDAT[args[i]])
		elseif c == 's' then
			args[i] = readMemString(amx, args[i])
		else
			i = i - 1
		end
	end

	fmt = fmt:gsub('(%%[%-%d%.]*)%*(%a)', '%1%2')
	local result = fmt:format(unpack(args))

	--replace colors
	if #result+1 <= outBufSize then
		writeMemString(amx, outBuf, colorizeString(result))
	end
end

-----------------------------------------------------
-- Alpha funcs
function GetAlpha(amx, elem)
	return getElementAlpha(alpha)
end

function SetAlpha(amx, elem, alpha)
	return setElementAlpha(elem, alpha)
end
GetPlayerAlpha = GetAlpha
GetVehicleAlpha = GetAlpha
GetObjectAlpha = GetAlpha
GetBotAlpha = GetAlpha
SetPlayerAlpha = SetAlpha
SetVehicleAlpha = SetAlpha
SetObjectAlpha = SetAlpha
SetBotAlpha = SetAlpha
-----------------------------------------------------
-- Misc player funcs
function IsPlayerInWater(amx, player)
	return isElementInWater(player)
end

function IsPlayerOnFire(amx, player)
	return isPedOnFire(player)
end

function IsPlayerDucked(amx, player)
	return isPedDucked(player)
end

function IsPlayerOnGround(amx, player)
	return isPedOnGround(amx, player)
end

function SetPlayerOnFire(amx, player, state)
	return setPedOnFire(player, state)
end

function GetPlayerStat(amx, player, stat)
	return getPedStat(player, stat)
end

function SetPlayerStat(amx, player, stat, value)
	return setPedStat(player, stat, value)
end

function GetPlayerDoingDriveBy(amx, ped)
	return getElementData(pedt, 'DoingDriveBy')
end

function SetPlayerDoingDriveBy(amx, ped, state)
	clientCall(root, 'setPedDoingGangDriveby', ped, state)
	setElementData(ped, 'DoingDriveBy', state)
	return true
end

function GetPlayerCanBeKnockedOffBike(amx, ped)
	return getElementData(ped, 'CanBeKnockedOffBike')
end

function SetPlayerCanBeKnockedOffBike(amx, ped, state)
	clientCall(root, 'setPedCanBeKnockedOffBike', ped, state)
	setElementData(ped, 'CanBeKnockedOffBike', state)
end

function SetPlayerWeaponSlot(amx, ped, slot)
	clientCall(root, 'setPedWeaponSlot', ped, slot)
	return true
end

function SetPlayerHeadless(amx, ped, state)
	return setPedHeadless(ped, state)
end

function GetPlayerBlurLevel(amx, player)
	return getPlayerBlurLevel(player)
end

function SetPlayerBlurLevel(amx, player, level)
	return setPlayerBlurLevel(player, level)
end

function SetPlayerControlState(amx, player, control, state)
	return setControlState(player, control, state)
end

function GetPlayerSkillLevel(amx, player, skill)
	return getPedStat(player, skill + 69)
end

IsBotInWater = IsPlayerInWater
IsBotOnFire = IsPlayerOnFire
IsBotDucked = IsPlayerDucked
IsBotOnGround = IsPlayerOnGround
GetBotFightingStyle = GetPlayerFightingStyle
SetBotFightingStyle = SetPlayerFightingStyle
SetBotOnFire = SetPlayerOnFire
GetBotSkin = GetPlayerSkin
SetBotSkin = SetPlayerSkin
GetBotStat = GetPlayerStat
SetBotStat = SetPlayerStat
GetBotDoingDriveBy = GetPlayerDoingDriveBy
SetBotDoingDriveBy = SetPlayerDoingDriveBy
GetBotCanBeKnockedOffBike = GetPlayerCanBeKnockedOffBike
SetBotCanBeKnockedOffBike = SetPlayerCanBeKnockedOffBike
SetBotWeaponSlot = SetPlayerWeaponSlot
SetBotHeadless = SetPlayerHeadless
GetBotVehicleSeat = GetPlayerVehicleSeat
GetBotVelocity = GetPlayerVelocity
SetBotVelocity = SetPlayerVelocity
-----------------------------------------------------
-- Bots
function CreateBot(amx, model, x, y, z, name)
	local ped = createPed(model, x, y, z)
	setElementData(ped, 'amx.shownametag', true, true)
	setElementData(ped, 'BotName', name, true)
	local pedID = addElem(g_Bots, ped)
	procCallOnAll('OnBotConnect', pedID, name)
	return pedID
end

function DestroyBot(amx, bot)
	removeElem(g_Bots, bot)
	destroyElement(bot)
end

function GetBotState(amx, bot)
	return getBotState(bot)
end

function PutBotInVehicle(amx, bot, vehicle, seat)
	return oldwarpPedIntoVehicle(bot, vehicle, seat)
end

function RemoveBotFromVehicle(amx, bot)
	local vehicle = getPedOccupiedVehicle(bot)
	if vehicle then
		return removePedFromVehicle(bot)
	end
end

function SetBotControlState(amx, bot, control, state)
	clientCall(root, 'setPedControlState', bot, control, state)
	return true
end

function SetBotAimTarget(amx, bot, x, y, z)
	clientCall(root, 'setPedAimTarget', bot, x, y, z)
	return true
end

function IsBotDead(amx, bot)
	return isPedDead(bot)
end

function KillBot(amx, bot)
	return killPed(bot)
end

function GetBotRot(amx, ped, refX, refY, refZ)
	local rX, rX, rZ = getPedRotation(ped)
	writeMemFloat(amx, refX, rX)
	writeMemFloat(amx, refY, rY)
	writeMemFloat(amx, refZ, rZ)
end

function SetBotRot(amx, Ped, rX, rY, rY)
	setPedRotation(ped, rX, rY, rZ)
end

function GetBotName(amx, bot, nameBuf, bufSize)
	local name = getElementData(bot, 'BotName')
	if #name <= bufSize then
		writeMemString(amx, nameBuf, name)
	end
end

GetBotHealth = GetPlayerHealth
SetBotHealth = SetPlayerHealth
GetBotArmour = GetPlayerArmour
SetBotArmour = SetPlayerArmour
GetBotPos = GetObjectPos
SetBotPos = SetObjectPos
-----------------------------------------------------
-- Native Markers
function CreateMarker(amx, x, y, z, typeid, size, r, g, b, a)
	local marker = createMarker(x, y, z, typeid, size, r, g, b, a, root)
	local markerID = addElem(g_Markers, marker)
	procCallOnAll('OnMarkerCreate', markerID)
	return markerID
end

function DestroyMarker(amx, marker)
	removeElem(g_Markers, marker)
	destroyElement(marker)
	return true
end

function GetMarkerColor(amx, marker, colorid)
	local R, G, B, A = getMarkerColor( marker )
	if colorid == 0 then return R end
	if colorid == 1 then return G end
	if colorid == 2 then return B end
	if colorid == 3 then return A end
	return false
end

function GetMarkerIcon(amx, marker)
	local icon = getMarkerIcon(marker)
	if icon == "none" then return 0 end
	if icon == "arrow" then return 1 end
	if icon == "finish" then return 2 end
	return false
end

function GetMarkerSize(amx, marker, refSize)
	local size = getMarkerSize(marker)
	writeMemFloat(amx, refSize, marker)
	return true
end

function GetMarkerTarget(amx, marker, refX, refY, refZ)
	local x, y, z = getMarkerTarget(marker)
	if x == false then return false end
	writeMemFloat(amx, refX, x)
	writeMemFloat(amx, refY, y)
	writeMemFloat(amx, refZ, z)
	return true
end

function GetMarkerType(amx, marker)
	local mtype = getMarkerType(marker)
	if mtype == false then return false end
	if mtype == "checkpoint" then return 0 end
	if mtype == "ring" then return 1 end
	if mtype == "cylinder" then return 2 end
	if mtype == "arrow" then return 3 end
	if mtype == "corona" then return 4 end
	return false
end

function SetMarkerColor(amx, marker, red, green, blue, alpha)
	return setMarkerColor(marker, red, green, blue, alpha)
end

function SetMarkerIcon(amx, marker, icon)
	if icon == 0 then icon = "none"
	elseif icon == 1 then icon = "arrow"
	elseif icon == 2 then icon = "finish"
	else return false end
	return setMarkerIcon(amx, marker, icon)
end

function SetMarkerSize(amx, marker, size)
	return setMarkerSize(marker, size)
end

function SetMarkerTarget(amx, marker, x, y, z)
	return setMarkerTarget(marker, x, y, z)
end

function SetMarkerType(amx, marker, typeid)
	if typeid == 0 then typeid = "checkpoint"
	elseif typeid == 1 then typeid = "ring"
	elseif typeid == 2 then typeid = "cylinder"
	elseif typeid == 3 then typeid = "arrow"
	elseif typeid == 4 then typeid = "corona"
	else return false end
	return setMarkerType(marker, typeid)
end

function IsPlayerInMarker(amx, marker, elem)
	return isElementWithinMarker(elem, marker)
end

IsVehicleInMarker = IsPlayerInMarker
IsBotInMarker = IsPlayerInMarker

-----------------------------------------------------
-- SlothBots
--
-----------------------------------------------------
-- Player Data
function SetPlayerDataInt(amx, player, key, value)
	return setElementData(player, key, value)
end

function GetPlayerDataInt(amx, player, key)
	return getElementData(player, key)
end

SetPlayerDataFloat = SetPlayerDataInt
GetPlayerDataFloat = GetPlayerDataInt
SetPlayerDataBool = SetPlayerDataInt
GetPlayerDataBool = GetPlayerDataInt
SetPlayerDataStr = SetPlayerDataInt

function GetPlayerDataStr(amx, player, key, buf, len)
	local data = getElementData(player, key)
	if #data <= len then
		writeMemString(amx, buf, data)
	end
end

function IsPlayerDataSet(amx, player, key)
	return true
end

function ResetPlayerData(amx, player, key)
	return setElementData(player, key, nil)
end

function ResetAllPlayerData(amx, player)
	return true
end


-----------------------------------------------------
-- Vehicles
function GetVehicleEngineState(amx, vehicle)
	return getVehicleEngineState(vehicle)
end

function SetVehicleEngineState(amx, vehicle, state)
	return setVehicleEngineState(vehicle, state)
end

function GetVehicleDoorState(amx, vehicle, door)
	return getVehicleDoorState(vehicle, door)
end

function SetVehicleDoorState(amx, vehicle, door, state)
	return setVehicleDoorState(vehicle, door, state)
end


function GetVehicleMaxPassengers(amx, vehicle)
	return getVehicleMaxPassengers(vehicle)
end


function GetVehicleLightState(amx, vehicle, light)
	return getVehicleLightState(vehicle, light)
end

function SetVehicleLightState(amx, vehicle, light, state)
	return setVehicleLightState(vehicle, light, state)
end

function GetVehicleOverrideLights(amx, vehicle)
	return  getVehicleOverrideLights(vehicle)
end

function SetVehicleOverrideLights(amx, vehicle, state)
	return setVehicleOverrideLights(vehicle, state)
end

function GetVehicleWheelState(amx, vehicle, wheelid)
	local w1, w2, w3, w4 = getVehicleWheelStates(vehicleid)
	if wheelid == 0 then return w1 end
	if wheelid == 1 then return w2 end
	if wheelid == 2 then return w3 end
	if wheelid == 3 then return w4 end
end

function SetVehicleWheelState(amx, vehicle, frontLeft, rearLeft, frontRight, rearRight)
	return setVehicleWheelStates(vehicle, frontLeft, rearLeft, frontRight, rearRight)
end

function GetVehiclePanelState(amx, vehicle, panel)
	return getVehiclePanelState(vehicle, panel)
end

function SetVehiclePanelState(amx, vehicle, panel, state)
	return setVehiclePanelState(vehicle, panel, state)
end

function GetVehiclePaintjob(amx, vehicle)
	return getVehiclePaintjob(vehicle)
end



function GetVehicleSirensOn(amx, vehicle)
	return getVehicleSirensOn(vehicle)
end


function SetVehicleSirensOn(amx, vehicle, state)
	return setVehicleSirensOn(vehicle, state)
end

function IsTrainDerailable(amx, train)
	return isTrainDerailable(train)
end

function IsTrainDerailed(amx, train)
	return isTrainDerailed(train)
end

function SetTrainDerailable(amx, train, state)
	return setTrainDerailable(train, state)
end

function SetTrainDerailed(amx, train, state)
	return setTrainDerailed(train, state)
end

function GetTrainDirection(amx, train)
	return getTrainDirection(train)
end

function SetTrainDirection(amx, train, direction)
	return setTrainDirection(train, direction)
end

function GetTrainSpeed(amx, train, refSpeed)
	local speed = getTrainSpeed(train)
	writeMemFloat(amx, refSpeed, speed)
	return true
end

function SetTrainSpeed(amx, train, speed)
	return setTrainSpeed(train, speed)
end


-----------------------------------------------------
-- Water
function GetWaveHeight(amx)
	return getWaveHeight()
end

function SetWaveHeight(amx, height)
	return setWaveHeight(height)
end

function SetWaterLevel(amx, level)
	return setWaterLevel(level)
end
-----------------------------------------------------
-- Pickups
function GetPickupType(amx, pickup)
	return getPickupType(pickup)
end

function SetPickupType(amx, pickup, typeid, amount, ammo)
	return setPickupType(pickup, typeid, amount, ammo)
end

function GetPickupWeapon(amx, pickup)
	return getPickupWeapon(pickup)
end

function GetPickupAmount(amx, pickup)
	return getPickupAmount(pickup)
end

function GetPickupAmmo(amx, pickup)
	return getPickupAmmo(pickup)
end
-----------------------------------------------------
-- Misc
function SetSkyGradient(amx, topRed, topGreen, topBlue, bottomRed, bottomGreen, bottomBlue)
	return setSkyGradient(topRed, topGreen, topBlue, bottomRed, bottomGreen, bottomBlue)
end

function ResetSkyGradient(amx)
	return resetSkyGradient()
end

function GetCloudsEnabled(amx)
	return getCloudsEnabled()
end

function SetCloudsEnabled(amx, state)
	return setCloudsEnabled(state)
end

function IsGarageOpen(amx, garage)
	return isGarageOpen(garage)
end

function SetGarageOpen(amx, garage, state)
	return setGarageOpen( garage, state )
end

function IsGlitchEnabled(amx, glitch)
	return isGlitchEnabled(glitch)
end

function SetGlitchEnabled(amx, glitch, state)
	return setGlitchEnabled(amx, glitch, state)
end

function SetFPSLimit(amx, limit)
	return setFPSLimit(limit)
end

function GetFPSLimit(amx)
	return getFPSLimit()
end

function GetPlayerCount(amx)
	return getPlayerCount(amx)
end

function GetRandomPlayer(amx)
	return getElemID(getRandomPlayer())
end

function FadePlayerCamera(amx, player, fadeIn, timeToFade, red, green, blue)
	return fadeCamera(player, fadeIn, timeToFade, red, green, blue)
end

function GetRuleValue(amx, rule, nameBuf, bufSize)
	local ruleval = getRuleValue(rule)
	if #ruleval <= bufSize then
		writeMemString(amx, nameBuf, ruleval)
	end
end

function SetRuleValue(amx, rule, value)
	return setRuleValue(rule, value)
end

function RemoveRuleValue(amx, rule)
	return removeRuleValue(rule)
end

function md5hash(amx, str, refStr, refSize)
	local hash = md5(str)
	if #hash <= refSize then
		writeMemString(amx, refStr, hash)
	end
end

function GetDistanceBetweenPoints2D(amx, x1, y1, x2, y2)
	return getDistanceBetweenPoints2D(x1, y1, x2, y2)
end

function GetDistanceBetweenPoints3D(amx, x1, y1, z1, x2, y2, z2)
	return getDistanceBetweenPoints3D(x1, y1, z1, x2, y2, z2)
end

function AddScoreboardColumn(amx, column)
	outputDebugString("AddScoreboardColumn is being ignored!")
	-- TODO(q): this needs to be added back later
	-- return exports.amxscoreboard:addScoreboardColumn('_' .. column)
end

function RemoveScoreboardColumn(amx, column)
	outputDebugString("RemoveScoreboardColumn is being ignored!")
	-- TODO(q): this needs to be added back later
	-- return exports.amxscoreboard:removeScoreboardColumn('_' .. column)
end

function SetScoreboardData(amx, player, column, data)
	return setElementData(player, '_' .. column, data)
end
-----------------------------------------------------
-- dummy





function SetObjectMaterial(amx)
	notImplemented('SetObjectMaterial')
end

function SendClientCheck(amx)
	notImplemented('SendClientCheck')
end

function SetPlayerObjectMaterial(amx)
	notImplemented('SetPlayerObjectMaterial')
end

function EditPlayerObject(amx)
	notImplemented('EditPlayerObject')
end

function NetStats_BytesReceived(amx, player)
	notImplemented('NetStats_BytesReceived')
end

function NetStats_BytesSent(amx, player)
	notImplemented('NetStats_BytesSent')
end

function NetStats_ConnectionStatus(amx, player)
	notImplemented('NetStats_ConnectionStatus')
end

function NetStats_GetConnectedTime(amx, player)
	notImplemented('NetStats_GetConnectedTime')
end

function NetStats_GetIpPort(amx, player)
	notImplemented('NetStats_GetIpPort')
end

function NetStats_MessagesReceived(amx, player)
	notImplemented('NetStats_MessagesReceived')
end

function NetStats_MessagesRecvPerSecond(amx, player)
	notImplemented('NetStats_MessagesRecvPerSecond')
end

function NetStats_MessagesSent(amx, player)
	notImplemented('NetStats_MessagesSent')
end

function NetStats_PacketLossPercent(amx, player)
	notImplemented('NetStats_PacketLossPercent')
end


function ShowCursor(amx, player, show, controls)
	showCursor(player, show, controls)
end

function AddEventHandler(amx, event, func)
	if g_EventNames[event] then
		g_Events[func] = event
	end
end

function RemoveEventHandler(amx, func)
	g_Events[func] = nil
end

function AttachElementToElement(amx, elem, toelem, xPos, yPos, zPos, xRot, yRot, zRot)
	return attachElements(elem, toelem, xPos, yPos, zPos, xRot, yRot, zRot)
end

function Dummy(amx, text)
	return 0
end
Broadcast = Dummy

function toggleUninmplementedErrors ( playerSource, commandName )
	if not isPlayerInACLGroup(playerSource, 'Console') then
		return
	end
	ShowUnimplementedErrors = not ShowUnimplementedErrors
	outputDebugString('[INFO]: ShowUnimplementedErrors is now ' .. (ShowUnimplementedErrors and "Enabled" or "Disabled"))
end
addCommandHandler ( "showunimplementederrors", toggleUninmplementedErrors )

-----------------------------------------------------
-- List of the functions and their argument types

g_SAMPSyscallPrototypes = {
	Broadcast = {'s'},

	AddMenuItem = {'m', 'i', 's'},
	AddPlayerClass = {'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i'},
	AddPlayerClassEx = {'t', 'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i'},
	AddPlayerClothes = {'p', 'i', 'i'},
	AddStaticPickup = {'i', 'i', 'f', 'f', 'f'},
	AddStaticVehicle = {'i', 'f', 'f', 'f', 'f', 'i', 'i'},
	AddStaticVehicleEx = {'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i'},
	AddVehicleComponent = {'v', 'i'},
	AllowAdminTeleport = {'b'},
	AllowInteriorWeapons = {'b'},
	AllowPlayerTeleport = {'p', 'b'},
	ApplyAnimation = {'p', 's', 's', 'f', 'b', 'b', 'b', 'b', 'i'},
	AttachObjectToPlayer = {'o', 'p', 'f', 'f', 'f', 'f', 'f', 'f'},
	AttachPlayerObjectToPlayer = {'p', 'i', 'p', 'f', 'f', 'f', 'f', 'f', 'f', client=true},
	AttachTrailerToVehicle = {'v', 'v'},

	Ban = {'p'},
	BanEx = {'p', 's'},

	CallLocalFunction = {'s', 's'},
	CallRemoteFunction = {'s', 's'},
	ChangeVehicleColor = {'v', 'i', 'i'},
	ChangeVehiclePaintjob = {'v', 'i'},
	ClearAnimations = {'p'},
	CreateExplosion = {'f', 'f', 'f', 'i', 'f'},
	CreateMenu = {'s', 'i', 'f', 'f', 'f', 'f'},
	CreateObject = {'i', 'f', 'f', 'f', 'f', 'f', 'f'},
	CreatePickup = {'i', 'i', 'f', 'f', 'f'},
	CreatePlayerObject = {'p', 'i', 'f', 'f', 'f', 'f', 'f', 'f'},
	CreateVehicle = {'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i'},

	DestroyMenu = {'m'},
	DestroyObject = {'o'},
	DestroyPickup = {'u'},
	DestroyPlayerObject = {'p', 'i'},
	DestroyVehicle = {'v'},
	DetachTrailerFromVehicle = {'v'},
	DisableInteriorEnterExits = {},
	DisableMenu = {'i'},
	DisableMenuRow = {'i', 'i'},
	DisablePlayerCheckpoint = {'p'},
	DisablePlayerRaceCheckpoint = {'p'},

	EnableStuntBonusForAll = {'b'},
	EnableStuntBonusForPlayer = {'p', 'b'},
	EnableTirePopping = {'b'},
	EnableZoneNames = {'b'},

	ForceClassSelection = {'i'},

	GameModeExit = {},
	GameTextForAll = {'s', 'i', 'i'},
	GameTextForPlayer = {'p', 's', 'i', 'i'},
	GangZoneCreate = {'f', 'f', 'f', 'f'},
	GangZoneDestroy = {'g'},
	GangZoneShowForPlayer = {'p', 'g', 'c'},
	GangZoneShowForAll = {'g', 'c'},
	GangZoneHideForPlayer = {'p', 'g'},
	GangZoneHideForAll = {'g'},
	GangZoneFlashForPlayer = {'p', 'g', 'c'},
	GangZoneFlashForAll = {'g', 'c'},
	GangZoneStopFlashForPlayer = {'p', 'g'},
	GangZoneStopFlashForAll = {'g'},
	GetConsoleVarAsBool = {'s'},
	GetConsoleVarAsInt = {'s'},
	GetConsoleVarAsString = {'s', 'r', 'i'},
	GetMaxPlayers = {},
	GetObjectPos = {'o', 'r', 'r', 'r'},
	GetObjectRot = {'o', 'r', 'r', 'r'},
	GetPlayerAmmo = {'p'},
	GetPlayerArmour = {'p', 'r'},
	GetPlayerCameraPos = {'p', 'r', 'r', 'r'},
	GetPlayerCameraFrontVector = {'p', 'r', 'r', 'r'},
	GetPlayerColor = {'p'},
	GetPlayerClothes = {'p', 'i'},
	GetPlayerFacingAngle = {'p', 'r'},
	GetPlayerHealth = {'p', 'r'},
	GetPlayerInterior = {'p'},
	GetPlayerIp = {'p', 'r', 'i'},
	GetPlayerKeys = {'p', 'r', 'r', 'r'},
	GetPlayerMenu = {'p'},
	GetPlayerMoney = {'p'},
	GetPlayerName = {'p', 'r', 'i'},
	GetPlayerObjectPos = {'p', 'i', 'r', 'r', 'r'},
	GetPlayerObjectRot = {'p', 'i', 'r', 'r', 'r'},
	GetPlayerPing = {'p'},
	GetPlayerPos = {'p', 'r', 'r', 'r'},
	GetPlayerScore = {'p'},
	GetPlayerSkin = {'p'},
	GetPlayerSpecialAction = {'p'},
	GetPlayerState = {'p'},
	GetPlayerTeam = {'p'},
	GetPlayerTime = {'p', 'r', 'r'},
	GetPlayerVehicleID = {'p'},
	GetPlayerVirtualWorld = {'p'},
	GetPlayerWantedLevel = {'p'},
	GetPlayerWeapon = {'p'},
	GetPlayerWeaponData = {'p', 'i', 'r', 'r'},
	GetServerVarAsBool = {'s'},
	GetServerVarAsInt = {'s'},
	GetServerVarAsString = {'s', 'r', 'i'},
	GetTickCount = {},
	GetVehicleHealth = {'v', 'r'},
	GetVehicleModel = {'v'},
	GetVehiclePos = {'v', 'r', 'r', 'r'},
	GetVehicleTrailer = {'v'},
	GetVehicleVelocity = {'v', 'r', 'r', 'r' },
	GetVehicleVirtualWorld = {'v'},
	GetVehicleZAngle = {'v', 'r'},
	GetWeaponName = {'i', 'r', 'i'},
	GivePlayerMoney = {'p', 'i'},
	GivePlayerWeapon = {'p', 'i', 'i'},

	GetPVarInt = {'p', 's'},
	GetPVarFloat = {'p', 's'},
	GetPVarString = {'p', 's', 'r', 'i'},
	GetPVarType = {'p', 's'},

	DeletePVar = {'p', 's'},

	HideMenuForPlayer = {'m', 'p'},

	IsPlayerAdmin = {'p'},
	IsPlayerConnected = {'i'},
	IsPlayerInAnyVehicle = {'p'},
	IsPlayerInCheckpoint = {'p'},
	IsPlayerInRaceCheckpoint = {'p'},
	IsPlayerInVehicle = {'p', 'v'},
	IsPluginLoaded = {'s'},
	IsTrailerAttachedToVehicle = {'v'},
	IsValidMenu = {'i'},
	IsValidObject = {'i'},
	IsValidPlayerObject = {'p', 'i'},
	IsValidVehicle = {'i'},

	Kick = {'p'},
	KillTimer = {'i'},

	LimitGlobalChatRadius = {'f'},
	LinkVehicleToInterior = {'v', 'i'},

	MoveObject = {'o', 'f', 'f', 'f', 'f'},
	MovePlayerObject = {'p', 'i', 'f', 'f', 'f', 'f'},

	PlayerPlaySound = {'p', 'i', 'f', 'f', 'f'},
	PlayerSpectatePlayer = {'p', 'p', 'i'},
	PlayerSpectateVehicle = {'p', 'v', 'i'},
	PutPlayerInVehicle = {'p', 'v', 'i'},
	RepairVehicle = {'v'},

	RemovePlayerClothes = {'p', 'i'},
	RemovePlayerFromVehicle = {'p'},
	RemovePlayerMapIcon = {'p', 'i', client=true},
	RemoveVehicleComponent = {'v', 'i'},
	ResetPlayerMoney = {'p'},
	ResetPlayerWeapons = {'p'},

	SendClientMessage = {'p', 'c', 's'},
	SendClientMessageToAll = {'c', 's'},
	SendDeathMessage = {'p', 'p', 'i'},
	SetEchoDestination = {},
	SendPlayerMessageToAll = {'p', 's'},
	SendPlayerMessageToPlayer = {'p', 'p', 's'},
	SendRconCommand = {'s'},
	SetCameraBehindPlayer = {'p'},
	SetDeathDropAmount = {'i'},
	SetDisabledWeapons = {},
	SetGameModeText = {'s'},
	SetGravity = {'f'},
	SetMenuColumnHeader = {'m', 'i', 's'},
	SetNameTagDrawDistance = {'f'},
	SetObjectPos = {'o', 'f', 'f', 'f'},
	SetObjectRot = {'o', 'f', 'f', 'f'},
	SetPlayerAmmo = {'p', 'i', 'i'},
	SetPlayerArmour = {'p', 'f'},
	SetPlayerCameraLookAt = {'p', 'f', 'f', 'f'},
	SetPlayerCameraPos = {'p', 'f', 'f', 'f'},
	SetPlayerCheckpoint = {'p', 'f', 'f', 'f', 'f'},
	SetPlayerColor = {'p', 'c'},
	SetPlayerDisabledWeapons = {'p'},
	SetPlayerFacingAngle = {'p', 'f'},
	SetPlayerGravity = {'p', 'f'},
	SetPlayerHealth = {'p', 'f'},
	SetPlayerInterior = {'p', 'i'},
	SetPlayerMapIcon = {'p', 'i', 'f', 'f', 'f', 'i', 'c', client=true},
	SetPlayerMarkerForPlayer = {'p', 'p', 'c', client=true},
	SetPlayerName = {'p', 's'},
	SetPlayerObjectPos = {'p', 'i', 'f', 'f', 'f'},
	SetPlayerObjectRot = {'p', 'i', 'f', 'f', 'f'},
	SetPlayerPos = {'p', 'f', 'f', 'f'},
	SetPlayerPosFindZ = {'p', 'f', 'f', 'f', client=true},
	SetPlayerRaceCheckpoint = {'p', 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'f'},
	SetPlayerScore = {'p', 'i'},
	SetPlayerSkin = {'p', 'i'},
	SetPlayerSpecialAction = {'p', 'i'},
	SetPlayerTeam = {'p', 't'},
	SetPlayerTime = {'p', 'i', 'i'},
	SetPlayerVirtualWorld = {'p', 'i'},
	SetPlayerWantedLevel = {'p', 'i'},
	SetPlayerWeather = {'p', 'i'},
	SetPlayerWorldBounds = {'p', 'f', 'f', 'f', 'f', client=true},
	SetSpawnInfo = {'p', 't', 'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i'},
	SetTeamCount = {'i'},
	SetTimer = {'s', 'i', 'b'},
	SetTimerEx = {'s', 'i', 'b', 's'},
	SetVehicleHealth = {'v', 'f'},
	SetVehicleModel = {'v', 'i'},
	SetVehicleNumberPlate = {'v', 's'},
	SetVehicleParamsForPlayer = {'v', 'p', 'b', 'b'},
	SetVehiclePos = {'v', 'f', 'f', 'f'},
	SetVehicleToRespawn = {'v'},
	SetVehicleVelocity = {'v', 'f', 'f', 'f'},
	SetVehicleVirtualWorld = {'v', 'i'},
	SetVehicleZAngle = {'v', 'f'},
	SetWeather = {'i'},
	SetWorldTime = {'i'},
	ShowMenuForPlayer = {'m', 'p'},
	ShowNameTags = {'b'},
	ShowPlayerMarker = {'p', 'b'},
	ShowPlayerMarkers = {'b'},
	ShowPlayerNameTagForPlayer = {'p', 'p', 'b'},
	SpawnPlayer = {'p'},
	StopObject = {'o'},
	StopPlayerObject = {'p', 'i'},

	SetPVarInt = {'p', 's', 'i'},
	SetPVarFloat = {'p', 's', 'f'},
	SetPVarString = {'p', 's', 's'},

	TextDrawAlignment = {'x', 'i'},
	TextDrawBackgroundColor = {'x', 'c'},
	TextDrawBoxColor = {'x', 'c'},
	TextDrawColor = {'x', 'c'},
	TextDrawCreate = {'f', 'f', 's'},
	TextDrawDestroy = {'i'},
	TextDrawFont = {'x', 'i'},
	TextDrawHideForAll = {'i'},
	TextDrawHideForPlayer = {'p', 'i'},
	TextDrawLetterSize = {'x', 'f', 'f'},
	TextDrawSetOutline = {'x', 'i'},
	TextDrawSetProportional = {'x', 'b'},
	TextDrawSetShadow = {'x', 'i'},
	TextDrawSetString = {'x', 's'},
	TextDrawShowForAll = {'i'},
	TextDrawShowForPlayer = {'p', 'i'},
	TextDrawTextSize = {'x', 'f', 'f'},
	TextDrawUseBox = {'x', 'b'},
	--Player textdraws
	PlayerTextDrawDestroy = {'p', 'i'},
  	PlayerTextDrawShow = {'p', 'i'},
  	PlayerTextDrawHide = {'p', 'i'},
  	PlayerTextDrawBoxColor = {'p', 'i', 'c'},
  	PlayerTextDrawUseBox = {'p', 'i', 'i'},
  	PlayerTextDrawTextSize = {'p', 'i', 'f', 'f'},
 	PlayerTextDrawLetterSize = {'p', 'i', 'f', 'f'},
	PlayerTextDrawAlignment = {'p', 'i', 'i'},
	PlayerTextDrawBackgroundColor = {'p', 'i', 'c'},
	PlayerTextDrawFont = {'p', 'i', 'i'},
	PlayerTextDrawColor = {'p', 'i', 'c'},
	PlayerTextDrawSetOutline = {'p', 'i', 'i'},
	PlayerTextDrawSetProportional = {'p', 'i', 'i'},
	PlayerTextDrawSetShadow = {'p', 'i', 'i'},
	PlayerTextDrawSetString = {'p', 'i', 's'},
	PlayerTextDrawSetPreviewModel = {'p', 'i', 'i'},
	PlayerTextDrawSetPreviewVehCol = {'p', 'i', 'i', 'i'},
	PlayerTextDrawSetSelectable = {'p', 'i', 'i'},
	PlayerTextDrawSetPreviewRot = {'p', 'i', 'f', 'f', 'f', 'f'},
	CreatePlayerTextDraw = {'p', 'f', 'f', 's'},

	TogglePlayerClock = {'p', 'b', client=true},
	TogglePlayerControllable = {'p', 'b'},
	TogglePlayerSpectating = {'p', 'b'},

	UsePlayerPedAnims = {},

	ShowCursor = {'p', 'b', 'b'},

	CreateBot = { 'i', 'f', 'f', 'f', 's'},
	DestroyBot = {'z'},
	IsBotInWater = {'z'},
	IsBotOnFire = {'z'},
	IsBotDucked = {'z'},
	IsBotOnGround = {'z'},
	GetBotHealth = {'z', 'r'},
	SetBotHealth = {'z', 'f'},
	GetBotArmour = {'z', 'r'},
	SetBotArmour = {'z', 'f'},
	GetBotPos = {'z', 'r', 'r', 'r'},
	SetBotPos = {'z', 'f', 'f', 'f'},
	GetBotRot = {'z', 'r', 'r', 'r'},
	SetBotRot = {'z', 'f', 'f', 'f'},
	GetPlayerFightingStyle = {'z'},
	SetPlayerFightingStyle = {'z','i'},
	SetBotOnFire = {'z', 'b'},
	GetBotSkin = {'z'},
	SetBotSkin = {'z', 'i'},
	GetBotStat = {'z', 'i'},
	SetBotStat = {'z', 'i', 'f'},
	GetBotState = {'z'},
	PutBotInVehicle = {'z', 'v', 'i'},
	RemoveBotFromVehicle = {'z'},
	SetBotControlState = {'z', 's', 'b'},
	SetBotAimTarget = {'z', 'f', 'f', 'f'},
	GetBotDoingDriveBy = {'z'},
	SetBotDoingDriveBy = {'z', 'b'},
	GetBotCanBeKnockedOffBike = {'z'},
	SetBotCanBeKnockedOffBike = {'z', 'b'},
	SetBotWeaponSlot = {'z', 'i'},
	SetBotHeadless = {'z', 'b'},
	IsBotDead = {'z'},
	KillBot = {'z'},
	GetBotAlpha = {'z'},
	SetBotAlpha = {'z', 'i'},
	GetBotName = {'z', 'r', 'i'},
	GetBotVehicleSeat = {'z'},
	GetBotVelocity = {'z', 'r', 'r', 'r'},
	SetBotVelocity = {'z', 'f', 'f', 'f'},


	-- players
	IsPlayerInWater = {'p'},
	IsPlayerOnFire = {'p'},
	IsPlayerDucked = {'p'},
	IsPlayerOnGround = {'p'},
	GetPlayerFightingStyle = {'p'},
	SetPlayerFightingStyle = {'p','i'},
	SetPlayerOnFire = {'p', 'b'},
	GetPlayerStat = {'p', 'i'},
	SetPlayerStat = {'p', 'i', 'f'},
	GetPlayerCanBeKnockedOffBike = {'p'},
	SetPlayerCanBeKnockedOffBike = {'p', 'b'},
	GetPlayerDoingDriveBy = {'p'},
	SetPlayerDoingDriveBy = {'p', 'b'},
	SetPlayerWeaponSlot = {'p', 'i'},
	SetPlayerHeadless = {'p', 'b'},
	GetPlayerBlurLevel = {'p'},
	SetPlayerBlurLevel = {'p', 'i'},
	GetPlayerAlpha = {'p'},
	SetPlayerAlpha = {'p', 'i'},
	FadePlayerCamera = {'p', 'b', 'f', 'i', 'i', 'i'},
	GetPlayerVehicleSeat = {'p'},
	GetPlayerVelocity = {'p', 'r', 'r', 'r'},
	SetPlayerVelocity = {'p', 'f', 'f', 'f'},
	SetPlayerControlState = {'p', 's', 'b'},
	GetPlayerSkillLevel = {'p', 'i'},
	SetPlayerSkillLevel = {'p', 'i', 'i'},
	SetPlayerArmedWeapon = {'p', 'i'},

	-- vehicles
	GetVehicleEngineState = {'v'},
	SetVehicleEngineState = {'v', 'b'},
	GetVehicleDoorState = {'v', 'i'},
	SetVehicleDoorState = {'v', 'i', 'i'},
	GetVehicleDamageStatus = {'v', 'r', 'r', 'r', 'r'},
	UpdateVehicleDamageStatus = {'v', 'i', 'i', 'i', 'i'},
	GetVehicleMaxPassengers = {'v'},
	GetVehicleParamsCarDoors = {'v', 'r', 'r', 'r', 'r'},
	SetVehicleParamsCarDoors = {'v', 'b', 'b', 'b', 'b'},
	GetVehicleParamsEx = {'v', 'r', 'r', 'r', 'r', 'r', 'r', 'r'},
	SetVehicleParamsEx = {'v', 'b', 'b', 'b', 'b', 'b', 'b', 'b'},
	GetVehicleLightState = {'v', 'i'},
	SetVehicleLightState = {'v', 'i', 'i'},
	GetVehicleOverrideLights = {'v'},
	SetVehicleOverrideLights = {'v', 'i'},
	GetVehicleWheelState = {'v','i'},
	SetVehicleWheelState = {'v','i','i','i','i'},
	GetVehicleAlpha = {'v'},
	SetVehicleAlpha = {'v', 'i'},
	GetVehiclePaintjob = {'v'},
	GetVehicleComponentInSlot = {'v', 'i'},
	GetVehicleSirensOn = {'v'},
	SetVehicleSirensOn = {'v', 'b'},
	IsTrainDerailable = {'v'},
	IsTrainDerailed = {'v'},
	SetTrainDerailable = {'v', 'b'},
	SetTrainDerailed = {'v', 'b'},
	GetTrainDirection = {'v'},
	SetTrainDirection = {'v', 'b'},
	GetTrainSpeed = {'v', 'r'},
	SetTrainSpeed = {'v', 'f'},
	GetVehicleComponentType = {'i'},

	-- pickups
	GetPickupType = {'u'},
	SetPickupType = {'u', 'i', 'i', 'i', 'i'},
	GetPickupWeapon = {'u'},
	GetPickupAmount = {'u'},
	GetPickupAmmo = {'u'},

	-- markers
	CreateMarker = {'f', 'f', 'f', 's', 'f', 'i', 'i', 'i', 'i'},
	DestroyMarker = {'k'},
	GetMarkerColor = {'k', 'i'},
	GetMarkerIcon = {'k'},
	GetMarkerSize = {'k', 'r'},
	GetMarkerTarget = {'k', 'r', 'r', 'r'},
	GetMarkerType = {'k'},
	SetMarkerColor = {'k', 'i', 'i', 'i', 'i'},
	SetMarkerIcon = {'k', 'i'},
	SetMarkerSize = {'k', 'f'},
	SetMarkerTarget = {'k', 'f', 'f', 'f'},
	SetMarkerType = {'k', 'i'},
	IsPlayerInMarker = {'k', 'p'},
	IsBotInMarker = {'k', 'z'},
	IsVehicleInMarker = {'k', 'v'},

	-- misc
	SetSkyGradient = {'i','i','i','i','i','i'},
	ResetSkyGradient = {},
	GetCloudsEnabled = {},
	SetCloudsEnabled = {'b'},
	IsGarageOpen = {'i'},
	SetGarageOpen = {'i','b'},
	IsGlitchEnabled = {'s'},
	SetGlitchEnabled = {'s', 'b'},
	GetFPSLimit = {},
	SetFPSLimit = {'i'},
	GetRandomPlayer = {},
	GetPlayerCount = {},
	GetObjectAlpha = {'o'},
	SetObjectAlpha = {'o', 'i'},
	GetWaveHeight = {},
	SetWaveHeight = {'f'},
	SetWaterLevel = {'f'},
	GetDistanceBetweenPoints2D = {'f', 'f', 'f', 'f'},
	GetDistanceBetweenPoints3D = {'f', 'f', 'f', 'f', 'f', 'f'},
	md5hash = {'s', 'r', 'i'},

	-- rules
	SetRuleValue = {'s', 's'},
	GetRuleValue = {'s', 'r', 'i'},
	RemoveRuleValue = {'s'},

	-- dialogs
	ShowPlayerDialog = {'p', 'i', 'i', 's','s', 's', 's', client=true},

	-- scoreboard
	AddScoreboardColumn = {'s'},
	RemoveScoreboardColumn = {'s'},
	SetScoreboardData = {'p', 's', 's'},

	-- dummy
	ConnectNPC = {'s', 's'},
	IsPlayerNPC = {'p'},
	SetPlayerChatBubble = {'p', 's', 'i', 'f', 'i'},

	TextDrawSetSelectable = {},
	SetObjectMaterial = {},
	GetVehicleModelInfo = {},
	GetPlayerSurfingObjectID = {},
	SendClientCheck = {},
	SetPlayerObjectMaterial = {},
	EditPlayerObject = {},
	TextDrawSetPreviewModel = {},
	TextDrawSetPreviewRot = {},
	AttachObjectToObject = {},
	HTTP = {'i', 'i', 's', 's', 's'},

	Create3DTextLabel = {'s', 'c', 'f', 'f', 'f', 'f', 'i', 'i'},
	CreatePlayer3DTextLabel = {'p', 's', 'c', 'f', 'f', 'f', 'f', 'i', 'i'},
	Delete3DTextLabel = {'a'},
	DeletePlayer3DTextLabel = {'p', 'a'},
	Attach3DTextLabelToPlayer = {'a', 'p', 'f', 'f', 'f'},
	Attach3DTextLabelToVehicle = {'a', 'v', 'f', 'f', 'f'},
	Update3DTextLabelText = {'a', 'c', 's'},
	UpdatePlayer3DTextLabelText = {'p', 'a', 'c', 's'},

	PlayCrimeReportForPlayer  = {'p', 'i', 'i'},

	GetPlayerSurfingVehicleID = {'p'},

	GetPlayerCameraMode = {'p'},
	GetObjectModel = {'o'},
	GetPlayerObjectModel = {'p', 'o'},
	GetVehicleParamsCarWindows = {'v', 'i', 'i', 'i', 'i'},

	-- network dummy
	NetStats_BytesReceived = {'p'},
	NetStats_BytesSent = {'p'},
	NetStats_ConnectionStatus = {'p'},
	NetStats_GetConnectedTime = {'p'},
	NetStats_GetIpPort = {'p','s','i'},
	NetStats_MessagesReceived = {'p'},
	NetStats_MessagesRecvPerSecond = {'p'},
	NetStats_MessagesSent = {'p'},
	NetStats_PacketLossPercent = {'p'},


	-- player data
	SetPlayerDataInt = {'p', 's', 'i'},
	GetPlayerDataInt = {'p', 's'},
	SetPlayerDataFloat = {'p', 's', 'f'},
	GetPlayerDataFloat = {'p', 's'},
	SetPlayerDataBool = {'p', 's', 'b'},
	GetPlayerDataBool = {'p', 's'},
	SetPlayerDataStr = {'p', 's', 's'},
	GetPlayerDataStr = {'p', 's', 'r', 'i'},
	IsPlayerDataSet = {'p', 's'},
	ResetPlayerData = {'p', 's'},
	ResetAllPlayerData = {'p'},

	AddEventHandler = {'s', 's'},
	RemoveEventHandler = {'s'},

	gpci = {'p', 'r', 'i'},

	AttachObjectToVehicle = {'o', 'v', 'f', 'f', 'f', 'f', 'f', 'f'},

	acos = {'f'},
	asin = {'f'},
	atan = {'f'},
	atan2 = {'f', 'f'},

	db_close = {'i'},
	db_free_result = {'i'},
	db_field_name = {'d', 'i', 'r', 'i'},
	db_get_field = {'d', 'i', 'r', 'i'},
	db_get_field_assoc = {'d', 's', 'r', 'i'},
	db_next_row = {'d'},
	db_num_fields = {'d'},
	db_num_rows = {'d'},
	db_open = {'s'},
	db_query = {'i', 's'},

	floatstr = {'s'},
	format = {'r', 'i', 's'},

	memcpy = {'r', 'r', 'i', 'i', 'i'},
	RemoveBuildingForPlayer = {'p', 'i', 'f', 'f', 'f', 'f'},
	ManualVehicleEngineAndLights = {},
	InterpolateCameraPos = {'p', 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i'},
	InterpolateCameraLookAt = {'p', 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i'},
	PlayAudioStreamForPlayer = {'p', 's', 'f', 'f', 'f', 'f', 'i'},
	StopAudioStreamForPlayer = {'p'},
	SetPlayerAttachedObject = {'p', 'i', 'i', 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i'},
	RemovePlayerAttachedObject = {'p', 'i'},
	AttachCameraToObject = {'p', 'o'},

	-- more dummies (unimplemented)
	EnableVehicleFriendlyFire = {},	
	DisableRemoteVehicleCollisions = {'p', 'i'},
	GetPlayerTargetPlayer = {'p'},
  	GetPlayerLastShotVectors = {'p', 'r', 'r', 'r', 'r', 'r', 'r'},
  	SelectObject = {'p'},
  	CancelEdit = {'p'},
	EditAttachedObject = {'p', 'i'},
  	EditObject = {'p', 'i'},
	IsPlayerAttachedObjectSlotUsed = {'p', 'i'},
	GetPlayerVersion = {'p', 's', 'i'},
	GetPlayerNetworkStats = {'p', 'r', 'i'},
	GetNetworkStats = {'r', 'i'},
	StartRecordingPlayerData = {'p', 'i', 's'},
	StopRecordingPlayerData = {'p'},
	GetAnimationName = {'i', 's', 'i', 's', 'i'},
	GetPlayerAnimationIndex = {'p'},
	GetPlayerDrunkLevel = {'p'},
	SetPlayerDrunkLevel = {'p', 'i'},
	SelectTextDraw = {'p', 'x'},
  	CancelSelectTextDraw = {'p'},
	GetActorPos = {'i', 'r', 'r', 'r'}, --r since the vals should be passed by ref
	GetPVarsUpperIndex = {'p'},
  	GetPVarNameAtIndex = {'p', 'i', 'r', 'i'},
	SetVehicleParamsCarWindows = {'v', 'i', 'i', 'i', 'i'},
	GetPlayerVersion = {'p', 's', 'i'},
	--End of unimplemented funcs

	-- new imp
	IsVehicleStreamedIn = {'v', 'p'},
	IsPlayerStreamedIn = {'p', 'p'},

	GetVehiclePoolSize = {},
	GetPlayerPoolSize = {},

	GetPlayerDistanceFromPoint = {'p', 'f', 'f', 'f'},
	GetVehicleDistanceFromPoint = {'v', 'f', 'f', 'f'},

	IsPlayerInRangeOfPoint = {'p', 'f', 'f', 'f', 'f'},

	VectorSize = {'f', 'f', 'f'},

	-- actors
	CreateActor = {'i', 'f', 'f', 'f', 'f'},

	IsValidActor = {'i'},
	IsActorStreamedIn = {'i'},
	DestroyActor = {'y'},
	ApplyActorAnimation = {'y', 's', 's', 'f', 'b', 'b', 'b', 'b', 'i'},
	ClearActorAnimations = {'y'},
	GetActorFacingAngle = {'y', 'r'},
	GetActorHealth = {'y', 'r'},
	GetActorPoolSize = {},
	GetActorVirtualWorld = {'y'},
	GetPlayerCameraTargetActor = {},
	GetPlayerTargetActor = {'p'},
	IsActorInvulnerable = {},
	SetActorFacingAngle = {'y', 'f'},
	SetActorHealth = {'y', 'f'},
	SetActorInvulnerable = {},
	SetActorPos = {'y', 'f', 'f', 'f'},
	SetActorVirtualWorld = {'y', 'i'},

	-- security
	SHA256_PassHash = {'s', 's', 'r', 'i'},

	-- siren
	GetVehicleParamsSirenState = {'v'},


	GetPlayerWeaponState = {'p'},

	-- Explosion
	CreateExplosionForPlayer = {'p', 'f', 'f', 'f', 'i', 'f'}
}
