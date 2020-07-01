function SetPlayerPos(amx, player, x, y, z)
	setElementPosition(player, x, y, z)
end
GetPlayerPos = GetObjectPos
function SetPlayerFacingAngle(amx, player, angle)
	setPedRotation(player, angle)
end
function GetPlayerFacingAngle(amx, player, refRot)
	writeMemFloat(amx, refRot, getPedRotation(player))
end
function IsPlayerInRangeOfPoint(amx, player, range, pX, pY, pZ)
	return getDistanceBetweenPoints3D(pX, pY, pZ, getElementPosition(player)) <= range
end

function GetPlayerDistanceFromPoint(amx, player, pX, pY, pZ)
	return float2cell(getDistanceBetweenPoints3D(pX, pY, pZ, getElementPosition(player)))
end

function IsPlayerStreamedIn(amx, otherPlayer, player)
	return g_Players[getElemID(player)].streamedPlayers[getElemID(otherPlayer)] == true
end

function SetPlayerInterior(amx, player, interior)
	local playerId = getElemID(player)
	if g_Players[playerId].viewingintro then
		return
	end
	local oldInt = getElementInterior(player)
	setElementInterior(player, interior)
	procCallOnAll('OnPlayerInteriorChange', playerId, interior, oldInt)
	clientCall(player, 'AMX_OnPlayerInteriorChange', interior, oldInt)
end

function GetPlayerInterior(amx, player)
	return getElementInterior(player)
end

function SetPlayerHealth(amx, player, health)
	setElementHealth(player, health)
end

function GetPlayerHealth(amx, player, refHealth)
	writeMemFloat(amx, refHealth, getElementHealth(player))
end

function SetPlayerArmour(amx, player, armor)
	setPedArmor(player, armor)
end

function GetPlayerArmour(amx, player, refArmor)
	writeMemFloat(amx, refArmor, getPedArmor(player))
end

function SetPlayerAmmo(amx, player, slot, ammo)
	setWeaponAmmo(player, slot, ammo)
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
-- TODO: GetPlayerTargetPlayer

function GetPlayerTargetActor(amx, player)
	local elem = getPedTarget(player)

	if getElementType(elem) == 'ped' and getElementData(elem, 'amx.actorped') then
		return getElemID(elem)
	end
	return INVALID_ACTOR_ID
end

function SetPlayerTeam(amx, player, team)
	setPlayerTeam(player, team)
end

function GetPlayerTeam(amx, player)
	return table.find(g_Teams, getPlayerTeam(player))
end

function SetPlayerScore(amx, player, score)
	setElementData(player, 'Score', score)
end

function GetPlayerScore(amx, player)
	return getElementData(player, 'Score')
end

function GetPlayerDrunkLevel(player)
	notImplemented('GetPlayerDrunkLevel', 'SCM is not supported.')
	return 0
end

function SetPlayerDrunkLevel(player)
	notImplemented('SetPlayerDrunkLevel', 'SCM is not supported.')
	return 0
end

function SetPlayerColor(amx, player, r, g, b)
	setPlayerNametagColor(player, r, g, b)
	if g_ShowPlayerMarkers then
		setBlipColor(g_Players[getElemID(player)].blip, r, g, b, 255)
	end
end

function GetPlayerColor(amx, player)
	local r, g, b = getPlayerNametagColor(player)
	return color2cell(r, g, b)
end

function SetPlayerSkin(amx, player, skin)
	setElementModel(player, skinReplace[skin] or skin)
end

function GetPlayerSkin(amx, player)
	return getElementModel(player)
end

function GivePlayerWeapon(amx, player, weaponID, ammo)
	giveWeapon(player, weaponID, ammo, true)
end

function ResetPlayerWeapons(amx, player)
	takeAllWeapons(player)
end

function SetPlayerArmedWeapon(amx, player, weapon)
	return setPedWeaponSlot(player, weapon)
end

function GetPlayerWeaponData(amx, player, slot, refWeapon, refAmmo)
	local playerdata = g_Players[getElemID(player)]
	local weapon = playerdata.weapons and playerdata.weapons[slot]
	if weapon then
		amx.memDAT[refWeapon], amx.memDAT[refAmmo] = weapon.id, weapon.ammo
	end
end

function GivePlayerMoney(amx, player, amount)
	givePlayerMoney(player, amount)
end

function ResetPlayerMoney(amx, player)
	setPlayerMoney(player, 0)
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
	local ip = getPlayerIP(player)
	if #ip < len then
		writeMemString(amx, refName, ip)
	end
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
end

function GetPlayerName(amx, player, nameBuf, bufSize)
	local name = getPlayerName(player)
	if #name <= bufSize then
		writeMemString(amx, nameBuf, name)
	end
end

function SetPlayerTime(amx, player, hours, minutes)
	clientCall(player, 'setTime', hours, minutes)
end


function GetPlayerTime(amx, player, refHour, refMinute)
	amx.memDAT[refHour], amx.memDAT[refMinute] = getTime()
end

-- TODO: TogglePlayerClock client

function SetPlayerWeather(amx, player, weatherID)
	clientCall(player, 'setWeather', weatherID % 256)
end

function ForceClassSelection(amx, playerID)
	if not g_Players[playerID] then
		return
	end
	g_Players[playerID].returntoclasssel = true
end

function SetPlayerWantedLevel(amx, player, level)
	setPlayerWantedLevel(player, level)
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
	setElementVelocity(player, vx, vy, vz)
end

function GetPlayerVelocity(amx, player, refVX, refVY, refVZ)
	local vx, vy, vz = getElementVelocity(player)
	writeMemFloat(amx, refVX, vx)
	writeMemFloat(amx, refVY, vy)
	writeMemFloat(amx, refVZ, vz)
end

-- dummy
function PlayCrimeReportForPlayer(amx, player, suspectid, crimeid)
	notImplemented('PlayCrimeReportForPlayer')
	return false
end

function PlayAudioStreamForPlayer(amx, player, url, posX, posY, posZ, distance, usepos)
	clientCall(player, 'PlayAudioStreamForPlayer', url, posX, posY, posZ, distance, usepos)
end

function StopAudioStreamForPlayer(amx, player)
	clientCall(player, 'StopAudioStreamForPlayer')
end

function SetPlayerShopName(amx)
	notImplemented('SetPlayerShopName')
	return false
end

function SetPlayerSkillLevel(amx, player, skill, level)
	return setPedStat(player, skill + 69, level)
end

function GetPlayerSurfingVehicleID(amx, player)
	return -1
end

function GetPlayerSurfingObjectID(amx)
	notImplemented('GetPlayerSurfingObjectID')
end

function RemoveBuildingForPlayer(amx, player, model, x, y, z, radius)
	clientCall(player, 'RemoveBuildingForPlayer', model, x, y, z, radius)
end

function GetPlayerLastShotVectors(amx)
	notImplemented('GetPlayerLastShotVectors')
	return false
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

function IsPlayerAttachedObjectSlotUsed(amx)
	notImplemented('IsPlayerAttachedObjectSlotUsed')
	return false
end

function EditAttachedObject(amx)
	notImplemented('EditAttachedObject')
	return false
end

function CreatePlayerTextDraw(amx, player, x, y, text)
	outputDebugString('CreatePlayerTextDraw called with args ' .. x .. ' ' .. y .. ' ' .. text)

	if ( not g_PlayerTextDraws[player] ) then --Create dimension if it doesn't exist
		outputDebugString('Created dimension for g_PlayerTextDraws[player]')
		g_PlayerTextDraws[player] = {}
	end

	local serverTDId = #g_PlayerTextDraws[player]+1
	local clientTDId = #g_TextDraws + serverTDId

	local textdraw = { x = x, y = y, lwidth=0.5, lheight = 0.5, shadow = { visible=0, align=1, text=text, font=1, lwidth=0.5, lheight = 0.5 } }
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
					--outputDebugString(string.format('A property changed for %d string: %s', textdraw.clientTDId, textdraw.text))
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

function PlayerTextDrawDestroy(amx, player, textdrawID)
    if not IsPlayerTextDrawValid(player, textdrawID) then
      return false
  end
  outputDebugString('Sending textdraw id s->' .. g_PlayerTextDraws[player][textdrawID].serverTDId .. ' c->' .. g_PlayerTextDraws[player][textdrawID].clientTDId .. ' for destruction')
  clientCall(player, 'TextDrawDestroy', g_PlayerTextDraws[player][textdrawID].clientTDId)
  g_PlayerTextDraws[player][textdrawID] = nil
end

function PlayerTextDrawLetterSize(amx, player, textdrawID, x, y)
	if not IsPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].lwidth = width
	g_PlayerTextDraws[player][textdrawID].lheight = height
	return true
end

function PlayerTextDrawTextSize(amx, player, textdrawID, x, y)
	if not IsPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].boxsize = { x, y }
	return true
end

function PlayerTextDrawAlignment(amx, player, textdrawID, align)
	if not IsPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].align = (align == 0 and 1 or align)
	return true
end

function PlayerTextDrawColor(amx, player, textdrawID, r, g, b, a)
    if not IsPlayerTextDrawValid(player, textdrawID) then
      return false
  end
  g_PlayerTextDraws[player][textdrawID].color = { r, g, b }
  return true
end

function PlayerTextDrawUseBox(amx, player, textdrawID, usebox)
	if not IsPlayerTextDrawValid(player, textdrawID) then
		outputDebugString('textdraw is invalid, not setting usebox ' .. textdrawID)
		return false
	end
	g_PlayerTextDraws[player][textdrawID].usebox = usebox
	return true
end

function PlayerTextDrawBoxColor(amx, player, textdrawID, r, g, b, a)
	if not IsPlayerTextDrawValid(player, textdrawID) then
		return false
	end
	g_PlayerTextDraws[player][textdrawID].boxcolor = { r, g, b, a }
end

function PlayerTextDrawSetShadow(amx, player, textdrawID, size)
    if not IsPlayerTextDrawValid(player, textdrawID) then
     return false
 end
 g_PlayerTextDraws[player][textdrawID].shade = size
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
	notImplemented('PlayerTextDrawSetProportional')
  --TextDrawSetProportional(amx, textdraw, proportional)
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

function PlayerTextDrawSetSelectable(amx)
	notImplemented('PlayerTextDrawSetSelectable')
	return false
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

function PlayerTextDrawSetString(amx, player, textdrawID, str)
    if not IsPlayerTextDrawValid(player, textdrawID) then
     return false
 end
 g_PlayerTextDraws[player][textdrawID].text = str
 return true
end

function PlayerTextDrawSetPreviewModel(amx)
	notImplemented('PlayerTextDrawSetPreviewModel')
	return false
end

function PlayerTextDrawSetPreviewRot(amx)
	notImplemented('PlayerTextDrawSetPreviewRot')
	return false
end

function PlayerTextDrawSetPreviewVehCol(amx)
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

function DeletePVar(amx, player, varname)
	g_Players[getElemID(player)].pvars[varname] = nil
	return 1
end

function GetPVarsUpperIndex(amx)
	notImplemented('GetPVarsUpperIndex')
	return false
end

function GetPVarNameAtIndex(amx)
	notImplemented('GetPVarNameAtIndex')
	return false
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
	warpPedIntoVehicle(player, vehicle, seat)
	if g_RCVehicles[getElementModel(vehicle)] then
		setElementAlpha(player, 0)
	end
	setPlayerState(player, seat == 0 and PLAYER_STATE_DRIVER or PLAYER_STATE_PASSENGER)
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
		removePedFromVehicle(player)
		if g_RCVehicles[getElementModel(vehicle)] then
			clientCall(root, 'setElementAlpha', player, 255)
		end
	end
	setPlayerState(player, PLAYER_STATE_ONFOOT)
end

function TogglePlayerControllable(amx, player, enable)
	toggleAllControls(player, enable, true, false)
end

function PlayerPlaySound(amx, player, soundID, x, y, z)
	notImplemented('PlayerPlaySound')
end

function ApplyAnimation(amx, player, animlib, animname, fDelta, loop, lockx, locky, freeze, time, forcesync)
	--time = Timer in ms. For a never-ending loop it should be 0.
	if time == 0 then
		loop = true
	end
	setPedAnimation(player, animlib, animname, time, loop, lockx or locky, false, freeze)
	setPedAnimationSpeed(player, animname, fDelta)
end

function ClearAnimations(amx, player)
	setPedAnimation(player, false)
	g_Players[getElemID(player)].specialaction = SPECIAL_ACTION_NONE
end

function GetPlayerAnimationIndex(player)
	notImplemented('GetPlayerAnimationIndex')
	return 0
end

function GetAnimationName(amx)
	notImplemented('GetAnimationName')
	return false
end

function GetPlayerSpecialAction(amx, player)
	if doesPedHaveJetPack(player) then
		return SPECIAL_ACTION_USEJETPACK
	else
		return g_Players[getElemID(player)].specialaction or SPECIAL_ACTION_NONE
	end
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

function DisableRemoteVehicleCollisions(amx)
	notImplemented('DisableRemoteVehicleCollisions')
	return false
end

function SetPlayerCheckpoint(amx, player, x, y, z, size)
	g_Players[getElemID(player)].checkpoint = { x = x, y = y, z = z, radius = size }
	clientCall(player, 'SetPlayerCheckpoint', x, y, z, size)
end

function DisablePlayerCheckpoint(amx, player)
	g_Players[getElemID(player)].checkpoint = nil
	clientCall(player, 'DisablePlayerCheckpoint')
end

function SetPlayerRaceCheckpoint(amx, player, type, x, y, z, nextX, nextY, nextZ, size)
	g_Players[getElemID(player)].racecheckpoint = { type = type, x = x, y = y, z = z, radius = size }
	clientCall(player, 'SetPlayerRaceCheckpoint', type, x, y, z, nextX, nextY, nextZ, size)
end

function DisablePlayerRaceCheckpoint(amx, player)
	g_Players[getElemID(player)].racecheckpoint = nil
	clientCall(player, 'DisablePlayerRaceCheckpoint')
end

-- SetPlayerWorldBounds client

-- SetPlayerMarkerForPlayer client

function ShowPlayerNameTagForPlayer(amx, player, playerToShow, show)
	clientCall(player, 'setPlayerNametagShowing', playerToShow, show)
end

-- SetPlayerMapIcon client
-- RemovePlayerMapIcon client

function AllowPlayerTeleport(amx, player, allow)
	deprecated('AllowPlayerTeleport', '0.3d')
end

function SetPlayerCameraPos(amx, player, x, y, z)
	fadeCamera(player, true)
	setCameraMatrix(player, x, y, z)
end

function SetPlayerCameraLookAt(amx, player, lx, ly, lz)
	fadeCamera(player, true)
	local x, y, z = getCameraMatrix(player)
	setCameraMatrix(player, x, y, z, lx, ly, lz)
end

function SetCameraBehindPlayer(amx, player)
	--In samp calling SetCameraBehindPlayer also unsets camera interpolation
	clientCall(player, 'removeCamHandlers')
	setCameraTarget(player, player)
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

function GetPlayerCameraMode(amx)
	notImplemented('GetPlayerCameraMode')
end

function EnablePlayerCameraTarget(amx)
	notImplemented('EnablePlayerCameraTarget')
	return false
end

function GetPlayerCameraTargetObject(amx)
	notImplemented('GetPlayerCameraTargetObject')
	return false
end

function GetPlayerCameraTargetVehicle(amx)
	notImplemented('GetPlayerCameraTargetVehicle')
	return false
end

function GetPlayerCameraTargetPlayer(amx)
	notImplemented('GetPlayerCameraTargetPlayer')
	return false
end

function GetPlayerCameraTargetActor(amx)
	notImplemented('GetPlayerCameraTargetActor')
	return false
end

function GetPlayerCameraAspectRatio(amx)
	notImplemented('GetPlayerCameraAspectRatio')
	return false
end

function GetPlayerCameraZoom(amx)
	notImplemented('GetPlayerCameraZoom')
	return false
end

function AttachCameraToObject(amx, player, object)
	clientCall(player, 'AttachCameraToObject', object)
end

function AttachCameraToPlayerObject(amx)
	notImplemented('AttachCameraToPlayerObject')
	return false
end

--playerid, Float:FromX, Float:FromY, Float:FromZ, Float:ToX, Float:ToY, Float:ToZ, time, cut = CAMERA_CUT
function InterpolateCameraPos(amx, player, FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut)
	clientCall(player, 'InterpolateCameraPos', FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut)
end
function InterpolateCameraLookAt(amx, player, FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut)
	clientCall(player, 'InterpolateCameraLookAt', FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut)
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

function SetPlayerVirtualWorld(amx, player, dimension)
	setElementDimension(player, dimension)
end

function EnableStuntBonusForAll(amx, enable)
	notImplemented('EnableStuntBonusForAll')
end

function EnableStuntBonusForPlayer(amx, player, enable)
	notImplemented('EnableStuntBonusForPlayer')
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

function StartRecordingPlayerData(amx)
	notImplemented('StartRecordingPlayerData')
	return false
end

function StopRecordingPlayerData(amx)
	notImplemented('StopRecordingPlayerData')
	return false
end

function SelectTextDraw(amx)
	notImplemented('SelectTextDraw')
	return false
end

function CancelSelectTextDraw(amx)
	notImplemented('CancelSelectTextDraw')
	return false
end

-- Explosion
function CreateExplosionForPlayer(amx, player, x, y, z, type, radius)
	clientCall(player, 'createExplosion', x, y, z, type, true, -1.0, false)
	return 1
end