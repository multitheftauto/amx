function CreateActor(amx, model, x, y, z, rotation)
	local actor = createPed(model, x, y, z, rotation, false)
	setElementData(actor, 'amx.actorped', true)
	setElementData(actor, 'amx.invulnerable', true)
	return addElem(g_Actors, actor)
end

function DestroyActor(amx, actor)
	for i, playerdata in pairs(g_Players) do
		playerdata.streamedActors[getElemID(actor)] = nil
	end

	removeElem(g_Actors, actor)
	destroyElement(actor)
	return true
end

function IsActorStreamedIn(amx, actorId, player)
	return g_Players[getElemID(player)].streamedActors[actorId] ~= nil
end

function ApplyActorAnimation(amx, actor, animlib, animname, fDelta, loop, lockx, locky, freeze, time)
	setPedAnimation(actor, animlib, animname, time, loop, lockx or locky, false, freeze)
	setPedAnimationSpeed(actor, animname, fDelta)
	return true
end

function ClearActorAnimations(amx, actor)
	return setPedAnimation(actor, false)
end

function SetActorFacingAngle(amx, actor, ang)
	local rotX, rotY, rotZ = getElementRotation(actor) -- get the local players's rotation
	return setElementRotation(actor, rotX, rotY, ang, "default", true) -- turn the player 10 degrees clockwise
end

function GetActorFacingAngle(amx, actor, refAng)
	if not actor then
		return false
	end
	local rX, rY, rZ = getElementRotation(actor)
	writeMemFloat(amx, refAng, rZ)
	return true
end

function GetActorPos(amx, actor, refX, refY, refZ)
	if not actor then
		return false
	end
	local x, y, z = getElementPosition(actor)
	writeMemFloat(amx, refX, x)
	writeMemFloat(amx, refY, y)
	writeMemFloat(amx, refZ, z)
	return true
end

function SetActorInvulnerable(amx, actor, invulnerable)
	if not actor then
		return false
	end
	setElementData(actor, 'amx.invulnerable', invulnerable)
	return true
end

function IsActorInvulnerable(amx, actor)
	return getElementData(actor, 'amx.invulnerable')
end

function IsValidActor(amx, actorId)
	return g_Actors[actorId] ~= nil
end

GetActorHealth = GetPlayerHealth
GetActorVirtualWorld = GetPlayerVirtualWorld

function GetActorPoolSize(amx)
	local highestId = 0
	for id, v in pairs(g_Actors) do
		if id > highestId then
			highestId = id
		end
	end
	return highestId
end

SetActorHealth = SetPlayerHealth
SetActorVirtualWorld = SetPlayerVirtualWorld

function SetActorPos(amx, actor, x, y, z)
	return setElementPosition(actor, x, y, z)
end

function GetPlayerCameraTargetActor(amx, player)
	notImplemented('GetPlayerCameraTargetActor')
	return INVALID_ACTOR_ID
end
