CreateVehicle = AddStaticVehicleEx

function DestroyVehicle(amx, vehicle)
	if vehicle then
		local vehicleID = getElemID(vehicle)
		clientCall(root, 'DestroyVehicle', vehicleID)
		for i, playerdata in pairs(g_Players) do
			playerdata.streamedVehicles[vehicleID] = nil
		end
		removeElem(g_Vehicles, vehicle)
		destroyElement(vehicle)
	end
	return true
end

function IsVehicleStreamedIn(amx, vehicle, player)
	return g_Players[getElemID(player)].streamedVehicles[getElemID(vehicle)] == true
end

function GetVehiclePos(amx, vehicle, refX, refY, refZ)
	if not vehicle then
		return false
	end
	local x, y, z = getElementPosition(vehicle)
	writeMemFloat(amx, refX, x)
	writeMemFloat(amx, refY, y)
	writeMemFloat(amx, refZ, z)
	return true
end

function SetVehiclePos(amx, vehicle, x, y, z)
	setElementFrozen(vehicle, true)

	setElementPosition(vehicle, x, y, z)
	setElementAngularVelocity(vehicle, 0, 0, 0)
	setElementVelocity(vehicle, 0, 0, 0)

	setTimer(setElementFrozen, 500, 1, vehicle, false)
	return true
end

function GetVehicleZAngle(amx, vehicle, refZ)
	if not vehicle then
		return false
	end
	local rX, rY, rZ = getVehicleRotation(vehicle)
	writeMemFloat(amx, refZ, rZ)
	return true
end

function GetVehicleRotationQuat(amx, vehicle, refW, refX, refY, refZ)
	notImplemented('GetVehicleRotationQuat')
	return false
end

GetVehicleDistanceFromPoint = GetPlayerDistanceFromPoint

function SetVehicleZAngle(amx, vehicle, rZ)
	local rX, rY = getVehicleRotation(vehicle)
	return setVehicleRotation(vehicle, 0, 0, rZ)
end

function SetVehicleParamsForPlayer(amx, vehicle, player, isObjective, doorsLocked)
	clientCall(player, 'SetVehicleParamsForPlayer', vehicle, isObjective, doorsLocked)
	return true
end

function ManualVehicleEngineAndLights()
	ManualVehEngineAndLights = true
end

function GetVehicleParamsEx(amx, vehicle, refEngine, refLights, refAlarm, refDoors, refBonnet, refBoot, refObjective)
	local vehicleID = getElemID(vehicle)

	amx.memDAT[refEngine] = getVehicleEngineState(vehicle) and 1 or 0 -- Lua expects this to be an int, so cast it
	amx.memDAT[refLights] = getVehicleOverrideLights(vehicle) == 2 and 1 or 0
	amx.memDAT[refAlarm] = g_Vehicles[vehicleID].alarm and 1 or 0
	amx.memDAT[refDoors] = isVehicleLocked(vehicle) and 1 or 0
	amx.memDAT[refBonnet] = getVehicleDoorOpenRatio(vehicle, 0) > 0 and 1 or 0
	amx.memDAT[refBoot] = getVehicleDoorOpenRatio(vehicle, 1) > 0 and 1 or 0
	amx.memDAT[refObjective] = g_Vehicles[vehicleID].objective or 0

	return true
end

function SetVehicleParamsEx(amx, vehicle, engine, lights, alarm, doors, bonnet, boot, objective)
	setVehicleEngineState(vehicle, engine)
	setVehicleOverrideLights(vehicle, lights and 2 or 1)
	-- TODO: Implement alarm
	setVehicleLocked(vehicle, doors)
	setVehicleDoorOpenRatio(vehicle, 0, bonnet and 1 or 0) -- bonnet
	setVehicleDoorOpenRatio(vehicle, 1, boot and 1 or 0) -- boot

	for i, playerdata in pairs(g_Players) do
		clientCall(playerdata.elem, 'SetVehicleParamsForPlayer', vehicle, objective, doors)
	end

	local vehicleID = getElemID(vehicle)
	g_Vehicles[vehicleID].alarm = alarm
	g_Vehicles[vehicleID].objective = objective
	g_Vehicles[vehicleID].engineState = engine
	return true
end
-- Siren

function GetVehicleParamsSirenState(amx, vehicle)
	local sirenParams = getVehicleSirenParams(vehicle)

	-- in SA-MP this native returns 3 states
	-- 1 - siren on
	-- 0 - siren off
	-- -1 - siren not exist, but we never get it.
	if (sirenParams.SirenCount > 0) then
		return 1
	else
		return 0
	end
end

function GetVehicleParamsCarDoors(amx, vehicle, refDriver, refPassenger, refBackLeft, refBackRight)
	amx.memDAT[refDriver] = getVehicleDoorOpenRatio(vehicle, 2) > 0
	amx.memDAT[refPassenger] = getVehicleDoorOpenRatio(vehicle, 3) > 0
	amx.memDAT[refBackLeft] = getVehicleDoorOpenRatio(vehicle, 4) > 0
	amx.memDAT[refBackRight] = getVehicleDoorOpenRatio(vehicle, 5) > 0
	return true
end

function SetVehicleParamsCarDoors(amx, vehicle, driver, passenger, backLeft, backRight)
	setVehicleDoorOpenRatio(vehicle, 2, driver and 1 or 0) -- bonnet
	setVehicleDoorOpenRatio(vehicle, 3, passenger and 1 or 0) -- bonnet
	setVehicleDoorOpenRatio(vehicle, 4, backLeft and 1 or 0) -- bonnet
	setVehicleDoorOpenRatio(vehicle, 5, backRight and 1 or 0) -- bonnet
	return true
end

function GetVehicleParamsCarWindows(amx, vehicle, frontLeft, frontRight, rearLeft, rearRight)
	notImplemented('GetVehicleParamsCarWindows')
	return false
end

function SetVehicleParamsCarWindows(amx, vehicle, frontLeft, frontRight, rearLeft, rearRight)
	notImplemented('SetVehicleParamsCarWindows')
	return false
end

function SetVehicleToRespawn(amx, vehicle)
	return respawnStaticVehicle(vehicle)
end

function LinkVehicleToInterior(amx, vehicle, interior)
	return setElementInterior(vehicle, interior)
end

function AddVehicleComponent(amx, vehicle, upgradeID)
	return addVehicleUpgrade(vehicle, upgradeID)
end

function RemoveVehicleComponent(amx, vehicle, upgradeID)
	return removeVehicleUpgrade(vehicle, upgradeID)
end

function ChangeVehicleColor(amx, vehicle, color1, color2)
	return setVehicleColorClamped(vehicle, color1, color2)
end

function setVehicleColorClamped(vehicle, color1, color2)
	color1 = clamp(color1, 0, 126)
	color2 = clamp(color2, 0, 126)
	return setVehicleColor(vehicle, color1, color2, 0, 0)
end

function ChangeVehiclePaintjob(amx, vehicle, paintjob)
	return setVehiclePaintjob(vehicle, paintjob)
end

function SetVehicleHealth(amx, vehicle, health)
	return setElementHealth(vehicle, health)
end

function GetVehicleHealth(amx, vehicle, refHealth)
	if not vehicle then
		return false
	end
	writeMemFloat(amx, refHealth, getElementHealth(vehicle))
	return true
end

function AttachTrailerToVehicle(amx, trailer, vehicle)
	return attachTrailerToVehicle(vehicle, trailer)
end

function DetachTrailerFromVehicle(amx, puller)
	return detachTrailerFromVehicle(puller)
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
	return setVehiclePlateText(vehicle, plate)
end

-- GetVehicleModelDummyPosition doesn't fit
function GetVehicleModelInfo(amx, model, type, refX, refY, refZ)
	if model < 400 or model > 611 then
		return false
	end

	local index = model - 400 + 1
	if not Vehicle_ModelInfo[index] then
		return false
	end

	local offsets = {
		[1] = {start = 1,  count = 3},  -- VEHICLE_MODEL_INFO_SIZE
		[2] = {start = 4,  count = 3},  -- VEHICLE_MODEL_INFO_FRONTSEAT
		[3] = {start = 7,  count = 3},  -- VEHICLE_MODEL_INFO_REARSEAT
		[4] = {start = 10, count = 3},  -- VEHICLE_MODEL_INFO_PETROLCAP
		[5] = {start = 13, count = 3},  -- VEHICLE_MODEL_INFO_WHEELSFRONT
		[6] = {start = 16, count = 3},  -- VEHICLE_MODEL_INFO_WHEELSREAR
		[7] = {start = 19, count = 3},  -- VEHICLE_MODEL_INFO_WHEELSMID
		[8] = {start = 22, count = 1},  -- VEHICLE_MODEL_INFO_FRONT_BUMPER_Z
		[9] = {start = 25, count = 1}   -- VEHICLE_MODEL_INFO_REAR_BUMPER_Z
	}

	local spec = offsets[type]
	if not spec then return false end

	local values = {}
	for i = spec.start, spec.start + spec.count - 1 do
		values[#values + 1] = Vehicle_ModelInfo[index][i] or 0.0
	end

	writeMemFloat(amx, refX, values[1])
	if spec.count >= 2 then writeMemFloat(amx, refY, values[2]) end
	if spec.count >= 3 then writeMemFloat(amx, refZ, values[3]) end
	return true
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
	local componentName = getVehicleUpgradeSlotName(componentid)

	local componentId = components[componentName]
	if tonumber(componentId) ~= nil then
		return componentId
	else
		return -1
	end
end

function RepairVehicle(amx, vehicle)
	return fixVehicle(vehicle)
end

function GetVehicleVelocity(amx, vehicle, refVX, refVY, refVZ)
	if not vehicle then
		return false
	end
	local vx, vy, vz = getElementVelocity(vehicle)
	writeMemFloat(amx, refVX, vx)
	writeMemFloat(amx, refVY, vy)
	writeMemFloat(amx, refVZ, vz)
	return true
end

function SetVehicleVelocity(amx, vehicle, vx, vy, vz)
	return setElementVelocity(vehicle, vx, vy, vz)
end

function SetVehicleAngularVelocity(amx, vehicle, vx, vy, vz)
	return setElementAngularVelocity(vehicle, vx, vy, vz)
end

function GetVehicleDamageStatus(amx, vehicle, refPanels, refDoors, refLights, refTires)
	local panelsState = getVehiclePanelState(vehicle, 0)
	panelsState = bitOr(panelsState, bitLShift(getVehiclePanelState(vehicle, 1), 4))
	panelsState = bitOr(panelsState, bitLShift(getVehiclePanelState(vehicle, 2), 8))
	panelsState = bitOr(panelsState, bitLShift(getVehiclePanelState(vehicle, 3), 12))
	panelsState = bitOr(panelsState, bitLShift(getVehiclePanelState(vehicle, 4), 16))
	panelsState = bitOr(panelsState, bitLShift(getVehiclePanelState(vehicle, 5), 20))
	panelsState = bitOr(panelsState, bitLShift(getVehiclePanelState(vehicle, 6), 24))

	local doorsState = getVehicleDoorState(vehicle, 0)
	doorsState = bitOr(doorsState, bitLShift(getVehicleDoorState(vehicle, 1), 8))
	doorsState = bitOr(doorsState, bitLShift(getVehicleDoorState(vehicle, 2), 16))
	doorsState = bitOr(doorsState, bitLShift(getVehicleDoorState(vehicle, 3), 24))

	local lightsState = getVehicleLightState(vehicle, 0)
	lightsState = bitOr(lightsState, bitLShift(getVehicleLightState(vehicle, 1), 2))
	lightsState = bitOr(lightsState, bitLShift(getVehicleLightState(vehicle, 2), 4))
	lightsState = bitOr(lightsState, bitLShift(getVehicleLightState(vehicle, 3), 6))

	local frontLeft, rearLeft, frontRight, rearRight = getVehicleWheelStates(vehicle)
	local tiresState = bitOr(rearRight, bitOr(bitLShift(frontRight, 1), bitOr(bitLShift(rearLeft, 2), bitLShift(frontLeft, 3))))

	amx.memDAT[refPanels] = panelsState
	amx.memDAT[refDoors] = doorsState
	amx.memDAT[refLights] = lightsState
	amx.memDAT[refTires] = tiresState

	return true
end

function UpdateVehicleDamageStatus(amx, vehicle, panels, doors, lights, tires)
	setVehiclePanelState(vehicle, 0, bitAnd(panels, 15))
	setVehiclePanelState(vehicle, 1, bitAnd(bitRShift(panels, 4), 15))
	setVehiclePanelState(vehicle, 2, bitAnd(bitRShift(panels, 8), 15))
	setVehiclePanelState(vehicle, 3, bitAnd(bitRShift(panels, 12), 15))
	setVehiclePanelState(vehicle, 4, bitAnd(bitRShift(panels, 16), 15))
	setVehiclePanelState(vehicle, 5, bitAnd(bitRShift(panels, 20), 15))
	setVehiclePanelState(vehicle, 6, bitAnd(bitRShift(panels, 24), 15))

	setVehicleDoorState(vehicle, 0, bitAnd(panels, 7))
	setVehicleDoorState(vehicle, 1, bitAnd(bitRShift(panels, 8), 7))
	setVehicleDoorState(vehicle, 2, bitAnd(bitRShift(panels, 16), 7))
	setVehicleDoorState(vehicle, 3, bitAnd(bitRShift(panels, 24), 7))

	setVehicleLightState(vehicle, 0, bitAnd(lights, 1))
	setVehicleLightState(vehicle, 2, bitAnd(bitRShift(lights, 2), 1))
	setVehicleLightState(vehicle, 3, bitAnd(bitRShift(lights, 4), 1))
	setVehicleLightState(vehicle, 4, bitAnd(bitRShift(lights, 6), 1))

	setVehicleWheelStates(vehicle, bitAnd(bitRShift(tires, 3), 1), bitAnd(bitRShift(tires, 2), 1), bitAnd(bitRShift(tires, 1), 1), bitAnd(tires, 1))

	return true
end

function SetVehicleVirtualWorld(amx, vehicle, dimension)
	return setElementDimension(vehicle, dimension)
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
