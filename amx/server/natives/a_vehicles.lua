CreateVehicle = AddStaticVehicleEx

function DestroyVehicle(amx, vehicle)
	local vehicleID = getElemID(vehicle)
	clientCall(root, 'DestroyVehicle', vehicleID)
	for i,playerdata in pairs(g_Players) do
		playerdata.streamedVehicles[vehicleID] = nil
	end
	removeElem(g_Vehicles, vehicle)
	destroyElement(vehicle)
end

function IsVehicleStreamedIn(amx, vehicle, player)
	return g_Players[getElemID(player)].streamedVehicles[getElemID(vehicle)] == true
end

GetVehiclePos = GetObjectPos

SetVehiclePos = SetObjectPos

function GetVehicleZAngle(amx, vehicle, refZ)
	local rX, rY, rZ = getVehicleRotation(vehicle)
	writeMemFloat(amx, refZ, rZ)
end

GetVehicleDistanceFromPoint = GetPlayerDistanceFromPoint

function SetVehicleZAngle(amx, vehicle, rZ)
	local rX, rY = getVehicleRotation(vehicle)
	setVehicleRotation(vehicle, 0, 0, rZ)
end

function SetVehicleParamsForPlayer(amx, vehicle, player, isObjective, doorsLocked)
	clientCall(player, 'SetVehicleParamsForPlayer', vehicle, isObjective, doorsLocked)
end


function ManualVehicleEngineAndLights()
	ManualVehEngineAndLights = true
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

function GetVehicleParamsCarWindows(amx, vehicle, int1, int2, int3, int4)
	notImplemented('GetVehicleParamsCarWindows')
end

function SetVehicleToRespawn(amx, vehicle)
	for seat=0,getVehicleMaxPassengers(vehicle) do
		local player = getVehicleOccupant(vehicle, seat)
		if player then
			removePedFromVehicle(player)
		end
	end
	respawnStaticVehicle(vehicle)
end

function LinkVehicleToInterior(amx, vehicle, interior)
	setElementInterior(vehicle, interior)
end

function AddVehicleComponent(amx, vehicle, upgradeID)
	addVehicleUpgrade(vehicle, upgradeID)
end

function RemoveVehicleComponent(amx, vehicle, upgradeID)
	removeVehicleUpgrade(vehicle, upgrade)
end

function ChangeVehicleColor(amx, vehicle, color1, color2)
	setVehicleColorClamped(vehicle, color1, color2)
end

function setVehicleColorClamped(vehicle, color1, color2)
	--This is to prevent negative color behavior, keep the original color if they sent -1 (I believe this is what samp does)
	if color1 ~= -1 and color2 ~= -1 then
		color1 = clamp(color1, 0, 126)
		color2 = clamp(color2, 0, 126)
		setVehicleColor(vehicle, color1, color2, 0, 0)
	end
end

function ChangeVehiclePaintjob(amx, vehicle, paintjob)
	setVehiclePaintjob(vehicle, paintjob)
end

function SetVehicleHealth(amx, vehicle, health)
	setElementHealth(vehicle, health)
end

function GetVehicleHealth(amx, vehicle, refHealth)
	writeMemFloat(amx, refHealth, getElementHealth(vehicle))
end

function AttachTrailerToVehicle(amx, trailer, vehicle)
	attachTrailerToVehicle(vehicle, trailer)
end

function DetachTrailerFromVehicle(amx, puller)
	detachTrailerFromVehicle(puller)
end

function IsTrailerAttachedToVehicle(amx, vehicle)
	return getVehicleTowedByVehicle(vehicle) ~= false
end

function GetVehicleTrailer(amx, vehicle)
	local trailer = getVehicleTowedByVehicle(vehicle)
	if not trailer then
		return 0
	end
	return getElemID(trailer)
end

function SetVehicleNumberPlate(amx, vehicle, plate)
	setVehiclePlateText(vehicle, plate)
end

function GetVehicleModelInfo(amx)
	notImplemented('GetVehicleModelInfo')
end

function GetVehicleComponentInSlot(amx, vehicle, slot)
	return getVehicleUpgradeOnSlot(vehicle, slot)
end

-- 0 - CARMODTYPE_SPOILER
-- 1 - CARMODTYPE_HOOD
-- 2 - CARMODTYPE_ROOF
-- 3 - CARMODTYPE_SIDESKIRT
-- 4 - CARMODTYPE_LAMPS
-- 5 - CARMODTYPE_NITRO
-- 6 - CARMODTYPE_EXHAUST
-- 7 - CARMODTYPE_WHEELS
-- 8 - CARMODTYPE_STEREO
-- 9 - CARMODTYPE_HYDRAULICS
-- 10 - CARMODTYPE_FRONT_BUMPER
-- 11 - CARMODTYPE_REAR_BUMPER
-- 12 - CARMODTYPE_VENT_RIGHT
-- 13 - CARMODTYPE_VENT_LEFT
function GetVehicleComponentType(amx, componentid)
	local components = {
		['Spoiler'] = 0,
		['Hood'] = 1,
		['Roof'] = 2,
		['Sideskirt'] = 3,
		['Headlights'] = 4,
		['Nitro'] = 5,
		['Exhaust'] = 6,
		['Wheels'] = 7,
		['Stereo'] = 8,
		['Hydraulics'] = 9,
		['Front Bumper'] = 10,
		['Rear Bumper'] = 11,

		-- TODO:
		-- 12 - CARMODTYPE_VENT_RIGHT
		-- 13 - CARMODTYPE_VENT_LEFT
		['Vent'] = 12
	}
	local componentName = getVehicleUpgradeSlotName (componentid)

	local componentId = components[componentName]
	if tonumber(componentId) ~= nil then
		return componentId
	else
		return -1
	end
end

function RepairVehicle(amx, vehicle)
	fixVehicle(vehicle)
end

-- function GetVehicleVelocity(amx, vehicle, refVX, refVY, refVZ)
-- 	local vx, vy, vz = getElementVelocity(vehicle)
-- 	writeMemFloat(amx, refVX, vx)
-- 	writeMemFloat(amx, refVY, vy)
-- 	writeMemFloat(amx, refVZ, vz)
-- end

-- function SetVehicleVelocity(amx, vehicle, vx, vy, vz)
--	setElementVelocity(vehicle, vx, vy, vz) \
	--setElementAngularVelocity(vehicle, vx, vy, vz) --This isn't needed, it makes the car spin and I believe samp doesn't do this
-- end

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

function SetVehicleVirtualWorld(amx, vehicle, dimension)
	setElementDimension(vehicle, dimension)
end

function GetVehicleVirtualWorld(amx, vehicle)
	return getElementDimension(vehicle)
end

function GetVehicleModel(amx, vehicle)
	return getElementModel(vehicle)
end

function IsValidVehicle(amx, vehicleID)
	return g_Vehicles[vehicleID] ~= nil
end
