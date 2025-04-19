function CreateObject(amx, model, x, y, z, rX, rY, rZ)
	local obj = createObject(model, x, y, z, rX, rY, rZ)
	if obj == false then
		obj = createObject(1337, x, y, z, rX, rY, rZ) -- Create a dummy object anyway since createobject can also be used to make camera attachments
		setElementAlpha(obj, 0)
		setElementCollisionsEnabled(obj, false)
		outputDebugString(string.format("[MTA AMX - WARNING]: Invalid model id %d (replaced with invisible and non-collidable), some object ids are not supported, consider updating your scripts", model))
	end
	return addElem(g_Objects, obj)
end

function AttachObjectToVehicle(amx, object, vehicle, offsetX, offsetY, offsetZ, rX, rY, rZ)
	return attachElements(object, vehicle, offsetX, offsetY, offsetZ, rX, rY, rZ)
end

function AttachObjectToObject(amx, object, attachtoid, offsetX, offsetY, offsetZ, rX, rY, rZ, syncRotation)
	return attachElements(object, attachtoid, offsetX, offsetY, offsetZ, rX, rY, rZ)
end

function AttachObjectToPlayer(amx, object, player, offsetX, offsetY, offsetZ, rX, rY, rZ)
	return attachElements(object, player, offsetX, offsetY, offsetZ, rX, rY, rZ)
end

function SetObjectPos(amx, object, x, y, z)
	return setElementPosition(object, x, y, z)
end

function GetObjectPos(amx, object, refX, refY, refZ)
	if not object then
		return false
	end
	local x, y, z = getElementPosition(object)
	writeMemFloat(amx, refX, x)
	writeMemFloat(amx, refY, y)
	writeMemFloat(amx, refZ, z)
	return true
end

function GetObjectRot(amx, object, refX, refY, refZ)
	if not object then
		return false
	end
	local rX, rY, rZ = getObjectRotation(object)
	writeMemFloat(amx, refX, rX)
	writeMemFloat(amx, refY, rY)
	writeMemFloat(amx, refZ, rZ)
	return true
end

function SetObjectRot(amx, object, rX, rY, rZ)
	if object then
		setObjectRotation(object, rX, rY, rZ)
	end
	return true
end

function GetObjectModel(amx, object)
	if object then
		return getElementModel(object)
	end
	return -1
end

function SetObjectNoCameraCol(amx, object)
	notImplemented('SetObjectNoCameraCol')
	return false
end

function IsValidObject(amx, objID)
	return g_Objects[objID] ~= nil
end

function DestroyObject(amx, object)
	if object then
		removeElem(g_Objects, object)
		destroyElement(object)
	end
	return true
end

function MoveObject(amx, object, x, y, z, speed, rX, rY, rZ)
	if not object then
		return 0
	end

	local distance = getDistanceBetweenPoints3D(x, y, z, getElementPosition(object))
	local time = distance / speed * 1000

	-- We need relative rotation
	local cRotX, cRotY, cRotZ = getElementRotation(object)
	cRotX = cRotX - rX
	cRotY = cRotY - rY
	cRotZ = cRotZ - rZ

	-- -1000 or less means no rotation change, so set it to 0.0
	if rX <= -1000.0 then cRotX = 0.0 end
	if rY <= -1000.0 then cRotY = 0.0 end
	if rZ <= -1000.0 then cRotZ = 0.0 end

	moveObject(object, time, x, y, z, cRotX, cRotY, cRotZ)
	setTimer(procCallOnAll, time, 1, 'OnObjectMoved', getElemID(object))
	return math.floor(time)
end

function StopObject(amx, object)
	return stopObject(object)
end

function IsObjectMoving(amx, object)
	return isObjectMoving(object)
end

function CreatePlayerObject(amx, player, model, x, y, z, rX, rY, rZ)
	if not g_PlayerObjects[player] then
		g_PlayerObjects[player] = {}
	end
	local objID = table.insert(g_PlayerObjects[player], {
		model = model,
		x = x, y = y, z = z,
		rx = rX, ry = rY, rz = rZ
	})
	clientCall(player, 'CreatePlayerObject', objID, model, x, y, z, rX, rY, rZ)
	return objID
end

function SetPlayerObjectPos(amx, player, objID, x, y, z)
	local obj = g_PlayerObjects[player] and g_PlayerObjects[player][objID]
	if not obj then
		return false
	end
	obj.x, obj.y, obj.z = x, y, z
	clientCall(player, 'SetPlayerObjectPos', objID, x, y, z)
	return true
end

function SetPlayerObjectRot(amx, player, objID, rX, rY, rZ)
	local obj = g_PlayerObjects[player] and g_PlayerObjects[player][objID]
	if not obj then
		return false
	end
	obj.rx, obj.ry, obj.rz = rX, rY, rZ
	clientCall(player, 'SetPlayerObjectRot', objID, rX, rY, rZ)
	return true
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
			local factor = (curtick - obj.moving.starttick) / obj.moving.duration
			x = obj.x + (obj.moving.x - obj.x) * factor
			y = obj.y + (obj.moving.y - obj.y) * factor
			z = obj.z + (obj.moving.z - obj.z) * factor
		end
	else
		x, y, z = obj.x, obj.y, obj.z
	end
	return x, y, z
end

function GetPlayerObjectPos(amx, player, objID, refX, refY, refZ)
	local x, y, z = getPlayerObjectPos(amx, player, objID)
	if not x then
		return false
	end
	writeMemFloat(amx, refX, x)
	writeMemFloat(amx, refY, y)
	writeMemFloat(amx, refZ, z)
	return true
end

function GetPlayerObjectRot(amx, player, objID, refX, refY, refZ)
	local obj = g_PlayerObjects[player] and g_PlayerObjects[player][objID]
	if not obj then
		return false
	end
	writeMemFloat(amx, refX, obj.rx)
	writeMemFloat(amx, refY, obj.ry)
	writeMemFloat(amx, refZ, obj.rz)
	return true
end

function GetPlayerObjectModel(amx, player, objID)
	if not player then return 0 end

	local obj = g_PlayerObjects[player] and g_PlayerObjects[player][objID]
	if not obj then return -1 end

	return g_PlayerObjects[player][objID].model
end

function SetPlayerObjectNoCameraCol(amx, player, objID)
	notImplemented('SetPlayerObjectNoCameraCol')
	return false
end

function IsValidPlayerObject(amx, player, objID)
	return g_PlayerObjects[player] and g_PlayerObjects[player][objID] and true
end

function DestroyPlayerObject(amx, player, objID)
	if g_PlayerObjects[player] and g_PlayerObjects[player][objID] then
		g_PlayerObjects[player][objID] = nil
		clientCall(player, 'DestroyPlayerObject', objID)
	end
	return true
end

function MovePlayerObject(amx, player, objID, x, y, z, speed, rX, rY, rZ)
	local obj = g_PlayerObjects[player] and g_PlayerObjects[player][objID]
	if not obj then
		return 0
	end
	local distance = getDistanceBetweenPoints3D(x, y, z, getPlayerObjectPos(amx, player, objID))
	local duration = distance / speed * 1000
	if obj.moving and isTimer(obj.moving.timer) then
		killTimer(obj.moving.timer)
	end
	local timer = setTimer(procCallOnAll, duration, 1, 'OnPlayerObjectMoved', getElemID(player), objID)
	obj.moving = { x = x, y = y, z = z, starttick = getTickCount(), duration = duration, timer = timer }
	clientCall(player, 'MovePlayerObject', objID, x, y, z, speed, rX, rY, rZ)
	return math.floor(duration)
end

function StopPlayerObject(amx, player, objID)
	local obj = g_PlayerObjects[player] and g_PlayerObjects[player][objID]
	if not obj then
		return false
	end
	if obj.moving then
		obj.x, obj.y, obj.z = getPlayerObjectPos(amx, player, objID)
		if isTimer(obj.moving.timer) then
			killTimer(obj.moving.timer)
		end
		obj.moving = nil
	end
	clientCall(player, 'StopPlayerObject', objID)
	return true
end

function IsPlayerObjectMoving(amx, player, objID)
	local obj = g_PlayerObjects[player] and g_PlayerObjects[player][objID]
	if not obj or not obj.moving then
		return false
	end
	return true
end

function SetObjectMaterialText(amx, object)
	notImplemented('SetObjectMaterialText')
	return false
end

function SetPlayerObjectMaterialText(amx, player)
	notImplemented('SetPlayerObjectMaterialText')
	return false
end

-- AttachPlayerObjectToPlayer client
-- AttachPlayerObjectToVehicle client

function SetObjectsDefaultCameraCol(amx, disable)
	notImplemented('SetObjectsDefaultCameraCol')
	return false
end

function EditPlayerObject(amx, player, object)
	notImplemented('EditPlayerObject')
	return false
end

function SetObjectMaterial(amx, object)
	notImplemented('SetObjectMaterial')
	return false
end

function SetPlayerObjectMaterial(amx, player)
	notImplemented('SetPlayerObjectMaterial')
	return false
end