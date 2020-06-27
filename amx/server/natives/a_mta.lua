function AddPlayerClothes(amx, player, type, index)
	local texture, model = getClothesByTypeIndex(type, index)
	addPedClothes(player, texture, model, type)
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
	removePedClothes(player, type)
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