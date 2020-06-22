-------------------------------
-- Players

function gameModeInit(player)
	clientCall(player, 'gamemodeLoad')
	local playerID = getElemID(player)
	local playerData = g_Players[playerID]
	for k,v in pairs(playerData) do
		if k ~= 'elem' and k ~= 'keys' and k ~= 'blip' then
			playerData[k] = nil
		end
	end
	setPlayerMoney(player, 0)
	takeAllWeapons(player)
	setElementInterior(player, 0)
	setElementDimension(player, 0)
	local r, g, b = math.random(50, 255), math.random(50, 255), math.random(50, 255)
	ShowPlayerMarker(false, player, g_ShowPlayerMarkers)
	setPlayerHudComponentVisible(player, 'area_name', g_ShowZoneNames)
	SetPlayerColor(false, player, r, g, b)
	setElementData(player, 'Score', 0)
	toggleAllControls(player, false, true, false)
	clientCall(player, 'showIntroScene')
	clientCall(player, 'TogglePlayerClock', false, false)
	g_Players[playerID].pvars = {}
	g_Players[playerID].streamedActors = {}
	g_Players[playerID].streamedVehicles = {}
	g_Players[playerID].streamedPlayers = {}
	g_Players[playerID].attachedObjects = {}
	if g_PlayerClasses[0] then
		g_Players[playerID].viewingintro = true
		fadeCamera(player, true)
		setTimer(
			function()
				if not isElement(player) or getElementType(player) ~= 'player' then
					return
				end
				g_Players[playerID].doingclasssel = true
				killPed(player)
				if procCallOnAll('OnPlayerRequestClass', playerID, 0) then
					putPlayerInClassSelection(player)
				else
					outputDebugString('Not allowed to select a class', 1)
				end
			end,
			5000,
			1
		)
	else
		setTimer(
			function()
				if not isElement(player) or getElementType(player) ~= 'player' then
					return
				end
				repeat until onPlayerInitSpawnPlayer(player, math.random(-20, 20), math.random(-20, 20), 3, math.random(0, 359), math.random(9, 288))
			end,
			5000,
			1
		)
	end
end

function onPlayerInitSpawnPlayer(player, x, y, z, rotation, skinid)
	local playerID = getElemID(player)
	g_Players[playerID].spawnedfromgamemodeinit = true
	return spawnPlayer(player, x, y, z, rotation, skinid)
end

function joinHandler(player)
	local playerJoined = not player
	if playerJoined then
		player = source
	end

	local playerID = addElem(g_Players, player)
	setElementData(player, 'ID', playerID)
	clientCall(player, 'setAMXVersion', amxVersionString())
	clientCall(player, 'setPlayerID', playerID)

	-- Keybinds
	bindKey(player, 'F4', 'down', "changeclass")
	bindKey(player, 'enter_exit', 'down', removePedJetPack)
	g_Players[playerID].keys = {}
	local function bindControls(player, t)
		for samp,mta in pairs(t) do
			bindKey(player, mta, 'down', keyStateChange)
			bindKey(player, mta, 'up', keyStateChange)
		end
	end
	bindControls(player, g_KeyMapping)
	bindControls(player, g_LeftRightMapping)
	bindControls(player, g_UpDownMapping)
	for k,v in ipairs(g_Keys) do
		bindKey(player, v, 'both', mtaKeyStateChange)
	end
	g_Players[playerID].updatetimer = setTimer(procCallOnAll, 100, 0, 'OnPlayerUpdate', playerID)

	if playerJoined then
		if getRunningGameMode() then
			gameModeInit(player)
		end
		if isWeaponSyncingNeeded() then
			clientCall(player, 'enableWeaponSyncing', true)
		end
		
		-- send menus
		for i,menu in pairs(g_Menus) do
			clientCall(player, 'CreateMenu', i, menu)
		end

		-- send textdraws
		for id,textdraw in pairs(g_TextDraws) do
			clientCall(player, 'TextDrawCreate', id, table.deshadowize(textdraw, true))
		end

		-- send 3d text labels
		for i,label in pairs(g_TextLabels) do
			clientCall(player, 'Create3DTextLabel', i, label)
		end

		table.each(
			g_LoadedAMXs,
			function(amx)
				procCallInternal(amx, 'OnPlayerConnect', playerID)

			end
		)
	end
	setPlayerNametagShowing(player, false)
end
addEventHandler('onPlayerJoin', root, joinHandler)

function classSelKey(player)
	clientCall(player, 'displayFadingMessage', 'Returning to class selection after next death', 0, 200, 200)
	outputChatBox('* Returning to class selection after next death', player, 0, 220, 220)
	g_Players[getElemID(player)].returntoclasssel = true
end
addCommandHandler ( "changeclass", classSelKey )

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
	local iState = nil
	if state == 'up' then iState = 0 end
	if state == 'down' then iState = 1 end
	procCallOnAll('OnKeyPress', getElemID(player), key, iState)
end

function buildKeyState(player, t)
	local keys = g_Players[getElemID(player)].keys
	local result = 0
	for samp,mta in pairs(t) do
		if type(mta) == 'table' then
			for i,key in ipairs(mta) do
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
	toggleAllControls(player, false, true, false)
	local playerID = getElemID(player)
	g_Players[playerID].viewingintro = nil
	g_Players[playerID].doingclasssel = true
	g_Players[playerID].selectedclass = g_Players[playerID].selectedclass or 0
	killPed(player)
	if g_Players[playerID].blip then
		setElementVisibleTo(g_Players[playerID].blip, root, false)
	end
	clientCall(player, 'startClassSelection', g_PlayerClasses)
	bindKey(player, 'arrow_l', 'down', requestClass, -1)
	bindKey(player, 'arrow_r', 'down', requestClass, 1)
	bindKey(player, 'lshift', 'down', requestSpawn)
	bindKey(player, 'rshift', 'down', requestSpawn)
	requestClass(player, false, false, 0)
end

function requestClass(player, btn, state, dir)
	local playerID = getElemID(player)
	local data = g_Players[playerID]
	data.selectedclass = data.selectedclass + dir
	if data.selectedclass > #g_PlayerClasses then
		data.selectedclass = 0
	elseif data.selectedclass < 0 then
		data.selectedclass = #g_PlayerClasses
	end
	local x, y, z = getElementPosition(player)
	if isPedDead(player) then
		spawnPlayer(player, x, y, z, getPedRotation(player), g_PlayerClasses[data.selectedclass][5], getElementInterior(player), playerID)
	else
		setElementModel(player, g_PlayerClasses[data.selectedclass][5])
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
	local playerID = getElemID(player)
	local playerdata = g_Players[playerID]
	playerdata.viewingintro = nil
	playerdata.doingclasssel = nil
	local spawninfo = playerdata.spawninfo or (g_PlayerClasses and g_PlayerClasses[playerdata.selectedclass])
	if not spawninfo then
		return
	end
	if x then
		spawninfo = table.shallowcopy(spawninfo)
		spawninfo[1], spawninfo[2], spawninfo[3], spawninfo[4] = x, y, z, r or spawninfo[4]
	end
	spawnPlayer(player, unpack(spawninfo))
	for i,weapon in ipairs(spawninfo.weapons) do
		if weapon[1] ~= -1 then
			giveWeapon(player, weapon[1], weapon[2], true)
		end
	end
	clientCall(player, 'destroyClassSelGUI')
	if playerdata.blip then
		setElementVisibleTo(playerdata.blip, root, true)
	end
end

addEventHandler('onPlayerSpawn', root,
	function()
		local playerID = getElemID(source)
		local playerdata = g_Players[playerID]
		if playerdata.doingclasssel or playerdata.beingremovedfromvehicle or playerdata.spawnedfromgamemodeinit then
			if playerdata.spawnedfromgamemodeinit ~= nil then
				playerdata.spawnedfromgamemodeinit = nil
			end
			return
		end
		toggleAllControls(source, true)
		procCallOnAll('OnPlayerSpawn', playerID)
		setPlayerState(source, PLAYER_STATE_ONFOOT)
		playerdata.vehicle = nil
		playerdata.specialaction = SPECIAL_ACTION_NONE
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
			for i,data in pairs(g_Players) do
				if getDistanceBetweenPoints3D(x, y, z, getElementPosition(data.elem)) <= g_GlobalChatRadius then
					outputChatBox(getPlayerName(source) .. ':#FFFFFF ' .. msg:gsub('#%x%x%x%x%x%x', ''), data.elem, r, g, b, true)
				end
			end
		else
			outputChatBox(getPlayerName(source) .. ':#FFFFFF ' .. msg:gsub('#%x%x%x%x%x%x', ''), root, r, g, b, true)
		end
	end
)

addEventHandler('onPlayerDamage', root,
	function(attacker, weapon, body, loss)

		if not attacker or not isElement(attacker) or getElementType(attacker) ~= 'player' then
			return
		end
		procCallOnAll('OnPlayerShootingPlayer', getElemID(source), getElemID(attacker), body, loss)
		if g_ServerVars.instagib then
			killPed(source)
		end
	end
)
addEventHandler('onPlayerWeaponSwitch', root,
	function(prev, current)
		procCallOnAll('OnPlayerWeaponSwitch', getElemID(source), prev, current)
	end
)

addEventHandler('onPlayerWasted', root,
	function(ammo, killer, weapon, bodypart)
		local playerID = getElemID(source)
		if g_Players[playerID].doingclasssel then
			return
		end
		local killerID = killer and killer ~= source and getElemID(killer) or 255
		setPlayerState(source, PLAYER_STATE_WASTED)
		procCallOnAll('OnPlayerDeath', playerID, killerID, weapon)
		if g_Players[playerID].returntoclasssel then
			g_Players[playerID].returntoclasssel = nil
			--setTimer(putPlayerInClassSelection, 3000, 1, source)
			setTimer(
				function()
					g_Players[playerID].spawninfo = nil
					g_Players[playerID].selectedclass = nil
					
					if procCallOnAll('OnPlayerRequestClass', playerID, 0) then
						putPlayerInClassSelection(player)
					end
				end, 3000, 1, source
			)
		else
			setTimer(spawnPlayerBySelectedClass, 3000, 1, source, false)
		end
		g_Players[playerID].vehicle = nil
		g_Players[playerID].specialaction = SPECIAL_ACTION_NONE
	end
)

local quitReasons = {
	['Timed out'] = 0,
	Quit = 1,
	Kicked = 2
}
addEventHandler('onPlayerQuit', root,
	function(reason)
		local vehicle = getPedOccupiedVehicle(source)
		if vehicle then
			triggerEvent('onVehicleExit', vehicle, source)
		end
		g_PlayerObjects[source] = nil
		local playerID = getElemID(source)

		for i,playerdata in pairs(g_Players) do
			playerdata.streamedPlayers[playerID] = nil
		end

		procCallOnAll('OnPlayerDisconnect', playerID, quitReasons[reason])
		if g_Players[playerID].blip then
			destroyElement(g_Players[playerID].blip)
		end
		if g_Players[playerID].updatetimer then
			killTimer( g_Players[playerID].updatetimer )
			g_Players[playerID].updatetimer = nil
		end
		g_Players[playerID] = nil
	end
)


-------------------------------
-- Vehicles

function respawnStaticVehicle(vehicle)
	if not isElement(vehicle) then
		return
	end
	local vehID = getElemID(vehicle)
	if not g_Vehicles[vehID] then
		return
	end
	if isTimer(g_Vehicles[vehID].respawntimer) then
		killTimer(g_Vehicles[vehID].respawntimer)
	end
	g_Vehicles[vehID].respawntimer = nil
	local spawninfo = g_Vehicles[vehID].spawninfo
	spawnVehicle(vehicle, spawninfo.x, spawninfo.y, spawninfo.z, 0, 0, spawninfo.angle)
	procCallInternal(amx, 'OnVehicleSpawn', vehID)
end

addEventHandler('onVehicleEnter', root,
	function(player, seat, jacked)
		local vehID = getElemID(source)
		if isPed(player) then
			local pedID = getElemID(player)
			g_Bots[pedID].vehicle = source
			setBotState(player, seat == 0 and PLAYER_STATE_DRIVER or PLAYER_STATE_PASSENGER)
			return
		end
		local playerID = getElemID(player)
		g_Players[playerID].vehicle = source
		setPlayerState(player, seat == 0 and PLAYER_STATE_DRIVER or PLAYER_STATE_PASSENGER)

		if g_Vehicles[vehID] and g_Vehicles[vehID].respawntimer then
			killTimer(g_Vehicles[vehID].respawntimer)
			g_Vehicles[vehID].respawntimer = nil
		end

		if ManualVehEngineAndLights then
			if (getVehicleType(source) ~= "Plane" and getVehicleType(source) ~= "Helicopter") then
				setVehicleEngineState(source, g_Vehicles[vehID].engineState)
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
		if isPed(player) then
			local pedID = getElemID(player)
			procCallOnAll('OnBotEnterVehicle', pedID, vehID, seat ~= 0 and 1 or 0)
			return
		end
		local playerID = getElemID(player)
		procCallOnAll('OnPlayerEnterVehicle', playerID, vehID, seat ~= 0 and 1 or 0)
	end
)

addEventHandler('onVehicleExit', root,
	function(player, seat, jacker)
		local vehID = getElemID(source)

		if isPed(player) then
			local pedID = getElemID(player)
			g_Bots[pedID].vehicle = nil
			setBotState(player, PLAYER_STATE_ONFOOT)
			return
		end

		local playerID = getElemID(player)
		g_Players[playerID].vehicle = nil
		setPlayerState(player, PLAYER_STATE_ONFOOT)

		for i=0,getVehicleMaxPassengers(source) do
			if getVehicleOccupant(source, i) then
				return
			end
		end
		if g_Vehicles[vehID] and g_Vehicles[vehID].respawntimer then
			killTimer(g_Vehicles[vehID].respawntimer)
			g_Vehicles[vehID].respawntimer = nil
		end
		g_Vehicles[vehID].respawntimer = setTimer(respawnStaticVehicle, g_Vehicles[vehID].respawndelay, 1, source)
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
			local pedID = getElemID(player)
			procCallOnAll('OnBotExitVehicle', pedID, vehID)
			return
		end

		local playerID = getElemID(player)
		procCallOnAll('OnPlayerExitVehicle', playerID, vehID)
	end
)

addEventHandler('onVehicleExplode', root,
	function()
		local vehID = getElemID(source)

		procCallOnAll('OnVehicleDeath', vehID, 0)		-- NOES, MY VEHICLE DIED

		if g_Vehicles[vehID].respawntimer then
			killTimer(g_Vehicles[vehID].respawntimer)
			g_Vehicles[vehID].respawntimer = nil
		end
		g_Vehicles[vehID].respawntimer = setTimer(respawnStaticVehicle, g_Vehicles[vehID].respawndelay, 1, source)
	end
)

addEventHandler('onVehicleDamage', root,
	function(loss)
		local vehID = getElemID(source)
		if not vehID then
			return
		end

		procCallOnAll('OnVehicleDamage', vehID, loss)
	end
)

function getPedOccupiedVehicle(player)
	local data = g_Players[getElemID(player)]
	return data and data.vehicle
end

function removePedFromVehicle(player)
	local playerdata = g_Players[getElemID(player)]
	if not playerdata.vehicle then
		return false
	end
	-- Built-in removePlayerFromVehicle is simply too unreliable
	local health, armor = getElementHealth(player), getPedArmor(player)
	local weapons, currentslot = playerdata.weapons, getPedWeaponSlot(player)
	playerdata.beingremovedfromvehicle = true
	local x, y, z = getElementPosition(playerdata.vehicle)
	local rx, ry, rz = getVehicleRotation(playerdata.vehicle)
	procCallOnAll('OnPlayerExitVehicle', getElemID(player), getElemID(playerdata.vehicle))
	spawnPlayerBySelectedClass(player, x + 4*math.cos(math.rad(rz+180)), y + 4*math.sin(math.rad(rz+180)), z + 1, rz)
	playerdata.beingremovedfromvehicle = nil
	playerdata.vehicle = nil
	setElementHealth(player, health)
	setPedArmor(player, armor)
	if weapons then
		giveWeapons(player, weapons, currentslot)
	end
	return true
end
-------------------------------
-- Markers
addEventHandler('onMarkerHit', root,
	function(elem, dimension)
		if getElementType(elem) == "player" or getElementType(elem) == "vehicle" or getElementType(elem) == "ped" then
			local elemtype = getElementType(elem)
			local elemid = getElemID(elem)
			procCallOnAll('OnMarkerHit', getElemID(source), elemtype, elemid, dimension);
		end
	end
)
addEventHandler('onMarkerLeave', root,
	function(elem, dimension)
		if getElementType(elem) == "player" or getElementType(elem) == "vehicle" or getElementType(elem) == "ped" then
			local elemtype = getElementType(elem)
			local elemid = getElemID(elem)
			procCallOnAll('OnMarkerLeave', getElemID(source), elemtype, elemid, dimension);
		end
	end
)
-------------------------------
-- Peds

addEventHandler('onPedWasted', root,
	function(totalAmmo, killer, killerWeapon, bodypart)
		if isPed(source) ~= true then return end
			procCallOnAll('OnBotDeath', getElemID(source), getElemID(killer), killerWeapon, bodypart)
	end
)
-------------------------------
-- Misc
addEvent('OnPlayerPickUpPickup_Ev', true)
addEventHandler('OnPlayerPickUpPickup_Ev', root,
	function(pickup)
		local model = getElementModel(pickup)

		procCallOnAll('OnPlayerPickUpPickup', getElemID(player), getElemID(pickup))

		if model == 370 then
			-- Jetpack pickup
			givePedJetPack(player)
		end
	end
)

addEventHandler('onConsole', root,
	function(cmd)
		cmd = '/' .. cmd:gsub('^([^%s]*)', g_CommandMapping)
		procCallOnAll('OnPlayerCommandText', getElemID(source), cmd)
	end
)

addEventHandler('onPlayerClick', root,
	function(mouseButton, buttonState, elem, worldPosX, worldPosY, worldPosZ, screenPosX, screenPosY)
		local iButton = nil
		local iState = nil
		local elemID = nil
		local playerID = getElemID(source)
		if elem ~= nil then elemID = getElemID(elem) end
		if mouseButton == 'left' then iButton = 0 end
		if mouseButton == 'middle' then iButton = 1 end
		if mouseButton == 'right' then iButton = 2 end
		if buttonState == 'up' then iState = 0 end
		if buttonState == 'down' then iState = 1 end

		procCallOnAll('OnPlayerClickWorld', playerID, iButton, iState, worldPosX, worldPosY, worldPosZ)
		if elem == nil then return end
		if getElementType(elem) == 'player' then
			procCallOnAll('OnPlayerClickWorldPlayer', playerID, iButton, iState, elemID, worldPosX, worldPosY, worldPosZ)
		end
		if getElementType(elem) == 'object' then
			procCallOnAll('OnPlayerClickWorldObject', playerID, iButton, iState, elemID, worldPosX, worldPosY, worldPosZ)
		end
		if getElementType(elem) == 'vehicle' then
			procCallOnAll('OnPlayerClickWorldVehicle', playerID, iButton, iState, elemID, worldPosX, worldPosY, worldPosZ)
		end

	end
)

addEventHandler('onPlayerChangeNick', root,
	function()
		cancelEvent()
	end
)

-- Actors
addEvent('onAmxClientActorStream', true)
addEventHandler('onAmxClientActorStream', root,
	function(actorId, streamed)
		local playerID = getElemID(source)
		if streamed then
			g_Players[playerID].streamedActors[actorId] = true
			procCallOnAll('OnActorStreamIn', actorId, playerID)
		else
			g_Players[playerID].streamedActors[actorId] = nil
			procCallOnAll('OnActorStreamOut', actorId, playerID)
		end
	end
)

-- Players
addEvent('onAmxClientPlayerStream', true)
addEventHandler('onAmxClientPlayerStream', root,
	function(otherId, streamed)
		local playerID = getElemID(source)
		if streamed then
			g_Players[playerID].streamedPlayers[otherId] = true
			procCallOnAll('OnPlayerStreamIn', otherId, playerID)
		else
			g_Players[playerID].streamedPlayers[otherId] = nil
			procCallOnAll('OnPlayerStreamOut', otherId, playerID)
		end
	end
)

-- Vehicles
addEvent('onAmxClientVehicleStream', true)
addEventHandler('onAmxClientVehicleStream', root,
	function(vehicleID, streamed)
		local playerID = getElemID(source)
		if streamed then
			g_Players[playerID].streamedVehicles[vehicleID] = true
			procCallOnAll('OnVehicleStreamIn', vehicleID, playerID)
		else
			g_Players[playerID].streamedVehicles[vehicleID] = nil
			procCallOnAll('OnVehicleStreamOut', vehicleID, playerID)
		end
	end
)
