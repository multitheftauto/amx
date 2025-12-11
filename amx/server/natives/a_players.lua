function SetPlayerPos(amx, player, x, y, z)
	local vehicle = getPedOccupiedVehicle(player)
	if vehicle then
		removePedFromVehicle(player)
		setTimer(setElementPosition, 500, 1, player, x, y, z)
	else
		return setElementPosition(player, x, y, z)
	end
	return true
end

function SetPlayerPosFindZ(amx, player, x, y, z)
	local vehicle = getPedOccupiedVehicle(player)
	if vehicle then
		removePedFromVehicle(player)
		setTimer(clientCall, 500, 1, player, 'SetPlayerPosFindZ', x, y, z)
	else
		clientCall(player, 'SetPlayerPosFindZ', x, y, z)
	end
	return true
end

function GetPlayerPos(amx, player, refX, refY, refZ)
	if not player then
		return false
	end

	local x, y, z

	-- initializing or spectating
	if getPlayerState(player) == 0 or getPlayerState(player) == 9 then
		x, y, z = getCameraMatrix(player)
	else
		x, y, z = getElementPosition(player)
	end

	writeMemFloat(amx, refX, x)
	writeMemFloat(amx, refY, y)
	writeMemFloat(amx, refZ, z)
	return true
end

function SetPlayerFacingAngle(amx, player, angle)
	local rotX, rotY, rotZ = getElementRotation(player)
	return setElementRotation(player, rotX, rotY, angle)
end

function GetPlayerFacingAngle(amx, player, refAng)
	if not player then
		return false
	end
	local rX, rY, rZ = getElementRotation(player)
	writeMemFloat(amx, refAng, rZ)
	return true
end

function IsPlayerInRangeOfPoint(amx, player, range, pX, pY, pZ)
	local cX, cY, cZ

	-- initializing or spectating
	if getPlayerState(player) == 0 or getPlayerState(player) == 9 then
		cX, cY, cZ = getCameraMatrix(player)
	else
		cX, cY, cZ = getElementPosition(player)
	end

	if not cX then return false end
	return getDistanceBetweenPoints3D(pX, pY, pZ, cX, cY, cZ) <= range
end

function GetPlayerDistanceFromPoint(amx, player, pX, pY, pZ)
	local cX, cY, cZ

	-- initializing or spectating
	if getPlayerState(player) == 0 or getPlayerState(player) == 9 then
		cX, cY, cZ = getCameraMatrix(player)
	else
		cX, cY, cZ = getElementPosition(player)
	end

	if not cX then return float2cell(0) end
	return float2cell(getDistanceBetweenPoints3D(pX, pY, pZ, cX, cY, cZ))
end

function IsPlayerStreamedIn(amx, otherPlayer, player)
	return g_Players[getElemID(player)].streamedPlayers[getElemID(otherPlayer)] == true
end

function SetPlayerInterior(amx, player, interior)
	local playerID = getElemID(player)
	if g_Players[playerID].viewingintro then
		return false
	end
	local oldInt = getElementInterior(player)
	setElementInterior(player, interior)
	if interior ~= oldInt then
		procCallOnAll('OnPlayerInteriorChange', playerID, interior, oldInt)
	end
	return true
end

function GetPlayerInterior(amx, player)
	return getElementInterior(player)
end

function SetPlayerHealth(amx, player, health)
	return setElementHealth(player, health)
end

function GetPlayerHealth(amx, player, refHealth)
	if not player then
		return false
	end
	writeMemFloat(amx, refHealth, getElementHealth(player))
	return true
end

function SetPlayerArmour(amx, player, armor)
	return setPedArmor(player, armor)
end

function GetPlayerArmour(amx, player, refArmor)
	if not player then
		return false
	end
	writeMemFloat(amx, refArmor, getPedArmor(player))
	return true
end

function SetPlayerAmmo(amx, player, slot, ammo)
	return setWeaponAmmo(player, slot, ammo)
end

function GetPlayerAmmo(amx, player)
	return getPedTotalAmmo(player)
end

-- Weapon
function GetPlayerWeaponState(amx, player)
	-- -1 WEAPONSTATE_UNKNOWN
	-- 0 WEAPONSTATE_NO_BULLETS
	-- 1 WEAPONSTATE_LAST_BULLET
	-- 2 WEAPONSTATE_MORE_BULLETS
	-- 3 WEAPONSTATE_RELOADING

	local vehicle = getPedOccupiedVehicle(player)
	if vehicle then return -1 end

	if isPedReloadingWeapon(player) then
		return 3
	end

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

function GetPlayerTargetPlayer(amx, player)
	local elem = getPedTarget(player)

	if elem and getElementType(elem) == 'player' then
		return getElemID(elem)
	end
	return INVALID_PLAYER_ID
end

function GetPlayerTargetActor(amx, player)
	local elem = getPedTarget(player)

	if elem and getElementType(elem) == 'ped' then
		if getElementData(elem, 'ActorPed') then
			return getElemID(elem)
		end
	end
	return INVALID_ACTOR_ID
end

function SetPlayerTeam(amx, player, team)
	if not team then return false end
	return setPlayerTeam(player, team)
end

function GetPlayerTeam(amx, player)
	local team = getPlayerTeam(player)
	local data = g_Players[getElemID(player)]

	if data.doingclasssel then
		team = g_PlayerClasses[data.selectedclass][8]
	end

	if not team then return 255 end
	return table.find(g_Teams, team)
end

function SetPlayerScore(amx, player, score)
	return setElementData(player, 'Score', score)
end

function GetPlayerScore(amx, player)
	return getElementData(player, 'Score')
end

function GetPlayerDrunkLevel(amx, player)
	local playerID = getElemID(player)
	if not g_Players[playerID] then
		return 0
	end
	return g_Players[playerID].drunklevel
end

function SetPlayerDrunkLevel(amx, player, level)
	local playerID = getElemID(player)
	if not g_Players[playerID] then return false end

	if level > 50000 then
		level = 50000
	elseif level < 0 then
		level = 0
	end

	g_Players[playerID].drunklevel = level
	local drunkMul = level > 2000 and math.floor(level * 0.02) or 0

	if drunkMul > 250 then
		drunkMul = 250
	elseif drunkMul < 5 then
		drunkMul = 0
	end

	clientCall(player, 'setCameraDrunkLevel', drunkMul)
	return true
end

function SetPlayerColor(amx, player, r, g, b)
	setPlayerNametagColor(player, r, g, b)

	local playerdata = g_Players[getElemID(player)]
	if g_PlayerMarkersMode ~= 0 and playerdata.blip then
		setBlipColor(playerdata.blip, r, g, b, 255)
	end
	return true
end

function GetPlayerColor(amx, player)
	local r, g, b = getPlayerNametagColor(player)
	return color2cell(r, g, b, 255)
end

function SetPlayerSkin(amx, player, skin)
	local model = g_SkinReplace[skin] or skin
	local skinset = setElementModel(player, model)
	if skinset then
		-- wanna see CJ in a white singlet?
		addPedClothes(player, 'vest', 'vest', 0)

		if not g_UseCJWalk then
			-- update walking style for a new skin
			setPedWalkingStyle(player, WalkingStyle[model] or 0)
		end
	end
	return skinset
end

function GetPlayerSkin(amx, player)
	return getElementModel(player)
end

function GivePlayerWeapon(amx, player, weaponID, ammo)
	return giveWeapon(player, weaponID, ammo, true)
end

function ResetPlayerWeapons(amx, player)
	return takeAllWeapons(player)
end

function SetPlayerArmedWeapon(amx, player, weapon)
	return setPedWeaponSlot(player, getSlotFromWeapon(weapon))
end

function GetPlayerWeaponData(amx, player, slot, refWeapon, refAmmo)
	local playerdata = g_Players[getElemID(player)]
	local weapon = playerdata.weapons and playerdata.weapons[slot]
	if weapon then
		amx.memDAT[refWeapon], amx.memDAT[refAmmo] = weapon.id, weapon.ammo
	end
	return true
end

function GivePlayerMoney(amx, player, amount)
	return givePlayerMoney(player, amount)
end

function ResetPlayerMoney(amx, player)
	return setPlayerMoney(player, 0)
end

function SetPlayerName(amx, player, name)
	return setPlayerName(player, name)
end

function GetPlayerMoney(amx, player)
	return getPlayerMoney(player)
end

function GetPlayerState(amx, player)
	return getPlayerState(player)
end

function GetPlayerIp(amx, player, refName, len)
	if not player then
		return -1
	elseif len <= 0 then
		return 0
	end

	local ip = getPlayerIP(player)

	local copyLen = math.min(#ip, len)
	writeMemString(amx, refName, ip:sub(1, copyLen))
	return copyLen
end

function GetPlayerPing(amx, player)
	return getPlayerPing(player)
end

function GetPlayerWeapon(amx, player)
	return getPedWeapon(player)
end

function GetPlayerKeys(amx, player, refKeys, refUpDown, refLeftRight)
	amx.memDAT[refKeys] = buildKeyState(player, g_KeyMapping)
	amx.memDAT[refUpDown] = buildKeyState(player, g_UpDownMapping)
	amx.memDAT[refLeftRight] = buildKeyState(player, g_LeftRightMapping)
	return true
end

function GetPlayerName(amx, player, nameBuf, bufSize)
	if bufSize <= 0 then return 0 end

	local name = getPlayerName(player)

	local copyLen = math.min(#name, bufSize)
	writeMemString(amx, nameBuf, name:sub(1, copyLen))
	return copyLen
end

function SetPlayerTime(amx, player, hours, minutes)
	clientCall(player, 'setTime', hours % 24, minutes % 60)
	return true
end

function GetPlayerTime(amx, player, refHour, refMinute)
	amx.memDAT[refHour], amx.memDAT[refMinute] = getTime()
	return true
end

-- TogglePlayerClock client

function SetPlayerWeather(amx, player, weatherID)
	clientCall(player, 'setWeather', weatherID % 256)
	return true
end

function ForceClassSelection(amx, player)
	local playerID = getElemID(player)
	if not g_Players[playerID] then
		return false
	end
	g_Players[playerID].returntoclasssel = true
	return true
end

function SetPlayerWantedLevel(amx, player, level)
	return setPlayerWantedLevel(player, level)
end

function GetPlayerWantedLevel(amx, player)
	return getPlayerWantedLevel(player)
end

function GetPlayerFightingStyle(amx, player)
	return getPedFightingStyle(player)
end

function SetPlayerFightingStyle(amx, player, style)
	return setPedFightingStyle(player, style)
end

function SetPlayerVelocity(amx, player, vx, vy, vz)
	return setElementVelocity(player, vx, vy, vz)
end

function GetPlayerVelocity(amx, player, refVX, refVY, refVZ)
	if not player then
		return false
	end
	local vx, vy, vz = getElementVelocity(player)
	writeMemFloat(amx, refVX, vx)
	writeMemFloat(amx, refVY, vy)
	writeMemFloat(amx, refVZ, vz)
	return true
end

function PlayCrimeReportForPlayer(amx, player, suspectid, crimeid)
	notImplemented('PlayCrimeReportForPlayer')
	return false
end

-- PlayAudioStreamForPlayer client
-- StopAudioStreamForPlayer client

function SetPlayerShopName(amx, player, shopname)
	notImplemented('SetPlayerShopName')
	return false
end

function SetPlayerSkillLevel(amx, player, skill, level)
	return setPedStat(player, skill + 69, level)
end

function GetPlayerSurfingVehicleID(amx, player)
	if not player then return end
	local surfElement = getPedContactElement(player)
	if surfElement and getElementType(surfElement) == 'vehicle' then
		if getVehicleOccupant(surfElement) then
			return getElemID(surfElement)
		end
	end
	return INVALID_VEHICLE_ID
end

function GetPlayerSurfingObjectID(amx, player)
	if not player then return end
	local surfElement = getPedContactElement(player)
	if surfElement and getElementType(surfElement) == 'object' then
		if isObjectMoving(surfElement) then
			return getElemID(surfElement)
		end
	end
	return INVALID_OBJECT_ID
end

function CreateExplosionForPlayer(amx, player, x, y, z, type, radius)
	clientCall(player, 'createExplosion', x, y, z, type, true, -1.0, false)
	return true
end

-- RemoveBuildingForPlayer client

function GetPlayerLastShotVectors(amx, player, refOrigX, refOrigY, refOrigZ, refHitX, refHitY, refHitZ)
	local playerID = getElemID(player)
	local playerData = g_Players[playerID]
	if not playerData then return end

	writeMemFloat(amx, refOrigX, playerData.shotVect.oX)
	writeMemFloat(amx, refOrigY, playerData.shotVect.oY)
	writeMemFloat(amx, refOrigZ, playerData.shotVect.oZ)

	writeMemFloat(amx, refHitX, playerData.shotVect.hX)
	writeMemFloat(amx, refHitY, playerData.shotVect.hY)
	writeMemFloat(amx, refHitZ, playerData.shotVect.hZ)
	return true
end

function SetPlayerAttachedObject(amx, player, index, modelid, bone, fOffsetX, fOffsetY, fOffsetZ, fRotX, fRotY, fRotZ, fScaleX, fScaleY, fScaleZ, materialcolor1, materialcolor2)
	local x, y, z = getElementPosition(player)
	local mtaBone = g_BoneMapping[bone]
	local obj = createObject(modelid, x, y, z)

	if obj then
		local playerID = getElemID(player)
		g_Players[playerID].attachedObjects[index] = obj
		setElementCollisionsEnabled(obj, false)
		setObjectScale(obj, fScaleX, fScaleY, fScaleZ)
		attachElementToBone(obj, player, mtaBone, fOffsetX, fOffsetY, fOffsetZ, fRotY, fRotX, fRotZ)
		-- TODO: Implement material colors
	else
		outputDebugString('SetPlayerAttachedObject: Cannot attach object since the model is invalid. Model id was ' .. modelid)
		return false
	end
	return true
end

function RemovePlayerAttachedObject(amx, player, index)
	local playerID = getElemID(player)
	local obj = g_Players[playerID].attachedObjects[index] -- Get the object stored at this slot
	if obj then
		detachElementFromBone(obj)
		destroyElement(obj)
		g_Players[playerID].attachedObjects[index] = nil
		return true
	end
	return false
end

function IsPlayerAttachedObjectSlotUsed(amx, player, index)
	local playerID = getElemID(player)
	local obj = g_Players[playerID].attachedObjects[index] -- Get the object stored at this slot
	if obj then
		return true
	end
	return false
end

function EditAttachedObject(amx, player, index)
	notImplemented('EditAttachedObject')
	return false
end

function CreatePlayerTextDraw(amx, player, x, y, text)
	--outputDebugString('CreatePlayerTextDraw called with args ' .. x .. ' ' .. y .. ' ' .. text)

	if (not g_PlayerTextDraws[player]) then -- Create dimension if it doesn't exist
		--outputDebugString('Created dimension for g_PlayerTextDraws[player]')
		g_PlayerTextDraws[player] = {}
	end

	local serverTDId = #g_PlayerTextDraws[player] + 1
	local clientTDId = #g_TextDraws + serverTDId

	local textdraw = { x = x, y = y, shadow = { align = 1, outlinesize = 0, shade = 2, text = text, font = 1, lwidth = 0.48, lheight = 1.12 } }
	textdraw.clientTDId = clientTDId
	textdraw.serverTDId = serverTDId
	textdraw.visible = false

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
					--outputDebugString(string.format('A property changed for %d string: %s', textdraw.clientTDId, textdraw.text))
					clientCall(player, 'TextDrawPropertyChanged', textdraw.clientTDId, k, v)
					t.shadow[k] = v
				end
			end
		}
	)

	--outputDebugString('assigned id s->' .. serverTDId .. ' c->' .. clientTDId .. ' to g_PlayerTextDraws[player]')
	clientCall(player, 'TextDrawCreate', clientTDId, table.deshadowize(textdraw, true))
	return serverTDId
end

local function isPlayerTextDrawValid(player, textdrawID)
	local tableType = type(g_PlayerTextDraws[player])
	if not g_PlayerTextDraws[player] or tableType ~= 'table' then
		return false
	end
	local textdraw = g_PlayerTextDraws[player][textdrawID]
	if not textdraw then
		return false
	end
	return true
end

function PlayerTextDrawDestroy(amx, player, textdrawID)
	if not isPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	--outputDebugString('Sending textdraw id s->' .. g_PlayerTextDraws[player][textdrawID].serverTDId .. ' c->' .. g_PlayerTextDraws[player][textdrawID].clientTDId .. ' for destruction')
	clientCall(player, 'TextDrawDestroy', g_PlayerTextDraws[player][textdrawID].clientTDId)
	g_PlayerTextDraws[player][textdrawID] = nil
	return true
end

function PlayerTextDrawLetterSize(amx, player, textdrawID, width, height)
	if not isPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].lwidth = width
	g_PlayerTextDraws[player][textdrawID].lheight = height
	return true
end

function PlayerTextDrawTextSize(amx, player, textdrawID, x, y)
	if not isPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].boxsize = { x, y }
	return true
end

function PlayerTextDrawAlignment(amx, player, textdrawID, align)
	if not isPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].align = align
	return true
end

function PlayerTextDrawColor(amx, player, textdrawID, r, g, b, a)
	if not isPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].color = { r, g, b }
	return true
end

function PlayerTextDrawUseBox(amx, player, textdrawID, usebox)
	if not isPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].usebox = usebox
	return true
end

function PlayerTextDrawBoxColor(amx, player, textdrawID, r, g, b, a)
	if not isPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].boxcolor = { r, g, b, a }
	return true
end

function PlayerTextDrawSetShadow(amx, player, textdrawID, size)
	if not isPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].shade = size
	return true
end

function PlayerTextDrawSetOutline(amx, player, textdrawID, size)
	if not isPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].outlinesize = size
	return true
end

function PlayerTextDrawSetProportional(amx, player, textdrawID, proportional)
	notImplemented('PlayerTextDrawSetProportional')
	return false
end

function PlayerTextDrawBackgroundColor(amx, player, textdrawID, r, g, b, a)
	if not isPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].outlinecolor = { r, g, b, a }
	return true
end

function PlayerTextDrawFont(amx, player, textdrawID, font)
	if not isPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].font = font
	return true
end

function PlayerTextDrawSetSelectable(amx, player, textdrawID, selectable)
	notImplemented('PlayerTextDrawSetSelectable')
	return false
end

function PlayerTextDrawShow(amx, player, textdrawID)
	if not isPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	--if g_PlayerTextDraws[player][textdrawID].visible then
	--	return false
	--end
	g_PlayerTextDraws[player][textdrawID].visible = true
	clientCall(player, 'TextDrawShowForPlayer', g_PlayerTextDraws[player][textdrawID].clientTDId)
	--outputDebugString('PlayerTextDrawShow: proccessed for ' .. textdrawID .. ' with ' .. g_PlayerTextDraws[player][textdrawID].text)
	return true
end

function PlayerTextDrawHide(amx, player, textdrawID)
	if not isPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	--if not g_PlayerTextDraws[player][textdrawID].visible then
	--	return false
	--end
	g_PlayerTextDraws[player][textdrawID].visible = false
	clientCall(player, 'TextDrawHideForPlayer', g_PlayerTextDraws[player][textdrawID].clientTDId)
	--outputDebugString('PlayerTextDrawHide: proccessed for ' .. textdrawID .. ' with ' .. g_PlayerTextDraws[player][textdrawID].text)
	return true
end

function PlayerTextDrawSetString(amx, player, textdrawID, str)
	if not isPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].text = str
	return true
end

function PlayerTextDrawSetPreviewModel(amx, player, textdrawID, model)
	notImplemented('PlayerTextDrawSetPreviewModel')
	return false
end

function PlayerTextDrawSetPreviewRot(amx, player, textdrawID, rX, rY, rZ, zoom)
	notImplemented('PlayerTextDrawSetPreviewRot')
	return false
end

function PlayerTextDrawSetPreviewVehCol(amx, player, textdrawID, color1, color2)
	notImplemented('PlayerTextDrawSetPreviewVehCol')
	return false
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
	return true
end

function GetPVarString(amx, player, varname, outbuf, length)
	if length <= 0 then return 0 end

	local value = g_Players[getElemID(player)].pvars[varname]
	if not value or value[1] ~= PLAYER_VARTYPE_STRING then
		return 0
	end

	local copyLen = math.min(#value[2], length)
	writeMemString(amx, outbuf, string.sub(value[2], 1, copyLen))
	return copyLen
end

function SetPVarString(amx, player, varname, value)
	g_Players[getElemID(player)].pvars[varname] = {PLAYER_VARTYPE_STRING, value}
	return true
end

function GetPVarFloat(amx, player, varname)
	local value = g_Players[getElemID(player)].pvars[varname]
	if not value or value[1] ~= PLAYER_VARTYPE_FLOAT then
		return float2cell(0)
	end
	return float2cell(value[2])
end

function SetPVarFloat(amx, player, varname, value)
	g_Players[getElemID(player)].pvars[varname] = {PLAYER_VARTYPE_FLOAT, value}
	return true
end

function DeletePVar(amx, player, varname)
	g_Players[getElemID(player)].pvars[varname] = nil
	return true
end

function GetPVarsUpperIndex(amx, player)
	local playerID = getElemID(player)
	if not g_Players[playerID] then return 0 end

	local varCount = 0
	for _ in pairs(g_Players[playerID].pvars) do
		varCount = varCount + 1
	end

	return varCount
end

function GetPVarNameAtIndex(amx, player, index, outbuf, length)
	if length <= 0 or index < 0 then return 0 end

	local playerID = getElemID(player)
	if not g_Players[playerID] then return 0 end

	local varNames = {}
	for name in pairs(g_Players[playerID].pvars) do
		table.insert(varNames, name)
	end

	if index >= #varNames then return 0 end
	local varName = string.upper(varNames[index + 1])

	local copyLen = math.min(#varName, length)
	writeMemString(amx, outbuf, varName:sub(1, copyLen))
	return copyLen
end

function GetPVarType(amx, player, varname)
	local value = g_Players[getElemID(player)].pvars[varname]
	if value then
		return value[1]
	end
	return PLAYER_VARTYPE_NONE
end

function SetPlayerChatBubble(amx, player, text, color, dist, exptime)
	notImplemented('SetPlayerChatBubble')
	return false
end

function PutPlayerInVehicle(amx, player, vehicle, seat)
	if not player then
		return false
	end
	warpPedIntoVehicle(player, vehicle, seat)
	if g_RCVehicles[getElementModel(vehicle)] then
		setPedWeaponSlot(player, 0)
		setElementCollisionsEnabled(player, false)
		setElementAlpha(player, 0)
	end
	--setPlayerState(player, seat == 0 and PLAYER_STATE_DRIVER or PLAYER_STATE_PASSENGER)
	-- No need to do this since the vehicle event gets called when we enter a vehicle
	return true
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

function GetPlayerVehicleSeat(amx, player)
	return getPedOccupiedVehicleSeat(player)
end

function RemovePlayerFromVehicle(amx, player)
	local vehicle = getPedOccupiedVehicle(player)
	if vehicle then
		if g_RCVehicles[getElementModel(vehicle)] then
			return removePedFromVehicle(player)
		else
			return setControlState(player, 'enter_exit', true)
		end
	end
	--setPlayerState(player, PLAYER_STATE_ONFOOT)
	-- No need to do this since the vehicle event gets called when we exit a vehicle
	return false
end

function TogglePlayerControllable(amx, player, enable)
	if not enable then
		local vehicle = getPedOccupiedVehicle(player)
		if vehicle then
			setElementAngularVelocity(vehicle, 0, 0, 0)
			setElementVelocity(vehicle, 0, 0, 0)
		end
	end

	setElementFrozen(player, not enable)
	return toggleAllControls(player, enable, true, false)
end

-- PlayerPlaySound client

function ApplyAnimation(amx, player, animlib, animname, fDelta, loop, lockx, locky, freeze, time, forcesync)
	-- time = Timer in ms. For a never-ending loop it should be 0.
	if time == 0 then
		loop = true
	end
	setPedAnimation(player, animlib, animname, time, loop, lockx or locky, false, freeze)
	setPedAnimationSpeed(player, animname, fDelta)
	return true
end

function ClearAnimations(amx, player, forcesync)
	removePedFromVehicle(player)
	setPedWearingJetpack(player, false)
	setPedAnimation(player, false)
	g_Players[getElemID(player)].specialaction = SPECIAL_ACTION_NONE
	return true
end

function GetPlayerAnimationIndex(amx, player)
	notImplemented('GetPlayerAnimationIndex')
	return 0
end

function GetAnimationName(amx, index, animLib, libLen, animName, nameLen)
	if libLen <= 0 or nameLen <= 0 then return false end

	local foundKey = lookupAnimByID[index]
	if not foundKey then return false end

	local animLibPart, animNamePart = foundKey:match("^([^:]+):([^:]+)$")
	if not animLibPart or not animNamePart then return false end

	local copyLen = math.min(#animLibPart, libLen)
	writeMemString(amx, animLib, animLibPart:sub(1, copyLen))
	copyLen = math.min(#animNamePart, nameLen)
	writeMemString(amx, animName, animNamePart:sub(1, copyLen))

	return true
end

function GetPlayerSpecialAction(amx, player)
	if not player then
		return SPECIAL_ACTION_NONE
	elseif isPedDucked(player) then
		return SPECIAL_ACTION_DUCK
	elseif isPedWearingJetpack(player) then
		return SPECIAL_ACTION_USEJETPACK
	end

	local playerdata = g_Players[getElemID(player)]
	return playerdata.specialaction or SPECIAL_ACTION_NONE
end

function SetPlayerSpecialAction(amx, player, actionID)
	if not player then return false end
	local playerdata = g_Players[getElemID(player)]

	if actionID == SPECIAL_ACTION_NONE then
		if playerdata.specialaction == SPECIAL_ACTION_USECELLPHONE then
			-- stop using cellphone properly

			actionID = SPECIAL_ACTION_STOPUSECELLPHONE
			playerdata.specialaction = SPECIAL_ACTION_STOPUSECELLPHONE
			return setPedAnimation(player, unpack(g_SpecialActions[actionID]))
		end
		setPedWearingJetpack(player, false)
	elseif actionID == SPECIAL_ACTION_USEJETPACK then
		return setPedWearingJetpack(player, true)
	elseif actionID >= SPECIAL_ACTION_DANCE1 and actionID <= SPECIAL_ACTION_PISSING then
		-- special actions won't be applied in vehicle

		if isPedInVehicle(player) then return false end
	end

	-- won't stop using cellphone if there's no cellphone
	if actionID == SPECIAL_ACTION_STOPUSECELLPHONE then
		if playerdata.specialaction ~= SPECIAL_ACTION_USECELLPHONE then return false end
	end

	if actionID >= SPECIAL_ACTION_DRINK_BEER and actionID <= SPECIAL_ACTION_DRINK_SPRUNK then
		-- player should hold a drink in hands instead of any weapon
		setPedWeaponSlot(player, 0)

		if actionID == SPECIAL_ACTION_DRINK_BEER then
			playerdata.drunklevel = playerdata.drunklevel + 1350
		elseif actionID == SPECIAL_ACTION_DRINK_WINE then
			playerdata.drunklevel = playerdata.drunklevel + 1350
		end
	end

	-- if special action cannot be set or it's invalid
	if not g_SpecialActions[actionID] then return false end

	setPedAnimation(player, unpack(g_SpecialActions[actionID]))
	playerdata.specialaction = actionID
	return true
end

function DisableRemoteVehicleCollisions(amx, player, disable)
	notImplemented('DisableRemoteVehicleCollisions')
	return false
end

function SetPlayerCheckpoint(amx, player, x, y, z, size)
	g_Players[getElemID(player)].checkpoint = { x = x, y = y, z = z, radius = size }
	clientCall(player, 'SetPlayerCheckpoint', x, y, z, size)
	return true
end

function DisablePlayerCheckpoint(amx, player)
	g_Players[getElemID(player)].checkpoint = nil
	clientCall(player, 'DisablePlayerCheckpoint')
	return true
end

function SetPlayerRaceCheckpoint(amx, player, type, x, y, z, nextX, nextY, nextZ, size)
	g_Players[getElemID(player)].racecheckpoint = { type = type, x = x, y = y, z = z, radius = size }
	clientCall(player, 'SetPlayerRaceCheckpoint', type, x, y, z, nextX, nextY, nextZ, size)
	return true
end

function DisablePlayerRaceCheckpoint(amx, player)
	g_Players[getElemID(player)].racecheckpoint = nil
	clientCall(player, 'DisablePlayerRaceCheckpoint')
	return true
end

-- SetPlayerWorldBounds client
-- SetPlayerMarkerForPlayer client

function ShowPlayerNameTagForPlayer(amx, player, playerToShow, show)
	clientCall(player, 'updateNameTagShowing', playerToShow, show)
	return true
end

-- SetPlayerMapIcon client
-- RemovePlayerMapIcon client

function AllowPlayerTeleport(amx, player, allow)
	deprecated('AllowPlayerTeleport', '0.3d')
	return true
end

function SetPlayerDisabledWeapons(amx, player, ...)
	deprecated('SetPlayerDisabledWeapons', '0.3')
	return true
end

function SetPlayerCameraPos(amx, player, x, y, z)
	if not player then
		return false
	end
	fadeCamera(player, true)
	setCameraMatrix(player, x, y, z)
	return true
end

function SetPlayerCameraLookAt(amx, player, lx, ly, lz, cut)
	if not player then
		return false
	end
	local x, y, z = getCameraMatrix(player)
	if not x then
		return false
	end
	fadeCamera(player, true)
	setCameraMatrix(player, x, y, z, lx, ly, lz)
	return true
end

function SetCameraBehindPlayer(amx, player)
	-- In SA-MP calling SetCameraBehindPlayer also unsets camera interpolation
	clientCall(player, 'removeCamHandlers')
	return setCameraTarget(player, player)
end

function GetPlayerCameraPos(amx, player, refX, refY, refZ)
	if not player then
		return false
	end
	local x, y, z = getCameraMatrix(player)
	writeMemFloat(amx, refX, x)
	writeMemFloat(amx, refY, y)
	writeMemFloat(amx, refZ, z)
	return true
end

function GetPlayerCameraFrontVector(amx, player, refX, refY, refZ)
	if not player then
		return false
	end

	local x, y, z, lx, ly, lz = getCameraMatrix(player)
	local vx, vy, vz = 0.0, 0.0, 0.0

	if x and lx then
		vx = lx - x
	end
	if y and ly then
		vy = ly - y
	end
	if z and lz then
		vz = lz - z
	end

	writeMemFloat(amx, refX, vx)
	writeMemFloat(amx, refY, vy)
	writeMemFloat(amx, refZ, vz)
	return true
end

function GetPlayerCameraMode(amx, player)
	notImplemented('GetPlayerCameraMode')
	return -1
end

function EnablePlayerCameraTarget(amx, player, enable)
	notImplemented('EnablePlayerCameraTarget')
	return false
end

function GetPlayerCameraTargetObject(amx, player)
	notImplemented('GetPlayerCameraTargetObject')
	return INVALID_OBJECT_ID
end

function GetPlayerCameraTargetVehicle(amx, player)
	notImplemented('GetPlayerCameraTargetVehicle')
	return INVALID_VEHICLE_ID
end

function GetPlayerCameraTargetPlayer(amx, player)
	notImplemented('GetPlayerCameraTargetPlayer')
	return INVALID_PLAYER_ID
end

function GetPlayerCameraTargetActor(amx, player)
	notImplemented('GetPlayerCameraTargetActor')
	return INVALID_ACTOR_ID
end

function GetPlayerCameraAspectRatio(amx, player)
	notImplemented('GetPlayerCameraAspectRatio')
	return float2cell(0)
end

function GetPlayerCameraZoom(amx, player)
	notImplemented('GetPlayerCameraZoom')
	return float2cell(0)
end

-- AttachCameraToObject client
-- AttachCameraToPlayerObject client
-- InterpolateCameraPos client
-- InterpolateCameraLookAt client

function IsPlayerAdmin(amx, player)
	return isPlayerInACLGroup(player, 'Admin') or isPlayerInACLGroup(player, 'Console')
end

function IsPlayerConnected(amx, playerID)
	return g_Players[playerID] ~= nil
end

function GetPlayerPoolSize(amx)
	local highestID = 0
	for id, v in pairs(g_Players) do
		if id > highestID then
			highestID = id
		end
	end
	return highestID
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
	return math.sqrt((playerdata.checkpoint.x - x) ^ 2 + (playerdata.checkpoint.y - y) ^ 2) <= playerdata.checkpoint.radius
end

function IsPlayerInRaceCheckpoint(amx, player)
	local playerdata = g_Players[getElemID(player)]
	if not playerdata.racecheckpoint then
		return false
	end
	local x, y = getElementPosition(player)
	return math.sqrt((playerdata.racecheckpoint.x - x) ^ 2 + (playerdata.racecheckpoint.y - y) ^ 2) <= playerdata.racecheckpoint.radius
end

function IsPlayerInVehicle(amx, player, vehicle)
	return getPedOccupiedVehicle(player) == vehicle
end

function SetPlayerVirtualWorld(amx, player, dimension)
	return setElementDimension(player, dimension)
end

function EnableStuntBonusForAll(amx, enable)
	notImplemented('EnableStuntBonusForAll')
	return true
end

function EnableStuntBonusForPlayer(amx, player, enable)
	notImplemented('EnableStuntBonusForPlayer')
	return false
end

function TogglePlayerSpectating(amx, player, enable)
	local playerdata = g_Players[getElemID(player)]
	if enable then
		fadeCamera(player, true)
		setCameraMatrix(player, 75.461357116699, 64.600051879883, 51.685581207275, 149.75857543945, 131.53228759766, 40.597320556641)
		-- controls, alpha, collisions and blip will be re-enabled on spawn
		toggleAllControls(player, false, true, false)
		setPedWeaponSlot(player, 0)
		setElementAlpha(player, 0)
		setElementCollisionsEnabled(player, false)
		setPlayerHudComponentVisible(player, 'radar', false)
		setPlayerState(player, PLAYER_STATE_SPECTATING)
		if playerdata.blip then
			setElementVisibleTo(playerdata.blip, root, false)
		end
	else
		setCameraTarget(player, player)
		clientCall(player, 'setCameraTarget', player) -- Clear the one on the client as well, otherwise we can't go back to normal camera after spectating vehicles
		-- In SA-MP calling TogglePlayerSpectating also unsets camera interpolation
		clientCall(player, 'removeCamHandlers')
		if playerdata.returntoclasssel then
			playerdata.returntoclasssel = nil
			playerdata.spawninfo = nil
			if procCallOnAll('OnPlayerRequestClass', getElemID(player), 0) then
				setElementAlpha(player, 255)
				setPlayerState(player, PLAYER_STATE_WASTED)
				putPlayerInClassSelection(player)
			else
				outputDebugString('Not allowed to select a class', 1)
				setPlayerState(player, PLAYER_STATE_SPAWNED)
			end
		else
			spawnPlayerBySelectedClass(player)
		end
	end
	return true
end

function PlayerSpectatePlayer(amx, player, playerToSpectate, mode)
	return setCameraTarget(player, playerToSpectate)
end

function PlayerSpectateVehicle(amx, player, vehicleToSpectate, mode)
	if getVehicleController(vehicleToSpectate) then
		return setCameraTarget(player, getVehicleController(vehicleToSpectate))
	else
		clientCall(player, 'setCameraTarget', vehicleToSpectate)
		return true
	end
end

function StartRecordingPlayerData(amx, player, type, name)
	notImplemented('StartRecordingPlayerData')
	return false
end

function StopRecordingPlayerData(amx, player)
	notImplemented('StopRecordingPlayerData')
	return false
end

function SelectTextDraw(amx, player, hovercolor)
	notImplemented('SelectTextDraw')
	return false
end

function CancelSelectTextDraw(amx, player)
	notImplemented('CancelSelectTextDraw')
	return false
end
