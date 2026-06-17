function CreateActor(amx, model, x, y, z, rotation)
	local actor = createPed(g_SkinReplace[model] or model, x, y, z, rotation, false)
	addPedClothes(actor, 'vest', 'vest', 0)
	setElementData(actor, 'ActorPed', true)
	setElementData(actor, 'Invulnerable', true)
	return addElem(g_Actors, actor)
end

function DestroyActor(amx, actor)
	if actor then
		local actorID = getElemID(actor)
		for i, playerdata in pairs(g_Players) do
			if playerdata.streamedActors[actorID] then
				playerdata.streamedActors[actorID] = nil
				procCallOnAll('OnActorStreamOut', actorID, i)
			end
		end
		removeElem(g_Actors, actor)
		destroyElement(actor)
	end
	return true
end

function IsActorStreamedIn(amx, actor, player)
	return g_Players[getElemID(player)].streamedActors[getElemID(actor)] == true
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

function SetActorPos(amx, actor, x, y, z)
	return setElementPosition(actor, x, y, z)
end

function SetActorFacingAngle(amx, actor, angle)
	local rotX, rotY, rotZ = getElementRotation(actor)
	return setElementRotation(actor, rotX, rotY, angle, 'default', true)
end

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

function IsValidActor(amx, actorID)
	return g_Actors[actorID] ~= nil
end

function GetActorPoolSize(amx)
	local highestID = 0
	for id, v in pairs(g_Actors) do
		if id > highestID then
			highestID = id
		end
	end
	return highestID
end

function GetPlayerCameraTargetActor(amx, player)
	notImplemented('GetPlayerCameraTargetActor')
	return INVALID_ACTOR_ID
end

GetActorHealth = GetPlayerHealth
SetActorHealth = SetPlayerHealth
GetActorVirtualWorld = GetPlayerVirtualWorld
SetActorVirtualWorld = SetPlayerVirtualWorld
GetActorFacingAngle = GetPlayerFacingAngle
GetActorPos = GetVehiclePos
