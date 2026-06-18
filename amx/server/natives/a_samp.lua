----------------------------------------------
-- Start of SA-MP API implementation

function SendClientMessage(amx, player, r, g, b, a, message)
	--[[
	for mta, samp in pairs(g_CommandMapping) do
		message = message:gsub('/' .. samp, '/' .. mta)
	end
	]] -- This replaces any part of a string, causing commands such as '/quitfaction' to display as '/outfaction'

	-- replace colors
	return outputChatBox(colorizeString(message), player, r, g, b, true)
end

function SendClientMessageToAll(amx, r, g, b, a, message)
	--[[
	for mta, samp in pairs(g_CommandMapping) do
		message = message:gsub('/' .. samp, '/' .. mta)
	end
	]] -- This replaces any part of a string, causing commands such as '/quitfaction' to display as '/outfaction'

	-- replace colors
	return outputChatBox(colorizeString(message), root, r, g, b, true)
end

function SendPlayerMessageToAll(amx, sender, message)
	local r, g, b = getPlayerNametagColor(sender)
	if not r then
		r, g, b = 255, 255, 255
	end
	local formattedMessage = getPlayerName(sender) .. ':#FFFFFF ' .. colorizeString(message)
	return outputChatBox(formattedMessage, root, r, g, b, true)
end

function SendPlayerMessageToPlayer(amx, playerTo, playerFrom, message)
	local r, g, b = getPlayerNametagColor(playerFrom)
	if not r then
		r, g, b = 255, 255, 255
	end
	local formattedMessage = getPlayerName(playerFrom) .. ':#FFFFFF ' .. colorizeString(message)
	return outputChatBox(formattedMessage, playerTo, r, g, b, true)
end

function SendDeathMessage(amx, killerID, victim, reason)
	local killmessages = getResourceFromName('killmessages')
	if not killmessages or getResourceState(killmessages) ~= 'running' then
		return false
	end

	if isElement(victim) and getElementType(victim) == 'player' then
		local killer = g_Players[killerID] and g_Players[killerID].elem or nil

		local pR, pG, pB = getPlayerNametagColor(victim)
		local kR, kG, kB = 255, 255, 255
		if isElement(killer) then
			kR, kG, kB = getPlayerNametagColor(killer)
		end

		triggerClientEvent(root, 'onClientPlayerKillMessage', victim, killer, reason, pR, pG, pB, kR, kG, kB)
	end
	return true
end

function SendDeathMessageToPlayer(amx, player, killerID, victim, reason)
	local killmessages = getResourceFromName('killmessages')
	if not killmessages or getResourceState(killmessages) ~= 'running' then
		return false
	end

	if not player then return false end
	if isElement(victim) and getElementType(victim) == 'player' then
		local killer = g_Players[killerID] and g_Players[killerID].elem or nil

		local pR, pG, pB = getPlayerNametagColor(victim)
		local kR, kG, kB = 255, 255, 255
		if isElement(killer) then
			kR, kG, kB = getPlayerNametagColor(killer)
		end

		triggerClientEvent(player, 'onClientPlayerKillMessage', victim, killer, reason, pR, pG, pB, kR, kG, kB)
	end
	return true
end

function GameTextForAll(amx, str, time, style)
	--[[
	for mta, samp in pairs(g_CommandMapping) do
		str = str:gsub('/' .. samp, '/' .. mta)
	end
	]] -- This replaces any part of a string, causing commands such as '/quitfaction' to display as '/outfaction'

	for i, player in pairs(g_Players) do
		GameTextForPlayer(amx, player.elem, str, time, style)
	end
	return true
end

function GameTextForPlayer(amx, player, str, time, style)
	--[[
	for mta, samp in pairs(g_CommandMapping) do
		str = str:gsub('/' .. samp, '/' .. mta)
	end
	]] -- This replaces any part of a string, causing commands such as '/quitfaction' to display as '/outfaction'

	clientCall(player, 'GameTextForPlayer', str, time, style)
	return true
end

function SetTimerEx(amx, fnName, interval, repeating, fmt, ...)
	local vals = { ... }
	for i, val in ipairs(vals) do
		if fmt:sub(i, i) == 's' then
			vals[i] = readMemString(amx, val)
		else
			vals[i] = amx.memDAT[val]
		end
	end

	if repeating then
		local timer = setTimer(procCallInternal, interval, 0, amx.name, fnName, unpack(vals))
		return table.insert(amx.timers, timer)
	else
		local id = table.insert(amx.timers, false)
		local timer = setTimer(
			function(timerID, ...)
				amx.timers[timerID] = nil
				procCallInternal(amx, fnName, ...)
			end,
			interval, 1, id, unpack(vals)
		)
		amx.timers[id] = timer
		return id
	end
end

SetTimer = SetTimerEx

function KillTimer(amx, timerID)
	if not amx.timers[timerID] then
		return
	end
	killTimer(amx.timers[timerID])
	amx.timers[timerID] = nil
end

local serverStartTick = getTickCount()
function GetTickCount(amx)
	return getTickCount() - serverStartTick
end

function GetMaxPlayers(amx)
	return getMaxPlayers()
end

function CallLocalFunction(amx, fnName, fmt, ...)
	local args = { ... }
	for i = 1, math.min(#fmt, #args) do
		if fmt:sub(i, i) == 's' then
			args[i] = readMemString(amx, args[i])
		else
			args[i] = amx.memDAT[args[i]]
		end
	end
	return procCallInternal(amx, fnName, unpack(args))
end

function CallRemoteFunction(amx, fnName, fmt, ...)
	local args = { ... }
	for i = 1, math.min(#fmt, #args) do
		if fmt:sub(i, i) == 's' then
			args[i] = readMemString(amx, args[i])
		else
			args[i] = amx.memDAT[args[i]]
		end
	end
	return procCallOnAll(fnName, unpack(args))
end

function VectorSize(amx, x, y, z)
	return float2cell(math.sqrt((x ^ 2) + (y ^ 2) + (z ^ 2)))
end

function acos(amx, f)
	return float2cell(math.deg(math.acos(f)))
end

function asin(amx, f)
	return float2cell(math.deg(math.asin(f)))
end

function atan(amx, f)
	return float2cell(math.deg(math.atan(f)))
end

function atan2(amx, x, y)
	return float2cell(math.deg(math.atan2(x, y)))
end

-- Security

function SHA256_PassHash(amx, pass, salt, ret_hash, ret_hash_len)
	if ret_hash_len <= 0 then return 0 end

	local secret = hash('sha256', pass .. '' .. salt) -- who is it guy which writes salt after pass?
	secret = string.upper(secret)

	local copy_len = math.min(#secret, ret_hash_len)
	writeMemString(amx, ret_hash, secret:sub(1, copy_len))
	return copy_len
end

function GetSVarInt(amx, varname)
	local value = g_SVars[varname]
	if not value or value[1] ~= SERVER_VARTYPE_INT then
		return 0
	end
	return value[2]
end

function SetSVarInt(amx, varname, value)
	g_SVars[varname] = {SERVER_VARTYPE_INT, value}
	return true
end

function GetSVarString(amx, varname, outbuf, length)
	if length <= 0 then return 0 end

	local value = g_SVars[varname]
	if not value or value[1] ~= SERVER_VARTYPE_STRING then
		return 0
	end

	local copyLen = math.min(#value[2], length)
	writeMemString(amx, outbuf, string.sub(value[2], 1, copyLen))
	return copyLen
end

function SetSVarString(amx, varname, value)
	g_SVars[varname] = {SERVER_VARTYPE_STRING, value}
	return true
end

function GetSVarFloat(amx, varname)
	local value = g_SVars[varname]
	if not value or value[1] ~= SERVER_VARTYPE_FLOAT then
		return float2cell(0)
	end
	return float2cell(value[2])
end

function SetSVarFloat(amx, varname, value)
	g_SVars[varname] = {SERVER_VARTYPE_FLOAT, value}
	return true
end

function DeleteSVar(amx, varname)
	g_SVars[varname] = nil
	return true
end

function GetSVarsUpperIndex(amx)
	local varCount = 0
	for _ in pairs(g_SVars) do
		varCount = varCount + 1
	end

	return varCount
end

function GetSVarNameAtIndex(amx, index, outbuf, length)
	if length <= 0 or index < 0 then return 0 end

	local varNames = {}
	for name in pairs(g_SVars) do
		table.insert(varNames, name)
	end

	if index >= #varNames then return 0 end
	local varName = varNames[index + 1]

	local copyLen = math.min(#varName, length)
	writeMemString(amx, outbuf, varName:sub(1, copyLen))
	return copyLen
end

function GetSVarType(amx, varname)
	local value = g_SVars[varname]
	if value then
		return value[1]
	end
	return SERVER_VARTYPE_NONE
end

function SetGameModeText(amx, gamemodeName)
	return setGameType(gamemodeName)
end

function SetTeamCount(amx, count)
	deprecated('SetTeamCount', '0.3')
	return false
end

function AddPlayerClass(amx, skin, x, y, z, angle, weap1, weap1_ammo, weap2, weap2_ammo, weap3, weap3_ammo)
	return AddPlayerClassEx(amx, false, skin, x, y, z, angle, weap1, weap1_ammo, weap2, weap2_ammo, weap3, weap3_ammo)
end

function AddPlayerClassEx(amx, team, skin, x, y, z, angle, weap1, weap1_ammo, weap2, weap2_ammo, weap3, weap3_ammo)
	local id = table.insert0(
		g_PlayerClasses,
		{
			x, y, z, angle, g_SkinReplace[skin] or skin, 0, 0, team,
			weapons = {
				{ weap1, weap1_ammo },
				{ weap2, weap2_ammo },
				{ weap3, weap3_ammo }
			}
		}
	)
	return id
end

function AddStaticVehicle(amx, model, x, y, z, angle, color1, color2)
	return AddStaticVehicleEx(amx, model, x, y, z, angle, color1, color2, 120)
end

function AddStaticVehicleEx(amx, model, x, y, z, angle, color1, color2, respawnDelay, addSiren)
	local vehicle = createVehicle(model, x, y, z, 0, 0, angle)
	if not vehicle then
		return INVALID_VEHICLE_ID
	end

	if not g_PoliceVehicles[model] then
		setVehicleColorClamped(vehicle, color1, color2)
	end

	local vehID = addElem(g_Vehicles, vehicle)
	if respawnDelay <= 0 then
		respawnDelay = 120
	end

	g_Vehicles[vehID].vehicleIsAlive = true
	g_Vehicles[vehID].respawndelay = respawnDelay * 1000
	g_Vehicles[vehID].spawninfo = { x = x, y = y, z = z, angle = angle }
	g_Vehicles[vehID].engineState = false

	setElementData(vehicle, 'WindowFrontLeft', true)
	setElementData(vehicle, 'WindowFrontRight', true)
	setElementData(vehicle, 'WindowRearLeft', true)
	setElementData(vehicle, 'WindowRearRight', true)

	if ManualVehEngineAndLights then
		if (getVehicleType(vehicle) ~= 'Plane' and getVehicleType(vehicle) ~= 'Helicopter') then
			setVehicleEngineState(vehicle, false)
			for i = 0, 4 do
				setVehicleLightState(vehicle, i, 0)
			end
		end
	end

	if getVehicleType(vehicle) == 'Train' then
		setTrainDerailable(vehicle, false)

		local model = getElementModel(vehicle)
		local carriageModels = {
			[537] = 569, -- Freight -> Freight carriage
			[538] = 570 -- Streak -> Streak carriage
		}

		local wagonModel = carriageModels[model]
		if wagonModel then
			local vehToAttach = vehicle

			for i = 1, 3 do
				local wagonID = AddStaticVehicleEx(amx, wagonModel, x, y, z, angle, color1, color2, respawnDelay, addSiren)
				if wagonID == INVALID_VEHICLE_ID then break end

				setElementParent(g_Vehicles[wagonID].elem, vehicle)
				attachTrailerToVehicle(vehToAttach, g_Vehicles[wagonID].elem)
				vehToAttach = g_Vehicles[wagonID].elem
			end
		end
	end

	if addSiren then
		addVehicleSirens(vehicle, 1, 1)
	end
	return vehID
end

function AddStaticPickup(amx, model, type, x, y, z, world)
	local mtaPickupType, mtaPickupAmount, mtaPickupAmmo
	if model == 1240 then		-- health
		mtaPickupType = 0
		mtaPickupAmount = 100
	elseif model == 1242 then	-- armor
		mtaPickupType = 1
		mtaPickupAmount = 100
	else						-- weapon
		mtaPickupType = 2
		mtaPickupAmount = g_WeaponIDMapping[model]
		if mtaPickupAmount then
			mtaPickupAmmo = g_PickupAmmo[mtaPickupAmount]
			if not mtaPickupAmmo then
				mtaPickupAmmo = 1
			end
		else
			mtaPickupType = 3
			mtaPickupAmount = model
		end
	end

	local pickup = createPickup(x, y, z, mtaPickupType, mtaPickupAmount, 30000, mtaPickupAmmo)
	if not pickup then
		outputDebugString('Failed to create pickup of model ' .. model, 2)
		return -1
	end

	if world and world ~= -1 then
		setElementDimension(pickup, world)
	end

	return addElem(g_Pickups, pickup)
end

CreatePickup = AddStaticPickup

function DestroyPickup(amx, pickup)
	removeElem(g_Pickups, pickup)
	destroyElement(pickup)
	return true
end

function ShowNameTags(amx, show)
	g_ShowNameTags = show
	clientCall(root, 'updateNameTagGlobals', {status = show})
	return true
end

function ShowPlayerMarkers(amx, mode)
	g_PlayerMarkersMode = mode
	for i, data in pairs(g_Players) do
		ShowPlayerMarker(amx, data.elem, mode)
	end
	return true
end

function GameModeExit(amx)
	local mapcycler = getResourceFromName('mapcycler')
	local votemanager = getResourceFromName('votemanager')

	if getResourceState(mapcycler) == 'running' then
		triggerEvent('onRoundFinished', getResourceRootElement(getThisResource()))
	elseif getResourceState(votemanager) == 'running' then
		exports.votemanager:voteMap(getThisResource())
	else
		local amx = getRunningGameMode(mode)
		if amx then unloadAMX(amx) end
	end
	return true
end

function SetWorldTime(amx, hours)
	return setTime(hours % 24, 0)
end

function GetWeaponName(amx, weaponID, buf, len)
	if len <= 0 then return 0 end

	local name = getWeaponNameFromID(weaponID)
	if not name then name = '' end

	local copyLen = math.min(#name, len)
	writeMemString(amx, buf, name:sub(1, copyLen))
	return copyLen
end

function EnableTirePopping(amx, enable)
	-- doesn't work in SA-MP as well, tire popping is always on
end

function EnableVehicleFriendlyFire(amx)
	g_FriendlyFire = true
	clientCall(root, 'updateFriendlyFire', true)
	return true
end

function AllowInteriorWeapons(amx, allow)
	deprecated('AllowInteriorWeapons', '0.3')
	return true
end

function SetWeather(amx, weatherID)
	return setWeather(weatherID % 256)
end

function SetGravity(amx, gravity)
	setGravity(gravity)
	table.each(g_Players, 'elem', setPedGravity, gravity)
	return true
end

function GetGravity(amx)
	return float2cell(getGravity())
end

function AllowAdminTeleport(amx, allow)
	deprecated('AllowAdminTeleport', '0.3d')
	return true
end

function SetDisabledWeapons(amx, ...)
	deprecated('SetDisabledWeapons', '0.3')
	return true
end

function SetDeathDropAmount(amx, amount)
	deprecated('SetDeathDropAmount', '0.3')
	return true
end

function CreateExplosion(amx, x, y, z, type, radius)
	return createExplosion(x, y, z, type)
end

function ShowPlayerMarker(amx, player, mode)
	local playerdata = g_Players[getElemID(player)]
	if not playerdata then return false end

	if mode and mode ~= 0 then
		if not playerdata.blip then
			local r, g, b = getPlayerNametagColor(player)
			playerdata.blip = createBlipAttachedTo(player, 0, 2, r, g, b)
		end

		if mode == 1 then -- Mode global
			setBlipVisibleDistance(playerdata.blip, g_PlayerMarkerRadius or 16383.0)
		elseif mode == 2 then -- Mode streamed
			setBlipVisibleDistance(playerdata.blip, 250.0)
		end
	elseif playerdata.blip then
		destroyElement(playerdata.blip)
		playerdata.blip = nil
	end
	return true
end

function EnableZoneNames(amx, enable)
	g_ShowZoneNames = enable
	for i, data in pairs(g_Players) do
		setPlayerHudComponentVisible(data.elem, 'area_name', enable)
	end
	return true
end

function UsePlayerPedAnims(amx)
	g_UseCJWalk = true
	for i, data in pairs(g_Players) do
		-- update walking style to default
		setPedWalkingStyle(data.elem, 0)
	end
	return true
end

function DisableInteriorEnterExits(amx)
	-- interiors resource implements enex markers
	local interiors = getResourceFromName('interiors')

	-- as we want to disable it, stop this resource
	if getResourceState(interiors) == 'running' then
		stopResource(interiors)
	end
	return true
end

function DisableNameTagLOS(amx)
	g_NameTagsLOS = false
	clientCall(root, 'updateNameTagGlobals', {los = false})
	return true
end

function SetNameTagDrawDistance(amx, distance)
	g_NameTagsRadius = distance
	clientCall(root, 'updateNameTagGlobals', {radius = distance})
	return true
end

function LimitGlobalChatRadius(amx, radius)
	if radius > 0 then
		g_GlobalChatRadius = radius
	end
	return true
end

function LimitPlayerMarkerRadius(amx, radius)
	if radius > 0 then
		g_PlayerMarkerRadius = radius
	end
	return true
end

function ConnectNPC(amx, name, script)
	notImplemented('ConnectNPC')
	return true
end

function IsPlayerNPC(amx, player)
	notImplemented('IsPlayerNPC')
	return false
end

function Kick(amx, player)
	kickPlayer(player)
	return true
end

function Ban(amx, player)
	banPlayer(player)
	return true
end

function BanEx(amx, player, reason)
	banPlayer(player, nil, reason)
	return true
end

function SendRconCommand(amx, command)
	print(doRCON(command))
	return true
end

function SpawnPlayer(amx, player)
	local playerdata = g_Players[getElemID(player)]
	if playerdata.doingclasssel then
		-- Call requestSpawn instead so we clear up any binds
		-- since there's a workaround in SA-MP to skip the spawn selection screen
		requestSpawn(player, false, false)
	else
		spawnPlayerBySelectedClass(player)
	end
	return true
end

function GetPlayerNetworkStats(amx, player, nameBuf, bufSize)
	if bufSize <= 0 then return false end

	local result = {}
	for index, value in pairs(getNetworkStats(player)) do
		table.insert(result, tostring(index) .. ': ' .. tostring(value))
	end
	result = table.concat(result, '\n')

	local copyLen = math.min(#result, bufSize)
	writeMemString(amx, nameBuf, string.sub(result, 1, copyLen))
	return true
end

function GetNetworkStats(amx, nameBuf, bufSize)
	if bufSize <= 0 then return false end

	local result = {}
	for index, value in pairs(getNetworkStats()) do
		table.insert(result, tostring(index) .. ': ' .. tostring(value))
	end
	result = table.concat(result, '\n')

	local copyLen = math.min(#result, bufSize)
	writeMemString(amx, nameBuf, string.sub(result, 1, copyLen))
	return true
end

function GetPlayerVersion(amx, player, nameBuf, bufSize)
	if bufSize <= 0 then return 0 end

	local version = getPlayerVersion(player)

	local copyLen = math.min(#version, bufSize)
	writeMemString(amx, nameBuf, version:sub(1, copyLen))
	return copyLen
end

function BlockIpAddress(amx, ip, time)
	if ip == '' then return false end

	local match = ipMaskToPattern(ip)
	local expires = (time > 0) and (getTickCount() + time) or false
	g_BlockedIPs[ip] = { match = match, expires = expires }

	local toKick = {}
	for id, data in pairs(g_Players) do
		if data.elem and isElement(data.elem) and getPlayerIP(data.elem):match(match) then
			toKick[#toKick + 1] = data.elem
		end
	end
	for i = 1, #toKick do
		kickPlayer(toKick[i], 'You are banned from this server.')
	end
	return true
end

function UnBlockIpAddress(amx, ip)
	if ip == '' then return false end
	g_BlockedIPs[ip] = nil
	return true
end

function GetServerVarAsBool(amx, varname)
	if not varname or varname == '' then
		return false
	end

	if g_ServerVars[varname] ~= nil then
		local val = tonumber(g_ServerVars[varname])

		if val then
			return val ~= 0
		elseif type(g_ServerVars[varname]) == 'boolean' then
			return g_ServerVars[varname]
		end

		return false
	end

	local val = get('amx.' .. varname)

	local numVal = tonumber(val)
	if numVal then
		return numVal ~= 0
	end

	return val and true
end

function GetServerVarAsInt(amx, varname)
	if not varname or varname == '' then
		return 0
	end

	if g_ServerVars[varname] ~= nil then
		local val = tonumber(g_ServerVars[varname])

		if val then
			return val
		elseif type(g_ServerVars[varname]) == 'boolean' then
			return g_ServerVars[varname] and 1 or 0
		end

		return 0
	end

	local val = get('amx.' .. varname)
	return val and tonumber(val) or 0
end

function GetServerVarAsString(amx, varname, buf, buflen)
	if buflen <= 0 then return 0 end
	if not varname or varname == '' then return 0 end

	local rawVal = g_ServerVars[varname] or get('amx.' .. varname)
	local valStr = (type(rawVal) == 'string') and rawVal or ''

	local copyLen = math.min(#valStr, buflen)
	writeMemString(amx, buf, valStr:sub(1, copyLen))
	return copyLen
end

GetConsoleVarAsBool = GetServerVarAsBool
GetConsoleVarAsInt = GetServerVarAsInt
GetConsoleVarAsString = GetServerVarAsString

function CreateMenu(amx, title, columns, x, y, leftColumnWidth, rightColumnWidth)
	local menu = { title = title, x = x, y = y, leftColumnWidth = leftColumnWidth, rightColumnWidth = rightColumnWidth, items = { [0] = {}, [1] = {} } }
	local id = table.insert(g_Menus, menu)
	menu.id = id
	clientCall(root, 'CreateMenu', id, menu)
	return id
end

function DestroyMenu(amx, menu)
	for i, playerdata in pairs(g_Players) do
		if playerdata.menu == menu then
			playerdata.menu = nil
		end
	end
	clientCall(root, 'DestroyMenu', menu.id)
	g_Menus[menu.id] = nil
	return true
end

function AddMenuItem(amx, menu, column, caption)
	if not menu or not menu.items[column] then
		return
	end
	table.insert(menu.items[column], caption)
	clientCall(root, 'AddMenuItem', menu.id, column, caption)
	return true
end

function SetMenuColumnHeader(amx, menu, column, text)
	if not menu or not menu.items[column] then
		return
	end
	menu.items[column][13] = text
	clientCall(root, 'SetMenuColumnHeader', menu.id, column, text)
	return true
end

function ShowMenuForPlayer(amx, menu, player)
	clientCall(player, 'ShowMenuForPlayer', menu.id)
	g_Players[getElemID(player)].menu = menu
	return true
end

function HideMenuForPlayer(amx, menu, player)
	clientCall(player, 'HideMenuForPlayer', menu.id)
	g_Players[getElemID(player)].menu = nil
	return true
end

function IsValidMenu(amx, menuID)
	return g_Menus[menuID] ~= nil
end

function DisableMenu(amx, menuID)
	local menu = g_Menus[menuID]
	if not menu then
		return false
	end
	menu.disabled = true
	for id, player in pairs(g_Players) do
		if GetPlayerMenu(amx, player.elem) == menuID then
			clientCall(player.elem, 'HideMenuForPlayer', menuID)
		end
	end
	return true
end

function DisableMenuRow(amx, menuID, rowID)
	local menu = g_Menus[menuID]
	if not menu then
		return false
	end
	clientCall(root, 'DisableMenuRow', menuID, rowID)
	return true
end

function GetPlayerMenu(amx, player)
	local playerdata = g_Players[getElemID(player)]
	return playerdata.menu and playerdata.menu.id or 0
end

function TextDrawCreate(amx, x, y, text)
	--outputDebugString('TextDrawCreate called with args ' .. x .. ' ' .. y .. ' ' .. text)

	if #g_TextDraws + 1 >= 2048 then return 65535 end

	local textdraw = { x = x, y = y, shadow = { align = 1, outlinesize = 0, shade = 2, text = text, font = 1, lwidth = 0.48, lheight = 1.12 } }
	textdraw.visible = false

	local id = table.insert(g_TextDraws, textdraw)
	textdraw.clientTDId = id

	setmetatable(
		textdraw,
		{
			__index = textdraw.shadow,
			__newindex = function(t, k, v)
				local different
				if not t.shadow[k] then
					different = true
				else
					if type(v) == 'table' then
						different = not table.cmp(v, t.shadow[k])
					else
						different = v ~= t.shadow[k]
					end
				end
				if different then
					--outputDebugString(string.format('A property changed for %s string: %s', textdraw.clientTDId, textdraw.text))
					clientCall(root, 'TextDrawPropertyChanged', textdraw.clientTDId, k, v)
					t.shadow[k] = v
				end
			end
		}
	)

	clientCall(root, 'TextDrawCreate', textdraw.clientTDId, table.deshadowize(textdraw, true))
	return id
end

function TextDrawDestroy(amx, textdrawID)
	if not g_TextDraws[textdrawID] then
		return false
	end
	clientCall(root, 'TextDrawDestroy', g_TextDraws[textdrawID].clientTDId)
	g_TextDraws[textdrawID] = nil
	return true
end

function TextDrawLetterSize(amx, textdraw, width, height)
	textdraw.lwidth = width
	textdraw.lheight = height
	return true
end

function TextDrawTextSize(amx, textdraw, x, y)
	textdraw.boxsize = { x, y } -- Game does 448 not 480
	return true
end

function TextDrawAlignment(amx, textdraw, align)
	textdraw.align = align
	return true
end

function TextDrawColor(amx, textdraw, r, g, b, a)
	textdraw.color = { r, g, b, a }
	return true
end

function TextDrawUseBox(amx, textdraw, usebox)
	textdraw.usebox = usebox
	return true
end

function TextDrawBoxColor(amx, textdraw, r, g, b, a)
	textdraw.boxcolor = { r, g, b, a }
	return true
end

function TextDrawSetShadow(amx, textdraw, size)
	textdraw.shade = size
	return true
end

function TextDrawSetOutline(amx, textdraw, size)
	textdraw.outlinesize = size
	return true
end

function TextDrawSetProportional(amx, textdraw, proportional)
	notImplemented('TextDrawSetProportional')
	return false
end

function TextDrawBackgroundColor(amx, textdraw, r, g, b, a)
	textdraw.outlinecolor = { r, g, b, a }
	return true
end

function TextDrawFont(amx, textdraw, font)
	textdraw.font = font
	return true
end

function TextDrawSetSelectable(amx, textdraw, selectable)
	textdraw.selectable = selectable
	return true
end

function TextDrawShowForPlayer(amx, player, textdrawID)
	local textdraw = g_TextDraws[textdrawID]
	if not textdraw then
		return false
	end
	clientCall(player, 'TextDrawShowForPlayer', textdraw.clientTDId)
	return true
end

function TextDrawHideForPlayer(amx, player, textdrawID)
	local textdraw = g_TextDraws[textdrawID]
	if not textdraw then
		return false
	end
	clientCall(player, 'TextDrawHideForPlayer', textdraw.clientTDId)
	return true
end

function TextDrawShowForAll(amx, textdrawID)
	for id, player in pairs(g_Players) do
		TextDrawShowForPlayer(amx, player.elem, textdrawID)
	end
	return true
end

function TextDrawHideForAll(amx, textdrawID)
	for id, player in pairs(g_Players) do
		TextDrawHideForPlayer(amx, player.elem, textdrawID)
	end
	return true
end

function TextDrawSetString(amx, textdraw, str)
	textdraw.text = str
	return true
end

function TextDrawSetPreviewModel(amx, textdraw, model)
	notImplemented('TextDrawSetPreviewModel')
	return false
end

function TextDrawSetPreviewRot(amx, textdraw, rX, rY, rZ, zoom)
	notImplemented('TextDrawSetPreviewRot')
	return false
end

function TextDrawSetPreviewVehCol(amx, textdraw, color1, color2)
	notImplemented('TextDrawSetPreviewVehCol')
	return false
end

function GangZoneCreate(amx, minX, minY, maxX, maxY)
	local zone = createRadarArea(minX, minY, maxX - minX, maxY - minY)
	local id = addElem(g_GangZones, zone)
	setElementVisibleTo(zone, root, false)
	return id
end

function GangZoneDestroy(amx, zone)
	removeElem(g_GangZones, zone)
	destroyElement(zone)
	return true
end

function GangZoneShowForPlayer(amx, player, zone, r, g, b, a)
	setRadarAreaColor(zone, r % 256, g % 256, b % 256, a % 256)
	setElementVisibleTo(zone, player, true)
	return true
end

function GangZoneShowForAll(amx, zone, r, g, b, a)
	setRadarAreaColor(zone, r % 256, g % 256, b % 256, a % 256)
	setElementVisibleTo(zone, root, true)
	return true
end

function GangZoneHideForPlayer(amx, player, zone)
	return setElementVisibleTo(zone, player, false)
end

function GangZoneHideForAll(amx, zone)
	return setElementVisibleTo(zone, root, false)
end

function GangZoneFlashForPlayer(amx, player, zone, r, g, b, a)
	clientCall(player, 'setRadarAreaFlashing', zone, true)
	return true
end

function GangZoneFlashForAll(amx, zone, r, g, b, a)
	return setRadarAreaFlashing(zone, true)
end

function GangZoneStopFlashForPlayer(amx, player, zone)
	clientCall(player, 'setRadarAreaFlashing', zone, false)
	return true
end

function GangZoneStopFlashForAll(amx, zone)
	return setRadarAreaFlashing(zone, false)
end

function Create3DTextLabel(amx, text, r, g, b, a, x, y, z, dist, vw, los)
	local textlabel = { text = colorizeString(text), color = {r = r, g = g, b = b, a = a}, X = x, Y = y, Z = z, dist = dist, vw = vw, los = los }
	local id = table.insert(g_TextLabels, textlabel)

	textlabel.id = id

	clientCall(root, 'Create3DTextLabel', id, textlabel)
	return id
end

function CreatePlayer3DTextLabel(amx, player, text, r, g, b, a, x, y, z, dist, attachedplayer, attachedvehicle, los)
	local textlabel = { text = colorizeString(text), color = {r = r, g = g, b = b, a = a}, X = x, Y = y, Z = z, dist = dist, vw = -1, los = los, attached = false }
	local id = table.insert(g_TextLabels, textlabel)

	textlabel.id = id
	if attachedplayer ~= INVALID_PLAYER_ID or attachedvehicle ~= INVALID_VEHICLE_ID then
		textlabel.attached = true
	end

	if attachedplayer ~= INVALID_PLAYER_ID then
		textlabel.attachedTo = g_Players[attachedplayer] and g_Players[attachedplayer].elem
	end

	if attachedvehicle ~= INVALID_VEHICLE_ID then
		textlabel.attachedTo = g_Vehicles[attachedvehicle] and g_Vehicles[attachedvehicle].elem
	end

	textlabel.offX = 0.0
	textlabel.offY = 0.0
	textlabel.offZ = 0.0

	clientCall(player, 'Create3DTextLabel', id, textlabel)
	return id
end

function Delete3DTextLabel(amx, textlabel)
	local id = textlabel.id
	if not g_TextLabels[id] then
		return
	end
	clientCall(root, 'Delete3DTextLabel', id)
	g_TextLabels[id] = nil
	return true
end

function DeletePlayer3DTextLabel(amx, player, textlabel)
	local id = textlabel.id
	if not g_TextLabels[id] then
		return
	end
	clientCall(player, 'Delete3DTextLabel', id)
	g_TextLabels[id] = nil
	return true
end

function Attach3DTextLabelToPlayer(amx, textlabel, player, offX, offY, offZ)
	textlabel.attached = true
	textlabel.offX = offX
	textlabel.offY = offY
	textlabel.offZ = offZ
	textlabel.attachedTo = player
	clientCall(root, 'Attach3DTextLabel', textlabel)
	return true
end

function Attach3DTextLabelToVehicle(amx, textlabel, vehicle, offX, offY, offZ)
	textlabel.attached = true
	textlabel.offX = offX
	textlabel.offY = offY
	textlabel.offZ = offZ
	textlabel.attachedTo = vehicle
	clientCall(root, 'Attach3DTextLabel', textlabel)
	return true
end

function Update3DTextLabelText(amx, textlabel, r, g, b, a, text)
	textlabel.text = colorizeString(text)
	textlabel.color = { r = r, g = g, b = b, a = a }
	clientCall(root, 'Update3DTextLabel', textlabel)
	return true
end

function UpdatePlayer3DTextLabelText(amx, player, textlabel, r, g, b, a, text)
	textlabel.text = colorizeString(text)
	textlabel.color = { r = r, g = g, b = b, a = a }
	clientCall(player, 'Update3DTextLabel', textlabel)
	return true
end

-- ShowPlayerDialog client

function floatstr(amx, str)
	return float2cell(tonumber(str) or 0)
end

function format(amx, outBuf, outBufSize, fmt, ...)
	local args = { ... }
	local argIndex = 0

	local function nextArg(kind)
		argIndex = argIndex + 1
		local addr = args[argIndex]
		if addr == nil then
			return kind == 'string' and '' or 0
		elseif kind == 'string' then
			return readMemString(amx, addr) or ''
		elseif kind == 'float' then
			return cell2float(amx.memDAT[addr] or 0)
		end
		return amx.memDAT[addr] or 0
	end

	local result = fmt:gsub('%%(%-?)(%*?%d*)(%.?%*?%d*)([%a%%])',
		function(flag, width, precision, conv)
			if conv == '%' then
				return '%' -- %% to literal percent sign
			end

			local kind
			if conv == 'd' or conv == 'i' or conv == 'x' or conv == 'c' then
				kind = 'int'
			elseif conv == 'f' then
				kind = 'float'
			elseif conv == 's' or conv == 'q' then
				kind = 'string'
			else
				-- leave unknown specifiers untouched
				return '%' .. flag .. width .. precision .. conv
			end

			if width:find('*', 1, true) then
				width = width:gsub('%*', tostring(nextArg('int')))
			end
			if precision:find('*', 1, true) then
				precision = precision:gsub('%*', tostring(nextArg('int')))
			end

			local value = nextArg(kind)
			if conv == 'i' then
				conv = 'd' -- string.format has no %i
			elseif conv == 'c' then
				value = value % 256 -- wrap to a byte
			elseif conv == 'q' then
				return ('%q'):format(value) -- no width/precision
			end

			local spec = '%' .. flag .. width .. precision .. conv
			local ok, formatted = pcall(string.format, spec, value)
			return ok and formatted or spec
		end
	)

	local copyLen = math.min(#result, outBufSize)
	writeMemString(amx, outBuf, result:sub(1, copyLen))
	return true
end

function SendClientCheck(amx, player, opcode, addr, offset, bytes)
	notImplemented('SendClientCheck')
	return false
end

function gpci(amx, player, nameBuf, bufSize)
	if bufSize <= 0 then return 0 end

	local serial = getPlayerSerial(player)

	local copyLen = math.min(#serial, bufSize)
	writeMemString(amx, nameBuf, serial:sub(1, copyLen))
	return copyLen
end

function SetSpawnInfo(amx, player, team, skin, x, y, z, angle, weap1, weap1_ammo, weap2, weap2_ammo, weap3, weap3_ammo)
	g_Players[getElemID(player)].spawninfo = {
		x, y, z, angle, g_SkinReplace[skin] or skin, 0, 0, team,
		weapons = { { weap1, weap1_ammo }, { weap2, weap2_ammo }, { weap3, weap3_ammo } }
	}
	return true
end

function NetStats_BytesReceived(amx, player)
	local networkStat = getNetworkStats(player)
	return networkStat.bytesReceived or 0
end

function NetStats_BytesSent(amx, player)
	local networkStat = getNetworkStats(player)
	return networkStat.bytesSent or 0
end

function NetStats_ConnectionStatus(amx, player)
	notImplemented('NetStats_ConnectionStatus')
	return 0 -- Status no action
end

function NetStats_GetConnectedTime(amx, player)
	local playerID = getElemID(player)
	if not g_Players[playerID].conntick then return 0 end
	return getTickCount() - g_Players[playerID].conntick
end

function NetStats_GetIpPort(amx, player, ip_port, ip_port_len)
	if ip_port_len <= 0 then return 0 end

	local ip = getPlayerIP(player)
	if not ip then ip = '0.0.0.0' end
	local port = 0 -- We haven't a solution for getting a client port
	local ipandport = tostring(ip) .. ':' .. tostring(port)

	local copy_len = math.min(#ipandport, ip_port_len)
	writeMemString(amx, ip_port, ipandport:sub(1, copy_len))
	return copy_len
end

function NetStats_MessagesReceived(amx, player)
	notImplemented('NetStats_MessagesReceived')
	return 0
end

function NetStats_MessagesRecvPerSecond(amx, player)
	notImplemented('NetStats_MessagesRecvPerSecond')
	return 0
end

function NetStats_MessagesSent(amx, player)
	notImplemented('NetStats_MessagesSent')
	return 0
end

function NetStats_PacketLossPercent(amx, player)
	local networkStat = getNetworkStats(player)
	return float2cell(networkStat.packetlossTotal or 0)
end

function GetServerTickRate(amx)
	notImplemented('GetServerTickRate')
	return 0
end
