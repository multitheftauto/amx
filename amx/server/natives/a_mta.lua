function AddPlayerClothes(amx, player, type, index)
	local texture, model = getClothesByTypeIndex(type, index)
	return addPedClothes(player, texture, model, type)
end

function GetPlayerClothes(amx, player, type)
	local texture, model = getPedClothes(player, type)
	if not texture then
		return
	end
	local type, index = getTypeIndexFromClothes(texture, model)
	return index
end

function RemovePlayerClothes(amx, player, type)
	return removePedClothes(player, type)
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
	return isElementOnFire(player)
end

function IsPlayerDucked(amx, player)
	return isPedDucked(player)
end

function IsPlayerOnGround(amx, player)
	return isPedOnGround(amx, player)
end

function SetPlayerOnFire(amx, player, fire)
	return setElementOnFire(player, fire)
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

function SetPlayerCanBeKnockedOffBike(amx, player, knockedOff)
	clientCall(root, 'setPedCanBeKnockedOffBike', player, knockedOff)
	return setElementData(player, 'CanBeKnockedOffBike', knockedOff)
end

function SetPlayerWeaponSlot(amx, player, slot)
	clientCall(root, 'setPedWeaponSlot', player, slot)
	return true
end

function SetPlayerHeadless(amx, player, headState)
	return setPedHeadless(player, headState)
end

function SetPlayerGravity(amx, player, gravity)
	return setPedGravity(player, gravity)
end

function GetPlayerBlurLevel(amx, player)
	return getPlayerBlurLevel(player)
end

function SetPlayerBlurLevel(amx, player, level)
	return setPlayerBlurLevel(player, level)
end

function SetPlayerControlState(amx, player, control, controlState)
	return setControlState(player, control, controlState)
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
	local bot = createPed(model, x, y, z)
	setElementData(bot, 'amx.shownametag', true, true)
	setElementData(bot, 'BotName', name, true)
	local botId = addElem(g_Bots, bot)
	procCallOnAll('OnBotConnect', botId, name)
	return botId
end

function DestroyBot(amx, bot)
	removeElem(g_Bots, bot)
	destroyElement(bot)
	return true
end

function GetBotState(amx, bot)
	return getBotState(bot)
end

function PutBotInVehicle(amx, bot, vehicle, seat)
	return warpPedIntoVehicle(bot, vehicle, seat)
end

function RemoveBotFromVehicle(amx, bot)
	local vehicle = getPedOccupiedVehicle(bot)
	if vehicle then
		return removePedFromVehicle(bot)
	end
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

function GetBotName(amx, bot, nameBuf, bufSize)
	local name = getElementData(bot, 'BotName')
	if #name <= bufSize then
		writeMemString(amx, nameBuf, name)
		return string.len(name)
	end
end

GetBotHealth = GetPlayerHealth
SetBotHealth = SetPlayerHealth
GetBotArmour = GetPlayerArmour
SetBotArmour = SetPlayerArmour

GetBotPos = GetActorPos
SetBotPos = SetActorPos
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
	writeMemFloat(amx, refSize, size)
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

function ResetPlayerData(amx, player, key)
	return setElementData(player, key, nil)
end
-----------------------------------------------------
-- Vehicles

function GetVehicleMaxPassengers(amx, vehicle)
	return getVehicleMaxPassengers(vehicle)
end

function SetVehicleModel(amx, vehicle, model)
	return setElementModel(vehicle, model)
end

function GetVehicleEngineState(amx, vehicle)
	return getVehicleEngineState(vehicle)
end

function SetVehicleEngineState(amx, vehicle, engineState)
	return setVehicleEngineState(vehicle, engineState)
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

function GetVehiclePaintjob(amx, vehicle)
	return getVehiclePaintjob(vehicle)
end

function GetVehicleSirenState(amx, vehicle)
	return getVehicleSirensOn(vehicle)
end

function SetVehicleSirenState(amx, vehicle, sirenState)
	return setVehicleSirensOn(vehicle, sirenState)
end

function IsTrainDerailable(amx, train)
	return isTrainDerailable(train)
end

function IsTrainDerailed(amx, train)
	return isTrainDerailed(train)
end

function SetTrainDerailable(amx, train, derailable)
	return setTrainDerailable(train, derailable)
end

function SetTrainDerailed(amx, train, derailed)
	return setTrainDerailed(train, derailed)
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

function SetCloudsEnabled(amx, enable)
	return setCloudsEnabled(enable)
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

function GetServerRule(amx, rule, nameBuf, bufSize)
	local ruleval = getRuleValue(rule)
	if #ruleval <= bufSize then
		writeMemString(amx, nameBuf, ruleval)
	end
end

function SetServerRule(amx, rule, value)
	return setRuleValue(rule, value)
end

function RemoveServerRule(amx, rule)
	return removeRuleValue(rule)
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

function ShowCursor(amx, player, show, controls)
	return showCursor(player, show, controls)
end

function AddEventHandler(amx, event, func)
	if g_EventNames[event] then
		g_Events[func] = event
	end
end

function RemoveEventHandler(amx, func)
	g_Events[func] = nil
end

function AttachElementToElement(amx, elem, toelem, posX, posY, posZ, rotX, rotY, rotZ)
	return attachElements(elem, toelem, posX, posY, posZ, rotX, rotY, rotZ)
end

function IsPluginLoaded(amx, pluginName)
	return amxIsPluginLoaded(pluginName)
end