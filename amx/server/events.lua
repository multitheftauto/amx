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
	local r, g, b = math.random(50, 255), math.random(50, 255), math.random(50, 255)
	ShowPlayerMarker(false, player, g_PlayerMarkersMode)
	setPlayerHudComponentVisible(player, 'area_name', g_ShowZoneNames)
	setPlayerHudComponentVisible(player, 'vehicle_name', false) -- SA-MP doesn't show vehicle names when entering vehicles
	SetPlayerColor(false, player, r, g, b)
	setElementData(player, 'Score', 0)
	toggleAllControls(player, false, true, false)
	clientCall(player, 'showIntroScene')
	clientCall(player, 'TogglePlayerClock', false, false)
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
	g_Players[playerID].shotVect = {
		oX = 0.0, oY = 0.0, oZ = 0.0,
		hX = 0.0, hY = 0.0, hZ = 0.0
	}
	g_Players[playerID].conntick = getTickCount()
	g_Players[playerID].viewingintro = true
	g_Players[playerID].state = PLAYER_STATE_NONE

	fadeCamera(player, true)
	setTimer(
		function()
			if not isElement(player) or getElementType(player) ~= 'player' then
				return
			end
			g_Players[playerID].doingclasssel = false
			if procCallOnAll('OnPlayerRequestClass', playerID, 0) then
				putPlayerInClassSelection(player)
			else
				outputDebugString('Not allowed to select a class', 1)
				g_Players[playerID].doingclasssel = true
				killPed(player)
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
	clientCall(player, 'setPlayerID', playerID)

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
	setPlayerNametagShowing(player, false)
end
addEventHandler('onPlayerJoin', root, joinHandler)

function classSelKey(player)
	clientCall(player, 'displayFadingMessage', 'Returning to class selection after next death', 136, 140, 68)
	outputChatBox('* Returning to class selection after next death', player, 136, 170, 98)
	g_Players[getElemID(player)].returntoclasssel = true
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
		return
	end
	if state == 'down' then
		procCallOnAll('OnPlayerKeyDown', getElemID(player), key)
		return
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

	toggleAllControls(player, false, true, false)
	g_Players[playerID].viewingintro = nil
	g_Players[playerID].doingclasssel = true
	g_Players[playerID].selectedclass = g_Players[playerID].selectedclass or 0
	killPed(player)
	if g_Players[playerID].blip then
		setElementVisibleTo(g_Players[playerID].blip, root, false)
	end
	if g_Players[playerID].updatetimer then
		killTimer(g_Players[playerID].updatetimer)
		g_Players[playerID].updatetimer = nil
	end
	setPlayerHudComponentVisible(player, 'area_name', false)
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
		spawnPlayer(player, x, y, z, getPedRotation(player), skin, getElementInterior(player), playerID)
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
	for i, weapon in ipairs(spawninfo.weapons) do
		if weapon[1] ~= -1 then
			giveWeapon(player, weapon[1], weapon[2], true)
		end
	end
	clientCall(player, 'destroyClassSelGUI')
	setPlayerHudComponentVisible(player, 'area_name', g_ShowZoneNames)
	if playerdata.blip then
		setElementVisibleTo(playerdata.blip, root, true)
	end
end

addEventHandler('onPlayerSpawn', root,
	function()
		local playerID = getElemID(source)
		local playerdata = g_Players[playerID]
		local spawninfo = playerdata.spawninfo or (g_PlayerClasses and g_PlayerClasses[playerdata.selectedclass])
		if not spawninfo or playerdata.doingclasssel then
			return
		end
		toggleAllControls(source, true)
		setElementAlpha(source, 255)
		setElementCollisionsEnabled(source, true)
		setPlayerState(source, PLAYER_STATE_SPAWNED)
		procCallOnAll('OnPlayerSpawn', playerID)

		-- wanna see CJ in a white singlet?
		addPedClothes(source, 'vest', 'vest', 0)

		if not g_UseCJWalk then
			local skin = getElementModel(source)
			setPedWalkingStyle(source, WalkingStyle[skin] or 0)
		end

		if g_Players[playerID].updatetimer then
			killTimer(g_Players[playerID].updatetimer)
		end
		g_Players[playerID].updatetimer = setTimer(procCallOnAll, 100, 0, 'OnPlayerUpdate', playerID)

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

addEventHandler('onPlayerDamage', root,
	function(attacker, weapon, body, loss)
		local playerId = getElemID(source)
		local attackerId = INVALID_PLAYER_ID

		if attacker ~= source and isElement(attacker) then
			if getElementType(attacker) == 'player' then
				attackerId = getElemID(attacker)
			elseif getElementType(attacker) == 'vehicle' then
				local driver = getVehicleOccupant(attacker)
				if driver and getElementType(driver) == 'player' then
					attackerId = getElemID(driver)
				end
			end
		end

		if attackerId ~= INVALID_PLAYER_ID then
			setTimer(procCallOnAll, 10, 1, 'OnPlayerGiveDamage', attackerId, playerId, float2cell(loss), weapon, body)
			-- This needs to be just a bit delayed to arrive after OnPlayerWeaponShot
		end

		setTimer(procCallOnAll, 10, 1, 'OnPlayerTakeDamage', playerId, attackerId, float2cell(loss), weapon, body)
		-- This needs to be just a bit delayed to arrive after OnPlayerWeaponShot
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
		setPlayerState(source, PLAYER_STATE_WASTED)
		procCallOnAll('OnPlayerDeath', playerID, killerID, weapon)
		if g_Players[playerID].returntoclasssel then
			g_Players[playerID].returntoclasssel = nil
			--setTimer(putPlayerInClassSelection, 3000, 1, source)
			local player = source
			setTimer(
				function()
					g_Players[playerID].spawninfo = nil
					g_Players[playerID].selectedclass = nil

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

		if g_Players[playerID].updatetimer then
			killTimer(g_Players[playerID].updatetimer)
			g_Players[playerID].updatetimer = nil
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

		for i, playerdata in pairs(g_Players) do
			playerdata.streamedPlayers[playerID] = nil
		end

		procCallOnAll('OnPlayerDisconnect', playerID, quitReasons[reason])
		if g_Players[playerID].blip then
			destroyElement(g_Players[playerID].blip)
		end
		if g_Players[playerID].updatetimer then
			killTimer(g_Players[playerID].updatetimer)
			g_Players[playerID].updatetimer = nil
		end
		g_Players[playerID] = nil
	end
)
-------------------------------
-- Vehicles

addEventHandler('onResourceStart', resourceRoot,
	function()
		setTimer(checkAndUpdatePlayerStates, 1000, 0)
	end,
	false
)

--[[ 
	If the player is slapped, or the vehicle is destroyed by a command, we need to handle such
	We also now check if the player has spawned or has a state of 'none', 
	if so and if they're on foot, we set their state
]]
function checkAndUpdatePlayerStates()
	for i, data in pairs(g_Players) do
		local state = getPlayerState(data.elem)
		if (state == PLAYER_STATE_DRIVER or state == PLAYER_STATE_PASSENGER) or 
			(state == PLAYER_STATE_SPAWNED or state == PLAYER_STATE_NONE) then
			if not isPedInVehicle(data.elem) then
				setCameraTarget(data.elem, data.elem)
				setPlayerState(data.elem, PLAYER_STATE_ONFOOT)
				setElementCollisionsEnabled(data.elem, true)
				setElementAlpha(data.elem, 255)
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
	local numPassengers = tonumber(getVehicleMaxPassengers(vehicle)) or 0
	for seat = 0, numPassengers do
		local player = getVehicleOccupant(vehicle, seat)
		if player then
			removePedFromVehicle(player)
		end
	end
	g_Vehicles[vehID].respawntimer = nil
	g_Vehicles[vehID].vehicleIsAlive = true
	local spawninfo = g_Vehicles[vehID].spawninfo
	setTimer(
		function()
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
			return
		end

		local playerID = getElemID(player)
		g_Players[playerID].vehicle = source
		setPlayerState(player, seat == 0 and PLAYER_STATE_DRIVER or PLAYER_STATE_PASSENGER)
		g_Players[playerID].specialaction = SPECIAL_ACTION_NONE

		if g_Vehicles[vehID] and g_Vehicles[vehID].respawntimer then
			killTimer(g_Vehicles[vehID].respawntimer)
			g_Vehicles[vehID].respawntimer = nil
		end

		if ManualVehEngineAndLights then
			if (g_Vehicles[vehID] and getVehicleType(source) ~= 'Plane' and getVehicleType(source) ~= 'Helicopter') then
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

		if g_RCVehicles[getElementModel(source)] then
			cancelEvent()
			return
		end

		if isPed(player) then
			local botID = getElemID(player)
			procCallOnAll('OnBotEnterVehicle', botID, vehID, seat ~= 0 and 1 or 0)
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
			local botID = getElemID(player)
			g_Bots[botID].vehicle = nil
			setBotState(player, PLAYER_STATE_ONFOOT)

			if g_RCVehicles[getElementModel(source)] then
				setElementCollisionsEnabled(player, true)
				setElementAlpha(player, 255)
			end
			return
		end

		local playerID = getElemID(player)
		g_Players[playerID].vehicle = nil
		setPlayerState(player, PLAYER_STATE_ONFOOT)

		if g_RCVehicles[getElementModel(source)] then
			setElementCollisionsEnabled(player, true)
			setElementAlpha(player, 255)
		end

		local numPassengers = tonumber(getVehicleMaxPassengers(source)) or 0
		for i = 0, numPassengers do
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
			local botID = getElemID(player)
			procCallOnAll('OnBotExitVehicle', botID, vehID)
			return
		end

		local playerID = getElemID(player)
		procCallOnAll('OnPlayerExitVehicle', playerID, vehID)
	end
)

addEventHandler('onVehicleExplode', root,
	function()
		local vehID = getElemID(source)

		-- So the OnVehicleDeath event only gets called once
		if g_Vehicles[vehID] and g_Vehicles[vehID].vehicleIsAlive then
			procCallOnAll('OnVehicleDeath', vehID, getElemID(client))

			if g_Vehicles[vehID].respawntimer then
				killTimer(g_Vehicles[vehID].respawntimer)
				g_Vehicles[vehID].respawntimer = nil
			end

			g_Vehicles[vehID].vehicleIsAlive = false
			g_Vehicles[vehID].respawntimer = setTimer(respawnStaticVehicle, 10000, 1, source)
		end
	end
)

addEvent('OnVehicleDamageStatusUpdate_Ev', true)
addEventHandler('OnVehicleDamageStatusUpdate_Ev', root,
	function(vehicle)
		local vehID = getElemID(vehicle)
		if not vehID then return end

		procCallOnAll('OnVehicleDamageStatusUpdate', vehID, getElemID(client))
	end
)

local _getPedOccupiedVehicle = getPedOccupiedVehicle
function getPedOccupiedVehicle(player)
	if not player then
		return false
	end
	if getElementType(player) ~= 'player' then
		return _getPedOccupiedVehicle(player)
	end
	local data = g_Players[getElemID(player)]
	return data and data.vehicle
end

local _removePedFromVehicle = removePedFromVehicle
function removePedFromVehicle(player)
	if not player then
		return false
	end
	local playerdata = g_Players[getElemID(player)]
	if getElementType(player) ~= 'player' or not playerdata.vehicle then
		return _removePedFromVehicle(player)
	end
	playerdata.vehicle = nil
	setTimer(_removePedFromVehicle, 500, 1, player)
	return true
end

function removePedFromVehicleEx(player)
	local playerdata = g_Players[getElemID(player)]
	if not playerdata.vehicle then
		return false
	end
	playerdata.vehicle = nil
	setControlState(player, 'enter_exit', true)
	return true
end
-------------------------------
-- Markers

addEventHandler('onMarkerHit', root,
	function(elem, dimension)
		if getElementType(elem) == 'player' or getElementType(elem) == 'vehicle' or getElementType(elem) == 'ped' then
			local elemtype = getElementType(elem)
			local elemid = getElemID(elem)
			procCallOnAll('OnMarkerHit', getElemID(source), elemtype, elemid, dimension)
		end
	end
)

addEventHandler('onMarkerLeave', root,
	function(elem, dimension)
		if getElementType(elem) == 'player' or getElementType(elem) == 'vehicle' or getElementType(elem) == 'ped' then
			local elemtype = getElementType(elem)
			local elemid = getElemID(elem)
			procCallOnAll('OnMarkerLeave', getElemID(source), elemtype, elemid, dimension)
		end
	end
)
-------------------------------
-- Peds

addEventHandler('onPedWasted', root,
	function(totalAmmo, killer, killerWeapon, bodypart)
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
		setBotState(source, PLAYER_STATE_WASTED)
		procCallOnAll('OnBotDeath', getElemID(source), killerID, killerWeapon, bodypart)
	end
)
-------------------------------
-- Misc

addEvent('OnPlayerWeaponShot_Ev', true)
addEventHandler('OnPlayerWeaponShot_Ev', root,
	function(weapon, hitType, hitId, startX, startY, startZ, hitX, hitY, hitZ, offsetX, offsetY, offsetZ)
		local playerID = getElemID(source)
		local playerData = g_Players[playerID]
		if not playerData then return end

		playerData.shotVect.oX = startX
		playerData.shotVect.oY = startY
		playerData.shotVect.oZ = startZ
		playerData.shotVect.hX = hitX
		playerData.shotVect.hY = hitY
		playerData.shotVect.hZ = hitZ

		procCallOnAll('OnPlayerWeaponShot', playerID, weapon, hitType, hitId, float2cell(offsetX), float2cell(offsetY), float2cell(offsetZ))
	end
)

addEvent('OnPlayerGiveDamageActor_Ev', true)
addEventHandler('OnPlayerGiveDamageActor_Ev', root,
	function(actor, loss, weapon, bodypart)
		if not actor or getElementData(actor, 'Invulnerable') then return end

		local playerID, actorID = getElemID(source), getElemID(actor)
		setTimer(procCallOnAll, 10, 1, 'OnPlayerGiveDamageActor', playerID, actorID, float2cell(loss), weapon, bodypart)
		-- This needs to be just a bit delayed to arrive after OnPlayerWeaponShot
	end
)

addEvent('OnPlayerPickUpPickup_Ev', true)
addEventHandler('OnPlayerPickUpPickup_Ev', root,
	function(pickup)
		procCallOnAll('OnPlayerPickUpPickup', getElemID(source), getElemID(pickup))

		local model = getElementModel(pickup)
		if model == 370 then
			-- Jetpack pickup
			setPedWearingJetpack(source, true)
		end
	end
)

addEvent('OnPlayerClickMap_Ev', true)
addEventHandler('OnPlayerClickMap_Ev', root,
	function(clickX, clickY, clickZ)
		local playerID = getElemID(source)

		procCallOnAll('OnPlayerClickMap', playerID, float2cell(clickX), float2cell(clickY), float2cell(clickZ))
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
		local iButton, iState, elemID = nil, nil, nil
		local playerID = getElemID(source)
		if elem ~= nil then elemID = getElemID(elem) end
		if mouseButton == 'left' then iButton = 0 end
		if mouseButton == 'middle' then iButton = 1 end
		if mouseButton == 'right' then iButton = 2 end
		if buttonState == 'up' then iState = 0 end
		if buttonState == 'down' then iState = 1 end

		procCallOnAll('OnPlayerClickWorld', playerID, iButton, iState, float2cell(worldPosX), float2cell(worldPosY), float2cell(worldPosZ))
		if elem == nil then return end
		if getElementType(elem) == 'player' then
			procCallOnAll('OnPlayerClickWorldPlayer', playerID, iButton, iState, elemID, float2cell(worldPosX), float2cell(worldPosY), float2cell(worldPosZ))
		end
		if getElementType(elem) == 'object' then
			procCallOnAll('OnPlayerClickWorldObject', playerID, iButton, iState, elemID, float2cell(worldPosX), float2cell(worldPosY), float2cell(worldPosZ))
		end
		if getElementType(elem) == 'vehicle' then
			procCallOnAll('OnPlayerClickWorldVehicle', playerID, iButton, iState, elemID, float2cell(worldPosX), float2cell(worldPosY), float2cell(worldPosZ))
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
