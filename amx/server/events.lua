-------------------------------
-- Players

function gameModeInit(player)
	clientCall(player, 'gamemodeLoad')
	local playerID = getElemID(player)
	local playerData = g_Players[playerID]
	for k, v in pairs(playerData) do
		if k ~= 'elem' and k ~= 'keys' and k ~= 'blip' then
			playerData[k] = nil
		end
	end
	setPlayerMoney(player, 0)
	takeAllWeapons(player)
	setElementInterior(player, 0)
	setElementDimension(player, 0)
	setPedStat(player, 22, 999) -- stamina
	setPedStat(player, 225, 999) -- underwater stamina
	for i = 69, 79 do setPedStat(player, i, 999) end -- weapon skills
	setPedStat(player, 160, 999) -- driving skill
	setPedStat(player, 229, 999) -- bike skill
	setPedStat(player, 230, 999) -- cycle skill
	addPedClothes(player, 'vest', 'vest', 0)
	setPlayerHudComponentVisible(player, 'area_name', g_ShowZoneNames)
	setPlayerHudComponentVisible(player, 'vehicle_name', false) -- SA-MP doesn't show vehicle names when entering vehicles
	setPlayerHudComponentVisible(player, 'radar', false)
	setPlayerNametagShowing(player, false)
	local r, g, b = math.random(50, 255), math.random(50, 255), math.random(50, 255)
	ShowPlayerMarker(nil, player, g_PlayerMarkersMode)
	SetPlayerColor(nil, player, r, g, b)
	setElementData(player, 'Score', 0)
	toggleAllControls(player, false, true, false)
	clientCall(player, 'showIntroScene')
	clientCall(player, 'TogglePlayerClock', false)
	clientCall(player, 'updateFriendlyFire', g_FriendlyFire)
	clientCall(player, 'updateNameTagGlobals', {
		status = g_ShowNameTags,
		radius = g_NameTagsRadius,
		los = g_NameTagsLOS
	})
	g_Players[playerID].pvars = {}
	g_Players[playerID].streamedActors = {}
	g_Players[playerID].streamedVehicles = {}
	g_Players[playerID].streamedPlayers = {}
	g_Players[playerID].attachedObjects = {}
	g_Players[playerID].streamedBots = {}
	g_Players[playerID].shotVect = {
		oX = 0.0, oY = 0.0, oZ = 0.0,
		hX = 0.0, hY = 0.0, hZ = 0.0
	}
	g_Players[playerID].conntick = getTickCount()
	g_Players[playerID].specialaction = SPECIAL_ACTION_NONE
	g_Players[playerID].viewingintro = true
	g_Players[playerID].state = PLAYER_STATE_NONE
	g_Players[playerID].doingclasssel = nil

	fadeCamera(player, true)
	setTimer(
		function()
			if not isElement(player) or getElementType(player) ~= 'player' then
				return
			end

			-- Don't draw the class selection UI if we're not initializing
			if g_Players[playerID].state ~= PLAYER_STATE_NONE then
				return
			end

			if procCallOnAll('OnPlayerRequestClass', playerID, 0) then
				putPlayerInClassSelection(player)
			else
				outputDebugString('Not allowed to select a class', 1)
				g_Players[playerID].doingclasssel = true
			end
		end,
		5000,
		1
	)
end

function joinHandler(player)
	local playerJoined = not player
	if playerJoined then
		player = source
	end

	local playerID = addElem(g_Players, player)
	setElementData(player, 'ID', playerID)

	clientCall(player, 'setAMXVersion', amxVersionString())

	-- Keybinds
	bindKey(player, 'F4', 'down', 'changeclass')
	bindKey(player, 'enter_exit', 'down', resetSpecialAction)
	g_Players[playerID].keys = {}
	local function bindControls(player, t)
		for samp, mta in pairs(t) do
			bindKey(player, mta, 'down', keyStateChange)
			bindKey(player, mta, 'up', keyStateChange)
		end
	end
	bindControls(player, g_KeyMapping)
	bindControls(player, g_LeftRightMapping)
	bindControls(player, g_UpDownMapping)
	for k, v in ipairs(g_Keys) do
		bindKey(player, v, 'both', mtaKeyStateChange)
	end

	if playerJoined then
		if getRunningGameMode() then
			gameModeInit(player)
		end
		if isWeaponSyncingNeeded() then
			clientCall(player, 'enableWeaponSyncing', true)
		end

		-- send menus
		for i, menu in pairs(g_Menus) do
			clientCall(player, 'CreateMenu', i, menu)
		end

		-- send textdraws
		for id, textdraw in pairs(g_TextDraws) do
			clientCall(player, 'TextDrawCreate', id, table.deshadowize(textdraw, true))
		end

		-- send 3d text labels
		for i, label in pairs(g_TextLabels) do
			clientCall(player, 'Create3DTextLabel', i, label)
		end

		procCallOnAll('OnPlayerConnect', playerID)
	end
end
addEventHandler('onPlayerJoin', root, joinHandler)

function classSelKey(player)
	local playerID = getElemID(player)
	if g_Players[playerID].returntoclasssel then return end

	clientCall(player, 'displayFadingMessage', 'Returning to class selection after next death', 136, 140, 68)
	outputChatBox('* Returning to class selection after next death', player, 136, 170, 98)
	g_Players[playerID].returntoclasssel = true
end
addCommandHandler('changeclass', classSelKey)

function keyStateChange(player, key, state)
	local id = getElemID(player)
	g_Players[id].keys[key] = (state == 'down')
	if g_KeyMapping[key] then
		local oldState = g_Players[id].keys.old or 0
		local newState = buildKeyState(player, g_KeyMapping)
		g_Players[id].keys.old = newState
		procCallOnAll('OnPlayerKeyStateChange', id, newState, oldState)
	end
end

function mtaKeyStateChange(player, key, state)
	if state == 'up' then
		procCallOnAll('OnPlayerKeyUp', getElemID(player), key)
	elseif state == 'down' then
		procCallOnAll('OnPlayerKeyDown', getElemID(player), key)
	end
end

function buildKeyState(player, t)
	local keys = g_Players[getElemID(player)].keys
	local result = 0
	for samp, mta in pairs(t) do
		if type(mta) == 'table' then
			for i, key in ipairs(mta) do
				if keys[key] then
					result = result + samp
					break
				end
			end
		elseif keys[mta] then
			result = result + samp
		end
	end
	return result
end

function syncPlayerWeapons(player, weapons)
	g_Players[getElemID(player)].weapons = weapons
end

function putPlayerInClassSelection(player)
	if not isElement(player) then
		return
	end
	local playerID = getElemID(player)
	if g_Players[playerID].doingclasssel then
		return
	end

	-- Don't draw the class selection UI if we're spectating
	local state = g_Players[playerID].state
	if state == PLAYER_STATE_SPECTATING then
		return
	end

	setElementFrozen(player, true)
	toggleAllControls(player, false, true, false)
	g_Players[playerID].viewingintro = nil
	g_Players[playerID].doingclasssel = true
	g_Players[playerID].selectedclass = g_Players[playerID].selectedclass or 0
	killPed(player)
	if g_Players[playerID].blip then
		setElementVisibleTo(g_Players[playerID].blip, root, false)
	end
	if isTimer(g_Players[playerID].updatetimer) then
		killTimer(g_Players[playerID].updatetimer)
	end
	g_Players[playerID].updatetimer = nil
	addPedClothes(player, 'vest', 'vest', 0)
	setPlayerHudComponentVisible(player, 'area_name', false)
	setPlayerHudComponentVisible(player, 'radar', false)
	clientCall(player, 'startClassSelection', g_PlayerClasses)
	bindKey(player, 'arrow_l', 'down', requestClass, -1)
	bindKey(player, 'arrow_r', 'down', requestClass, 1)
	bindKey(player, 'lshift', 'down', requestSpawn)
	bindKey(player, 'rshift', 'down', requestSpawn)
	requestClass(player, false, false, 0)
end

function requestClass(player, btn, state, dir)
	if not isElement(player) then
		return
	end
	local playerID = getElemID(player)
	local data = g_Players[playerID]
	if dir > 0 then
		playSoundFrontEnd(player, 6)
	elseif dir < 0 then
		playSoundFrontEnd(player, 14)
	end
	data.selectedclass = data.selectedclass + dir
	if data.selectedclass > #g_PlayerClasses then
		data.selectedclass = 0
	elseif data.selectedclass < 0 then
		data.selectedclass = #g_PlayerClasses
	end
	local skin = 0
	local x, y, z = getElementPosition(player)
	if g_PlayerClasses[0] then
		skin = g_PlayerClasses[data.selectedclass][5]
	end
	if isPedDead(player) then
		spawnPlayer(player, x, y, z, getElementRotation(player), skin, getElementInterior(player), playerID)
	else
		setElementModel(player, skin)
	end
	clientCall(player, 'selectClass', data.selectedclass)
	procCallOnAll('OnPlayerRequestClass', playerID, data.selectedclass)
end

function requestSpawn(player, btn, state)
	local playerID = getElemID(player)
	if procCallOnAll('OnPlayerRequestSpawn', playerID) then
		unbindKey(player, 'arrow_l', 'down', requestClass)
		unbindKey(player, 'arrow_r', 'down', requestClass)
		unbindKey(player, 'lshift', 'down', requestSpawn)
		unbindKey(player, 'rshift', 'down', requestSpawn)
		spawnPlayerBySelectedClass(player)
	end
end

function spawnPlayerBySelectedClass(player, x, y, z, r)
	if not isElement(player) then
		return
	end
	local playerdata = g_Players[getElemID(player)]
	playerdata.viewingintro = nil
	playerdata.doingclasssel = nil
	local spawninfo = playerdata.spawninfo or (g_PlayerClasses and g_PlayerClasses[playerdata.selectedclass])
	if not spawninfo then
		if not g_PlayerClasses[0] then
			spawninfo = {
				0.0, 0.0, 3.1279, 0.0, 0, 0, 0, false,
				weapons = { { -1, 0 }, { -1, 0 }, { -1, 0 } }
			}
		else
			spawninfo = g_PlayerClasses[0]
		end
	end
	if x then
		spawninfo = table.shallowcopy(spawninfo)
		spawninfo[1], spawninfo[2], spawninfo[3], spawninfo[4] = x, y, z, r or spawninfo[4]
	end
	if playerdata.state ~= PLAYER_STATE_WASTED and playerdata.state ~= PLAYER_STATE_NONE then
		playerdata.spawnint = getElementInterior(player)
		playerdata.spawnhealth = getElementHealth(player)
		playerdata.spawnarmor = getPedArmor(player)
	end
	spawnPlayer(player, unpack(spawninfo))
	setPlayerTeam(player, spawninfo[8] or nil)
	for i, weapon in ipairs(spawninfo.weapons) do
		if weapon[1] > 0 then
			giveWeapon(player, weapon[1], weapon[2], true)
		end
	end
	setPedWeaponSlot(player, 0)
	clientCall(player, 'destroyClassSelGUI')
	if playerdata.blip then
		setElementVisibleTo(playerdata.blip, root, true)
	end
end

addEventHandler('onPlayerSpawn', root,
	function()
		local playerID = getElemID(source)

		if g_Players[playerID].doingclasssel then
			return
		end

		setPlayerState(source, PLAYER_STATE_SPAWNED)
		handlePlayerSpawn(source)
	end
)

function handlePlayerSpawn(player)
	local playerID = getElemID(player)
	local playerdata = g_Players[playerID]

	setElementFrozen(player, false)
	toggleAllControls(player, true)
	setElementAlpha(player, 255)
	setElementCollisionsEnabled(player, true)
	setPlayerHudComponentVisible(player, 'area_name', g_ShowZoneNames)
	setPlayerHudComponentVisible(player, 'radar', true)

	if playerdata.spawnint then
		setElementInterior(player, playerdata.spawnint)
		playerdata.spawnint = nil
	end

	if playerdata.spawnhealth then
		setElementHealth(player, playerdata.spawnhealth)
		playerdata.spawnhealth = nil
	end

	if playerdata.spawnarmor then
		setPedArmor(player, playerdata.spawnarmor)
		playerdata.spawnarmor = nil
	end

	-- wanna see CJ in a white singlet?
	addPedClothes(player, 'vest', 'vest', 0)

	if not g_UseCJWalk then
		local skin = getElementModel(player)
		setPedWalkingStyle(player, WalkingStyle[skin] or 0)
	end

	if isTimer(playerdata.updatetimer) then
		killTimer(playerdata.updatetimer)
	end
	playerdata.updatetimer = setTimer(procCallOnAll, 100, 0, 'OnPlayerUpdate', playerID)

	playerdata.vehicle = nil
	playerdata.specialaction = SPECIAL_ACTION_NONE
	setElementData(player, 'SpecialAction', nil)
	playerdata.drunklevel = 0

	procCallOnAll('OnPlayerSpawn', playerID)
	if playerdata.oldint then
		-- manually call delayed callback, originally called while being not spawned
		procCallOnAll('OnPlayerInteriorChange', playerID, getElementInterior(player), playerdata.oldint)
		playerdata.oldint = nil
	end
	setPlayerState(player, PLAYER_STATE_ONFOOT)
end

addEventHandler('onElementInteriorChange', root,
	function(oldInterior, newInterior)
		if getElementType(source) ~= 'player' then return end

		local playerID = getElemID(source)
		local playerdata = g_Players[playerID]

		if playerdata.spawnint then return end

		-- call OnPlayerInteriorChange only if player spawned
		if playerdata.state ~= PLAYER_STATE_WASTED and playerdata.state ~= PLAYER_STATE_NONE then
			procCallOnAll('OnPlayerInteriorChange', playerID, newInterior, oldInterior)
		else -- otherwise make it to be called after onPlayerSpawn event
			-- it's necessary to replicate SA-MP callbacks order
			playerdata.oldint = oldInterior
		end
	end
)

addEventHandler('onPlayerChat', root,
	function(msg, type)
		if type ~= 0 then
			return
		end
		cancelEvent()
		msg = tostring(msg)
		if not procCallOnAll('OnPlayerText', getElemID(source), msg) then
			return
		end

		local r, g, b = getPlayerNametagColor(source)

		if g_GlobalChatRadius then
			local x, y, z = getElementPosition(source)
			for i, data in pairs(g_Players) do
				if getDistanceBetweenPoints3D(x, y, z, getElementPosition(data.elem)) <= g_GlobalChatRadius then
					outputChatBox(getPlayerName(source) .. ':#FFFFFF ' .. msg:gsub('#%x%x%x%x%x%x', ''), data.elem, r, g, b, true)
				end
			end
		else
			outputChatBox(getPlayerName(source) .. ':#FFFFFF ' .. msg:gsub('#%x%x%x%x%x%x', ''), root, r, g, b, true)
		end
	end
)

addEventHandler('onPlayerWeaponSwitch', root,
	function(prev, current)
		procCallOnAll('OnPlayerWeaponSwitch', getElemID(source), current, prev)
	end
)

addEventHandler('onPlayerWeaponReload', root,
	function(weapon, clip, ammo)
		procCallOnAll('OnPlayerWeaponReload', getElemID(source), weapon, clip, ammo)
	end
)

addEvent('onPlayerDamage_Ev', true)
addEventHandler('onPlayerDamage_Ev', root,
	function(opponent, giveTake, loss, weapon, bodypart)
		local playerID, otherID = getElemID(client), getElemID(opponent)
		if not playerID then return end

		local reason
		if g_DamageTypes[weapon] then
			reason = g_DamageTypes[weapon]
		else
			reason = weapon
		end

		if giveTake then
			if not opponent or not g_Players[otherID] or reason > 46 then return end
			setTimer(procCallOnAll, 1, 1, 'OnPlayerGiveDamage', playerID, otherID, float2cell(loss), reason, bodypart)
			-- This needs to be just a bit delayed to arrive after OnPlayerWeaponShot
		else
			if not opponent then otherID = INVALID_PLAYER_ID end
			procCallOnAll('OnPlayerTakeDamage', playerID, otherID, float2cell(loss), reason, bodypart)
		end
	end
)

addEventHandler('onPlayerWasted', root,
	function(ammo, killer, weapon, bodypart)
		local playerID = getElemID(source)
		if g_Players[playerID].doingclasssel then
			return
		end

		local killerID = INVALID_PLAYER_ID
		if killer ~= source and isElement(killer) then
			if getElementType(killer) == 'player' then
				killerID = getElemID(killer)
			elseif getElementType(killer) == 'vehicle' then
				local driver = getVehicleOccupant(killer)

				if driver and getElementType(driver) == 'player' then
					killerID = getElemID(driver)
				end
			end
		end

		local reason
		if g_DamageTypes[weapon] then
			reason = g_DamageTypes[weapon]
		else
			reason = weapon
		end

		setPlayerState(source, PLAYER_STATE_WASTED)
		procCallOnAll('OnPlayerDeath', playerID, killerID, reason)

		if g_Players[playerID].returntoclasssel then
			g_Players[playerID].returntoclasssel = nil
			--setTimer(putPlayerInClassSelection, 3000, 1, source)
			local player = source
			setTimer(
				function()
					if not isElement(player) then return end

					g_Players[playerID].spawninfo = nil

					if procCallOnAll('OnPlayerRequestClass', playerID, 0) then
						putPlayerInClassSelection(player)
					else
						outputDebugString('Not allowed to select a class', 1)
					end
				end, 3000, 1
			)
		else
			setTimer(spawnPlayerBySelectedClass, 3000, 1, source, false)
		end

		g_Players[playerID].spawnint = nil
		g_Players[playerID].spawnhealth = nil
		g_Players[playerID].spawnarmor = nil

		if isTimer(g_Players[playerID].updatetimer) then
			killTimer(g_Players[playerID].updatetimer)
		end
		g_Players[playerID].updatetimer = nil

		g_Players[playerID].vehicle = nil
		g_Players[playerID].specialaction = SPECIAL_ACTION_NONE
		setElementData(source, 'SpecialAction', nil)
		clientCall(source, 'setCameraDrunkLevel', 0)
		g_Players[playerID].drunklevel = 0
	end
)

local quitReasons = {
	Quit = 1,
	Kicked = 2,
	Banned = 2
}
addEventHandler('onPlayerQuit', root,
	function(reason)
		local vehicle = getPedOccupiedVehicle(source)
		if isElement(vehicle) then
			triggerEvent('onVehicleExit', vehicle, source)
		end
		g_PlayerObjects[source] = nil
		g_PlayerTextDraws[source] = nil

		local playerID = getElemID(source)
		procCallOnAll('OnPlayerDisconnect', playerID, quitReasons[reason] or 0)

		for i, playerdata in pairs(g_Players) do
			playerdata.streamedPlayers[playerID] = nil
		end

		if g_Players[playerID].blip then
			destroyElement(g_Players[playerID].blip)
			g_Players[playerID].blip = nil
		end

		if isTimer(g_Players[playerID].updatetimer) then
			killTimer(g_Players[playerID].updatetimer)
		end
		g_Players[playerID] = nil
	end
)

addEventHandler('onResourceStart', resourceRoot,
	function()
		setTimer(checkAndUpdatePlayers, 1000, 0)
	end,
	false
)

--[[ 
	If the player is slapped or the vehicle is destroyed by a command, we need to handle such
	If the player has spawned or has a state of 'none' and they're on foot, we set their state
	Now it's also used for updating players drunk level (decrease it over time)
]]
function checkAndUpdatePlayers()
	if not getRunningGameMode() then
		return
	end

	for i, data in pairs(g_Players) do
		local state = getPlayerState(data.elem)

		if state == PLAYER_STATE_SPAWNED or state == PLAYER_STATE_NONE then
			if not data.doingclasssel and not data.viewingintro then
				handlePlayerSpawn(data.elem)
			end
		elseif state == PLAYER_STATE_DRIVER or state == PLAYER_STATE_PASSENGER then
			if not isPedInVehicle(data.elem) then
				setCameraTarget(data.elem, data.elem)
				setPlayerState(data.elem, PLAYER_STATE_ONFOOT)
				setElementCollisionsEnabled(data.elem, true)
				setElementAlpha(data.elem, 255)
			end
		end

		if g_Players[i].drunklevel and g_Players[i].drunklevel > 0 then
			g_Players[i].drunklevel = g_Players[i].drunklevel - 50
			if g_Players[i].drunklevel < 2250 then
				clientCall(data.elem, 'setCameraDrunkLevel', 0)
			elseif g_Players[i].drunklevel <= 12500 then
				local drunkMul = math.floor(g_Players[i].drunklevel * 0.02)
				clientCall(data.elem, 'setCameraDrunkLevel', drunkMul)
			end
		end
	end

	for i, data in pairs(g_Bots) do
		local state = getBotState(data.elem)

		if state == PLAYER_STATE_DRIVER or state == PLAYER_STATE_PASSENGER then
			if not isPedInVehicle(data.elem) then
				setBotState(data.elem, PLAYER_STATE_ONFOOT)
				setElementCollisionsEnabled(data.elem, true)
				setElementAlpha(data.elem, 255)
			end
		end
	end
end
-------------------------------
-- Vehicles

function respawnStaticVehicle(vehicle)
	if not isElement(vehicle) then
		return false
	end

	local vehID = getElemID(vehicle)
	if not g_Vehicles[vehID] then
		return false
	end

	if isTimer(g_Vehicles[vehID].respawntimer) then
		killTimer(g_Vehicles[vehID].respawntimer)
	end
	g_Vehicles[vehID].respawntimer = nil

	if getVehicleType(vehicle) == 'Train' and getVehicleTowingVehicle(vehicle) then
		-- if it's a train carriage, don't process respawn
		return false
	end

	local occupants = getVehicleOccupants(vehicle)
	if occupants then
		for seat, player in pairs(occupants) do
			removePedFromVehicle(player)
		end
	end

	local spawninfo = g_Vehicles[vehID].spawninfo
	setTimer(
		function()
			if not isElement(vehicle) then return end
			g_Vehicles[vehID].vehicleIsAlive = true

			setElementData(vehicle, 'WindowFrontLeft', true)
			setElementData(vehicle, 'WindowFrontRight', true)
			setElementData(vehicle, 'WindowRearLeft', true)
			setElementData(vehicle, 'WindowRearRight', true)

			SetVehicleParamsEx(nil, vehicle, false, false, false, false, false, false, false)
			setVehicleOverrideLights(vehicle, 0)
			for i = 2, 5 do
				setVehicleDoorOpenRatio(vehicle, i, 0)
			end

			spawnVehicle(vehicle, spawninfo.x, spawninfo.y, spawninfo.z, 0, 0, spawninfo.angle)
			procCallOnAll('OnVehicleSpawn', vehID)
		end, 500, 1
	)
	return true
end

addEventHandler('onVehicleEnter', root,
	function(player, seat, jacked)
		local vehID = getElemID(source)

		if isPed(player) then
			local botID = getElemID(player)
			g_Bots[botID].vehicle = source
			setBotState(player, seat == 0 and PLAYER_STATE_DRIVER or PLAYER_STATE_PASSENGER)
		else
			local playerID = getElemID(player)
			g_Players[playerID].vehicle = source
			setPlayerState(player, seat == 0 and PLAYER_STATE_DRIVER or PLAYER_STATE_PASSENGER)
			resetSpecialAction(player)
		end

		if g_Vehicles[vehID] then
			if isTimer(g_Vehicles[vehID].respawntimer) then
				killTimer(g_Vehicles[vehID].respawntimer)
			end
			g_Vehicles[vehID].respawntimer = nil

			if ManualVehEngineAndLights then
				if getVehicleType(source) ~= 'Plane' and getVehicleType(source) ~= 'Helicopter' then
					setVehicleEngineState(source, g_Vehicles[vehID].engineState)
				end
			end
		end
	end
)

addEventHandler('onVehicleStartEnter', root,
	function(player, seat, jacked)
		local vehID = getElemID(source)
		if not vehID then
			return
		end

		if g_RCVehicles[getElementModel(source)] then
			cancelEvent()
			return
		end

		if isPed(player) then
			local botID = getElemID(player)
			procCallOnAll('OnBotEnterVehicle', botID, vehID, seat ~= 0 and 1 or 0)
		else
			local playerID = getElemID(player)
			procCallOnAll('OnPlayerEnterVehicle', playerID, vehID, seat ~= 0 and 1 or 0)
		end
	end
)

addEventHandler('onVehicleExit', root,
	function(player, seat, jacker)
		local vehID = getElemID(source)

		if isPed(player) then
			local botID = getElemID(player)
			g_Bots[botID].vehicle = nil
			setBotState(player, PLAYER_STATE_ONFOOT)
		else
			local playerID = getElemID(player)
			g_Players[playerID].vehicle = nil
			setPlayerState(player, PLAYER_STATE_ONFOOT)
		end

		if g_RCVehicles[getElementModel(source)] then
			setElementCollisionsEnabled(player, true)
			setElementAlpha(player, 255)
		end

		local occupants = getVehicleOccupants(source)
		local _, occupant = occupants and next(occupants)
		if occupant or getVehicleType(source) == 'Train' then return end

		if g_Vehicles[vehID] and g_Vehicles[vehID].vehicleIsAlive then
			if isTimer(g_Vehicles[vehID].respawntimer) then
				killTimer(g_Vehicles[vehID].respawntimer)
			end
			g_Vehicles[vehID].respawntimer = setTimer(respawnStaticVehicle, g_Vehicles[vehID].respawndelay, 1, source)
		end
	end
)

addEventHandler('onVehicleStartExit', root,
	function(player, seat, jacked, door)
		local vehID = getElemID(source)
		if not vehID then
			return
		end

		if g_RCVehicles[getElementModel(source)] then
			cancelEvent()
			return
		end

		if isPed(player) then
			local botID = getElemID(player)
			procCallOnAll('OnBotExitVehicle', botID, vehID)
		else
			local playerID = getElemID(player)
			procCallOnAll('OnPlayerExitVehicle', playerID, vehID)
		end
	end
)

addEventHandler('onVehicleExplode', root,
	function(withExplosion, player)
		local vehID = getElemID(source)

		-- So the OnVehicleDeath event only gets called once
		if g_Vehicles[vehID] and g_Vehicles[vehID].vehicleIsAlive then
			procCallOnAll('OnVehicleDeath', vehID, getElemID(player))

			if isTimer(g_Vehicles[vehID].respawntimer) then
				killTimer(g_Vehicles[vehID].respawntimer)
			end
			g_Vehicles[vehID].respawntimer = setTimer(respawnStaticVehicle, 10000, 1, source)

			g_Vehicles[vehID].vehicleIsAlive = false
		end
	end
)

addEvent('onVehicleDamageStatusUpdate_Ev', true)
addEventHandler('onVehicleDamageStatusUpdate_Ev', root,
	function(vehicle)
		local playerID, vehID = getElemID(client), getElemID(vehicle)
		if not playerID or not g_Vehicles[vehID] then return end

		procCallOnAll('OnVehicleDamageStatusUpdate', vehID, playerID)
	end
)

addEvent('onPlayerStunt_Ev', true)
addEventHandler('onPlayerStunt_Ev', root,
	function(vehicle, stuntType, stuntTime, stuntDistance)
		local playerID, vehID = getElemID(client), getElemID(vehicle)
		if not playerID or not g_Vehicles[vehID] then return end

		procCallOnAll('OnPlayerStunt', playerID, vehID, stuntType, stuntTime, float2cell(stuntDistance))
	end
)
-------------------------------
-- Bots

addEvent('onBotDamage_Ev', true)
addEventHandler('onBotDamage_Ev', root,
	function(bot, giveTake, loss, weapon, bodypart)
		local playerID, botID = getElemID(client), getElemID(bot)
		if not playerID or not g_Bots[botID] then return end

		local reason
		if g_DamageTypes[weapon] then
			reason = g_DamageTypes[weapon]
		else
			reason = weapon
		end

		if giveTake then
			procCallOnAll('OnBotGiveDamage', botID, playerID, float2cell(loss), reason, bodypart)
		else
			setTimer(procCallOnAll, 1, 1, 'OnBotTakeDamage', botID, playerID, float2cell(loss), reason, bodypart)
			-- This needs to be just a bit delayed to arrive after OnPlayerWeaponShot
		end
	end
)

addEventHandler('onPedWasted', root,
	function(ammo, killer, weapon, bodypart)
		if isPed(source) ~= true then return end
		if getElementData(source, 'ActorPed') then return end

		local killerID = INVALID_PLAYER_ID
		if isElement(killer) then
			if getElementType(killer) == 'player' then
				killerID = getElemID(killer)
			elseif getElementType(killer) == 'vehicle' then
				local driver = getVehicleOccupant(killer)

				if driver and getElementType(driver) == 'player' then
					killerID = getElemID(driver)
				end
			end
		end

		local reason
		if g_DamageTypes[weapon] then
			reason = g_DamageTypes[weapon]
		else
			reason = weapon
		end

		setBotState(source, PLAYER_STATE_WASTED)
		procCallOnAll('OnBotDeath', getElemID(source), killerID, reason, bodypart)
	end
)
-------------------------------
-- Menus

addEvent('onPlayerSelectedMenuRow_Ev', true)
addEventHandler('onPlayerSelectedMenuRow_Ev', root,
	function(selectedRow)
		local playerID = getElemID(client)
		if not playerID then return end

		procCallOnAll('OnPlayerSelectedMenuRow', playerID, selectedRow)
	end
)

addEvent('onPlayerExitedMenu_Ev', true)
addEventHandler('onPlayerExitedMenu_Ev', root,
	function()
		local playerID = getElemID(client)
		if not playerID then return end

		procCallOnAll('OnPlayerExitedMenu', playerID)
	end
)
-------------------------------
-- Checkpoints

addEvent('onPlayerCheckpoint_Ev', true)
addEventHandler('onPlayerCheckpoint_Ev', root,
	function(entered)
		local playerID = getElemID(client)
		if not playerID then return end

		if entered then
			procCallOnAll('OnPlayerEnterCheckpoint', playerID)
		else
			procCallOnAll('OnPlayerLeaveCheckpoint', playerID)
		end
	end
)

addEvent('onPlayerRaceCheckpoint_Ev', true)
addEventHandler('onPlayerRaceCheckpoint_Ev', root,
	function(entered)
		local playerID = getElemID(client)
		if not playerID then return end

		if entered then
			procCallOnAll('OnPlayerEnterRaceCheckpoint', playerID)
		else
			procCallOnAll('OnPlayerLeaveRaceCheckpoint', playerID)
		end
	end
)
-------------------------------
-- Markers

addEventHandler('onMarkerHit', root,
	function(elem, dimension)
		local elemType = getElementType(elem)
		if elemType == 'player' or elemType == 'vehicle' or elemType == 'ped' then
			local elemID = getElemID(elem)

			if elemType == 'ped' then
				if getElementData(elem, 'ActorPed') then
					elemType = 'actor'
				else
					elemType = 'bot'
				end
			end

			procCallOnAll('OnMarkerHit', getElemID(source), elemType, elemID, dimension)
		end
	end
)

addEventHandler('onMarkerLeave', root,
	function(elem, dimension)
		local elemType = getElementType(elem)
		if elemType == 'player' or elemType == 'vehicle' or elemType == 'ped' then
			local elemID = getElemID(elem)

			if elemType == 'ped' then
				if getElementData(elem, 'ActorPed') then
					elemType = 'actor'
				else
					elemType = 'bot'
				end
			end

			procCallOnAll('OnMarkerLeave', getElemID(source), elemType, elemID, dimension)
		end
	end
)
-------------------------------
-- Misc

addEvent('onPlayerWeaponShot_Ev', true)
addEventHandler('onPlayerWeaponShot_Ev', root,
	function(weapon, hitType, hitID, startX, startY, startZ, hitX, hitY, hitZ, offsetX, offsetY, offsetZ)
		local playerID = getElemID(client)
		local playerData = g_Players[playerID]

		if not playerData or not hitID then return end

		playerData.shotVect.oX = startX
		playerData.shotVect.oY = startY
		playerData.shotVect.oZ = startZ
		playerData.shotVect.hX = hitX
		playerData.shotVect.hY = hitY
		playerData.shotVect.hZ = hitZ

		procCallOnAll('OnPlayerWeaponShot', playerID, weapon, hitType, hitID, float2cell(offsetX), float2cell(offsetY), float2cell(offsetZ))
	end
)

addEvent('onPlayerGiveDamageActor_Ev', true)
addEventHandler('onPlayerGiveDamageActor_Ev', root,
	function(actor, loss, weapon, bodypart)
		local playerID, actorID = getElemID(client), getElemID(actor)
		if not playerID or not g_Actors[actorID] then return end

		local reason
		if g_DamageTypes[weapon] then
			reason = g_DamageTypes[weapon]
		else
			reason = weapon
		end

		setTimer(procCallOnAll, 1, 1, 'OnPlayerGiveDamageActor', playerID, actorID, float2cell(loss), reason, bodypart)
		-- This needs to be just a bit delayed to arrive after OnPlayerWeaponShot
	end
)

addEvent('onPlayerPickUpPickup_Ev', true)
addEventHandler('onPlayerPickUpPickup_Ev', root,
	function(pickup)
		local playerID, pickupID = getElemID(client), getElemID(pickup)
		if not playerID or not g_Pickups[pickupID] then return end

		procCallOnAll('OnPlayerPickUpPickup', playerID, pickupID)

		local model = getElementModel(pickup)
		if model == 370 then
			-- Jetpack pickup
			setPedWearingJetpack(client, true)
		end
	end
)

addEvent('onDialogResponse_Ev', true)
addEventHandler('onDialogResponse_Ev', root,
	function(dialogID, response, listItem, inputText)
		local playerID = getElemID(client)
		if not playerID or not dialogID then return end

		procCallOnAll('OnDialogResponse', playerID, dialogID, response, listItem, inputText)
	end
)

addEvent('onPlayerClickMap_Ev', true)
addEventHandler('onPlayerClickMap_Ev', root,
	function(clickX, clickY, clickZ)
		local playerID = getElemID(client)
		if not playerID then return end

		procCallOnAll('OnPlayerClickMap', playerID, float2cell(clickX), float2cell(clickY), float2cell(clickZ))
	end
)

addEvent('onDrunkLevelRequested', true)
addEventHandler('onDrunkLevelRequested', root,
	function()
		local playerdata = g_Players[getElemID(client)]

		-- do not increase it from sprunk or cigar
		if playerdata.specialaction == SPECIAL_ACTION_DRINK_BEER or
		   playerdata.specialaction == SPECIAL_ACTION_DRINK_WINE then
			playerdata.drunklevel = playerdata.drunklevel + 1350
		end
	end
)

addEventHandler('onConsole', root,
	function(cmd)
		cmd = '/' .. cmd:gsub('^([^%s]*)', g_CommandMapping)
		if getElementType(source) ~= 'player' then return end
		procCallOnAll('OnPlayerCommandText', getElemID(source), cmd)
	end
)

addEventHandler('onPlayerClick', root,
	function(mouseButton, buttonState, elem, worldPosX, worldPosY, worldPosZ, screenPosX, screenPosY)
		local iButton, iState = nil, nil
		local playerID = getElemID(source)

		if mouseButton == 'left' then iButton = 0 end
		if mouseButton == 'middle' then iButton = 1 end
		if mouseButton == 'right' then iButton = 2 end
		if buttonState == 'up' then iState = 0 end
		if buttonState == 'down' then iState = 1 end

		if not elem then
			procCallOnAll('OnPlayerClickWorld', playerID, iButton, iState, 'none', 65535, float2cell(worldPosX), float2cell(worldPosY), float2cell(worldPosZ))
			return
		end

		local elemType = getElementType(elem)
		if elemType == 'player' or elemType == 'vehicle' or elemType == 'object' or elemType == 'ped' then
			local elemID = getElemID(elem)

			if elemType == 'ped' then
				if getElementData(elem, 'ActorPed') then
					elemType = 'actor'
				else
					elemType = 'bot'
				end
			end

			procCallOnAll('OnPlayerClickWorld', playerID, iButton, iState, elemType, elemID, float2cell(worldPosX), float2cell(worldPosY), float2cell(worldPosZ))
		end

	end
)

addEventHandler('onPlayerChangeNick', root,
	function()
		cancelEvent()
	end
)

-- Actors
addEvent('onActorStream_Ev', true)
addEventHandler('onActorStream_Ev', root,
	function(actor, streamed)
		local playerID, actorID = getElemID(client), getElemID(actor)
		if not playerID or not g_Actors[actorID] then return end

		if streamed then
			g_Players[playerID].streamedActors[actorID] = true
			procCallOnAll('OnActorStreamIn', actorID, playerID)
		else
			g_Players[playerID].streamedActors[actorID] = nil
			procCallOnAll('OnActorStreamOut', actorID, playerID)
		end
	end
)

-- Players
addEvent('onPlayerStream_Ev', true)
addEventHandler('onPlayerStream_Ev', root,
	function(player, streamed)
		local playerID, otherID = getElemID(client), getElemID(player)
		if not playerID or not g_Players[otherID] then return end

		if streamed then
			g_Players[playerID].streamedPlayers[otherID] = true
			procCallOnAll('OnPlayerStreamIn', otherID, playerID)
		else
			g_Players[playerID].streamedPlayers[otherID] = nil
			procCallOnAll('OnPlayerStreamOut', otherID, playerID)
		end
	end
)

-- Vehicles
addEvent('onVehicleStream_Ev', true)
addEventHandler('onVehicleStream_Ev', root,
	function(vehicle, streamed)
		local playerID, vehID = getElemID(client), getElemID(vehicle)
		if not playerID or not g_Vehicles[vehID] then return end

		if streamed then
			g_Players[playerID].streamedVehicles[vehID] = true
			procCallOnAll('OnVehicleStreamIn', vehID, playerID)
		else
			g_Players[playerID].streamedVehicles[vehID] = nil
			procCallOnAll('OnVehicleStreamOut', vehID, playerID)
		end
	end
)

-- Bots
addEvent('onBotStream_Ev', true)
addEventHandler('onBotStream_Ev', root,
	function(bot, streamed)
		local playerID, botID = getElemID(client), getElemID(bot)
		if not playerID or not g_Bots[botID] then return end

		if streamed then
			g_Players[playerID].streamedBots[botID] = true
			procCallOnAll('OnBotStreamIn', botID, playerID)
		else
			g_Players[playerID].streamedBots[botID] = nil
			procCallOnAll('OnBotStreamOut', botID, playerID)
		end
	end
)

-- depends on killmessages resource
local function playerKillMessage(killer, weapon, bodypart)
	-- disable adding kill messages automatically
	cancelEvent()
end
addEventHandler('onPlayerKillMessage', root, playerKillMessage)

-- depends on scoreboard resource
addEvent('onPlayerClickPlayer_Ev', true)
addEventHandler('onPlayerClickPlayer_Ev', root,
	function(clickPlayer)
		local playerID, clickedID = getElemID(client), getElemID(clickPlayer)
		if not playerID or not g_Players[clickedID] then return end

		-- the last argument is a click source which is always 0
		procCallOnAll('OnPlayerClickPlayer', playerID, clickedID, 0)
	end
)
