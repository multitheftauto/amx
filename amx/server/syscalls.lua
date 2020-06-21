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

----------------------------------------------
--  Start of SA-MP API implementation

local skinReplace = {
	-- invalid skins
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0,
	[8] = 0,
	[42] = 0,
	[65] = 0,
	[74] = 0,
	[86] = 0,
	[119] = 0,
	[149] = 0,
	[208] = 0,
	[273] = 0,
}

function AddMenuItem(amx, menu, column, caption)
	table.insert(menu.items[column], caption)
	clientCall(root, 'AddMenuItem', menu.id, column, caption)
end

function AddPlayerClass(amx, skin, x, y, z, angle, weap1, weap1_ammo, weap2, weap2_ammo, weap3, weap3_ammo)
	return AddPlayerClassEx(amx, false, skin, x, y, z, angle, weap1, weap1_ammo, weap2, weap2_ammo, weap3, weap3_ammo)
end

function AddPlayerClassEx(amx, team, skin, x, y, z, angle, weap1, weap1_ammo, weap2, weap2_ammo, weap3, weap3_ammo)
	local id = table.insert0(
		g_PlayerClasses,
		{
			x, y, z, angle, skinReplace[skin] or skin, 0, 0, team,
			weapons={
				{weap1, weap1_ammo},
				{weap2, weap2_ammo},
				{weap3, weap3_ammo}
			}
		}
	)
	return id
end

function AddPlayerClothes(amx, player, type, index)
	local texture, model = getClothesByTypeIndex(type, index)
	addPedClothes(player, texture, model, type)
end

local function housePickup()
	procCallOnAll('OnPlayerPickUpPickup', getElemID(player), getElemID(source))
	cancelEvent()
end
function AddStaticPickup(amx, model, type, x, y, z)
	local mtaPickupType, mtaPickupAmount, respawntime
	if model == 1240 then		-- health
		mtaPickupType = 0
		mtaPickupAmount = 100
	elseif model == 1242 then	-- armor
		mtaPickupType = 1
		mtaPickupAmount = 100
	elseif model == 1272 or model == 1273 then
		mtaPickupType = 3
		mtaPickupAmount = model
	else						-- weapon
		mtaPickupType = 2
		mtaPickupAmount = g_WeaponIDMapping[model]
		if not mtaPickupAmount then
			mtaPickupType = 3
			mtaPickupAmount = model
		end
	end

	local pickup = createPickup(x, y, z, mtaPickupType, mtaPickupAmount)
	if not pickup then
		outputDebugString('Failed to create pickup of model ' .. model, 2)
		return 0
	end
	if isCustomPickup(pickup) then
		-- house pickups don't disappear on pickup
		addEventHandler('onPickupUse', pickup, housePickup, false)
	end
	return addElem(g_Pickups, pickup)
end

function AddStaticVehicle(amx, model, x, y, z, angle, color1, color2)
	return AddStaticVehicleEx(amx, model, x, y, z, angle, color1, color2, 120)
end

function AddStaticVehicleEx(amx, model, x, y, z, angle, color1, color2, respawnDelay)
	local vehicle = createVehicle(model, x, y, z, 0, 0, angle)
	if(vehicle == false) then
		return false
	end

	if not g_PoliceVehicles[model] then
		if(color1 <= 0 and color1 >= 126) then color1 = math.random(1, 126) end
		if(color2 <= 0 and color2 >= 126) then color2 = math.random(1, 126) end

		setVehicleColor(vehicle, color1, color2, 0, 0)
	end
	local vehID = addElem(g_Vehicles, vehicle)
	if respawnDelay < 0 then
		respawnDelay = 120
	end
	g_Vehicles[vehID].respawndelay = respawnDelay*1000
	g_Vehicles[vehID].spawninfo = { x = x, y = y, z = z, angle = angle }
	if ManualVehEngineAndLights then
		if (getVehicleType(vehicle) ~= "Plane" and getVehicleType(vehicle) ~= "Helicopter") then
			setVehicleEngineState(vehicle, false)
			for i=0, 4 do
				setVehicleLightState(vehicle, i, 0)
			end
			g_Vehicles[vehID].engineState = false
		end
	end
	return vehID
end

function AddVehicleComponent(amx, vehicle, upgradeID)
	addVehicleUpgrade(vehicle, upgradeID)
end

function AllowAdminTeleport(amx, allow)
	deprecated('AllowAdminTeleport', '0.3d')
end

function AllowInteriorWeapons(amx, allow)
	deprecated('AllowInteriorWeapons', '0.3d')
end

function AllowPlayerTeleport(amx, player, allow)
	deprecated('AllowPlayerTeleport', '0.3d')
end

function ApplyAnimation(amx, player, animlib, animname, fDelta, loop, lockx, locky, freeze, time, forcesync)
	--time = Timer in ms. For a never-ending loop it should be 0.
	if time == 0 then
		loop = true
	end
	setPedAnimation(player, animlib, animname, time, loop, lockx or locky, false, freeze)
	setPedAnimationSpeed(player, animname, fDelta)
end

function AttachObjectToPlayer(amx, object, player, offsetX, offsetY, offsetZ, rX, rY, rZ)
	attachElements(object, player, offsetX, offsetY, offsetZ, rX, rY, rZ)
end

function AttachTrailerToVehicle(amx, trailer, vehicle)
	attachTrailerToVehicle(vehicle, trailer)
end

function ManualVehicleEngineAndLights() 
	ManualVehEngineAndLights = true
end

function Ban(amx, player)
	banPlayer(player)
end

function BanEx(amx, player, reason)
	banPlayer(player, nil, reason)
end

--Dummy for now
function GetPlayerDrunkLevel(player)
	notImplemented('GetPlayerDrunkLevel', 'SCM is not supported.')
	return 0
end

function GetPlayerAnimationIndex(player)
	notImplemented('GetPlayerAnimationIndex')
	return 0
end

function EditPlayerObject(amx, player, object)
	--givePlayerMoney(player, amount)
	notImplemented('EditPlayerObject')
end


function CallLocalFunction(amx, fnName, fmt, ...)
	local args = { ... }
	for i=1,math.min(#fmt, #args) do
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
	for i=1,math.min(#fmt, #args) do
		if fmt:sub(i, i) == 's' then
			args[i] = readMemString(amx, args[i])
		else
			args[i] = amx.memDAT[args[i]]
		end
	end
	return procCallOnAll(fnName, unpack(args))
end

function ChangeVehicleColor(amx, vehicle, color1, color2)
	setVehicleColor(vehicle, color1, color2, 0, 0)
end

function ChangeVehiclePaintjob(amx, vehicle, paintjob)
	setVehiclePaintjob(vehicle, paintjob)
end

function ClearAnimations(amx, player)
	setPedAnimation(player, false)
	g_Players[getElemID(player)].specialaction = SPECIAL_ACTION_NONE
end

function CreateExplosion(amx, x, y, z, type, radius)
	createExplosion(x, y, z, type)
end

function CreateMenu(amx, title, columns, x, y, leftColumnWidth, rightColumnWidth)
	local menu = { title = title, x = x, y = y, leftColumnWidth = leftColumnWidth, rightColumnWidth = rightColumnWidth, items = { [0] = {}, [1] = {} } }
	local id = table.insert(g_Menus, menu)
	menu.id = id
	clientCall(root, 'CreateMenu', id, menu)
	return id
end

function CreateObject(amx, model, x, y, z, rX, rY, rZ)
	outputConsole('CreateObject(' .. model .. ')')
	local obj = createObject(model, x, y, z, rX, rY, rZ)
	if obj == false then
		obj = createObject(1337, x, y, z, rX, rY, rZ) --Create a dummy object anyway since createobject can also be used to make camera attachments
		setElementAlpha(obj, 0)
		setElementCollisionsEnabled(obj, false)
		outputDebugString(string.format("[MTA AMX - WARNING]: The provided model id (%d) is invalid (the model was replaced with id 1337, is now invisible and non-collidable), some object ids are not supported, consider updating your scripts.", model))
	end
	return addElem(g_Objects, obj)
end

CreatePickup = AddStaticPickup

function CreatePlayerObject(amx, player, model, x, y, z, rX, rY, rZ)
	outputConsole('CreatePlayerObject(' .. model .. ')')
	if not g_PlayerObjects[player] then
		g_PlayerObjects[player] = {}
	end
	local objID = table.insert(g_PlayerObjects[player], { x = x, y = y, z = z, rx = rX, ry = rY, rz = rZ })
	clientCall(player, 'CreatePlayerObject', objID, model, x, y, z, rX, rY, rZ)
	return objID
end

CreateVehicle = AddStaticVehicleEx

function DestroyMenu(amx, menu)
	for i,playerdata in pairs(g_Players) do
		if playerdata.menu == menu then
			playerdata.menu = nil
		end
	end
	clientCall(root, 'DestroyMenu', menu.id)
	g_Menus[menu.id] = nil
end

function DestroyObject(amx, object)
	removeElem(g_Objects, object)
	destroyElement(object)
end

function DestroyPickup(amx, pickup)
	removeElem(g_Pickups, pickup)
	destroyElement(pickup)
end

function DestroyPlayerObject(amx, player, objID)
	g_PlayerObjects[player][objID] = nil
	clientCall(player, 'DestroyPlayerObject', objID)
end

function DestroyVehicle(amx, vehicle)
	clientCall(root, 'DestroyVehicle', getElemID(vehicle))
	removeElem(g_Vehicles, vehicle)
	local vehicleID = getElemID(vehicle)
	for i,playerdata in pairs(g_Players) do
		playerdata.streamedVehicles[vehicleID] = nil
	end
	destroyElement(vehicle)
end

function DetachTrailerFromVehicle(amx, puller)
	detachTrailerFromVehicle(puller)
end

function DisableInteriorEnterExits(amx)

end

function DisableMenu(amx, menuID)
	local menu = g_Menus[menuID]
	if not menu then
		return
	end
	menu.disabled = true
	for id,player in pairs(g_Players) do
		if GetPlayerMenu(amx, player.elem) == menuID then
			clientCall(player.elem, 'HideMenuForPlayer', menuID)
		end
	end
end

function DisableMenuRow(amx, menuID, rowID)
	local menu = g_Menus[menuID]
	if not menu then
		return
	end
	clientCall(root, 'DisableMenuRow', menuID, rowID)
end

function DisablePlayerCheckpoint(amx, player)
	g_Players[getElemID(player)].checkpoint = nil
	clientCall(player, 'DisablePlayerCheckpoint')
end

function DisablePlayerRaceCheckpoint(amx, player)
	g_Players[getElemID(player)].racecheckpoint = nil
	clientCall(player, 'DisablePlayerRaceCheckpoint')
end

function EnableStuntBonusForAll(amx, enable)

end

function EnableStuntBonusForPlayer(amx, player, enable)

end

function EnableTirePopping(amx, enable)

end

function EnableZoneNames(amx, enable)
	g_ShowZoneNames = enable
	for i,data in pairs(g_Players) do
		setPlayerHudComponentVisible(data.elem, 'area_name', enable)
	end
end

function ForceClassSelection(amx, playerID)
	if not g_Players[playerID] then
		return
	end
	g_Players[playerID].returntoclasssel = true
end

function GameModeExit(amx)
	if getResourceState(getResourceFromName('mapcycler')) == 'running' then
		triggerEvent('onRoundFinished', getResourceRootElement(getThisResource()))
	else
		exports.votemanager:voteMap(getThisResource())
	end
end

function GameTextForAll(amx, str, time, style)
	str = str:lower()
	for mta,samp in pairs(g_CommandMapping) do
		str = str:gsub('/' .. samp, '/' .. mta)
	end
	for i,player in pairs(g_Players) do
		GameTextForPlayer(amx, player.elem, str, time, style)
	end
end

function GameTextForPlayer(amx, player, str, time, style)
	str = str:lower()
	for mta,samp in pairs(g_CommandMapping) do
		str = str:gsub('/' .. samp, '/' .. mta)
	end
	clientCall(player, 'GameTextForPlayer', str, time, style)
end

function GangZoneCreate(amx, minX, minY, maxX, maxY)
	local zone = createRadarArea(minX + (maxX - minX)/2, minY + (maxY - minY)/2, maxX - minX, maxY - minY)
	local id = addElem(g_GangZones, zone)
	setElementVisibleTo(zone, root, false)
	return id
end

function GangZoneDestroy(amx, zone)
	removeElem(g_GangZones, zone)
	destroyElement(zone)
end

function GangZoneShowForPlayer(amx, player, zone, r, g, b, a)
	if r < 1 then r = 1 end
	if g < 1 then g = 1 end
	if b < 1 then b = 1 end
	if a < 1 then a = 1 end
	setRadarAreaColor(zone, r, g, b, a)
	setElementVisibleTo(zone, player, true)
end

function GangZoneShowForAll(amx, zone, r, g, b, a)
	if r < 1 then r = 1 end
	if g < 1 then g = 1 end
	if b < 1 then b = 1 end
	if a < 1 then a = 1 end
	setRadarAreaColor(zone, r, g, b, a)
	setElementVisibleTo(zone, root, true)
end

function GangZoneHideForPlayer(amx, player, zone)
	setElementVisibleTo(zone, player, false)
end

function GangZoneHideForAll(amx, zone)
	setElementVisibleTo(zone, root, false)
end

function GangZoneFlashForPlayer(amx, player, zone, r, g, b, a)
	clientCall(player, 'setRadarAreaFlashing', zone, true)
end

function GangZoneFlashForAll(amx, zone, r, g, b, a)
	setRadarAreaFlashing(zone, true)
end

function GangZoneStopFlashForPlayer(amx, player, zone)
	clientCall(player, 'setRadarAreaFlashing', zone, false)
end

function GangZoneStopFlashForAll(amx, zone)
	setRadarAreaFlashing(zone, false)
end

GetConsoleVarAsBool = GetServerVarAsBool
GetConsoleVarAsInt = GetServerVarAsInt
GetConsoleVarAsString = GetServerVarAsString

function GetMaxPlayers(amx)
	return getMaxPlayers()
end

function GetObjectPos(amx, object, refX, refY, refZ)
	local x, y, z = getElementPosition(object)
	writeMemFloat(amx, refX, x)
	writeMemFloat(amx, refY, y)
	writeMemFloat(amx, refZ, z)
end

function GetObjectRot(amx, object, refX, refY, refZ)
	local rX, rX, rZ = getObjectRotation(object)
	writeMemFloat(amx, refX, rX)
	writeMemFloat(amx, refY, rY)
	writeMemFloat(amx, refZ, rZ)
end

function GetPlayerAmmo(amx, player)
	return getPedTotalAmmo(player)
end

function GetPlayerArmour(amx, player, refArmor)
	writeMemFloat(amx, refArmor, getPedArmor(player))
end

function GetPlayerCameraPos(amx, player, refX, refY, refZ)
	local x, y, z = getCameraMatrix(player)
	writeMemFloat(amx, refX, x)
	writeMemFloat(amx, refY, y)
	writeMemFloat(amx, refZ, z)
end

function GetPlayerCameraFrontVector(amx, player, refX, refY, refZ)
	local x, y, z, lx, ly, lz = getCameraMatrix(player)
	writeMemFloat(amx, refX, lx)
	writeMemFloat(amx, refY, ly)
	writeMemFloat(amx, refZ, lz)
end

function GetPlayerColor(amx, player)
	local r, g, b = getPlayerNametagColor(player)
	return color2cell(r, g, b)
end

function GetPlayerClothes(amx, player, type)
	local texture, model = getPedClothes(player, type)
	if not texture then
		return
	end
	local type, index = getTypeIndexFromClothes(texture, model)
	return index
end

function GetPlayerFacingAngle(amx, player, refRot)
	writeMemFloat(amx, refRot, getPedRotation(player))
end

function GetPlayerHealth(amx, player, refHealth)
	writeMemFloat(amx, refHealth, getElementHealth(player))
end

function GetPlayerInterior(amx, player)
	return getElementInterior(player)
end

function GetPlayerIp(amx, player, refName, len)
	local ip = getPlayerIP(player)
	if #ip < len then
		writeMemString(amx, refName, ip)
	end
end

function GetPlayerKeys(amx, player, refKeys, refUpDown, refLeftRight)
	amx.memDAT[refKeys] = buildKeyState(player, g_KeyMapping)
	amx.memDAT[refUpDown] = buildKeyState(player, g_UpDownMapping)
	amx.memDAT[refLeftRight] = buildKeyState(player, g_LeftRightMapping)
end

function GetPlayerMenu(amx, player)
	local playerdata = g_Players[getElemID(player)]
	return playerdata.menu and playerdata.menu.id or 0
end

function GetPlayerMoney(amx, player)
	return getPlayerMoney(player)
end

function GetPlayerName(amx, player, nameBuf, bufSize)
	local name = getPlayerName(player)
	if #name <= bufSize then
		writeMemString(amx, nameBuf, name)
	end
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

function GetPlayerObjectPos(amx, player, objID, refX, refY, refZ)
	local x, y, z = getPlayerObjectPos(amx, player, objID)
	if not x then
		return
	end
	writeMemFloat(amx, refX, x)
	writeMemFloat(amx, refY, y)
	writeMemFloat(amx, refZ, z)
end

function GetPlayerObjectRot(amx, player, objID, refX, refY, refZ)
	local obj = g_PlayerObjects[player] and g_PlayerObjects[player][objID]
	if not obj then
		return
	end
	writeMemFloat(amx, refX, obj.rx)
	writeMemFloat(amx, refY, obj.ry)
	writeMemFloat(amx, refZ, obj.rz)
end

function GetPlayerPing(amx, player)
	return getPlayerPing(player)
end

GetPlayerPos = GetObjectPos

function GetPlayerScore(amx, player)
	return getElementData(player, 'Score')
end

function GetPlayerSkin(amx, player)
	return getElementModel(player)
end

function GetPlayerSpecialAction(amx, player)
	if doesPedHaveJetPack(player) then
		return SPECIAL_ACTION_USEJETPACK
	else
		return g_Players[getElemID(player)].specialaction or SPECIAL_ACTION_NONE
	end
end

function GetPlayerState(amx, player)
	return getPlayerState(player)
end

function GetPlayerTeam(amx, player)
	return table.find(g_Teams, getPlayerTeam(player))
end

function GetPlayerTime(amx, player, refHour, refMinute)
	amx.memDAT[refHour], amx.memDAT[refMinute] = getTime()
end

function GetPlayerVehicleID(amx, player)
	local vehicle = getPedOccupiedVehicle(player)
	if not vehicle then
		return 0
	end
	return getElemID(vehicle)
end

function GetPlayerVirtualWorld(amx, player)
	return getElementDimension(player)
end

function GetPlayerWantedLevel(amx, player)
	return getPlayerWantedLevel(player)
end

function GetPlayerWeapon(amx, player)
	return getPedWeapon(player)
end

function GetPVarInt(amx, player, varname)
	local value = g_Players[getElemID(player)].pvars[varname]
	if not value or value[1] ~= PLAYER_VARTYPE_INT then
		return 0
	end
	return value[2]
end

function SetPVarInt(amx, player, varname, value)
	g_Players[getElemID(player)].pvars[varname] = {PLAYER_VARTYPE_INT, value}
	return 1
end

function GetPVarFloat(amx, player, varname)
	local value = g_Players[getElemID(player)].pvars[varname]
	if not value or value[1] ~= PLAYER_VARTYPE_FLOAT then
		return 0
	end
	return float2cell(value[2])
end

function SetPVarFloat(amx, player, varname, value)
	g_Players[getElemID(player)].pvars[varname] = {PLAYER_VARTYPE_FLOAT, value}
	return 1
end

function GetPVarString(amx, player, varname, outbuf, length)
	local value = g_Players[getElemID(player)].pvars[varname]
	if not value or value[1] ~= PLAYER_VARTYPE_STRING then
		return 0
	end

	if #value[2] < length then
		writeMemString(amx, outbuf, value[2])
	else
		writeMemString(amx, outbuf, string.sub(value, 0, length - 1))
	end
	return 1
end

function SetPVarString(amx, player, varname, value)
	g_Players[getElemID(player)].pvars[varname] = {PLAYER_VARTYPE_STRING, value}
	return 1
end

function GetPVarType(amx, player, varname)
	local value = g_Players[getElemID(player)].pvars[varname]
	if value then
		return value[1]
	end
	return PLAYER_VARTYPE_NONE
end

function DeletePVar(amx, player, varname)
	g_Players[getElemID(player)].pvars[varname] = nil
	return 1
end

function RemoveBuildingForPlayer(amx, player, model, x, y, z, radius)
	clientCall(player, 'RemoveBuildingForPlayer', model, x, y, z, radius)
end

--playerid, Float:FromX, Float:FromY, Float:FromZ, Float:ToX, Float:ToY, Float:ToZ, time, cut = CAMERA_CUT
function InterpolateCameraPos(amx, player, FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut)
	clientCall(player, 'InterpolateCameraPos', FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut)
end
function InterpolateCameraLookAt(amx, player, FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut)
	clientCall(player, 'InterpolateCameraLookAt', FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut)
end

function PlayAudioStreamForPlayer(amx, player, url, posX, posY, posZ, distance, usepos)
	clientCall(player, 'PlayAudioStreamForPlayer', url, posX, posY, posZ, distance, usepos)
end

function StopAudioStreamForPlayer(amx, player)
	clientCall(player, 'StopAudioStreamForPlayer')
end

function EnableVehicleFriendlyFire(amx)
	notImplemented('EnableVehicleFriendlyFire')
	return 1;
end

function GetPlayerWeaponData(amx, player, slot, refWeapon, refAmmo)
	local playerdata = g_Players[getElemID(player)]
	local weapon = playerdata.weapons and playerdata.weapons[slot]
	if weapon then
		amx.memDAT[refWeapon], amx.memDAT[refAmmo] = weapon.id, weapon.ammo
	end
end

function GetServerVarAsBool(amx, varname)
	return get('amx.' .. varname) and true
end

function GetServerVarAsInt(amx, varname)
	local val = get('amx.' .. varname)
	return val and tonumber(val)
end

function GetServerVarAsString(amx, varname, buf, buflen)
	local val = get('amx.' .. varname)
	writeMemString(amx, buf, val and #val < buflen and val or '')
end

local serverStartTick = getTickCount()
function GetTickCount(amx)
	return getTickCount() - serverStartTick
end

function GetVehicleHealth(amx, vehicle, refHealth)
	writeMemFloat(amx, refHealth, getElementHealth(vehicle))
end

function GetVehicleModel(amx, vehicle)
	return getElementModel(vehicle)
end

GetVehiclePos = GetObjectPos

function GetVehicleTrailer(amx, vehicle)
	local trailer = getVehicleTowedByVehicle(vehicle)
	if not trailer then
		return 0
	end
	return getElemID(trailer)
end

function GetVehicleVelocity(amx, vehicle, refVX, refVY, refVZ)
	local vx, vy, vz = getElementVelocity(vehicle)
	writeMemFloat(amx, refVX, vx)
	writeMemFloat(amx, refVY, vy)
	writeMemFloat(amx, refVZ, vz)
end

function GetVehicleVirtualWorld(amx, vehicle)
	return getElementDimension(vehicle)
end

function GetVehicleZAngle(amx, vehicle, refZ)
	local rX, rY, rZ = getVehicleRotation(vehicle)
	writeMemFloat(amx, refZ, rZ)
end

function GetWeaponName(amx, weaponID, buf, len)
	local name = getWeaponNameFromID(weaponID)
	if name ~= false and #name < len then
		writeMemString(amx, buf, name)
		return 1
	else
		writeMemString(amx, buf, '') --I was going to return 'None' in here, but I believe SA-MP just returns a blank string
		return 0
	end
	return 1
end

function GivePlayerMoney(amx, player, amount)
	givePlayerMoney(player, amount)
end

function GivePlayerWeapon(amx, player, weaponID, ammo)
	giveWeapon(player, weaponID, ammo, true)
end

function HideMenuForPlayer(amx, menu, player)
	clientCall(player, 'HideMenuForPlayer', menu.id)
	g_Players[getElemID(player)].menu = nil
end

function IsPlayerAdmin(amx, player)
	return isPlayerInACLGroup(player, 'Admin') or isPlayerInACLGroup(player, 'Console')
end

function IsPlayerConnected(amx, playerID)
	return g_Players[playerID] ~= nil
end

function IsPlayerInAnyVehicle(amx, player)
	return getPedOccupiedVehicle(player) and true
end

function IsPlayerInCheckpoint(amx, player)
	local playerdata = g_Players[getElemID(player)]
	if not playerdata.checkpoint then
		return false
	end
	local x, y = getElementPosition(player)
	return math.sqrt((playerdata.checkpoint.x - x)^2 + (playerdata.checkpoint.y - y)^2) <= playerdata.checkpoint.radius
end

function IsPlayerInRaceCheckpoint(amx, player)
	local playerdata = g_Players[getElemID(player)]
	if not playerdata.racecheckpoint then
		return false
	end
	local x, y = getElementPosition(player)
	return math.sqrt((playerdata.racecheckpoint.x - x)^2 + (playerdata.racecheckpoint.y - y)^2) <= playerdata.racecheckpoint.radius
end

function IsPlayerInVehicle(amx, player, vehicle)
	return getPedOccupiedVehicle(player) == vehicle
end

function IsPluginLoaded(amx, pluginName)
	return amxIsPluginLoaded(pluginName)
end

function IsTrailerAttachedToVehicle(amx, vehicle)
	return getVehicleTowedByVehicle(vehicle) ~= false
end

function IsValidMenu(amx, menuID)
	return g_Menus[menuID] ~= nil
end

function IsValidObject(amx, objID)
	return g_Objects[objID] ~= nil
end

function IsValidPlayerObject(amx, player, objID)
	return g_PlayerObjects[player] and g_PlayerObjects[player][objID] and true
end

function IsValidVehicle(amx, vehicleID)
	return g_Vehicles[vehicleID] ~= nil
end

function Kick(amx, player)
	kickPlayer(player)
end

function KillTimer(amx, timerID)
	if not amx.timers[timerID] then
		return
	end
	killTimer(amx.timers[timerID])
	amx.timers[timerID] = nil
end

function LimitGlobalChatRadius(amx, radius)
	if radius > 0 then
		g_GlobalChatRadius = radius
	end
end

function LinkVehicleToInterior(amx, vehicle, interior)
	setElementInterior(vehicle, interior)
end

function MoveObject(amx, object, x, y, z, speed)
	local distance = getDistanceBetweenPoints3D(x, y, z, getElementPosition(object))
	local time = distance/speed*1000
	moveObject(object, time, x, y, z, 0, 0, 0)
	setTimer(procCallOnAll, time, 1, 'OnObjectMoved', getElemID(object))
end

function MovePlayerObject(amx, player, objID, x, y, z, speed)
	local obj = g_PlayerObjects[player] and g_PlayerObjects[player][objID]
	if not obj then
		return
	end
	local distance = getDistanceBetweenPoints3D(x, y, z, getPlayerObjectPos(amx, player, objID))
	local duration = distance/speed*1000
	if obj.moving and isTimer(obj.moving.timer) then
		killTimer(obj.moving.timer)
	end
	local timer = setTimer(procCallOnAll, duration, 1, 'OnPlayerObjectMoved', getElemID(player), objID)
	obj.moving = { x = x, y = y, z = z, starttick = getTickCount(), duration = duration, timer = timer }
	clientCall(player, 'MovePlayerObject', objID, x, y, z, speed)
end

function PlayerPlaySound(amx, player, soundID, x, y, z)

end

function PlayerSpectatePlayer(amx, player, playerToSpectate, mode)
	setCameraTarget(player, playerToSpectate)
end

function PlayerSpectateVehicle(amx, player, vehicleToSpectate, mode)
	if getVehicleController(vehicleToSpectate) then
		setCameraTarget(player, getVehicleController(vehicleToSpectate))
	else
		clientCall(player, 'setCameraTarget', vehicleToSpectate)
	end
end

function PutPlayerInVehicle(amx, player, vehicle, seat)
	warpPedIntoVehicle(player, vehicle, seat)
	if g_RCVehicles[getElementModel(vehicle)] then
		setElementAlpha(player, 0)
	end
	setPlayerState(player, seat == 0 and PLAYER_STATE_DRIVER or PLAYER_STATE_PASSENGER)
end

function RemovePlayerClothes(amx, player, type)
	removePedClothes(player, type)
end

function RemovePlayerFromVehicle(amx, player)
	local vehicle = getPedOccupiedVehicle(player)
	if vehicle then
		removePedFromVehicle(player)
		if g_RCVehicles[getElementModel(vehicle)] then
			clientCall(root, 'setElementAlpha', player, 255)
		end
	end
	setPlayerState(player, PLAYER_STATE_ONFOOT)
end

function RemoveVehicleComponent(amx, vehicle, upgradeID)
	removeVehicleUpgrade(vehicle, upgrade)
end

function ResetPlayerMoney(amx, player)
	setPlayerMoney(player, 0)
end

function ResetPlayerWeapons(amx, player)
	takeAllWeapons(player)
end

function SendClientMessage(amx, player, r, g, b, a, message)
	if message:len() > 75 and message:match('^%-+$') then
		message = ('-'):rep(75)
	elseif message:len() > 43 and message:match('^_+$') then
		message = ('_'):rep(43)
	elseif message:len() > 44 and message:match('^%*+$') then
		message = ('*'):rep(44)
	else
		for mta,samp in pairs(g_CommandMapping) do
			message = message:gsub('/' .. samp, '/' .. mta)
		end
	end

	--replace colors
	outputChatBox(colorizeString(message), player, r, g, b, true)
end

--replace colors
function colorizeString(string) 
	return string:gsub("(=?{[0-9A-Fa-f]*})",
	function(colorMatches)
		colorMatches = colorMatches:gsub("[{}]+", "") --replace the curly brackets with nothing
		colorMatches = '#' .. colorMatches --Append to the beginning
		return colorMatches 
	end)
end

function SendClientMessageToAll(amx, r, g, b, a, message)
	if (amx.proc == 'OnPlayerConnect' and message:match('joined')) or (amx.proc == 'OnPlayerDisconnect' and message:match('left')) then
		return
	end

	--replace colors
	message = colorizeString(message)

	for i,data in pairs(g_Players) do
		SendClientMessage(amx, data.elem, r, g, b, a, message)
	end
end

function SendDeathMessage(amx, killer, victim, reason)
	-- no implementation needed, killmessages resource shows kills already
end

function SendPlayerMessageToAll(amx, sender, message)
	outputChatBox(getPlayerName(sender) .. ' ' .. message, root, 255, 255, 255, true)
end

function SendPlayerMessageToPlayer(amx, playerTo, playerFrom, message)
	outputChatBox(getPlayerName(playerFrom) .. ' ' .. message, playerTo, 255, 255, 255, true)
end

function SendRconCommand(amx, command)
	print(doRCON(command))
end

function SetCameraBehindPlayer(amx, player)
	--In samp calling SetCameraBehindPlayer also unsets camera interpolation
	clientCall(player, 'removeCamHandlers')
	setCameraTarget(player, player)
end

function SetDeathDropAmount(amx, amount)

end

function SetDisabledWeapons(amx, ...)

end

function SetEchoDestination(amx)

end

function SetGameModeText(amx, gamemodeName)
	setGameType(gamemodeName)
end

function SetGravity(amx, gravity)
	setGravity(gravity)
	table.each(g_Players, 'elem', setPedGravity, gravity)
end

function SetMenuColumnHeader(amx, menu, column, text)
	menu.items[column][13] = text
	clientCall(root, 'SetMenuColumnHeader', menu.id, column, text)
end

function SetNameTagDrawDistance(amx, distance)

end

function SetObjectPos(amx, object, x, y, z)
	if(getElementType(object) == 'vehicle') then
		setElementFrozen(object, true)
	end

	setElementPosition(object, x, y, z)

	if getElementType(object) == 'vehicle' then
		setElementAngularVelocity(object, 0, 0, 0)
		setElementVelocity(object, 0, 0, 0)
		setTimer(setElementFrozen, 500, 1, object, false)
	end
end

function SetObjectRot(amx, object, rX, rY, rY)
	setObjectRotation(object, rX, rY, rZ)
end

function SetPlayerAmmo(amx, player, slot, ammo)
	setWeaponAmmo(player, slot, ammo)
end

function SetPlayerArmour(amx, player, armor)
	setPedArmor(player, armor)
end

function SetPlayerCameraLookAt(amx, player, lx, ly, lz)
	fadeCamera(player, true)
	local x, y, z = getCameraMatrix(player)
	setCameraMatrix(player, x, y, z, lx, ly, lz)
end

function SetPlayerCameraPos(amx, player, x, y, z)
	fadeCamera(player, true)
	setCameraMatrix(player, x, y, z)
end

function SetPlayerCheckpoint(amx, player, x, y, z, size)
	g_Players[getElemID(player)].checkpoint = { x = x, y = y, z = z, radius = size }
	clientCall(player, 'SetPlayerCheckpoint', x, y, z, size)
end

function SetPlayerColor(amx, player, r, g, b)
	setPlayerNametagColor(player, r, g, b)
	if g_ShowPlayerMarkers then
		setBlipColor(g_Players[getElemID(player)].blip, r, g, b, 255)
	end
end

function SetPlayerDisabledWeapons(amx, player, ...)

end

function SetPlayerFacingAngle(amx, player, angle)
	setPedRotation(player, angle)
end

function SetPlayerGravity(amx, player, gravity)
	setPedGravity(player, gravity)
end

function SetPlayerHealth(amx, player, health)
	setElementHealth(player, health)
end

function SetPlayerInterior(amx, player, interior)
	if g_Players[getElemID(player)].viewingintro then
		return
	end
	setElementInterior(player, interior)
end

function SetPlayerObjectPos(amx, player, objID, x, y, z)
	local obj = g_PlayerObjects[player] and g_PlayerObjects[player][objID]
	if not obj then
		return
	end
	if obj.moving then
		if isTimer(obj.moving.timer) then
			killTimer(obj.moving.timer)
		end
		obj.moving = nil
	end
	obj.x, obj.y, obj.z = x, y, z
	clientCall(player, 'SetPlayerObjectPos', objID, x, y, z)
end

function SetPlayerObjectRot(amx, player, objID, rX, rY, rZ)
	local obj = g_PlayerObjects[player] and g_PlayerObjects[player][objID]
	if not obj then
		return
	end
	obj.rx, obj.ry, obj.rz = rX, rY, rZ
	clientCall(player, 'SetPlayerObjectRot', objID, rX, rY, rZ)
end

function SetPlayerName(amx, player, name)
	return setPlayerName(player, name)
end

function SetPlayerPos(amx, player, x, y, z)
	setElementPosition(player, x, y, z)
end

function SetPlayerRaceCheckpoint(amx, player, type, x, y, z, nextX, nextY, nextZ, size)
	g_Players[getElemID(player)].racecheckpoint = { type = type, x = x, y = y, z = z, radius = size }
	clientCall(player, 'SetPlayerRaceCheckpoint', type, x, y, z, nextX, nextY, nextZ, size)
end

function SetPlayerScore(amx, player, score)
	setElementData(player, 'Score', score)
end

function SetPlayerSkin(amx, player, skin)
	setElementModel(player, skinReplace[skin] or skin)
end

function SetPlayerSpecialAction(amx, player, actionID)
	if actionID == SPECIAL_ACTION_NONE then
		removePedJetPack(player)
		setPedAnimation(player, false)
	elseif actionID == SPECIAL_ACTION_USEJETPACK then
		givePedJetPack(player)
	elseif g_SpecialActions[actionID] then
		setPedAnimation(player, unpack(g_SpecialActions[actionID]))
	end
	g_Players[getElemID(player)].specialaction = actionID
end

function SetPlayerTeam(amx, player, team)
	setPlayerTeam(player, team)
end

function SetPlayerTime(amx, player, hours, minutes)
	clientCall(player, 'setTime', hours, minutes)
end

function SetPlayerVirtualWorld(amx, player, dimension)
	setElementDimension(player, dimension)
end

function SetPlayerWantedLevel(amx, player, level)
	setPlayerWantedLevel(player, level)
end

function SetPlayerWeather(amx, player, weatherID)
	clientCall(player, 'setWeather', weatherID % 256)
end

function SetSpawnInfo(amx, player, team, skin, x, y, z, angle, weap1, weap1_ammo, weap2, weap2_ammo, weap3, weap3_ammo)
	g_Players[getElemID(player)].spawninfo = {
		x, y, z, angle, skinReplace[skin] or skin, 0, 0, team,
		weapons={ {weap1, weap1_ammo}, {weap2, weap2_ammo}, {weap3, weap3_ammo} }
	}
end

function SetTeamCount(amx, count)

end

function SetTimerEx(amx, fnName, interval, repeating, fmt, ...)
	local vals = { ... }
	for i,val in ipairs(vals) do
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
			function(id, ...)
				amx.timers[id] = nil
				procCallInternal(amx, fnName, ...)
			end,
			interval, 1, id, unpack(vals)
		)
		amx.timers[id] = timer
		return id
	end
end

SetTimer = SetTimerEx

function SetVehicleHealth(amx, vehicle, health)
	setElementHealth(vehicle, health)
end

function SetVehicleModel(amx, vehicle, model)
	setElementModel(vehicle, model)
end

function SetVehicleNumberPlate(amx, vehicle, plate)
	setVehiclePlateText(vehicle, plate)
end

function SetVehicleParamsForPlayer(amx, vehicle, player, isObjective, doorsLocked)
	clientCall(player, 'SetVehicleParamsForPlayer', vehicle, isObjective, doorsLocked)
end

SetVehiclePos = SetObjectPos

function SetVehicleToRespawn(amx, vehicle)
	for seat=0,getVehicleMaxPassengers(vehicle) do
		local player = getVehicleOccupant(vehicle, seat)
		if player then
			removePedFromVehicle(player)
		end
	end
	local spawninfo = g_Vehicles[getElemID(vehicle)].spawninfo
	spawnVehicle(vehicle, spawninfo.x, spawninfo.y, spawninfo.z, 0, 0, spawninfo.angle)
end

function SetVehicleVelocity(amx, vehicle, vx, vy, vz)
	setElementVelocity(vehicle, vx, vy, vz)
	--setElementAngularVelocity(vehicle, vx, vy, vz) --This isn't needed, it makes the car spin and I believe samp doesn't do this
end

function SetVehicleVirtualWorld(amx, vehicle, dimension)
	setElementDimension(vehicle, dimension)
end

function SetVehicleZAngle(amx, vehicle, rZ)
	local rX, rY = getVehicleRotation(vehicle)
	setVehicleRotation(vehicle, 0, 0, rZ)
end

function RepairVehicle(amx, vehicle)
	fixVehicle(vehicle)
end

function SetWeather(amx, weatherID)
	setWeather(weatherID % 256)
end

function SetWorldTime(amx, hours)
	setTime(hours, 0)
end

function ShowMenuForPlayer(amx, menu, player)
	clientCall(player, 'ShowMenuForPlayer', menu.id)
	g_Players[getElemID(player)].menu = menu
end

function ShowNameTags(amx, show)
	table.each(g_Players, 'elem', setPlayerNametagShowing, show)
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

function ShowPlayerMarkers(amx, show)
	g_ShowPlayerMarkers = show
	for i,data in pairs(g_Players) do
		ShowPlayerMarker(amx, data.elem, show)
	end
end

function ShowPlayerNameTagForPlayer(amx, player, playerToShow, show)
	clientCall(player, 'setPlayerNametagShowing', playerToShow, show)
end

function SpawnPlayer(amx, player)
	spawnPlayerBySelectedClass(player)
end

function StopObject(amx, object)
	stopObject(object)
end

function StopPlayerObject(amx, player, objID)
	local obj = g_PlayerObjects[player] and g_PlayerObjects[player][objID]
	if not obj then
		return
	end
	if obj.moving then
		obj.x, obj.y, obj.z = getPlayerObjectPos(amx, player, objID)
		if isTimer(obj.moving.timer) then
			killTimer(obj.moving.timer)
		end
		obj.moving = nil
	end
	clientCall(player, 'StopPlayerObject', objID)
end

function TextDrawAlignment(amx, textdraw, align)
	textdraw.align = (align == 0 and 1 or align)
end

function TextDrawBackgroundColor(amx, textdraw, r, g, b, a)
	textdraw.outlinecolor = { r, g, b, a }
end

function TextDrawBoxColor(amx, textdraw, r, g, b, a)
	textdraw.boxcolor = { r, g, b, a }
end

function TextDrawColor(amx, textdraw, r, g, b, a)
	textdraw.color = { r, g, b }
end

function TextDrawCreate(amx, x, y, text)
	outputDebugString('TextDrawCreate called with args ' .. x .. ' ' .. y .. ' ' .. text)
	local textdraw = { x = x, y = y, shadow = {align=1, text=text, font=1, lwidth=0.5, lheight = 0.5} }
	local id = table.insert(g_TextDraws, textdraw)
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
					clientCall(root, 'TextDrawPropertyChanged', id, k, v)
					t.shadow[k] = v
				end
			end
		}
	)
	clientCall(root, 'TextDrawCreate', id, table.deshadowize(textdraw, true))
	return id
end

--Mainly just wrappers to the other non-player functions
function PlayerTextDrawDestroy(amx, player, textdrawID)
  	if not IsPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	clientCall(player, 'TextDrawDestroy', g_PlayerTextDraws[player][textdrawID].clientTDId)
	g_PlayerTextDraws[player][textdrawID] = nil
end
function PlayerTextDrawShow(amx, player, textdrawID)
	if not IsPlayerTextDrawValid(player, textdrawID) then
		outputDebugString('PlayerTextDrawShow: not showing anything, not valid')
		return false
	end
	--if g_PlayerTextDraws[player][textdrawID].visible == 1 then
	--	return false
	--end
	g_PlayerTextDraws[player][textdrawID].visible = true
	clientCall(player, 'TextDrawShowForPlayer', g_PlayerTextDraws[player][textdrawID].clientTDId)
	--outputDebugString('PlayerTextDrawShow: proccessed for ' .. textdrawID .. ' with ' .. g_PlayerTextDraws[player][textdrawID].text)
	return true
end
function PlayerTextDrawHide(amx, player, textdrawID)
  	if not IsPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	--if g_PlayerTextDraws[player][textdrawID].visible == 0 then
	--	return false
	--end
	g_PlayerTextDraws[player][textdrawID].visible = false
	clientCall(player, 'TextDrawHideForPlayer', g_PlayerTextDraws[player][textdrawID].clientTDId)
	--outputDebugString('PlayerTextDrawHide: proccessed for ' .. textdrawID .. ' with ' .. g_PlayerTextDraws[player][textdrawID].text)
end
function PlayerTextDrawBoxColor(amx, player, textdrawID, r, g, b, a)
	if not IsPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].boxcolor = { r, g, b, a }
end
function PlayerTextDrawUseBox(amx, player, textdrawID, usebox)
	if not IsPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].usebox = usebox
	return true
end
function PlayerTextDrawTextSize(amx, player, textdrawID, x, y)
	if not IsPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].boxsize = { x, y }
	return true
end
function PlayerTextDrawLetterSize(amx, player, textdrawID, x, y)
	if not IsPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].lwidth = width
	g_PlayerTextDraws[player][textdrawID].lheight = height
	return true
end
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
function CreatePlayerTextDraw(amx, player, x, y, text)
	outputDebugString('CreatePlayerTextDraw called with args ' .. x .. ' ' .. y .. ' ' .. text)

	if ( not g_PlayerTextDraws[player] ) then --Create dimension if it doesn't exist
		outputDebugString('Created dimension for g_PlayerTextDraws[player]')
		g_PlayerTextDraws[player] = {}
	end

	local serverTDId = #g_PlayerTextDraws[player]+1
	local clientTDId = #g_TextDraws + serverTDId

	local textdraw = { x = x, y = y, lwidth=0.5, lheight = 0.5, shadow = { visible=0, align=1, text=text, font=1, lwidth=0.5, lheight = 0.5} }
	textdraw.clientTDId = clientTDId
	textdraw.serverTDId = serverTDId
	textdraw.visible = 0

	g_PlayerTextDraws[player][serverTDId] = textdraw

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
					--table.dump(v, 1, nil) --Dump the data
					--outputDebugString(string.format('A property changed for %s string: %s visibility is %d', textdraw.serverTDId, textdraw.text, textdraw.visible))
					clientCall(player, 'TextDrawPropertyChanged', textdraw.clientTDId, k, v)
					t.shadow[k] = v
				end
			end
		}
	)

	outputDebugString('assigned id s->' .. serverTDId .. ' c->' .. clientTDId .. ' to g_PlayerTextDraws[player]')
	clientCall(player, 'TextDrawCreate', clientTDId, table.deshadowize(textdraw, true))
	return serverTDId
end
function PlayerTextDrawAlignment(amx, player, textdrawID, align)
	if not IsPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].align = (align == 0 and 1 or align)
	return true
end
function PlayerTextDrawBackgroundColor(amx, player, textdrawID, r, g, b, a)
	if not IsPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].outlinecolor = { r, g, b, a }
	return true
end
function PlayerTextDrawFont(amx, player, textdrawID, font)
	if not IsPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].font = font
	return true
end
function PlayerTextDrawColor(amx, player, textdrawID, r, g, b, a)
  	if not IsPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].color = { r, g, b }
	return true
end
function PlayerTextDrawSetOutline(amx, player, textdrawID, size)
	if not IsPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].outlinesize = size
	return true
end
function PlayerTextDrawSetProportional(amx, player, textdrawID, proportional)
  --TextDrawSetProportional(amx, textdraw, proportional)
end
function PlayerTextDrawSetShadow(amx, player, textdrawID, size)
   	if not IsPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].shade = size
	return true
end
function PlayerTextDrawSetString(amx, player, textdrawID, str)
   	if not IsPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].text = str
	return true
end
--End of player textdraws
function TextDrawDestroy(amx, textdrawID)
	if not g_TextDraws[textdrawID] then
		return
	end
	clientCall(root, 'TextDrawDestroy', textdrawID)
	g_TextDraws[textdrawID] = nil
end

function TextDrawFont(amx, textdraw, font)
	textdraw.font = font
end

function TextDrawHideForAll(amx, textdrawID)
	for id,player in pairs(g_Players) do
		TextDrawHideForPlayer(amx, player.elem, textdrawID)
	end
end

function TextDrawHideForPlayer(amx, player, textdrawID)
	local textdraw = g_TextDraws[textdrawID]
	if not textdraw then
		return
	end
	clientCall(player, 'TextDrawHideForPlayer', textdrawID)
end

function TextDrawLetterSize(amx, textdraw, width, height)
	textdraw.lwidth = width
	textdraw.lheight = height
end

function TextDrawSetOutline(amx, textdraw, size)
	textdraw.outlinesize = size
end

function TextDrawSetProportional(amx, textdraw, proportional)

end

function TextDrawSetShadow(amx, textdraw, size)
	textdraw.shade = size
end

function TextDrawSetString(amx, textdraw, str)
	textdraw.text = str
end

function TextDrawShowForAll(amx, textdrawID)
	for id,player in pairs(g_Players) do
		TextDrawShowForPlayer(amx, player.elem, textdrawID)
	end
end

function TextDrawShowForPlayer(amx, player, textdrawID)
	local textdraw = g_TextDraws[textdrawID]
	if not textdraw then
		return
	end
	clientCall(player, 'TextDrawShowForPlayer', textdrawID)
end

function TextDrawTextSize(amx, textdraw, x, y)
	textdraw.boxsize = { x, y } --Game does 448 not 480
end

function TextDrawUseBox(amx, textdraw, usebox)
	textdraw.usebox = usebox
end

function TogglePlayerControllable(amx, player, enable)
	toggleAllControls(player, enable, true, false)
end

function TogglePlayerSpectating(amx, player, enable)
	if enable then
		fadeCamera(player, true)
		setCameraMatrix(player, 75.461357116699, 64.600051879883, 51.685581207275, 149.75857543945, 131.53228759766, 40.597320556641)
		setPlayerHudComponentVisible(player, 'radar', false)
		setPlayerState(player, PLAYER_STATE_SPECTATING)
	else
		local playerdata = g_Players[getElemID(player)]
		local spawninfo = playerdata.spawninfo or (g_PlayerClasses and g_PlayerClasses[playerdata.selectedclass])
		if not spawninfo then
			putPlayerInClassSelection(player)
			return
		end
		if isPedDead(player) then
			spawnPlayerBySelectedClass(player)
		end
		--In samp calling TogglePlayerSpectating also unsets camera interpolation
		clientCall(player, 'removeCamHandlers')
		setCameraTarget(player, player)
		clientCall(player, 'setCameraTarget', player) --Clear the one on the client as well, otherwise we can't go back to normal camera after spectating vehicles
		setPlayerHudComponentVisible(player, 'radar', true)
		setPlayerState(player, PLAYER_STATE_ONFOOT)
	end
end

function UsePlayerPedAnims(amx)

end

-----------------------------------------------------
-- Actor funcs
function CreateActor(amx, model, x, y, z, rotation)
	local actor = createPed(model, x, y, z, rotation, false)
	setElementData(actor, 'amx.actorped', true)
	return addElem(g_Actors, actor)
end

function IsValidActor(amx, actorId)
	return g_Objects[actorId] ~= nil
end

function IsActorStreamedIn(amx, actorId, player)
	return g_Players[getElemID(player)].streamedActors[actorId] ~= nil
end

function DestroyActor(amx, actor)
	for i,playerdata in pairs(g_Players) do
		playerdata.streamedActors[getElemID(actor)] = nil
	end

	removeElem(g_Actors, actor)
	destroyElement(actor)
end

function ApplyActorAnimation(amx, actor, animlib, animname, fDelta, loop, lockx, locky, freeze, time)
	setPedAnimation(actor, animlib, animname, time, loop, lockx or locky, false, freeze)
	setPedAnimationSpeed(actor, animname, fDelta)
end

function ClearActorAnimations(amx, actor)
	setPedAnimation(actor, false)
end

function GetActorFacingAngle(amx, actor, refAng)
	local rX, rY, rZ = getElementRotation(vehicle)
	writeMemFloat(amx, refAng, rZ)
end

GetActorHealth = GetPlayerHealth

function GetActorPoolSize(amx)
	local highestId = 0
	for id,v in pairs(g_Actors) do
		if id > highestId then
			highestId = id
		end
	end
	return highestId
end

GetActorVirtualWorld = GetPlayerVirtualWorld

-- new stuff

function GetPlayerPoolSize(amx)
	local highestId = 0
	for id,v in pairs(g_Players) do
		if id > highestId then
			highestId = id
		end
	end
	return highestId
end

-- stub
function GetPlayerCameraTargetActor(amx)
	return INVALID_ACTOR_ID
end

function GetPlayerTargetActor(amx, player)
	local elem = getPedTarget(player)

	if getElementType(elem) == 'ped' and getElementData(elem, 'amx.actorped') then
		return getElemID(elem)
	end
	return INVALID_ACTOR_ID
end

-- stub
function IsActorInvulnerable(amx)
	return 1
end

function SetActorFacingAngle(amx, actor, ang)
	local rotX, rotY, rotZ = getElementRotation(actor) -- get the local players's rotation
    setElementRotation(actor, rotX, rotY, ang, "default", true) -- turn the player 10 degrees clockwise
end

SetActorHealth = SetPlayerHealth

-- stub
function SetActorInvulnerable(amx)
	return 1
end

SetActorPos = SetPlayerPos

SetActorVirtualWorld = SetPlayerVirtualWorld

-----------------------------------------------------

function acos(amx, f)
	return float2cell(math.acos(f))
end

function asin(amx, f)
	return float2cell(math.asin(f))
end

function atan(amx, f)
	return float2cell(math.atan(f))
end

function atan2(amx, x, y)
	return float2cell(math.atan2(y, x))
end

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

function GetPlayerFightingStyle(amx, player)
	return getPedFightingStyle(player)
end

function SetPlayerFightingStyle(amx, player, style)
	return setPedFightingStyle(player, style)
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

function GetPlayerVehicleSeat(amx, player)
	return getPedOccupiedVehicleSeat(player)
end

function GetPlayerVelocity(amx, player, refVX, refVY, refVZ)
	local vx, vy, vz = getElementVelocity(player)
	writeMemFloat(amx, refVX, vx)
	writeMemFloat(amx, refVY, vy)
	writeMemFloat(amx, refVZ, vz)
end

function SetPlayerVelocity(amx, player, vx, vy, vz)
	setElementVelocity(player, vx, vy, vz)
end

function SetPlayerControlState(amx, player, control, state)
	return setControlState(player, control, state)
end

function GetPlayerSkillLevel(amx, player, skill)
	return getPedStat(player, skill + 69)
end

function SetPlayerSkillLevel(amx, player, skill, level)
	return setPedStat(player, skill + 69, level)
end

function SetPlayerArmedWeapon(amx, player, weapon)
	return setPedWeaponSlot(player, weapon)
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

function GetVehicleDamageStatus(amx, vehicle, refPanels, refDoors, refLights, refTires)
	local panelsState = getVehiclePanelState(vehicle, 0)
	panelsState = binor(panelsState, binshl(getVehiclePanelState(vehicle, 1), 4) )
	panelsState = binor(panelsState, binshl(getVehiclePanelState(vehicle, 2), 8) )
	panelsState = binor(panelsState, binshl(getVehiclePanelState(vehicle, 3), 12) )
	panelsState = binor(panelsState, binshl(getVehiclePanelState(vehicle, 4), 16) )
	panelsState = binor(panelsState, binshl(getVehiclePanelState(vehicle, 5), 20) )
	panelsState = binor(panelsState, binshl(getVehiclePanelState(vehicle, 6), 24) )

	local doorsState = getVehicleDoorState(vehicle, 0)
	doorsState = binor(doorsState, binshl(getVehicleDoorState(vehicle, 1), 8) )
	doorsState = binor(doorsState, binshl(getVehicleDoorState(vehicle, 2), 16) )
	doorsState = binor(doorsState, binshl(getVehicleDoorState(vehicle, 3), 24) )

	local lightsState = getVehicleLightState(vehicle, 0)
	lightsState = binor(lightsState, binshl(getVehicleLightState(vehicle, 1), 2) )
	lightsState = binor(lightsState, binshl(getVehicleLightState(vehicle, 2), 4) )
	lightsState = binor(lightsState, binshl(getVehicleLightState(vehicle, 3), 6) )

	local frontLeft, rearLeft, frontRight, rearRight = getVehicleWheelStates ( vehicle )

	local tiresState = binor(rearRight, binor(binshl(frontRight, 1), binor(binshl(rearLeft, 2), binshl(frontLeft, 3))) )

	amx.memDAT[refPanels] = panelsState
	amx.memDAT[refDoors] = doorsState
	amx.memDAT[refLights] = lightsState
	amx.memDAT[refTires] = tiresState
end

function UpdateVehicleDamageStatus(amx, vehicle, panels, doors, lights, tires)
	setVehiclePanelState(vehicle, 0, binand(panels, 15))
	setVehiclePanelState(vehicle, 1, binand(binshr(panels, 4), 15))
	setVehiclePanelState(vehicle, 2, binand(binshr(panels, 8), 15))
	setVehiclePanelState(vehicle, 3, binand(binshr(panels, 12), 15))
	setVehiclePanelState(vehicle, 4, binand(binshr(panels, 16), 15))
	setVehiclePanelState(vehicle, 5, binand(binshr(panels, 20), 15))
	setVehiclePanelState(vehicle, 6, binand(binshr(panels, 24), 15))

	setVehicleDoorState(vehicle, 0, binand(panels, 7))
	setVehicleDoorState(vehicle, 1, binand(binshr(panels, 8), 7))
	setVehicleDoorState(vehicle, 2, binand(binshr(panels, 16), 7))
	setVehicleDoorState(vehicle, 3, binand(binshr(panels, 24), 7))

	setVehicleLightState(vehicle, 0, binand(lights, 1))
	setVehicleLightState(vehicle, 2, binand(binshr(lights, 2), 1))
	setVehicleLightState(vehicle, 3, binand(binshr(lights, 4), 1))
	setVehicleLightState(vehicle, 4, binand(binshr(lights, 6), 1))

	setVehicleWheelStates(vehicle, binand(binshr(tires, 3), 1), binand(binshr(tires, 2), 1), binand(binshr(tires, 1), 1), binand(tires, 1) )
end

function GetVehicleMaxPassengers(amx, vehicle)
	return getVehicleMaxPassengers(vehicle)
end

function GetVehicleParamsCarDoors(amx, vehicle, refDriver, refPassenger, refBackleft, refBackright)
	amx.memDAT[refDriver] = getVehicleDoorOpenRatio(vehicle, 2) > 0
	amx.memDAT[refPassenger] = getVehicleDoorOpenRatio(vehicle, 3) > 0
	amx.memDAT[refBackleft] = getVehicleDoorOpenRatio(vehicle, 4) > 0
	amx.memDAT[refBackright] = getVehicleDoorOpenRatio(vehicle, 5) > 0
	return 1
end

function SetVehicleParamsCarDoors(amx, vehicle, driver, passenger, backleft, backright)
	setVehicleDoorOpenRatio(vehicle, 2, driver and 1 or 0) -- bonnet
	setVehicleDoorOpenRatio(vehicle, 3, passenger and 1 or 0) -- bonnet
	setVehicleDoorOpenRatio(vehicle, 4, backleft and 1 or 0) -- bonnet
	setVehicleDoorOpenRatio(vehicle, 5, backright and 1 or 0) -- bonnet
end

function GetVehicleParamsEx(amx, vehicle, refEngine, refLights, refAlarm, refDoors, refBonnet, refBoot, refObjective)
	local vehicleID = getElemID(vehicle)

	amx.memDAT[refEngine] = getVehicleEngineState(vehicle) and 1 or 0 --Lua expects this to be an int, so cast it
	amx.memDAT[refLights] = getVehicleOverrideLights(vehicle) == 2 and 1 or 0
	amx.memDAT[refAlarm] = g_Vehicles[vehicleID].alarm and 1 or 0
	amx.memDAT[refDoors] = isVehicleLocked(vehicle) and 1 or 0
	amx.memDAT[refBonnet] = getVehicleDoorOpenRatio(vehicle, 0) > 0 and 1 or 0
	amx.memDAT[refBoot] = getVehicleDoorOpenRatio(vehicle, 1) > 0 and 1 or 0
	amx.memDAT[refObjective] = g_Vehicles[vehicleID].objective or 0

	return 1
end

function SetVehicleParamsEx(amx, vehicle, engine, lights, alarm, doors, bonnet, boot, objective)
	setVehicleEngineState(vehicle, engine)
	setVehicleOverrideLights(vehicle, lights and 2 or 1)
	-- TODO: implement alarm
	setVehicleLocked(vehicle, doors)
	setVehicleDoorOpenRatio(vehicle, 0, bonnet and 1 or 0) -- bonnet
	setVehicleDoorOpenRatio(vehicle, 1, boot and 1 or 0) -- boot

	for i, playerdata in pairs(g_Players) do
		clientCall(playerdata.elem, 'SetVehicleParamsForPlayer', vehicle, objective, doors)
	end

	local vehicleID = getElemID(vehicle)
	g_Vehicles[vehicleID].alarm = alarm;
	g_Vehicles[vehicleID].objective = objective;
	g_Vehicles[vehicleID].engineState = engine;
	return 1
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

function GetVehicleComponentInSlot(amx, vehicle, slot)
	return getVehicleUpgradeOnSlot(vehicle, slot)
end

function GetVehicleSirensOn(amx, vehicle)
	return getVehicleSirensOn(vehicle)
end

function GetVehiclePoolSize(amx)
	local highestId = 0
	for id,v in pairs(g_Vehicles) do
		if id > highestId then
			highestId = id
		end
	end
	return highestId
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
function ConnectNPC(amx, name, script)
	notImplemented('ConnectNPC')
	return true
end

function IsPlayerNPC(amx, player)
	notImplemented('IsPlayerNPC')
	return false
end

function IsVehicleStreamedIn(amx, vehicle, player)
	return g_Players[getElemID(player)].streamedVehicles[getElemID(vehicle)] == true
end

function IsPlayerStreamedIn(amx, otherPlayer, player)
	return g_Players[getElemID(player)].streamedPlayers[getElemID(otherPlayer)] == true
end

function SetPlayerChatBubble(amx, player, text, color, dist, exptime)
	notImplemented('SetPlayerChatBubble')
	return false
end


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
		print('Current protocol is not supporting')
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

function Create3DTextLabel(amx, text, r, g, b, a, x, y, z, dist, vw, los)
	text = text:lower()
	for mta,samp in pairs(g_CommandMapping) do
		text = text:gsub('/' .. samp, '/' .. mta)
	end
	local textlabel = { text = text, color = {r = r, g = g, b = b, a = a}, X = x, Y = y, Z = z, dist = dist, vw = vw, los = los }
	local id = table.insert(g_TextLabels, textlabel)

	textlabel.id = id

	clientCall(root, 'Create3DTextLabel', id, textlabel)
	return id
end

function CreatePlayer3DTextLabel(amx, player, text, r, g, b, a, x, y, z, dist, vw, los)
	text = text:lower()
	for mta,samp in pairs(g_CommandMapping) do
		text = text:gsub('/' .. samp, '/' .. mta)
	end
	local textlabel = { text = text, color = {r = r, g = g, b = b, a = a}, X = x, Y = y, Z = z, dist = dist, vw = vw, los = los }
	local id = table.insert(g_TextLabels, textlabel)

	textlabel.id = id

	clientCall(root, 'Create3DTextLabel', id, textlabel)
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
	clientCall(root, 'Delete3DTextLabel', id)
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
	textlabel.text = text
	textlabel.color = {r = r, g = g, b = b, a = a}
	return true
end

function UpdatePlayer3DTextLabelText(amx, textlabel, r, g, b, a, text)
	textlabel.text = text
	textlabel.color = {r = r, g = g, b = b, a = a}
	return true
end

function PlayCrimeReportForPlayer(amx, player, suspectid, crimeid)
	return false
end

function IsPlayerInRangeOfPoint(amx, player, range, pX, pY, pZ)
	return getDistanceBetweenPoints3D(pX, pY, pZ, getElementPosition(player)) <= range
end

function GetPlayerDistanceFromPoint(amx, player, pX, pY, pZ)
	return float2cell(getDistanceBetweenPoints3D(pX, pY, pZ, getElementPosition(player)))
end

GetVehicleDistanceFromPoint = GetPlayerDistanceFromPoint

function GetPlayerSurfingVehicleID(amx, player)
	return -1
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

function VectorSize(amx, x, y, z)
	return float2cell(math.sqrt( (x^2) + (y^2) + (z^2)))
end

function SetPlayerAttachedObject(amx, player, index, modelid, bone, fOffsetX, fOffsetY, fOffsetZ, fRotX, fRotY, fRotZ, fScaleX, fScaleY, fScaleZ, materialcolor1, materialcolor2)
	local x, y, z = getElementPosition (player)
	local mtaBone = g_BoneMapping[bone]
	local obj = createObject(modelid, x, y, z)

	if obj ~= false then
		local playerID = getElemID(player)
		g_Players[playerID].attachedObjects[index] = obj
		setElementCollisionsEnabled (obj, false)
		setObjectScale (obj, fScaleX, fScaleY, fScaleZ)
		attachElementToBone(obj, player, mtaBone, fOffsetX, fOffsetY, fOffsetZ, fRotX, fRotY, fRotZ)
		--Todo: Implement material colors
	else
		outputDebugString('SetPlayerAttachedObject: Cannot attach object since the model is invalid. Model id was ' .. modelid)
		return 0
	end
	return 1
end

function RemovePlayerAttachedObject(amx, player, index)
	local playerID = getElemID(player)
	local obj = g_Players[playerID].attachedObjects[index] --Get the object stored at this slot
	if obj ~= false then
		detachElementFromBone( obj )
		destroyElement( obj )
		g_Players[playerID].attachedObjects[index] = nil
		return 1
	end
	return 0
end

function AttachCameraToObject(amx, player, object)
	clientCall(player, 'AttachCameraToObject', object)
end

-- Security

function SHA256_PassHash(amx, pass, salt, ret_hash, ret_hash_len)
	local secret = hash ( 'sha256', pass .. '' .. salt ) -- who is it guy which writes salt after pass?
	writeMemString(amx, ret_hash, string.upper(secret) )
end

-- Siren

function GetVehicleParamsSirenState(amx, vehicle)
	local sirenstat = getVehicleSirensOn ( vehicle )

	-- in samp this native returns 3 states
	-- 1 - siren on
	-- 0 - siren off
	-- -1 - siren not exist, but we never get it.
	if (sirenstat == true) then
		return 1
	else
		return 0
	end
end


-- Weapon
function GetPlayerWeaponState(amx, player)
	-- -1 WEAPONSTATE_UNKNOWN 
	-- 0 WEAPONSTATE_NO_BULLETS
	-- 1 WEAPONSTATE_LAST_BULLET
	-- 2 WEAPONSTATE_MORE_BULLETS
	-- 3 WEAPONSTATE_RELOADING

	local vehicle = getPedOccupiedVehicle(player)
	if vehicle ~= nil then return -1 end

	-- TODO: Function don't return 3 because a isPedReloadingWeapon function only client-side
	local ammo = getPedAmmoInClip(player)
	if ammo == 0 then 
		return 0
	elseif ammo == 1 then 
		return 1
	elseif ammo >= 2 then 
		return 2
	else
		return -1
	end
end
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
	NetStats_GetConnectedTime = {},
	GetPlayerSurfingObjectID = {},
	SendClientCheck = {},
	NetStats_PacketLossPercent = {},
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


	GetPlayerWeaponState = {'p'}
}
