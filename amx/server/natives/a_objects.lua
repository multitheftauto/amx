function CreateObject(amx, model, x, y, z, rX, rY, rZ)
	local obj = createObject(model, x, y, z, rX, rY, rZ)
	if obj == false then
		obj = createObject(1337, x, y, z, rX, rY, rZ) --Create a dummy object anyway since createobject can also be used to make camera attachments
		setElementAlpha(obj, 0)
		setElementCollisionsEnabled(obj, false)
		outputDebugString(string.format("[MTA AMX - WARNING]: The provided model id (%d) is invalid (the model was replaced with id 1337, is now invisible and non-collidable), some object ids are not supported, consider updating your scripts.", model))
	end
	return addElem(g_Objects, obj)
end

-- TODO: AttachObjectToVehicle dummy
function AttachObjectToVehicle(amx)
	notImplemented('AttachObjectToVehicle')
end

function AttachObjectToObject(amx)
	notImplemented('AttachObjectToObject')
end

function AttachObjectToPlayer(amx, object, player, offsetX, offsetY, offsetZ, rX, rY, rZ)
	attachElements(object, player, offsetX, offsetY, offsetZ, rX, rY, rZ)
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

function SetObjectRot(amx, object, rX, rY, rY)
	setObjectRotation(object, rX, rY, rZ)
end

function GetObjectModel(amx, objID)
	if g_Objects[objID] ~= nil then
		return getElementModel(g_Objects[objID])
	end
	return -1
end

function SetObjectNoCameraCol(amx)
	notImplemented('SetObjectNoCameraCol')
end

function IsValidObject(amx, objID)
	return g_Objects[objID] ~= nil
end

function DestroyObject(amx, object)
	removeElem(g_Objects, object)
	destroyElement(object)
end

function MoveObject(amx, object, x, y, z, speed)
	local distance = getDistanceBetweenPoints3D(x, y, z, getElementPosition(object))
	local time = distance/speed*1000
	moveObject(object, time, x, y, z, 0, 0, 0)
	setTimer(procCallOnAll, time, 1, 'OnObjectMoved', getElemID(object))
end

function StopObject(amx, object)
	stopObject(object)
end

function IsObjectMoving(amx)
	notImplemented('IsObjectMoving')
end

function CreatePlayerObject(amx, player, model, x, y, z, rX, rY, rZ)
	if not g_PlayerObjects[player] then
		g_PlayerObjects[player] = {}
	end
	local objID = table.insert(g_PlayerObjects[player], { x = x, y = y, z = z, rx = rX, ry = rY, rz = rZ })
	clientCall(player, 'CreatePlayerObject', objID, model, x, y, z, rX, rY, rZ)
	return objID
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

function GetPlayerObjectModel(amx, player, object)
	notImplemented('GetPlayerObjectModel')
end


function IsValidPlayerObject(amx, player, objID)
	return g_PlayerObjects[player] and g_PlayerObjects[player][objID] and true
end

function DestroyPlayerObject(amx, player, objID)
	g_PlayerObjects[player][objID] = nil
	clientCall(player, 'DestroyPlayerObject', objID)
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


function SetObjectMaterialText(amx)
	notImplemented('SetObjectMaterialText')
end
-- AttachPlayerObjectToPlayer client


function SetObjectsDefaultCameraCol(amx, disable)
	notImplemented('SetObjectsDefaultCameraCol')
end

function EditPlayerObject(amx, player, object)
	notImplemented('EditPlayerObject')
end

function SetObjectMaterial(amx)
	notImplemented('SetObjectMaterial')
end

function SendClientCheck(amx)
	notImplemented('SendClientCheck')
end

function SetPlayerObjectMaterial(amx)
	notImplemented('SetPlayerObjectMaterial')
end

function EditPlayerObject(amx)
	notImplemented('EditPlayerObject')
end
