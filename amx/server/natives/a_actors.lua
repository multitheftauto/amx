function CreateActor(amx, model, x, y, z, rotation)
	local actor = createPed(g_SkinReplace[model] or model, x, y, z, rotation, false)
	addPedClothes(actor, 'vest', 'vest', 0)
	setElementData(actor, 'ActorPed', true)
	setElementData(actor, 'Invulnerable', true)
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
	-- time = Timer in ms. For a never-ending loop it should be 0.
	if time == 0 then
		loop = true
	end
	setPedAnimation(actor, animlib, animname, time, loop, lockx or locky, false, freeze)
	setPedAnimationSpeed(actor, animname, fDelta)
	return true
end

function ClearActorAnimations(amx, actor)
	return setPedAnimation(actor, false)
end

function SetActorFacingAngle(amx, actor, angle)
	local rotX, rotY, rotZ = getElementRotation(actor)
	return setElementRotation(actor, rotX, rotY, angle, 'default', true)
end

GetActorFacingAngle = GetPlayerFacingAngle
GetActorPos = GetPlayerPos

function SetActorInvulnerable(amx, actor, invulnerable)
	if not actor then
		return false
	end
	setElementData(actor, 'Invulnerable', invulnerable)
	return true
end

function IsActorInvulnerable(amx, actor)
	return getElementData(actor, 'Invulnerable')
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
