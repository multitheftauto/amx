function AddPlayerClothes(amx, player, type, index)
	local texture, model = getClothesByTypeIndex(type, index)
	return addPedClothes(player, texture, model, type)
end

function GetPlayerClothes(amx, player, type)
	local texture, model = getPedClothes(player, type)
	if not texture then
		return -1
	end
	local cType, cIndex = getTypeIndexFromClothes(texture, model)
	if not cType then
		return -1
	end
	return cIndex
end

function RemovePlayerClothes(amx, player, type)
	return removePedClothes(player, type)
end

AddBotClothes = AddPlayerClothes
GetBotClothes = GetPlayerClothes
RemoveBotClothes = RemovePlayerClothes
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
	return isElementOnFire(player)
end

function SetPlayerOnFire(amx, player, fire)
	return setElementOnFire(player, fire)
end

function IsPlayerDucked(amx, player)
	return isPedDucked(player)
end

function IsPlayerOnGround(amx, player)
	return isPedOnGround(amx, player)
end

function IsPlayerChoking(amx, player)
	return isPedChoking(amx, player)
end

function SetPlayerChoking(amx, player, choking)
	return setPedChoking(player, choking)
end

function GetPlayerWalkingStyle(amx, player)
	return getPedWalkingStyle(player)
end

function SetPlayerWalkingStyle(amx, player, style)
	-- if style is MOVE_DEFAULT and CJ walk isn't enabled
	if style == 0 and not g_UseCJWalk then
		-- return walking style back to default for this skin
		local skin = getElementModel(player)
		return setPedWalkingStyle(player, WalkingStyle[skin] or 0)
	end
	return setPedWalkingStyle(player, style)
end

function GetPlayerStat(amx, player, stat)
	return getPedStat(player, stat)
end

function SetPlayerStat(amx, player, stat, value)
	return setPedStat(player, stat, value)
end

function GetPlayerDoingDriveBy(amx, player)
	return getElementData(player, 'DoingDriveBy')
end

function SetPlayerDoingDriveBy(amx, player, driveBy)
	clientCall(root, 'setPedDoingGangDriveby', player, driveBy)
	return setElementData(player, 'DoingDriveBy', driveBy)
end

function GetPlayerCanBeKnockedOffBike(amx, player)
	return getElementData(player, 'CanBeKnockedOffBike')
end

function SetPlayerCanBeKnockedOffBike(amx, player, knockOff)
	clientCall(root, 'setPedCanBeKnockedOffBike', player, knockOff)
	return setElementData(player, 'CanBeKnockedOffBike', knockOff)
end

function GetPlayerWeaponSlot(amx, player)
	return getPedWeaponSlot(player)
end

function SetPlayerWeaponSlot(amx, player, slot)
	return setPedWeaponSlot(player, slot)
end

function GetPlayerAmmoInClip(amx, player)
	return getPedAmmoInClip(player)
end

function GetPlayerIdleTime(amx, player)
	return getPlayerIdleTime(player)
end

function IsPlayerHeadless(amx, player)
	return isPedHeadless(player)
end

function SetPlayerHeadless(amx, player, headless)
	return setPedHeadless(player, headless)
end

function GetPlayerBlurLevel(amx, player)
	return getPlayerBlurLevel(player)
end

function SetPlayerBlurLevel(amx, player, level)
	return setPlayerBlurLevel(player, level)
end

function IsPlayerMapForced(amx, player)
	return isPlayerMapForced(player)
end

function ForcePlayerMap(amx, player, forceOn)
	return forcePlayerMap(player, forceOn)
end

function FadePlayerCamera(amx, player, fadeIn, timeToFade, red, green, blue)
	return fadeCamera(player, fadeIn, timeToFade, red, green, blue)
end

function SetPlayerControlState(amx, player, control, controlState)
	return setControlState(player, control, controlState)
end

function IsPlayerCursorShowing(amx, player)
	return isCursorShowing(player)
end

function ShowPlayerCursor(amx, player, show, controls)
	return showCursor(player, show, controls)
end

function RemovePlayerWeapon(amx, player, weaponID)
	return takeWeapon(player, weaponID)
end

function GetPlayerGravity(amx, player)
	return float2cell(getPedGravity(player))
end

function SetPlayerGravity(amx, player, gravity)
	return setPedGravity(player, gravity)
end

function GetPlayerSkillLevel(amx, player, skill)
	return getPedStat(player, skill + 69)
end
-----------------------------------------------------
-- Bots

function CreateBot(amx, model, x, y, z, name)
	local bot = createPed(g_SkinReplace[model] or model, x, y, z)
	addPedClothes(bot, 'vest', 'vest', 0)
	setElementData(bot, 'ShowNameTag', true)
	setElementData(bot, 'BotName', name)
	local botId = addElem(g_Bots, bot)
	procCallOnAll('OnBotConnect', botId, name)
	g_Bots[botId].state = PLAYER_STATE_ONFOOT
	g_Bots[botId].vehicle = nil
	return botId
end

function DestroyBot(amx, bot)
	removeElem(g_Bots, bot)
	destroyElement(bot)
	return true
end

function GetBotRot(amx, bot, refX, refY, refZ)
	if not bot then
		return false
	end
	local rX, rY, rZ = getPedRotation(bot)
	writeMemFloat(amx, refX, rX)
	writeMemFloat(amx, refY, rY)
	writeMemFloat(amx, refZ, rZ)
	return true
end

function SetBotRot(amx, bot, rX, rY, rZ)
	return setPedRotation(bot, rX, rY, rZ)
end

function GetBotInterior(amx, bot)
	return getElementInterior(bot)
end

function SetBotInterior(amx, bot, interior)
	return setElementInterior(bot, interior)
end

function GetBotState(amx, bot)
	return getBotState(bot)
end

function PutBotInVehicle(amx, bot, vehicle, seat)
	if not bot then
		return false
	end
	warpPedIntoVehicle(bot, vehicle, seat)
	if g_RCVehicles[getElementModel(vehicle)] then
		setPedWeaponSlot(bot, 0)
		setElementCollisionsEnabled(bot, false)
		setElementAlpha(bot, 0)
	end
	return true
end

function RemoveBotFromVehicle(amx, bot)
	local vehicle = getPedOccupiedVehicle(bot)
	if vehicle then
		removePedFromVehicle(bot)
		if g_RCVehicles[getElementModel(vehicle)] then
			setElementCollisionsEnabled(bot, true)
			setElementAlpha(bot, 255)
		end
		return true
	end
	return false
end

function SetBotControlState(amx, bot, control, controlState)
	clientCall(root, 'setPedControlState', bot, control, controlState)
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

function GetBotName(amx, bot, nameBuf, bufSize)
	if bufSize <= 0 then return 0 end

	local name = getElementData(bot, 'BotName')

	local copyLen = math.min(#name, bufSize)
	writeMemString(amx, nameBuf, name:sub(1, copyLen))
	return copyLen
end

IsBotInWater = IsPlayerInWater
IsBotOnFire = IsPlayerOnFire
SetBotOnFire = SetPlayerOnFire
IsBotDucked = IsPlayerDucked
IsBotOnGround = IsPlayerOnGround
IsBotChoking = IsPlayerChoking
SetBotChoking = SetPlayerChoking
GetBotHealth = GetPlayerHealth
SetBotHealth = SetPlayerHealth
GetBotArmour = GetPlayerArmour
SetBotArmour = SetPlayerArmour
GetBotPos = GetPlayerPos
SetBotPos = SetPlayerPos
GetBotVelocity = GetPlayerVelocity
SetBotVelocity = SetPlayerVelocity
GetBotVirtualWorld = GetPlayerVirtualWorld
SetBotVirtualWorld = SetPlayerVirtualWorld
GetBotFightingStyle = GetPlayerFightingStyle
SetBotFightingStyle = SetPlayerFightingStyle
GetBotWalkingStyle = GetPlayerWalkingStyle
SetBotWalkingStyle = SetPlayerWalkingStyle
GetBotSkin = GetPlayerSkin
SetBotSkin = SetPlayerSkin
GetBotSkillLevel = GetPlayerSkillLevel
SetBotSkillLevel = SetPlayerSkillLevel
GetBotStat = GetPlayerStat
SetBotStat = SetPlayerStat
GetBotVehicleID = GetPlayerVehicleID
GetBotVehicleSeat = GetPlayerVehicleSeat
IsBotInVehicle = IsPlayerInVehicle
IsBotInAnyVehicle = IsPlayerInAnyVehicle
GetBotDoingDriveBy = GetPlayerDoingDriveBy
SetBotDoingDriveBy = SetPlayerDoingDriveBy
GetBotCanBeKnockedOffBike = GetPlayerCanBeKnockedOffBike
SetBotCanBeKnockedOffBike = SetPlayerCanBeKnockedOffBike
GetBotAmmo = GetPlayerAmmo
GetBotWeaponState = GetPlayerWeaponState
GetBotWeapon = GetPlayerWeapon
GetBotWeaponSlot = GetPlayerWeaponSlot
SetBotWeaponSlot = SetPlayerWeaponSlot
GetBotAmmoInClip = GetPlayerAmmoInClip
IsBotHeadless = IsPlayerHeadless
SetBotHeadless = SetPlayerHeadless
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
	local R, G, B, A = getMarkerColor(marker)
	if colorid == 0 then return R end
	if colorid == 1 then return G end
	if colorid == 2 then return B end
	if colorid == 3 then return A end
	return 0
end

function GetMarkerIcon(amx, marker)
	local icon = getMarkerIcon(marker)
	if icon == false then return -1 end
	if icon == 'none' then return 0 end
	if icon == 'arrow' then return 1 end
	if icon == 'finish' then return 2 end
	return -1
end

function GetMarkerSize(amx, marker, refSize)
	if not marker then
		return false
	end
	local size = getMarkerSize(marker)
	writeMemFloat(amx, refSize, size)
	return true
end

function GetMarkerTarget(amx, marker, refX, refY, refZ)
	if not marker then
		return false
	end
	local x, y, z = getMarkerTarget(marker)
	if x == false then return false end
	writeMemFloat(amx, refX, x)
	writeMemFloat(amx, refY, y)
	writeMemFloat(amx, refZ, z)
	return true
end

function GetMarkerType(amx, marker)
	local mtype = getMarkerType(marker)
	if mtype == false then return -1 end
	if mtype == 'checkpoint' then return 0 end
	if mtype == 'ring' then return 1 end
	if mtype == 'cylinder' then return 2 end
	if mtype == 'arrow' then return 3 end
	if mtype == 'corona' then return 4 end
	return -1
end

function SetMarkerColor(amx, marker, red, green, blue, alpha)
	return setMarkerColor(marker, red, green, blue, alpha)
end

function SetMarkerIcon(amx, marker, icon)
	if icon == 0 then icon = 'none'
	elseif icon == 1 then icon = 'arrow'
	elseif icon == 2 then icon = 'finish'
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
	if typeid == 0 then typeid = 'checkpoint'
	elseif typeid == 1 then typeid = 'ring'
	elseif typeid == 2 then typeid = 'cylinder'
	elseif typeid == 3 then typeid = 'arrow'
	elseif typeid == 4 then typeid = 'corona'
	else return false end
	return setMarkerType(marker, typeid)
end

function IsPlayerInMarker(amx, marker, elem)
	return isElementWithinMarker(elem, marker)
end

IsVehicleInMarker = IsPlayerInMarker
IsBotInMarker = IsPlayerInMarker
-----------------------------------------------------
-- Player Data

function SetPlayerIntData(amx, player, key, value)
	return setElementData(player, key, value)
end

function GetPlayerIntData(amx, player, key)
	return getElementData(player, key)
end

SetPlayerFloatData = SetPlayerIntData

function GetPlayerFloatData(amx, player, key)
	return float2cell(getElementData(player, key))
end

SetPlayerBoolData = SetPlayerIntData
GetPlayerBoolData = GetPlayerIntData
SetPlayerStringData = SetPlayerIntData

function GetPlayerStringData(amx, player, key, buf, len)
	if len <= 0 then return 0 end

	local data = getElementData(player, key)

	local copyLen = math.min(#data, len)
	writeMemString(amx, buf, data:sub(1, copyLen))
	return copyLen
end

function ResetPlayerData(amx, player, key)
	return setElementData(player, key, nil)
end
-----------------------------------------------------
-- Vehicles

function SetVehicleModel(amx, vehicle, model)
	return setElementModel(vehicle, model)
end

function GetVehicleMaxPassengers(amx, vehicle)
	return getVehicleMaxPassengers(vehicle)
end

function GetVehicleEngineState(amx, vehicle)
	return getVehicleEngineState(vehicle)
end

function SetVehicleEngineState(amx, vehicle, engine)
	return setVehicleEngineState(vehicle, engine)
end

function GetVehicleSirenState(amx, vehicle)
	return getVehicleSirensOn(vehicle)
end

function SetVehicleSirenState(amx, vehicle, siren)
	return setVehicleSirensOn(vehicle, siren)
end

function GetVehicleDoorState(amx, vehicle, door)
	return getVehicleDoorState(vehicle, door)
end

function SetVehicleDoorState(amx, vehicle, door, doorState)
	return setVehicleDoorState(vehicle, door, doorState)
end

function GetVehicleLightState(amx, vehicle, light)
	return getVehicleLightState(vehicle, light)
end

function SetVehicleLightState(amx, vehicle, light, lightState)
	return setVehicleLightState(vehicle, light, lightState)
end

function GetVehicleOverrideLights(amx, vehicle)
	return getVehicleOverrideLights(vehicle)
end

function SetVehicleOverrideLights(amx, vehicle, override)
	return setVehicleOverrideLights(vehicle, override)
end

function GetVehicleWheelState(amx, vehicle, wheel)
	local w1, w2, w3, w4 = getVehicleWheelStates(vehicle)
	if wheel == 0 then return w1 end
	if wheel == 1 then return w2 end
	if wheel == 2 then return w3 end
	if wheel == 3 then return w4 end
end

function SetVehicleWheelState(amx, vehicle, frontLeft, rearLeft, frontRight, rearRight)
	return setVehicleWheelStates(vehicle, frontLeft, rearLeft, frontRight, rearRight)
end

function GetVehiclePanelState(amx, vehicle, panel)
	return getVehiclePanelState(vehicle, panel)
end

function SetVehiclePanelState(amx, vehicle, panel, panelState)
	return setVehiclePanelState(vehicle, panel, panelState)
end

function GetVehicleVariant(amx, vehicle, refVar1, refVar2)
	if not vehicle then
		return false
	end
	local variant1, variant2 = getVehicleVariant(vehicle)
	amx.memDAT[refVar1] = variant1
	amx.memDAT[refVar2] = variant2
	return true
end

function SetVehicleVariant(amx, vehicle, variant1, variant2)
	return setVehicleVariant(vehicle, variant1, variant2)
end

function IsTrainDerailable(amx, train)
	return isTrainDerailable(train)
end

function SetTrainDerailable(amx, train, derailable)
	return setTrainDerailable(train, derailable)
end

function IsTrainDerailed(amx, train)
	return isTrainDerailed(train)
end

function SetTrainDerailed(amx, train, derailed)
	return setTrainDerailed(train, derailed)
end

function GetTrainDirection(amx, train)
	return getTrainDirection(train)
end

function SetTrainDirection(amx, train, clockwise)
	return setTrainDirection(train, clockwise)
end

function GetTrainSpeed(amx, train, refSpeed)
	if not train then
		return false
	end
	local speed = getTrainSpeed(train)
	writeMemFloat(amx, refSpeed, speed)
	return true
end

function SetTrainSpeed(amx, train, speed)
	return setTrainSpeed(train, speed)
end

function GetVehicleOccupant(amx, vehicle, seat)
	local player = getVehicleOccupant(vehicle, seat)
	if not player then
		return INVALID_PLAYER_ID
	end
	return getElemID(player)
end

function GetVehicleNumberPlate(amx, vehicle, buf, len)
	if len <= 0 then return 0 end

	local plate = getVehiclePlateText(vehicle)

	local copyLen = math.min(#plate, len)
	writeMemString(amx, buf, plate:sub(1, copyLen))
	return copyLen
end

function GetVehicleColor(amx, vehicle, refColor1, refColor2)
	if not vehicle then
		return false
	end
	local color1, color2 = getVehicleColor(vehicle, false)
	amx.memDAT[refColor1] = color1
	amx.memDAT[refColor2] = color2
	return true
end

function GetVehiclePaintjob(amx, vehicle)
	return getVehiclePaintjob(vehicle)
end

GetVehicleInterior = GetPlayerInterior
IsVehicleInWater = IsPlayerInWater
IsVehicleOnGround = IsPlayerOnGround
-----------------------------------------------------
-- Water

function GetWaveHeight(amx)
	return float2cell(getWaveHeight())
end

function SetWaveHeight(amx, height)
	return setWaveHeight(height)
end

function SetWaterLevel(amx, level)
	return setWaterLevel(level)
end
-----------------------------------------------------
-- Objects

function IsObjectBreakable(amx, object)
	return isObjectBreakable(object)
end

function SetObjectBreakable(amx, object, breakable)
	return setObjectBreakable(object, breakable)
end

function GetObjectScale(amx, object, refX, refY, refZ)
	if not object then
		return false
	end
	local sX, sY, sZ = getObjectScale(object)
	writeMemFloat(amx, refX, sX)
	writeMemFloat(amx, refY, sY)
	writeMemFloat(amx, refZ, sZ)
	return true
end

function SetObjectScale(amx, object, sX, sY, sZ)
	return setObjectScale(object, sX, sY, sZ)
end

-----------------------------------------------------
-- Pickups

function GetPickupType(amx, pickup)
	return getPickupType(pickup)
end

function SetPickupType(amx, pickup, typeid, model, ammo)
	return setPickupType(pickup, typeid, model, ammo)
end

function GetPickupAmount(amx, pickup)
	return getPickupAmount(pickup)
end

function GetPickupWeapon(amx, pickup)
	return getPickupWeapon(pickup)
end

function GetPickupAmmo(amx, pickup)
	return getPickupAmmo(pickup)
end
-----------------------------------------------------
-- World

function GetGameSpeed(amx)
	return float2cell(getGameSpeed())
end

function SetGameSpeed(amx, speed)
	return setGameSpeed(speed)
end

function GetRainLevel(amx)
	local rainLvl = getRainLevel() or 0
	return float2cell(rainLvl)
end

function SetRainLevel(amx, level)
	return setRainLevel(level)
end

function ResetRainLevel(amx)
	return resetRainLevel()
end

function GetSkyGradient(amx, refTopRed, refTopGreen, refTopBlue, refBtmRed, refBtmGreen, refBtmBlue)
	local topRed, topGreen, topBlue, btmRed, btmGreen, btmBlue = getSkyGradient()

	amx.memDAT[refTopRed] = topRed
	amx.memDAT[refTopGreen] = topGreen
	amx.memDAT[refTopBlue] = topBlue
	amx.memDAT[refBtmRed] = btmRed
	amx.memDAT[refBtmGreen] = btmGreen
	amx.memDAT[refBtmBlue] = btmBlue

	return true
end

function SetSkyGradient(amx, topRed, topGreen, topBlue, btmRed, btmGreen, btmBlue)
	return setSkyGradient(topRed, topGreen, topBlue, btmRed, btmGreen, btmBlue)
end

function ResetSkyGradient(amx)
	return resetSkyGradient()
end

function GetFogDistance(amx)
	local fogDist = getFogDistance() or 0
	return float2cell(fogDist)
end

function SetFogDistance(amx, distance)
	return setFogDistance(distance)
end

function ResetFogDistance(amx)
	return resetFogDistance()
end

function GetCloudsEnabled(amx)
	return getCloudsEnabled()
end

function SetCloudsEnabled(amx, enable)
	return setCloudsEnabled(enable)
end

function SetWeatherBlended(amx, weather)
	return setWeatherBlended(weather)
end

function GetInteriorSoundsEnabled(amx)
	return getInteriorSoundsEnabled()
end

function SetInteriorSoundsEnabled(amx, enable)
	return setInteriorSoundsEnabled(enable)
end

function GetOcclusionsEnabled(amx)
	return getOcclusionsEnabled()
end

function SetOcclusionsEnabled(amx, enable)
	return setOcclusionsEnabled(enable)
end

function IsGarageOpen(amx, garage)
	return isGarageOpen(garage)
end

function SetGarageOpen(amx, garage, open)
	return setGarageOpen(garage, open)
end

function IsGlitchEnabled(amx, glitch)
	return isGlitchEnabled(glitch)
end

function SetGlitchEnabled(amx, glitch, enable)
	return setGlitchEnabled(amx, glitch, enable)
end

function GetAircraftMaxVelocity(amx)
	return float2cell(getAircraftMaxVelocity())
end

function SetAircraftMaxVelocity(amx, velocity)
	return setAircraftMaxVelocity(velocity)
end

function GetAircraftMaxHeight(amx)
	return float2cell(getAircraftMaxHeight())
end

function SetAircraftMaxHeight(amx, height)
	return setAircraftMaxHeight(height)
end

function GetJetpackMaxHeight(amx)
	return float2cell(getJetpackMaxHeight())
end

function SetJetpackMaxHeight(amx, height)
	return setJetpackMaxHeight(height)
end

function GetWeaponSlot(amx, weapon)
	return getSlotFromWeapon(weapon) or -1
end

function GetFPSLimit(amx)
	return getFPSLimit()
end

function SetFPSLimit(amx, limit)
	return setFPSLimit(limit)
end

function GetRandomPlayer(amx)
	return getElemID(getRandomPlayer())
end

function GetPlayerCount(amx)
	return getPlayerCount(amx)
end
-----------------------------------------------------
-- Rules

function IsValidServerRule(amx, rule)
	return getRuleValue(rule) and true or false
end

function GetServerRule(amx, rule, nameBuf, bufSize)
	if bufSize <= 0 then return 0 end

	local ruleval = getRuleValue(rule)

	local copyLen = math.min(#ruleval, bufSize)
	writeMemString(amx, nameBuf, ruleval:sub(1, copyLen))
	return copyLen
end

function SetServerRule(amx, rule, value)
	return setRuleValue(rule, value)
end

function RemoveServerRule(amx, rule)
	return removeRuleValue(rule)
end
-----------------------------------------------------
-- Scoreboard

function AddScoreBoardColumn(amx, column)
	local scoreboard = getResourceFromName('scoreboard')
	if getResourceState(scoreboard) ~= 'running' then return false end
	return exports.scoreboard:scoreboardAddColumn(column)
end

function SetPlayerScoreBoardData(amx, player, column, value)
	local scoreboard = getResourceFromName('scoreboard')
	if getResourceState(scoreboard) ~= 'running' then return false end
	return setElementData(player, column, value)
end

function RemoveScoreBoardColumn(amx, column)
	local scoreboard = getResourceFromName('scoreboard')
	if getResourceState(scoreboard) ~= 'running' then return false end
	return exports.scoreboard:scoreboardRemoveColumn(column)
end
-----------------------------------------------------
-- Misc

function AddEventHandler(amx, event, func)
	if g_EventNames[event] then
		g_Events[func] = event
	end
end

function RemoveEventHandler(amx, func)
	g_Events[func] = nil
end

function IsPluginLoaded(amx, pluginName)
	return amxIsPluginLoaded(pluginName)
end