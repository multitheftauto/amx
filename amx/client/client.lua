local dxDrawText = dxDrawText
local tocolor = tocolor

local VEHICLE_DROP_TRY_INTERVAL = 100
local VEHICLE_DROP_MAX_TRIES = 30

local MENU_ITEM_HEIGHT = 25
local MENU_TOP_PADDING = MENU_ITEM_HEIGHT * 2
local MENU_BOTTOM_PADDING = 10
local MENU_SIDE_PADDING = 20

local defaultEmptyTableMt = {
	__index = function(t, k)
		local info = {}
		t[k] = info
		return t[k]
	end
}

g_Vehicles = {}
setmetatable(g_Vehicles, defaultEmptyTableMt)

g_Menus = {}
g_PlayerObjects = {}
g_TextDraws = {}
g_TextLabels = {}
g_Blips = {}

addEventHandler('onClientResourceStart', resourceRoot,
	function()
		triggerServerEvent('onLoadedAtClient', resourceRoot)
		setTimer(checkTextLabels, 500, 0)
	end,
	false
)

function enableDebug()
	local state = not isDebugViewActive()
	setDebugViewActive(state)
end
addCommandHandler('debug', enableDebug)

function setAMXVersion(ver)
	g_AMXVersion = ver
end

function gamemodeLoad()
	setTime(12, 0)
	setAmbientSoundEnabled('gunfire', false)
	setDebugViewActive(true)
end

function destroyGlobalElements()
	for id, vehicle in pairs(g_Vehicles) do
		g_Vehicles[id] = nil
	end

	for id, menu in pairs(g_Menus) do
		DestroyMenu(id)
	end

	for id, textlabel in pairs(g_TextLabels) do
		Delete3DTextLabel(id)
	end

	for id, textdraw in pairs(g_TextDraws) do
		destroyTextDraw(textdraw)
	end

	table.each(g_Blips, destroyElement)
	table.each(g_PlayerObjects, destroyElement)
end

function gamemodeUnload()
	if g_ClassSelectionInfo then
		if g_ClassSelectionInfo.gui then
			table.each(g_ClassSelectionInfo.gui, destroyElement)
		end
		g_ClassSelectionInfo = nil
	end
	DisablePlayerCheckpoint()
	DisablePlayerRaceCheckpoint()
	destroyAllGameTexts()
	destroyClassSelGUI()
	if g_WorldBounds and g_WorldBounds.handled then
		removeEventHandler('onClientRender', root, checkWorldBounds)
		g_WorldBounds = nil
	end
	destroyGlobalElements()
	setElementAlpha(localPlayer, 255)
end
-----------------------------
-- Class selection screen

function startClassSelection(classInfo)
	g_ClassSelectionInfo = classInfo

	-- environment
	if g_StartTime then
		setTime(unpack(g_StartTime))
		g_StartTime = nil
	end
	if g_StartWeather then
		setWeather(g_StartWeather)
		g_StartWeather = nil
	end

	setElementCollisionsEnabled(localPlayer, false)

	-- interaction
	if not g_ClassSelectionInfo.selectedclass then
		g_ClassSelectionInfo.selectedclass = 0
	end
	g_ClassSelectionInfo.gui = {
		img = guiCreateStaticImage(35, screenHeight - 410, 205, 236, 'images/logo_small.png', false),
		btnLeft = guiCreateButton(screenWidth / 2 - 145 - 70, screenHeight - 100, 140, 20, '<<<', false),
		btnRight = guiCreateButton(screenWidth / 2 - 70, screenHeight - 100, 140, 20, '>>>', false),
		btnSpawn = guiCreateButton(screenWidth / 2 + 145 - 70, screenHeight - 100, 140, 20, 'Spawn', false)
	}

	addEventHandler('onClientGUIClick', g_ClassSelectionInfo.gui.btnLeft, ClassSelLeft)
	addEventHandler('onClientGUIClick', g_ClassSelectionInfo.gui.btnRight, ClassSelRight)
	addEventHandler('onClientGUIClick', g_ClassSelectionInfo.gui.btnSpawn, ClassSelSpawn)

	showCursor(true)
	removeEventHandler('onClientRender', root, renderClassSelText)
	addEventHandler('onClientRender', root, renderClassSelText)
end

function ClassSelLeft()
	server.requestClass(localPlayer, false, false, -1)
end

function ClassSelRight()
	server.requestClass(localPlayer, false, false, 1)
end

function ClassSelSpawn()
	server.requestSpawn(localPlayer, false, false)
end

function renderClassSelText()
	if not g_ClassSelectionInfo then
		return
	end

	drawShadowText(g_AMXVersion, 20, screenHeight - 170, tocolor(39, 171, 250), 1, 'default-bold', 1, 230)
	drawShadowText('Use left and right arrow keys to select class.', 20, screenHeight - 150, tocolor(240, 240, 240))
	drawShadowText('Press SHIFT when ready to spawn.', 20, screenHeight - 136, tocolor(240, 240, 240))

	if not g_ClassSelectionInfo[0] or not g_ClassSelectionInfo.selectedclass then
		return
	end

	drawShadowText('Class ' .. g_ClassSelectionInfo.selectedclass .. ' weapons:', 20, screenHeight - 110, tocolor(240, 240, 240))
	local weapon, ammo, linenum, line
	linenum = 0
	for i, weapondata in ipairs(g_ClassSelectionInfo[g_ClassSelectionInfo.selectedclass].weapons) do
		weapon, ammo = weapondata[1], weapondata[2]
		if weapon > 0 and ammo ~= -1 then
			linenum = linenum + 1
			if ammo ~= 0 then
				line = ammo .. 'x '
			else
				line = ''
			end
			line = line .. (getWeaponNameFromID(weapon) or weapon)
			drawShadowText(line, 25, screenHeight - 110 + 14 * linenum, tocolor(240, 240, 240))
		end
	end
end

function selectClass(classid)
	fadeCamera(true)
	g_ClassSelectionInfo.selectedclass = classid
end

function destroyClassSelGUI()
	if g_ClassSelectionInfo and g_ClassSelectionInfo.gui then
		for i, elem in pairs(g_ClassSelectionInfo.gui) do
			destroyElement(elem)
		end
		g_ClassSelectionInfo.gui = nil
		removeEventHandler('onClientRender', root, renderClassSelText)
	end

	setCameraTarget(localPlayer)
	setElementCollisionsEnabled(localPlayer, true)
	ShowPlayerDialog(-1, -1, '', '', '', '') -- hide any dialog and cursor

	if g_ClassSelectionInfo and g_ClassSelectionInfo.gui then
		removeEventHandler('onClientGUIClick', g_ClassSelectionInfo.gui.btnLeft, ClassSelLeft)
		removeEventHandler('onClientGUIClick', g_ClassSelectionInfo.gui.btnRight, ClassSelRight)
		removeEventHandler('onClientGUIClick', g_ClassSelectionInfo.gui.btnSpawn, ClassSelSpawn)
	end
end

addEventHandler('onClientResourceStop', resourceRoot,
	function()
		destroyClassSelGUI()
		TogglePlayerClock(true)
		removeEventHandler('onClientRender', root, renderTextDraws)
		removeEventHandler('onClientRender', root, renderMenu)
		cancelSelectTextDraw()
	end
)
-----------------------------
-- Camera

g_IntroScenes = {
	{ pos = {1480.6602783203, -895.64221191406, 59.47342300415},   lookat = {1425.9151611328, -811.95843505859, 80.428070068359}, hour = 22 },
	{ pos = {340.99697875977, -2056.0290527344, 12.975963592529},  lookat = {414.72384643555, -1988.4691162109, 18.528661727905}  },
	{ pos = {587.87091064453, -1603.4930419922, 56.795890808105},  lookat = {503.70782470703, -1549.4876708984, 12.30154800415}   },
	{ pos = {2087.1223144531, 1326.7012939453, 12.497343063354},   lookat = {2177.5185546875, 1283.9398193359, 25.791206359863}   },
	{ pos = {-2350.7131347656, 2616.9641113281, 59.754123687744},  lookat = {-2389.2639160156, 2524.6936035156, 51.430431365967}  },
	{ pos = {-2134.8439941406, 648.99450683594, 58.182228088379},  lookat = {-2190.6123046875, 565.98913574219, 48.198886871338}  },
	{ pos = {-1920.4506835938, 671.93243408203, 46.611064910889},  lookat = {-2010.3052978516, 628.04443359375, 97.929328918457}  },
	{ pos = {-2826.470703125, -321.03930664063, 15.318729400635},  lookat = {-2726.5969238281, -316.01550292969, 35.185661315918} },
	{ pos = {1962.1159667969, -1243.6359863281, 21.70813369751},   lookat = {1936.1663818359, -1147.0615234375, 22.263687133789}  },
	{ pos = {709.04748535156, -768.44177246094, 93.960334777832},  lookat = {721.93560791016, -867.60778808594, 62.820266723633}  },
	{ pos = {-273.57577514648, -1792.1629638672, 44.541469573975}, lookat = {-318.5471496582, -1881.4802246094, 51.203201293945}, hour = 0 },
	{ pos = {-1617.8410644531, 483.92135620117, 76.319374084473},  lookat = {-1615.3560791016, 583.89050292969, 70.766677856445}, hour = 0 }
}

local introSceneShown = false
function showIntroScene()
	if introSceneShown then
		return
	end
	fadeCamera(true)

	local scene = table.random(g_IntroScenes)
	setCameraMatrix(scene.pos[1], scene.pos[2], scene.pos[3], scene.lookat[1], scene.lookat[2], scene.lookat[3])
	g_StartTime = { getTime() }
	g_StartWeather = getWeather()
	setTime(scene.hour or 12, 0)
	setWeather(0)

	introSceneShown = true
end
-----------------------------
-- Pickup related

function pickupOnInteriorChangeLoop()
	local vw = getElementDimension(localPlayer)
	local interior = getElementInterior(localPlayer)

	-- Only for those that are streamed in
	for i, v in ipairs(getElementsByType('pickup', root)) do
		if isElement(v) then
			setElementInterior(v, interior)
			setElementDimension(v, vw)
		end
	end
end

local function clientPlayerPickupHit(thePickup, matchingDimension)
	triggerServerEvent('onPlayerPickUpPickup_Ev', localPlayer, thePickup)
end
addEventHandler('onClientPlayerPickupHit', localPlayer, clientPlayerPickupHit)

local interiorTimerPtr = false
local function clientInteriorChange(oldInt, interior)
	if interiorTimerPtr then return end

	-- Every second check for pickups
	interiorTimerPtr = setTimer(pickupOnInteriorChangeLoop, 1000, 0)
end
addEventHandler('onClientElementInteriorChange', localPlayer, clientInteriorChange)
-----------------------------
-- Camera related

function removeCamHandlers()
	removeInterpCamHandler()
	removeCamAttachHandler()
end

-- Camera attachments
-- Based on https://forum.multitheftauto.com/topic/36692-move-camera-by-mouse-like-normal/#comment-368670
local ca = {}
ca.active = 0
ca.objCamPos = nil
ca.dist = 0.025
ca.speed = 5
ca.x = math.rad(60)
ca.y = math.rad(60)
ca.z = math.rad(15)
ca.maxZ = math.rad(89)
ca.minZ = math.rad(-45)

function removeCamAttachHandler()
	--outputConsole('removeCamAttachHandler was called')
	if (ca.active == 1) then
		--outputConsole('Destroying cam attach handler...')
		ca.active = 0
	end
end

function camAttachRender()
	if (ca.active == 1) then
		local x1, y1, z1 = 0.0, 0.0, 0.0
		if isElement(ca.objCamPos) then
			x1, y1, z1 = getElementPosition(ca.objCamPos)
		end
		local camDist = ca.dist
		local cosZ = math.cos(ca.z)
		local camX = x1 + math.cos(ca.x) * camDist * cosZ
		local camY = y1 + math.sin(ca.y) * camDist * cosZ
		local camZ = z1 + math.sin(ca.z) * camDist
		setCameraMatrix(camX, camY, camZ, x1, y1, z1)

		-- If aiming, set the target (does nothing, todo fix)
		if getPedTask(localPlayer, 'secondary', 0) == 'TASK_SIMPLE_USE_GUN' or isPedDoingGangDriveby(localPlayer) then
			setPedAimTarget(localPlayer, camX, camY, camZ)
			setPlayerHudComponentVisible(localPlayer, 'crosshair', true)
			--outputConsole('ped is aiming')
		end

		--outputConsole(string.format('camAttachRender - Camera Matrix is: CamPos: %f %f %f CamLookAt: %f %f %f', camX, camY, camZ, x1, y1, z1))
	else
		removeEventHandler('onClientPreRender', root, camAttachRender)
	end
end

function cursorMouseMoveHandler(curX, curY, absX, absY)
	if (ca.active == 1) then
		if isCursorShowing() or isMainMenuActive() then return end
		if isChatBoxInputActive() or isConsoleActive() then return end

		local diffX = curX - 0.5
		local diffY = curY - 0.5
		local camX = ca.x - diffX * ca.speed
		local camY = ca.y - diffX * ca.speed
		local camZ = ca.z + (diffY * ca.speed) / math.pi
		if (camZ > ca.maxZ) then
			camZ = ca.maxZ
		end
		if (camZ < ca.minZ) then
			camZ = ca.minZ
		end
		ca.x = camX
		ca.y = camY
		ca.z = camZ
	else
		removeEventHandler('onClientCursorMove', root, cursorMouseMoveHandler)
	end
end

function AttachCameraToObject(camObj)
	--outputConsole('AttachCameraToObject was called')

	if not isElement(camObj) then
		return
	end

	ca.active = 1
	ca.objCamPos = camObj

	removeEventHandler('onClientPreRender', root, camAttachRender)
	addEventHandler('onClientPreRender', root, camAttachRender)

	removeEventHandler('onClientCursorMove', root, cursorMouseMoveHandler)
	addEventHandler('onClientCursorMove', root, cursorMouseMoveHandler)
end

function AttachCameraToPlayerObject(camobjID)
	--outputConsole('AttachCameraToPlayerObject was called')

	if not isElement(g_PlayerObjects[camobjID]) then
		return
	end

	ca.active = 1
	ca.objCamPos = g_PlayerObjects[camobjID]

	removeEventHandler('onClientPreRender', root, camAttachRender)
	addEventHandler('onClientPreRender', root, camAttachRender)

	removeEventHandler('onClientCursorMove', root, cursorMouseMoveHandler)
	addEventHandler('onClientCursorMove', root, cursorMouseMoveHandler)
end

-- Camera Interpolation
-- Originally from https://wiki.multitheftauto.com/wiki/SmoothMoveCamera
local sm = {}
sm.moov = 0
sm.objCamPos, sm.objLookAt = nil, nil

function removeInterpCamHandler()
	--outputConsole('removeInterpCamHandler was called')
	if (sm.moov == 1) then
		--outputConsole('Destroying cam handler...')
		sm.moov = 0
	end
end

function camRender()
	if (sm.moov == 1) then
		local x1, y1, z1, x2, y2, z2 = 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
		if isElement(sm.objCamPos) then
			x1, y1, z1 = getElementPosition(sm.objCamPos)
		end
		if isElement(sm.objLookAt) then
			x2, y2, z2 = getElementPosition(sm.objLookAt)
		end
		--outputConsole(string.format('Current Camera Matrix is: CamPos: %f %f %f CamLookAt: %f %f %f', x1, y1, z1, x2, y2, z2))
		setCameraMatrix(x1, y1, z1, x2, y2, z2)
	else
		removeEventHandler('onClientPreRender', root, camRender)
	end
end

function setupCameraObject(FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut)
	sm.moov = 1
	local camObj = createObject(1337, FromX, FromY, FromZ)
	setElementCollisionsEnabled(camObj, false)
	setElementAlpha(camObj, 0)
	setObjectScale(camObj, 0.01)
	moveObject(camObj, time, ToX, ToY, ToZ, ToX, ToY, ToZ, 'InOutQuad')
	setTimer(removeInterpCamHandler, time, 1)
	setTimer(destroyElement, time, 1, camObj)
	return camObj
end

function InterpolateCameraPos(FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut)
	--outputConsole(string.format('InterpolateCameraPos called with args %f %f %f %f %f %f %d %d', FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut))
	sm.objCamPos = setupCameraObject(FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut)
	addEventHandler('onClientPreRender', root, camRender)
end

function InterpolateCameraLookAt(FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut)
	--outputConsole(string.format('InterpolateCameraLookAt called with args %f %f %f %f %f %f %d %d', FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut))
	sm.objLookAt = setupCameraObject(FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut)
	addEventHandler('onClientPreRender', root, camRender)
end
-----------------------------
-- Player objects

function RemoveBuildingForPlayer(model, x, y, z, radius)
	if model == -1 then
		for i = 321, 18630 do -- Remove all world models around radius if they sent -1
			removeWorldModel(i, radius, x, y, z)
		end
		return -- Don't run the rest of the code
	end
	removeWorldModel(model, radius, x, y, z)
	return
end

function RestoreBuildingForPlayer(model, x, y, z, radius)
	if model == -1 then
		for i = 321, 18630 do -- Restore all world models around radius if they sent -1
			restoreWorldModel(i, radius, x, y, z)
		end
		return -- Don't run the rest of the code
	end
	restoreWorldModel(model, radius, x, y, z)
	return
end

function RestoreAllBuildingsForPlayer()
	restoreAllWorldModels()
end

function AttachPlayerObjectToPlayer(objID, attachPlayer, offsetX, offsetY, offsetZ, rX, rY, rZ)
	local obj = g_PlayerObjects[objID]
	if not obj then
		return
	end
	attachElements(obj, attachPlayer, offsetX, offsetY, offsetZ, rX, rY, rZ)
end

function AttachPlayerObjectToVehicle(objID, attachVehicle, offsetX, offsetY, offsetZ, rX, rY, rZ)
	local obj = g_PlayerObjects[objID]
	if not obj then
		return
	end
	attachElements(obj, attachVehicle, offsetX, offsetY, offsetZ, rX, rY, rZ)
end

function CreatePlayerObject(objID, model, x, y, z, rX, rY, rZ)
	g_PlayerObjects[objID] = createObject(model, x, y, z, rX, rY, rZ)
	if not g_PlayerObjects[objID] then
		g_PlayerObjects[objID] = createObject(1337, x, y, z, rX, rY, rZ) -- Create a dummy object anyway since createobject can also be used to make camera attachments
		setElementAlpha(g_PlayerObjects[objID], 0)
		setElementCollisionsEnabled(g_PlayerObjects[objID], false)
	end
end

function DestroyPlayerObject(objID)
	local obj = g_PlayerObjects[objID]
	if not obj then
		return
	end
	destroyElement(obj)
	g_PlayerObjects[objID] = nil
end

function MovePlayerObject(objID, x, y, z, speed, rX, rY, rZ)
	local obj = g_PlayerObjects[objID]
	if not obj then return 0 end

	local distance = getDistanceBetweenPoints3D(x, y, z, getElementPosition(obj))
	local time = distance / speed * 1000

	-- We need relative rotation
	local cRotX, cRotY, cRotZ = getElementRotation(obj)
	cRotX = cRotX - rX
	cRotY = cRotY - rY
	cRotZ = cRotZ - rZ

	-- -1000 or less means no rotation change, so set it to 0.0
	if rX <= -1000.0 then cRotX = 0.0 end
	if rY <= -1000.0 then cRotY = 0.0 end
	if rZ <= -1000.0 then cRotZ = 0.0 end

	moveObject(obj, time, x, y, z, cRotX, cRotY, cRotZ)
	return math.floor(time)
end

function SetPlayerObjectPos(objID, x, y, z)
	local obj = g_PlayerObjects[objID]
	if not obj then
		return
	end
	setElementPosition(obj, x, y, z)
end

function SetPlayerObjectRot(objID, rX, rY, rZ)
	local obj = g_PlayerObjects[objID]
	if not obj then
		return
	end
	setElementRotation(obj, rX, rY, rZ)
end

function StopPlayerObject(objID)
	local obj = g_PlayerObjects[objID]
	if not obj then
		return
	end
	stopObject(obj)
end
-----------------------------
-- Audio & SFX

local pAudioStreamSound = nil -- SA-MP can only do one stream at a time anyway
function PlayAudioStreamForPlayer(url, posX, posY, posZ, distance, usepos)
	--outputConsole(string.format('PlayAudioStreamForPlayer called with args %s %f %f %f %f %d', url, posX, posY, posZ, distance, usepos))
	if pAudioStreamSound and isElement(pAudioStreamSound) then -- If there's one already playing, stop it
		--outputConsole('PlayAudioStreamForPlayer is stopping an audio stream')
		stopSound(pAudioStreamSound)
	end

	if not usepos then
		--outputConsole(string.format('PlayAudioStreamForPlayer now playing non-3d sound %s', url))
		pAudioStreamSound = playSound(url)
	else
		--outputConsole(string.format('PlayAudioStreamForPlayer now playing 3d sound %s with max dist %d', url, distance))
		pAudioStreamSound = playSound3D(url, posX, posY, posZ)
		setSoundMaxDistance(pAudioStreamSound, distance)
	end

	if pAudioStreamSound and isElement(pAudioStreamSound) then
		setSoundVolume(pAudioStreamSound, 1.0)
	end
end

function StopAudioStreamForPlayer()
	if not pAudioStreamSound then return end
	if not isElement(pAudioStreamSound) then return end

	stopSound(pAudioStreamSound)
end

local sfxSound = nil
function PlayerPlaySound(soundid, posX, posY, posZ)
	if sfxSound and isElement(sfxSound) then
		stopSound(sfxSound)
	end

	-- only 'script' container supported
	if not getSFXStatus('script') then return end

	for bankId = 1, #SFX_Offset do
		local bank = SFX_Offset[bankId]
		local first = bank.first
		local last = bank.last or first

		if soundid >= first and soundid <= last then
			local bankIdx = bankId - 1
			local audioEvent = soundid - first

			if posX ~= 0.0 or posY ~= 0.0 or posZ ~= 0.0 then
				--outputConsole(string.format('PlayerPlaySound now playing 3d sound %d (bank %d)', audioEvent, bankIdx))
				sfxSound = playSFX3D('script', bankIdx, audioEvent, posX, posY, posZ)
			else
				--outputConsole(string.format('PlayerPlaySound now playing non-3d sound %d (bank %d)', audioEvent, bankIdx))
				sfxSound = playSFX('script', bankIdx, audioEvent)
			end
			break
		end
	end

	if sfxSound and isElement(sfxSound) then
		setSoundVolume(sfxSound, 1.0)
	end
end
-----------------------------
-- Checkpoints

function OnPlayerEnterCheckpoint(elem)
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if (vehicle and elem == vehicle) or (not vehicle and elem == localPlayer) then
		triggerServerEvent('onPlayerCheckpoint_Ev', localPlayer, true)
	end
end

function OnPlayerLeaveCheckpoint(elem)
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if (vehicle and elem == vehicle) or (not vehicle and elem == localPlayer) then
		triggerServerEvent('onPlayerCheckpoint_Ev', localPlayer, false)
	end
end

function DisablePlayerCheckpoint()
	if not g_PlayerCheckpoint then
		return
	end
	removeEventHandler('onClientColShapeHit', g_PlayerCheckpoint.colshape, OnPlayerEnterCheckpoint)
	removeEventHandler('onClientColShapeLeave', g_PlayerCheckpoint.colshape, OnPlayerLeaveCheckpoint)
	for k, elem in pairs(g_PlayerCheckpoint) do
		destroyElement(elem)
	end
	g_PlayerCheckpoint = nil
end

function SetPlayerCheckpoint(x, y, z, size)
	if g_PlayerCheckpoint then
		DisablePlayerCheckpoint()
	end
	local hitZ = getGroundPosition(x, y, z)
	if hitZ and hitZ ~= 0 then z = hitZ end
	g_PlayerCheckpoint = {
		marker = createMarker(x, y, z, 'cylinder', size, 255, 0, 0, 150),
		colshape = createColCircle(x, y, size),
		blip = createBlip(x, y, z)
	}
	setBlipOrdering(g_PlayerCheckpoint.blip, 2)
	setElementAlpha(g_PlayerCheckpoint.marker, 128)
	addEventHandler('onClientColShapeHit', g_PlayerCheckpoint.colshape, OnPlayerEnterCheckpoint)
	addEventHandler('onClientColShapeLeave', g_PlayerCheckpoint.colshape, OnPlayerLeaveCheckpoint)
end

function OnPlayerEnterRaceCheckpoint(elem)
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if (vehicle and elem == vehicle) or (not vehicle and elem == localPlayer) then
		triggerServerEvent('onPlayerRaceCheckpoint_Ev', localPlayer, true)
	end
end

function OnPlayerLeaveRaceCheckpoint(elem)
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if (vehicle and elem == vehicle) or (not vehicle and elem == localPlayer) then
		triggerServerEvent('onPlayerRaceCheckpoint_Ev', localPlayer, false)
	end
end

function DisablePlayerRaceCheckpoint()
	if not g_PlayerRaceCheckpoint then
		return
	end
	removeEventHandler('onClientColShapeHit', g_PlayerRaceCheckpoint.colshape, OnPlayerEnterRaceCheckpoint)
	removeEventHandler('onClientColShapeLeave', g_PlayerRaceCheckpoint.colshape, OnPlayerLeaveRaceCheckpoint)
	for k, elem in pairs(g_PlayerRaceCheckpoint) do
		destroyElement(elem)
	end
	g_PlayerRaceCheckpoint = nil
end

function SetPlayerRaceCheckpoint(type, x, y, z, nextX, nextY, nextZ, size)
	if g_PlayerRaceCheckpoint then
		DisablePlayerRaceCheckpoint()
	end
	g_PlayerRaceCheckpoint = {
		marker = createMarker(x, y, z, type < 2 and 'checkpoint' or 'ring', size, 255, 0, 0),
		colshape = type < 2 and createColCircle(x, y, size) or createColSphere(x, y, z, size * 1.5),
		blip = createBlip(x, y, z, 0, 2, 255, 0, 0),
		nextblip = createBlip(nextX, nextY, nextZ, 0, 1, 255, 0, 0)
	}
	setBlipOrdering(g_PlayerRaceCheckpoint.blip, 2)
	setBlipOrdering(g_PlayerRaceCheckpoint.nextblip, 2)
	if type == 1 or type == 4 then
		setMarkerIcon(g_PlayerRaceCheckpoint.marker, 'finish')
	end
	setElementAlpha(g_PlayerRaceCheckpoint.marker, 128)
	setMarkerTarget(g_PlayerRaceCheckpoint.marker, nextX, nextY, nextZ)
	addEventHandler('onClientColShapeHit', g_PlayerRaceCheckpoint.colshape, OnPlayerEnterRaceCheckpoint)
	addEventHandler('onClientColShapeLeave', g_PlayerRaceCheckpoint.colshape, OnPlayerLeaveRaceCheckpoint)
end
-----------------------------
-- Vehicles

function SetVehicleParamsForPlayer(vehicle, isObjective, doorsLocked)
	local vehID = getElemID(vehicle)
	if not vehID then
		return
	end
	if isObjective then
		local vehInfo = g_Vehicles[vehID]
		if isElement(vehInfo.blip) then
			destroyElement(vehInfo.blip)
		end

		vehInfo.blip = createBlipAttachedTo(vehicle, 0, 2, 226, 192, 99)
		setBlipOrdering(vehInfo.blip, 1)
		vehInfo.blippersistent = true
		setElementParent(vehInfo.blip, vehicle)

		if not vehInfo.marker then
			local x, y, z = getElementPosition(vehicle)
			vehInfo.marker = createMarker(x, y, z, 'arrow', 2, 255, 255, 100)
			attachElements(vehInfo.marker, vehicle, 0, 0, 6)
			setElementParent(vehInfo.marker, vehicle)
		end
	end
	setVehicleLocked(vehicle, doorsLocked)
end

local vehicleDrops = {}		-- { [vehicle] = { timer = timer, tries = tries } }

function dropVehicle(vehicle)
	local dropdata = vehicleDrops[vehicle]
	if not dropdata then
		return
	end
	dropdata.tries = dropdata.tries + 1
	if dropdata.tries >= VEHICLE_DROP_MAX_TRIES then
		vehicleDrops[vehicle] = nil
	end
	if not isElement(vehicle) or not isVehicleEmpty(vehicle) then
		if isElement(vehicle) then
			setElementCollisionsEnabled(vehicle, true)
		end
		if dropdata.tries < VEHICLE_DROP_MAX_TRIES then
			killTimer(dropdata.timer)
		end
		vehicleDrops[vehicle] = nil
		return
	end

	local _, _, bottom, _, _, top = getElementBoundingBox(vehicle)
	if not bottom then
		top = getElementDistanceFromCentreOfMassToBaseOfModel(vehicle)
		if not top then
			return
		end
		bottom = -top
	end
	local x, y, z = getElementPosition(vehicle)

	local _, _, _, hitZ = processLineOfSight(x, y, z + top, x, y, z - 10, true, false)
	hitZ = hitZ or getGroundPosition(x, y, z + top)
	if hitZ then
		setElementCollisionsEnabled(vehicle, true)
		if z < hitZ - bottom - 0.5 or top > 2 then
			local _, _, rz = getElementRotation(vehicle)
			setElementPosition(vehicle, x, y, hitZ + 2 * math.abs(bottom))
			setElementRotation(vehicle, 0, 0, rz)
			setElementVelocity(vehicle, 0, 0, -0.05)
		end
		if dropdata.tries < VEHICLE_DROP_MAX_TRIES then
			killTimer(dropdata.timer)
		end
		vehicleDrops[vehicle] = nil
	elseif dropdata.tries >= VEHICLE_DROP_MAX_TRIES then
		setElementCollisionsEnabled(vehicle, true)
	end
end

local localVehicle = false
local remoteCollisionDisabled = false

addEventHandler('onClientElementStreamIn', root,
	function()
		if getElementType(source) == 'vehicle' then
			-- drop floating/underground vehicles
			local specVeh = getVehicleType(source) == 'Boat' or getVehicleType(source) == 'Train'
			if not vehicleDrops[source] and isVehicleEmpty(source) and not specVeh then
				setElementCollisionsEnabled(source, false)
				local timer = setTimer(dropVehicle, VEHICLE_DROP_TRY_INTERVAL, VEHICLE_DROP_MAX_TRIES, source)
				vehicleDrops[source] = { timer = timer, tries = 0 }
			end

			local vehID = getElemID(source)
			local vehInfo = vehID and g_Vehicles[vehID]

			if vehInfo and not vehInfo.blip and not getVehicleOccupant(source) then
				vehInfo.blip = createBlipAttachedTo(source, 0, 1, 136, 136, 136, 150, 0, 500.0)
				setElementParent(vehInfo.blip, source)
			end

			setVehicleWindowOpen(source, 2, not getElementData(source, 'WindowFrontRight'))
			setVehicleWindowOpen(source, 3, not getElementData(source, 'WindowRearRight'))
			setVehicleWindowOpen(source, 4, not getElementData(source, 'WindowFrontLeft'))
			setVehicleWindowOpen(source, 5, not getElementData(source, 'WindowRearLeft'))

			if localVehicle and source ~= localVehicle then
				local collide = not (remoteCollisionDisabled and getVehicleOccupant(source))
				setElementCollidableWith(localVehicle, source, collide)
			end

			if getVehicleType(source) == 'Train' and getVehicleTowingVehicle(source) then
				-- if it's a train carriage, don't call stream event
				return
			end

			triggerServerEvent('onVehicleStream_Ev', localPlayer, source, true)
		elseif getElementType(source) == 'player' then
			if source == localPlayer then return end
			triggerServerEvent('onPlayerStream_Ev', localPlayer, source, true)
		elseif getElementType(source) == 'ped' then
			if getElementData(source, 'ActorPed') then
				triggerServerEvent('onActorStream_Ev', localPlayer, source, true)
			else
				triggerServerEvent('onBotStream_Ev', localPlayer, source, true)
			end
		end
	end
)

addEventHandler('onClientElementStreamOut', root,
	function()
		if getElementType(source) == 'vehicle' then
			local vehID = getElemID(source)
			local vehInfo = vehID and g_Vehicles[vehID]

			if vehInfo and vehInfo.blip and not vehInfo.blippersistent then
				if isElement(vehInfo.blip) then
					destroyElement(vehInfo.blip)
				end
				vehInfo.blip = nil
			end

			if getVehicleType(source) == 'Train' and getVehicleTowingVehicle(source) then
				-- if it's a train carriage, don't call stream event
				return
			end

			triggerServerEvent('onVehicleStream_Ev', localPlayer, source, false)
		elseif getElementType(source) == 'player' then
			if source == localPlayer then return end
			triggerServerEvent('onPlayerStream_Ev', localPlayer, source, false)
		elseif getElementType(source) == 'ped' then
			if getElementData(source, 'ActorPed') then
				triggerServerEvent('onActorStream_Ev', localPlayer, source, false)
			else
				triggerServerEvent('onBotStream_Ev', localPlayer, source, false)
			end
		end
	end
)

local function clientPlayerQuit(reason)
	local vehicle = getPedOccupiedVehicle(source)
	if vehicle then
		local vehInfo = g_Vehicles[getElemID(vehicle)]

		if vehInfo and not vehInfo.blip then
			vehInfo.blip = createBlipAttachedTo(vehicle, 0, 1, 136, 136, 136, 150, 0, 500.0)
			setElementParent(vehInfo.blip, vehicle)
		end
	end
end
addEventHandler('onClientPlayerQuit', root, clientPlayerQuit)

local function clientPlayerStuntFinish(stuntType, stuntTime, stuntDistance)
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if not vehicle then return cancelEvent() end

	triggerServerEvent('onPlayerStunt_Ev', localPlayer, vehicle, stuntType, stuntTime, stuntDistance)
end
addEventHandler('onClientPlayerStuntFinish', root, clientPlayerStuntFinish)

local friendlyFire = false

local function clientVehicleDamage(attacker, weapon, loss, x, y, z, tire)
	if not isElement(source) then return end

	-- get the driver from either players or peds
	local occupants = getVehicleOccupants(source)
	local driver = occupants and occupants[0] -- seat 0

	if not driver then
		-- block any damage for unoccupied vehicles like SA-MP does
		return cancelEvent()
	end

	if friendlyFire then
		local issuer = attacker

		if issuer then
			if getElementType(issuer) == 'vehicle' then
				issuer = getVehicleOccupant(issuer)
			end
			if issuer == driver then
				issuer = nil
			end
		end

		local team = getPlayerTeam(driver)
		if issuer and team and getTeamName(team) ~= 'Team 256' then
			if getPlayerTeam(issuer) == team then
				-- block any damage from a teammate
				return cancelEvent()
			end
		end
	end

	if driver ~= localPlayer then return end
	triggerServerEvent('onVehicleDamageStatusUpdate_Ev', localPlayer, source)
end
addEventHandler('onClientVehicleDamage', root, clientVehicleDamage)

-- emulate SA-MP behaviour: block enter attempts as driver to locked vehicles
addEventHandler('onClientVehicleStartEnter', root,
	function(player, seat, door)
		if (player == localPlayer and seat == 0 and isVehicleLocked(source)) then
			cancelEvent()
		end
	end
)

addEventHandler('onClientVehicleEnter', root,
	function(player, seat)
		if seat == 0 then
			local vehInfo = g_Vehicles[getElemID(source)]

			if vehInfo and vehInfo.blip and not vehInfo.blippersistent then
				if isElement(vehInfo.blip) then
					destroyElement(vehInfo.blip)
				end
				vehInfo.blip = nil
			end

			if player == localPlayer then
				localVehicle = source
				for _, veh in ipairs(getElementsByType('vehicle', root, true)) do
					if veh ~= source then
						local collide = not (remoteCollisionDisabled and getVehicleOccupant(veh))
						setElementCollidableWith(source, veh, collide)
					end
				end
			elseif remoteCollisionDisabled then
				if localVehicle and source ~= localVehicle then
					setElementCollidableWith(localVehicle, source, false)
				end
			end
		end
	end
)

addEventHandler('onClientVehicleExit', root,
	function(player, seat)
		if seat == 0 then
			local vehInfo = g_Vehicles[getElemID(source)]

			if vehInfo and not vehInfo.blip then
				vehInfo.blip = createBlipAttachedTo(source, 0, 1, 136, 136, 136, 150, 0, 500.0)
				setElementParent(vehInfo.blip, source)
			end

			if player == localPlayer then
				localVehicle = false
				for _, veh in ipairs(getElementsByType('vehicle', root, true)) do
					if veh ~= source then
						setElementCollidableWith(source, veh, true)
					end
				end
			elseif remoteCollisionDisabled then
				if localVehicle and source ~= localVehicle then
					setElementCollidableWith(localVehicle, source, true)
				end
			end
		end
	end
)

function DestroyVehicle(vehID)
	g_Vehicles[vehID] = nil
end

function updateRemoteCollision(disable)
	remoteCollisionDisabled = disable

	localVehicle = getPedOccupiedVehicle(localPlayer)
	if localVehicle and getVehicleOccupant(localVehicle) == localPlayer then
		for _, veh in ipairs(getElementsByType('vehicle', root, true)) do
			if veh ~= localVehicle then
				local collide = not (disable and getVehicleOccupant(veh))
				setElementCollidableWith(localVehicle, veh, collide)
			end
		end
	else
		localVehicle = false
	end
end

function updateFriendlyFire(enable)
	friendlyFire = enable
end
-----------------------------
-- Text

function visibleTextDrawsExist()
	if table.find(g_TextDraws, 'visible', true) then
		return true
	end
	return false
end

function showTextDraw(textdraw)
	if not visibleTextDrawsExist() then
		addEventHandler('onClientRender', root, renderTextDraws)
	end
	textdraw.visible = true
end

function hideTextDraw(textdraw)
	textdraw.visible = false
	if not visibleTextDrawsExist() then
		removeEventHandler('onClientRender', root, renderTextDraws)
	end
end

function initTextDraw(textdraw)
	if not textdraw then return end
	textdraw.clientTDId = textdraw.clientTDId or (#g_TextDraws + 1)
	g_TextDraws[textdraw.clientTDId] = textdraw

	if textdraw.font then
		-- GTA replaces such brackets with stars on these fonts
		if textdraw.font == 0 or textdraw.font == 2 then
			textdraw.text = textdraw.text:gsub(']', '★')
		end

		-- and also makes chars in same case on these fonts
		if textdraw.font == 2 then
			textdraw.text = textdraw.text:upper()
		elseif textdraw.font == 3 then
			textdraw.text = textdraw.text:lower()
		end
	end

	local tWidth, tHeight = dxGetTextSize(textdraw.text, textdraw.lwidth, textdraw.lheight)
	local lineHeight = (tHeight or 0.25) / 2 -- space between lines (vertical) also used to calculate size of the box if any
	local lineWidth = (tWidth or 0.25) -- space between words (horizontal)

	local text = textdraw.text:gsub('~k~~(.-)~', getSAMPBoundKey)
	local lines = {}
	local pos, stop, c

	stop = 0
	while true do
		pos, stop, c = text:find('~(%a)~', stop + 1)
		if c and c:lower() == 'n' then -- If we found a new line
			lines[#lines + 1] = text:sub(1, pos - 1)
			text = text:sub(stop + 1)
			stop = 0
		elseif not pos then
			lines[#lines + 1] = text
			break
		end
	end
	while #lines > 0 and lines[#lines]:match('^%s*$') do
		lines[#lines] = nil
	end

	textdraw.parts = {}

	local font = g_TextDrawFonts[textdraw.font and textdraw.font >= 0 and textdraw.font <= #g_TextDrawFonts and textdraw.font or 0]
	local baseColor = textdraw.color or tocolor(225, 225, 225)
	local alpha = bitExtract(baseColor, 24, 8)

	local TDXPos = textdraw.x or DEFAULT_SCREEN_WIDTH - #lines * lineWidth
	local TDYPos = textdraw.y or DEFAULT_SCREEN_HEIGHT - #lines * lineHeight

	textdraw.absheight = #lines * lineHeight

	-- Process the lines we previously found
	for _, line in ipairs(lines) do
		local colorpos = 1
		local color

		while true do
			local start = line:find('~%a~', colorpos)
			if not start then
				break
			end

			local extrabright = 0
			colorpos = start
			while true do
				c = line:match('^~(%a)~', colorpos)
				if not c then
					break
				end
				colorpos = colorpos + 3
				c = c:lower()
				if g_TextDrawColorMapping[c] then
					color = g_TextDrawColorMapping[c]
				elseif c == 'h' then
					extrabright = extrabright + 1
				else
					line = line:sub(1, start - 1) .. line:sub(colorpos)
					colorpos = start
					break
				end
			end

			if extrabright > 0 then
				local factor = 1.5 ^ extrabright
				color = color and table.shallowcopy(color) or colorToRGB(baseColor)
				for i = 1, 3 do
					color[i] = math.min(math.floor(color[i] * factor + 0.5), 255)
				end
			elseif not color then
				color = colorToRGB(baseColor)
			end
			baseColor = tocolor(color[1], color[2], color[3], alpha)
			line = line:sub(1, start - 1) .. ('#%02X%02X%02X'):format(unpack(color)) .. line:sub(colorpos)
			colorpos = start + 7
		end

		-- Remove any remaining single tildes
		line = line:gsub('~', '')

		local textWidth = dxGetTextWidth(line:gsub('#%x%x%x%x%x%x', ''), textdraw.lwidth, font)
		textdraw.width = math.max(textdraw.width or 0, textWidth)

		TDXPos = textdraw.x -- left by default

		if textdraw.align == 2 then -- center
			TDXPos = TDXPos - textWidth / 2
		elseif textdraw.align == 3 then -- right
			TDXPos = TDXPos - textWidth
		end

		if color then
			color = textdraw.color or tocolor(225, 225, 225)
		else
			color = baseColor
		end

		colorpos = 1
		local nextcolorpos
		while colorpos < line:len() + 1 do
			local r, g, b = line:sub(colorpos, colorpos + 6):match('#(%x%x)(%x%x)(%x%x)')
			if r then
				color = tocolor(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16), alpha)
				colorpos = colorpos + 7
			end
			nextcolorpos = line:find('#%x%x%x%x%x%x', colorpos) or line:len() + 1
			local part = { text = line:sub(colorpos, nextcolorpos - 1), x = TDXPos, y = TDYPos, color = color }
			table.insert(textdraw.parts, part)
			TDXPos = TDXPos + dxGetTextWidth(part.text, textdraw.lwidth, font)
			colorpos = nextcolorpos
		end
		TDYPos = TDYPos + lineHeight
	end
end

g_TextDrawSelectMode = false
g_TextDrawHoverColor = nil

function getTextDrawClickBounds(textdraw)
	local sourceX = posStretchX(textdraw.x or 0)
	local sourceY = posStretchY(textdraw.y or 0)
	local x, w, h

	if textdraw.boxsize then
		w = posStretchX(textdraw.boxsize[1]) - sourceX
	else
		w = posStretchX(textdraw.width or 0)
	end

	h = posStretchY(textdraw.absheight or 0)
	x = sourceX -- left by default

	if textdraw.align == 2 then -- center
		if textdraw.boxsize then
			w = posStretchX(textdraw.boxsize[2])
		end
		x = sourceX - (w / 2)
	elseif textdraw.align == 3 then -- right
		x = sourceX - w
	end

	return x, sourceY, w, h
end

function getHoveredTextDraw()
	if not g_TextDrawSelectMode then
		return nil
	end

	local cursorX, cursorY = getCursorPosition()
	if not cursorX then
		return nil
	end
	cursorX = cursorX * screenWidth
	cursorY = cursorY * screenHeight

	local hovered
	for id, textdraw in pairs(g_TextDraws) do
		if textdraw.visible and textdraw.selectable then
			local x, y, w, h = getTextDrawClickBounds(textdraw)
			if w > 0 and h > 0 and cursorX >= x and cursorX <= x + w and cursorY >= y and cursorY <= y + h then
				if not hovered or textdraw.clientTDId > hovered.clientTDId then
					hovered = textdraw
				end
			end
		end
	end
	return hovered
end

function renderTextDraws()
	if isPlayerMapVisible() then return end

	local hoveredTextDraw = getHoveredTextDraw()

	for id, textdraw in pairs(g_TextDraws) do
		if textdraw.visible and textdraw.parts and not (textdraw.text:match('^%s*$')) then
			local font = g_TextDrawFonts[textdraw.font and textdraw.font >= 0 and textdraw.font <= #g_TextDrawFonts and textdraw.font or 0]

			local scalex = sizeScaleX(textdraw.lwidth)
			local scaley = sizeScaleY(textdraw.lheight) * 0.5

			local sourceX = posStretchX(textdraw.x)
			local sourceY = posStretchY(textdraw.y)

			-- Process box alignments
			if textdraw.usebox and textdraw.usebox ~= 0 then
				--outputConsole('textdraw uses box: ' .. textdraw.text)
				local boxcolor = textdraw.boxcolor or tocolor(0, 0, 0)
				local x, w, h

				-- Calculates box size
				if textdraw.boxsize then
					w = posStretchX(textdraw.boxsize[1]) - sourceX
				else
					w = posStretchX(textdraw.width)
				end

				h = posStretchY(textdraw.absheight)
				x = sourceX -- left by default

				if textdraw.align == 2 then -- center
					-- need to invert x and y
					if textdraw.boxsize then
						w = posStretchX(textdraw.boxsize[2])
					end

					x = sourceX - (w / 2)
				elseif textdraw.align == 3 then -- right
					x = sourceX - w
				end

				dxDrawRectangle(x, sourceY, w, h, boxcolor)
				--outputConsole(string.format('Drawing textdraw box: sourceX: %f, sourceY: %f %s', sourceX, sourceY, textdraw.text))
			end

			for i, part in pairs(textdraw.parts) do

				sourceX = posStretchX(part.x)
				sourceY = posStretchY(part.y)

				part.text = part.text:gsub('_', ' ') -- replace underscores with spaces
				--outputConsole(string.format('text: %s partx: %f, party: %f sourceX: %f, sourceY: %f', part.text, part.x, part.y, sourceX, sourceY))

				-- Draw the shadow
				if textdraw.shade and textdraw.shade ~= 0 and textdraw.outlinesize == 0 then
					local shade = textdraw.shade * 2
					dxDrawText(
						part.text, sourceX + shade, sourceY + shade, sourceX + shade, sourceY + shade,
						textdraw.outlinecolor or tocolor(0, 0, 0), scalex, scaley, font
					)
				end

				-- Draw the actual text
				local partColor = part.color
				if textdraw == hoveredTextDraw and g_TextDrawHoverColor then
					-- highlighted when hovered in selection mode
					partColor = g_TextDrawHoverColor
				end
				drawBorderText(
					part.text, sourceX, sourceY, partColor, scalex, scaley,
					font, textdraw.outlinesize, textdraw.outlinecolor
				)
			end
		end
	end
end

function destroyTextDraw(textdraw)
	if not textdraw then
		return
	end
	hideTextDraw(textdraw)
	--table.removevalue(g_TextDraws, textdraw)
	g_TextDraws[textdraw.clientTDId] = nil
end

local gameText = {}
local gIndex = 1

function destroyAllGameTexts()
	for i = 1, 100 do
		if gameText[i] then
			destroyGameText(i)
		end
	end
end

function destroyAllGameTextsWithStyle(stylePassed)
	for i = 1, 100 do
		if gameText[i] and gameText[i].style == stylePassed then
			destroyGameText(i)
		end
	end
end

function GameTextForPlayer(text, time, style)
	if gameText[gIndex] then
		destroyGameText(gIndex)
	end

	if style >= 0 and style <= 6 then
		-- So same styles don't overlap
		destroyAllGameTextsWithStyle(style)
	else
		return
	end

	--[[
		alignments
			1 = left
			2 = center
			3 = right
	]]
	gameText[gIndex] = { text = text, outlinesize = 2, shade = 0 }
	if (style >= 0 and style <= 1) or style == 6 then
		if style == 0 then
			gameText[gIndex].x = 0.5 * DEFAULT_SCREEN_WIDTH
			gameText[gIndex].y = 0.45 * DEFAULT_SCREEN_HEIGHT
			gameText[gIndex].color = tocolor(144, 98, 16)
			gameText[gIndex].align = 2
			time = 9000 -- Displays for 9 seconds regardless of time set
		elseif style == 1 then
			gameText[gIndex].x = 0.95 * DEFAULT_SCREEN_WIDTH
			gameText[gIndex].y = 0.7 * DEFAULT_SCREEN_HEIGHT
			gameText[gIndex].color = tocolor(144, 98, 16)
			gameText[gIndex].align = 3
			time = 8000 -- Displays for 8 seconds regardless of time set
		else
			gameText[gIndex].x = 0.5 * DEFAULT_SCREEN_WIDTH
			gameText[gIndex].y = 0.15 * DEFAULT_SCREEN_HEIGHT
			gameText[gIndex].color = tocolor(169, 196, 228)
			gameText[gIndex].align = 2
		end
		gameText[gIndex].lheight = 2.0
		gameText[gIndex].lwidth = 1.0
		gameText[gIndex].font = 3
	elseif style == 2 then
		gameText[gIndex].x = 0.5 * DEFAULT_SCREEN_WIDTH
		gameText[gIndex].y = 0.35 * DEFAULT_SCREEN_HEIGHT
		gameText[gIndex].lheight = 3.0
		gameText[gIndex].lwidth = 2.0
		gameText[gIndex].color = tocolor(225, 225, 225)
		gameText[gIndex].outlinesize = 3
		gameText[gIndex].align = 2
		gameText[gIndex].font = 0
	elseif style >= 3 and style <= 5 then
		gameText[gIndex].x = 0.5 * DEFAULT_SCREEN_WIDTH
		if style == 3 then
			gameText[gIndex].y = 0.35 * DEFAULT_SCREEN_HEIGHT
			gameText[gIndex].color = tocolor(144, 98, 16)
		elseif style == 4 then
			gameText[gIndex].y = 0.25 * DEFAULT_SCREEN_HEIGHT
			gameText[gIndex].color = tocolor(144, 98, 16)
		elseif style == 5 then
			gameText[gIndex].y = 0.5 * DEFAULT_SCREEN_HEIGHT
			gameText[gIndex].color = tocolor(225, 225, 225)
			time = 3000 -- Displays for 3 seconds regardless of time set
		end
		gameText[gIndex].lheight = 2.0
		gameText[gIndex].lwidth = 0.8
		gameText[gIndex].align = 2
		gameText[gIndex].font = 2
	end
	gameText[gIndex].style = style
	initTextDraw(gameText[gIndex])
	showTextDraw(gameText[gIndex])
	gameText[gIndex].timer = setTimer(destroyGameText, time, 1, gIndex)
	gIndex = gIndex >= 100 and 1 or gIndex + 1 -- Limit to 100
end

function destroyGameText(index)
	if not gameText[index] then
		return
	end
	destroyTextDraw(gameText[index])
	if gameText[index].timer then
		killTimer(gameText[index].timer)
		gameText[index].timer = nil
	end
	gameText[index] = nil
end

function renderTextLabels()
	for id, textlabel in pairs(g_TextLabels) do
		if textlabel.enabled then
			if textlabel.attached and isElement(textlabel.attachedTo) then
				local oX, oY, oZ = getElementPosition(textlabel.attachedTo)
				oX = oX + textlabel.offX
				oY = oY + textlabel.offY
				oZ = oZ + textlabel.offZ
				textlabel.X = oX
				textlabel.Y = oY
				textlabel.Z = oZ
			else
				textlabel.attached = false
				textlabel.attachedTo = nil
			end

			local screenX, screenY = getScreenFromWorldPosition(textlabel.X, textlabel.Y, textlabel.Z, textlabel.dist, false)
			local pX, pY, pZ, _, _, _ = getCameraMatrix() --getElementPosition(localPlayer)
			local dist = getDistanceBetweenPoints3D(pX, pY, pZ, textlabel.X, textlabel.Y, textlabel.Z)
			local vw = getElementDimension(localPlayer)

			if screenX and dist <= textlabel.dist and (vw == textlabel.vw or textlabel.vw == -1) then -- Because player textlabels don't have VW's, since we're processing both here
				if not textlabel.los or isLineOfSightClear(pX, pY, pZ, textlabel.X, textlabel.Y, textlabel.Z, true, false, false) then
					dxDrawText(textlabel.text, screenX, screenY, screenX, screenY, tocolor(textlabel.color.r, textlabel.color.g, textlabel.color.b, textlabel.color.a), 1.0, 'default-bold', 'center', 'top', false, false, false, true)
				end
			end
		end
	end
end
addEventHandler('onClientRender', root, renderTextLabels)

function checkTextLabels()
	for id, textlabel in pairs(g_TextLabels) do

		local pX, pY, pZ = getElementPosition(localPlayer)
		local dist = getDistanceBetweenPoints3D(pX, pY, pZ, textlabel.X, textlabel.Y, textlabel.Z)

		if dist <= textlabel.dist then
			textlabel.enabled = true
		else
			textlabel.enabled = false
		end

	end
end

function Create3DTextLabel(id, textlabel)
	textlabel.id = id
	--outputConsole('Created text label with id ' .. textlabel.id)
	textlabel.enabled = false
	g_TextLabels[id] = textlabel
end

function Delete3DTextLabel(id)
	g_TextLabels[id] = nil
end

function Attach3DTextLabel(textlabel)
	local id = textlabel.id
	--outputConsole('Attaching text label with id ' .. textlabel.id)
	textlabel.enabled = true
	g_TextLabels[id] = textlabel
end

function Update3DTextLabel(textlabel)
	local id = textlabel.id
	--outputConsole('Updating text label with id ' .. textlabel.id)
	g_TextLabels[id] = textlabel
end

function TextDrawCreate(id, textdraw)
	textdraw.clientTDId = id
	textdraw.visible = false
	--outputConsole('Got TextDrawCreate, textdraw id ' .. id)

	g_TextDraws[id] = textdraw
	if textdraw.x then
		textdraw.x = textdraw.x
		textdraw.y = textdraw.y
	end
	for prop, val in pairs(textdraw) do
		TextDrawPropertyChanged(id, prop, val, true)
	end
	initTextDraw(textdraw)
end

function TextDrawDestroy(id)
	local textdraw = g_TextDraws[id]
	if textdraw then
		destroyTextDraw(textdraw)
	end
end

function TextDrawHideForPlayer(id)
	local textdraw = g_TextDraws[id]
	if textdraw then
		hideTextDraw(textdraw)
	end
end

function TextDrawPropertyChanged(id, prop, newval, skipInit)
	if not g_TextDraws then
		outputConsole('[TextDrawPropertyChanged] Error: g_TextDraws is nil')
		return
	end

	local textdraw = g_TextDraws[id]
	if not textdraw then
		outputConsole('[TextDrawPropertyChanged] Error: g_TextDraws is nil at index: ' .. id)
		return
	end

	--outputConsole('[TextDrawPropertyChanged]: Received new property ' .. prop .. ' - ' .. newval .. ' for ' .. textdraw.text)

	textdraw[prop] = newval
	if prop == 'lwidth' then
		-- same as multiplying by (4 / 3)
		textdraw.lwidth = textdraw.lwidth / 0.75
	elseif prop:match('color') then
		textdraw[prop] = tocolor(unpack(newval))
	end
	if not skipInit then
		initTextDraw(textdraw)
	end
end

function TextDrawShowForPlayer(id)
	--outputConsole(string.format('TextDrawShowForPlayer trying to show textdraw with id %d', id))
	local textdraw = g_TextDraws[id]
	if textdraw then
		--outputConsole(string.format('TextDrawShowForPlayer trying to show textdraw with text %s', textdraw.text))
		showTextDraw(textdraw)
	end
end

function textDrawSelectClickHandler(button, state)
	if button ~= 'left' or state ~= 'down' or not g_TextDrawSelectMode then
		return
	end

	local hovered = getHoveredTextDraw()
	if hovered then
		triggerServerEvent('onPlayerClickTextDraw_Ev', localPlayer, hovered.clientTDId)
	end
end

function selectTextDraw(r, g, b, a)
	g_TextDrawHoverColor = tocolor(r, g, b, a)

	if not g_TextDrawSelectMode then
		g_TextDrawSelectMode = true
		addEventHandler('onClientClick', root, textDrawSelectClickHandler)
		showCursor(true)
	end
end

function cancelSelectTextDraw()
	if not g_TextDrawSelectMode then
		return
	end

	g_TextDrawSelectMode = false
	g_TextDrawHoverColor = nil
	removeEventHandler('onClientClick', root, textDrawSelectClickHandler)

	if g_ClassSelectionInfo and g_ClassSelectionInfo.gui then
		showCursor(true)
	else
		showCursor(false)
	end
end
-----------------------------
-- Menus

local function updateMenuSize(menu)
	if not menu then return end

	menu.width = (#menu.items[1] > 0 and (menu.leftColumnWidth + menu.rightColumnWidth) or (menu.leftColumnWidth)) + 2 * MENU_SIDE_PADDING
	menu.height = MENU_ITEM_HEIGHT * math.max(#menu.items[0], #menu.items[1]) + MENU_TOP_PADDING + MENU_BOTTOM_PADDING
end

function AddMenuItem(menuID, column, caption)
	local menu = g_Menus[menuID]
	if not menu then return end

	table.insert(menu.items[column], caption)
	updateMenuSize(menu)
end

function CreateMenu(menuID, menu)
	if not menu then return end

	menu.x = math.floor(menu.x * screenWidth / 640)
	menu.y = math.floor(menu.y * screenHeight / 480)
	menu.leftColumnWidth = math.floor(menu.leftColumnWidth * screenWidth / 640)
	menu.rightColumnWidth = math.floor(menu.rightColumnWidth * screenWidth / 640)

	g_Menus[menuID] = menu
	updateMenuSize(menu)
end

function DisableMenuRow(menuID, rowID)
	local menu = g_Menus[menuID]
	if not menu then return end

	menu.disabledrows = menu.disabledrows or {}
	table.insert(menu.disabledrows, rowID)
end

function SetMenuColumnHeader(menuID, column, text)
	local menu = g_Menus[menuID]
	if not menu then return end

	menu.items[column][13] = text
end

function ShowMenuForPlayer(menuID)
	if not g_Menus[menuID] then return end

	if g_CurrentMenu and g_CurrentMenu.anim then
		g_CurrentMenu.anim:remove()
		g_CurrentMenu.anim = nil
	end

	local prevMenu = g_CurrentMenu
	g_CurrentMenu = g_Menus[menuID]
	local closebtnSide = screenWidth * (27 / 1024)

	if not prevMenu then
		g_CurrentMenu.alpha = 0

		g_CurrentMenu.closebtn = guiCreateStaticImage(g_CurrentMenu.x + g_CurrentMenu.width - closebtnSide, g_CurrentMenu.y, closebtnSide, closebtnSide, 'images/closebtn.png', false, nil)
		guiSetAlpha(g_CurrentMenu.closebtn, 0)
		addEventHandler('onClientMouseEnter', g_CurrentMenu.closebtn,
			function()
				guiSetVisible(g_CurrentMenu.closebtn, false)
				guiSetVisible(g_CurrentMenu.closebtnhover, true)
			end,
			false
		)

		g_CurrentMenu.closebtnhover = guiCreateStaticImage(g_CurrentMenu.x + g_CurrentMenu.width - closebtnSide, g_CurrentMenu.y, closebtnSide, closebtnSide, 'images/closebtn_hover.png', false, nil)
		guiSetVisible(g_CurrentMenu.closebtnhover, false)
		guiSetAlpha(g_CurrentMenu.closebtnhover, .75)

		addEventHandler('onClientGUIClick', g_CurrentMenu.closebtnhover, menuHideHandler, false)
		addEventHandler('onClientMouseLeave', g_CurrentMenu.closebtnhover,
			function()
				guiSetVisible(g_CurrentMenu.closebtnhover, false)
				guiSetVisible(g_CurrentMenu.closebtn, true)
			end,
			false
		)

		g_CurrentMenu.anim = Animation.createAndPlay(
			g_CurrentMenu,
			{ time = 500, from = 0, to = 1, fn = setMenuAlpha },
			function()
				setMenuAlpha(g_CurrentMenu, 1)
				if g_CurrentMenu then
					g_CurrentMenu.anim = nil
				end
			end
		)

		addEventHandler('onClientRender', root, renderMenu)
		addEventHandler('onClientClick', root, menuClickHandler)
		showCursor(true)
	else
		g_CurrentMenu.closebtn = prevMenu.closebtn
		prevMenu.closebtn = nil
		guiSetPosition(g_CurrentMenu.closebtn, g_CurrentMenu.x + g_CurrentMenu.width - closebtnSide, g_CurrentMenu.y, false)
		g_CurrentMenu.closebtnhover = prevMenu.closebtnhover
		prevMenu.closebtnhover = nil
		guiSetPosition(g_CurrentMenu.closebtnhover, g_CurrentMenu.x + g_CurrentMenu.width - closebtnSide, g_CurrentMenu.y, false)
		setMenuAlpha(g_CurrentMenu, 1)
	end

	bindKey('enter', 'down', menuHideHandler)
end

function HideMenuForPlayer(menuID)
	if g_CurrentMenu and (not menuID or g_CurrentMenu.id == menuID) then
		if g_CurrentMenu.anim then
			g_CurrentMenu.anim:remove()
			g_CurrentMenu.anim = nil
		end
		if menuID then
			g_CurrentMenu.anim = Animation.createAndPlay(g_CurrentMenu, { time = 500, from = 1, to = 0, fn = setMenuAlpha }, closeMenu)
		else
			g_CurrentMenu.anim = Animation.createAndPlay(g_CurrentMenu, { time = 500, from = 1, to = 0, fn = setMenuAlpha }, exitMenu)
		end
	end
end

function DestroyMenu(menuID)
	if not g_Menus[menuID] then return end

	if g_CurrentMenu and menuID == g_CurrentMenu.id then
		closeMenu()
	end

	g_Menus[menuID] = nil
end

function setMenuAlpha(menu, alpha)
	if not menu then return end

	menu.alpha = alpha

	if menu.closebtn then
		guiSetAlpha(menu.closebtn, .75 * alpha)
	end
	if menu.closebtnhover then
		guiSetAlpha(menu.closebtnhover, .75 * alpha)
	end
end

function closeMenu()
	removeEventHandler('onClientRender', root, renderMenu)
	removeEventHandler('onClientClick', root, menuClickHandler)
	g_CurrentMenu.anim = nil
	destroyElement(g_CurrentMenu.closebtn)
	g_CurrentMenu.closebtn = nil
	destroyElement(g_CurrentMenu.closebtnhover)
	g_CurrentMenu.closebtnhover = nil
	g_CurrentMenu = nil
	unbindKey('enter', 'down', menuHideHandler)
	if g_ClassSelectionInfo and g_ClassSelectionInfo.gui then
		showCursor(true)
	else
		showCursor(false)
	end
end

function exitMenu()
	triggerServerEvent('onPlayerExitedMenu_Ev', localPlayer)
	closeMenu()
end

function renderMenu()
	local menu = g_CurrentMenu
	if not menu or isPlayerMapVisible() then
		return
	end

	-- background
	dxDrawRectangle(menu.x, menu.y, menu.width, menu.height, tocolor(0, 0, 0, 128 * menu.alpha))

	if menu.title then
		local titleX = menu.x + MENU_SIDE_PADDING
		local titleY = menu.y + MENU_ITEM_HEIGHT - MENU_BOTTOM_PADDING
		dxDrawText(menu.title, titleX, titleY, titleX, titleY, tocolor(255, 255, 255, 255 * menu.alpha), 0.9, 'bankgothic', 'left', 'center', false, false, false, true)
	end

	local cursorX, cursorY = getCursorPosition()

	if not cursorX then
		closeMenu()
		return
	end

	cursorY = screenHeight * cursorY
	-- selected row
	local selectedRow
	if cursorY >= menu.y + MENU_TOP_PADDING and cursorY < menu.y + menu.height - MENU_BOTTOM_PADDING then
		selectedRow = math.floor((cursorY - menu.y - MENU_TOP_PADDING) / MENU_ITEM_HEIGHT)
		dxDrawRectangle(menu.x, menu.y + MENU_TOP_PADDING + selectedRow * MENU_ITEM_HEIGHT, menu.width, MENU_ITEM_HEIGHT, tocolor(98, 152, 219, 192 * menu.alpha))
	end

	-- menu items
	for column = 0, 1 do
		for i, text in pairs(menu.items[column]) do
			local x = menu.x + MENU_SIDE_PADDING + column * menu.leftColumnWidth
			local y, color, scale
			if i < 13 then
				-- regular item
				y = menu.y + MENU_TOP_PADDING + (i - 1) * MENU_ITEM_HEIGHT
				if menu.disabledrows and table.find(menu.disabledrows, i - 1) then
					color = tocolor(100, 100, 100, 255 * menu.alpha)
				else
					color = (i - 1) == selectedRow and tocolor(255, 255, 255, 255 * menu.alpha) or tocolor(180, 180, 180, 255 * menu.alpha)
				end
				scale = 0.7
			else
				-- column header
				y = menu.y + MENU_TOP_PADDING - MENU_ITEM_HEIGHT
				color = tocolor(228, 190, 57, 255 * menu.alpha)
				scale = 0.8
			end
			drawShadowText(text, x, y + 5, color, scale, 'pricedown')
		end
	end
end

function menuClickHandler(button, state, clickX, clickY)
	if state ~= 'up' then
		return
	end

	if not g_CurrentMenu then
		return
	end

	local cursorX, cursorY = getCursorPosition()
	cursorY = screenHeight * cursorY
	if cursorY < g_CurrentMenu.y + MENU_TOP_PADDING or cursorY > g_CurrentMenu.y + MENU_TOP_PADDING + math.max(#g_CurrentMenu.items[0], #g_CurrentMenu.items[1]) * MENU_ITEM_HEIGHT then
		return
	end

	local selectedRow = math.floor((clickY - g_CurrentMenu.y - MENU_TOP_PADDING) / MENU_ITEM_HEIGHT)
	if not (g_CurrentMenu.disabledrows and table.find(g_CurrentMenu.disabledrows, selectedRow)) then
		playSoundFrontEnd(1)
		triggerServerEvent('onPlayerSelectedMenuRow_Ev', localPlayer, selectedRow)
		closeMenu()
	else
		playSoundFrontEnd(4)
	end
end

function menuHideHandler()
	if not g_CurrentMenu.anim then
		playSoundFrontEnd(2)
		HideMenuForPlayer()
	end
end
-----------------------------
-- Others

function SetPlayerPosFindZ(x, y, z)
	local hitZ = getGroundPosition(x, y, z)
	if hitZ and hitZ ~= 0 then z = hitZ + 1 end
	setElementPosition(localPlayer, x, y, z)
end

local function clientPlayerDamage(attacker, weapon, bodypart, loss)
	local issuer = attacker

	if issuer then
		if getElementType(issuer) == 'vehicle' then
			issuer = getVehicleOccupant(issuer)
		end
		if issuer == source then
			issuer = nil
		end
	end

	if issuer == localPlayer then -- give damage
		triggerServerEvent('onPlayerDamage_Ev', issuer, source, true, loss, weapon, bodypart)
	elseif source == localPlayer then -- take damage
		if issuer and getElementType(issuer) ~= 'player' then
			if getElementType(issuer) == 'ped' and not getElementData(issuer, 'ActorPed') then
				triggerServerEvent('onBotDamage_Ev', source, issuer, true, loss, weapon, bodypart)
			end

			issuer = nil
		end

		triggerServerEvent('onPlayerDamage_Ev', source, issuer, false, loss, weapon, bodypart)

		local team = getPlayerTeam(source)
		if issuer and team and getTeamName(team) ~= 'Team 256' then
			if getPlayerTeam(issuer) == team then cancelEvent() end
		end
	end
end
addEventHandler('onClientPlayerDamage', root, clientPlayerDamage)

local function clientPlayerWeaponFire(weapon, ammo, ammoInClip, hitX, hitY, hitZ, hitElement, startX, startY, startZ)
	if weapon < 22 or (weapon > 34 and weapon ~= 38) then return end

	local hitId, hitType = 65535, 0
	local offsetX, offsetY, offsetZ = hitX, hitY, hitZ

	if hitElement and isElement(hitElement) then
		local elemType = getElementType(hitElement)

		hitType = ({
			player = 1,
			vehicle = 2,
			object = 3
		})[elemType] or 0

		if hitType > 0 then
			hitId = getElemID(hitElement)

			for k, elem in pairs(g_PlayerObjects) do
				if elem == hitElement then
					hitId = k
					hitType = 4
					break
				end
			end

			offsetX, offsetY, offsetZ = getElementPosition(hitElement)
			offsetX = hitX - offsetX
			offsetY = hitY - offsetY
			offsetZ = hitZ - offsetZ
		end
	end

	triggerServerEvent('onPlayerWeaponShot_Ev', localPlayer, weapon, hitType, hitId, startX, startY, startZ, hitX, hitY, hitZ, offsetX, offsetY, offsetZ)
end
addEventHandler('onClientPlayerWeaponFire', localPlayer, clientPlayerWeaponFire)

local function clientPedDamage(attacker, weapon, bodypart, loss)
	if getElementType(source) == 'ped' then
		local issuer = attacker

		if issuer and getElementType(issuer) == 'vehicle' then
			local driver = getVehicleOccupant(issuer)

			if driver and getElementType(driver) == 'player' then
				issuer = driver
			else
				issuer = nil
			end
		end

		if getElementData(source, 'ActorPed') then
			if issuer == localPlayer and not getElementData(source, 'Invulnerable') then
				triggerServerEvent('onPlayerGiveDamageActor_Ev', issuer, source, loss, weapon, bodypart)
			end

			-- Actor damage controlled by the server in any case
			return cancelEvent()
		elseif issuer == localPlayer then
			triggerServerEvent('onBotDamage_Ev', issuer, source, false, loss, weapon, bodypart)
		end
	end
end
addEventHandler('onClientPedDamage', root, clientPedDamage)

function enableWeaponSyncing(enable)
	if enable and not g_WeaponSyncTimer then
		g_WeaponSyncTimer = setTimer(sendWeapons, 250, 0)
	elseif not enable and g_WeaponSyncTimer then
		killTimer(g_WeaponSyncTimer)
		g_WeaponSyncTimer = nil
	end
end

local prevWeapons
function sendWeapons()
	local weapons = {}
	local needResync = false
	for slot = 0, 12 do
		weapons[slot] = { id = getPedWeapon(localPlayer, slot), ammo = getPedTotalAmmo(localPlayer, slot) }
		if not needResync and (not prevWeapons or prevWeapons[slot].ammo ~= weapons[slot].ammo or prevWeapons[slot].id ~= weapons[slot].id) then
			needResync = true
		end
	end
	if needResync then
		server.syncPlayerWeapons(localPlayer, weapons)
		prevWeapons = weapons
	end
end

function RemovePlayerMapIcon(blipID)
	if isElement(g_Blips[blipID]) then
		destroyElement(g_Blips[blipID])
		g_Blips[blipID] = nil
		return true
	end
	return false
end

function SetPlayerMapIcon(blipID, x, y, z, type, r, g, b, a, style)
	if isElement(g_Blips[blipID]) then
		destroyElement(g_Blips[blipID])
		g_Blips[blipID] = nil
	end
	local hitZ = getGroundPosition(x, y, z)
	if hitZ and hitZ ~= 0 then z = hitZ end
	g_Blips[blipID] = createBlip(x, y, z, type, 2, r, g, b, a)
	if style == 0 or style == 2 then -- Local / local checkpoint
		setBlipVisibleDistance(g_Blips[blipID], 250.0)
	end
	if style == 2 or style == 3 then -- Local checkpoint / global checkpoint
		local marker = createMarker(x, y, z, 'cylinder', 2.0, 255, 0, 0, 50)
		attachElements(marker, g_Blips[blipID], 0, 0, 0)
		setElementParent(marker, g_Blips[blipID])
	end
	return true
end

function SetPlayerWorldBounds(xMax, xMin, yMax, yMin)
	g_WorldBounds = g_WorldBounds or {}
	g_WorldBounds.xmin, g_WorldBounds.ymin, g_WorldBounds.xmax, g_WorldBounds.ymax = xMin, yMin, xMax, yMax
	if not g_WorldBounds.handled then
		addEventHandler('onClientRender', root, checkWorldBounds)
		g_WorldBounds.handled = true
	end
end

function checkWorldBounds()
	if g_ClassSelectionInfo and g_ClassSelectionInfo.gui then
		return
	end

	local x, y, z, vx, vy, vz
	local elem = getPedOccupiedVehicle(localPlayer)
	local isVehicle

	if elem then
		if getVehicleController(elem) == localPlayer then
			isVehicle = true
			vx, vy, vz = getElementVelocity(elem)
		else
			return
		end
	else
		elem = localPlayer
		isVehicle = false
	end

	if getElementInterior(elem) > 0 then
		return
	end

	local bounds = g_WorldBounds
	x, y, z = getElementPosition(elem)

	local changed = false
	if x < bounds.xmin then
		x = bounds.xmin
		if isVehicle and vx < 0 then
			vx = -vx
		end
		changed = true
	elseif x > bounds.xmax then
		x = bounds.xmax
		if isVehicle and vx > 0 then
			vx = -vx
		end
		changed = true
	end
	if y < bounds.ymin then
		y = bounds.ymin
		if isVehicle and vy < 0 then
			vy = -vy
		end
		changed = true
	elseif y > bounds.ymax then
		y = bounds.ymax
		if isVehicle and vy > 0 then
			vy = -vy
		end
		changed = true
	end
	if changed then
		GameTextForPlayer('Stay within the ~r~world boundries', 1000, 5)

		if isVehicle then
			setElementVelocity(elem, vx, vy, vz)
		else
			setElementPosition(elem, x, y, z)
		end
	end
end

function SetPlayerMarkerForPlayer(blippedPlayer, r, g, b, a)
	if a == 0 then
		destroyBlipsAttachedTo(blippedPlayer)
	else
		createBlipAttachedTo(blippedPlayer, 0, 2, r, g, b, a)
	end
end

function TogglePlayerClock(toggle)
	setMinuteDuration(toggle and 1000 or 2147483647)
	setPlayerHudComponentVisible('clock', toggle)
	return true
end

function createListDialog(titleText, message, button1txt, button2txt)
	if isElement(listWindow) then
		removeEventHandler('onClientGUIClick', root, OnListDialogButton1Click) -- Remove handlers so they are not registered more than once
		removeEventHandler('onClientGUIClick', root, OnListDialogButton2Click)
		destroyElement(listWindow) -- Assuming listWindow is the parent of everything, it should remove the whole hierarchy
	end

	listDialog = nil
	listWindow = guiCreateWindow(screenWidth / 2 - 541 / 2, screenHeight / 2 - 352 / 2, 541, 352, titleText, false)
	guiWindowSetMovable(listWindow, false)
	guiWindowSetSizable(listWindow, false)
	listGrid = guiCreateGridList(0.0, 0.1, 1.0, 0.8, true, listWindow)
	guiGridListSetSelectionMode(listGrid, 2)
	guiGridListSetScrollBars(listGrid, true, true)
	guiGridListSetSortingEnabled(listGrid, false)
	--listColumn = guiGridListAddColumn(listGrid, 'List', 0.85)

	local xpos = 0.0
	if #button1txt == 0 or #button2txt == 0 then
		xpos = 0.40 -- Center
	end

	listButton1 = guiCreateButton(xpos ~= 0.0 and xpos or 0.3, 0.9, 0.15, 0.1, button1txt, true, listWindow)
	listButton2 = guiCreateButton(xpos ~= 0.0 and xpos or 0.5, 0.9, 0.15, 0.1, button2txt, true, listWindow)

	if #button1txt == 0 then
		guiSetVisible(listButton1, false)
	end
	if #button2txt == 0 then
		guiSetVisible(listButton2, false)
	end

	guiSetVisible(listWindow, false)
	addEventHandler('onClientGUIClick', listButton1, OnListDialogButton1Click, false)
	addEventHandler('onClientGUIClick', listButton2, OnListDialogButton2Click, false)
	return listGrid
end

function createInputDialog(titleText, message, button1txt, button2txt)
	if isElement(inputWindow) then
		removeEventHandler('onClientGUIClick', root, OnInputDialogButton1Click) -- Remove handlers so they are not registered more than once
		removeEventHandler('onClientGUIClick', root, OnInputDialogButton2Click)
		destroyElement(inputWindow) -- Assuming inputWindow is the parent of everything, it should remove the whole hierarchy
	end

	inputDialog = nil
	inputWindow = guiCreateWindow(screenWidth / 2 - 541 / 2, screenHeight / 2 - 352 / 2, 541, 352, titleText, false)
	guiWindowSetMovable(inputWindow, false)
	guiWindowSetSizable(inputWindow, false)
	inputLabel = guiCreateColoredLabel(0.1, 0.1, 1.0, 0.8, message, inputWindow, true)
	inputEdit = guiCreateEdit(0.0, 0.7, 1.0, 0.1, '', true, inputWindow)

	local xpos = 0.0
	if #button1txt == 0 or #button2txt == 0 then
		xpos = 0.40 -- Center
	end

	inputButton1 = guiCreateButton(xpos ~= 0.0 and xpos or 0.3, 0.9, 0.15, 0.1, button1txt, true, inputWindow) -- x, y, width, height
	inputButton2 = guiCreateButton(xpos ~= 0.0 and xpos or 0.5, 0.9, 0.15, 0.1, button2txt, true, inputWindow)

	if #button1txt == 0 then
		guiSetVisible(inputButton1, false)
	end
	if #button2txt == 0 then
		guiSetVisible(inputButton2, false)
	end

	guiSetVisible(inputWindow, false)
	addEventHandler('onClientGUIClick', inputButton1, OnInputDialogButton1Click, false)
	addEventHandler('onClientGUIClick', inputButton2, OnInputDialogButton2Click, false)
end

function createMessageDialog(titleText, message, button1txt, button2txt)
	if isElement(msgWindow) then
		removeEventHandler('onClientGUIClick', root, OnMessageDialogButton1Click) -- Remove handlers so they are not registered more than once
		removeEventHandler('onClientGUIClick', root, OnMessageDialogButton2Click)
		destroyElement(msgWindow) -- Assuming msgWindow is the parent of everything, it should remove the whole hierarchy
	end

	msgDialog = nil
	msgWindow = guiCreateWindow(screenWidth / 2 - 541 / 2, screenHeight / 2 - 352 / 2, 541, 352, titleText, false)
	guiWindowSetMovable(msgWindow, false)
	guiWindowSetSizable(msgWindow, false)
	msgLabel = guiCreateColoredLabel(0.1, 0.1, 1.0, 0.7, message, msgWindow, true)

	local xpos = 0.0
	if #button1txt == 0 or #button2txt == 0 then
		xpos = 0.40 -- Center
	end

	msgButton1 = guiCreateButton(xpos ~= 0.0 and xpos or 0.3, 0.9, 0.15, 0.1, button1txt, true, msgWindow) -- x, y, width, height
	msgButton2 = guiCreateButton(xpos ~= 0.0 and xpos or 0.5, 0.9, 0.15, 0.1, button2txt, true, msgWindow)

	if #button1txt == 0 then
		guiSetVisible(msgButton1, false)
	end
	if #button2txt == 0 then
		guiSetVisible(msgButton2, false)
	end

	guiSetVisible(msgWindow, false)
	addEventHandler('onClientGUIClick', msgButton1, OnMessageDialogButton1Click, false)
	addEventHandler('onClientGUIClick', msgButton2, OnMessageDialogButton2Click, false)
end

function clearListItem()
	if listColumn then
		guiGridListRemoveColumn(listGrid, listColumn) -- First remove the default column
	end
	local colAmount = guiGridListGetColumnCount(listGrid)
	for i = 1, colAmount do -- Column indexes appear to start from 1
		if not guiGridListRemoveColumn(listGrid, i) then -- Always clean up all columns
			outputConsole('[ShowPlayerDialog] Error: Couldn\'t remove column: ' .. 'idx: ' .. i)
		end
		--outputConsole('vals: ' .. 'idx: ' .. i)
	end
	guiGridListClear(listGrid)
end

function OnListDialogButton1Click(button, state)
	if button == 'left' then
		local row, column = guiGridListGetSelectedItem(listGrid)
		local text = guiGridListGetItemText(listGrid, row, column)
		triggerServerEvent('onDialogResponse_Ev', localPlayer, listDialog, 1, row, text)
		guiSetVisible(listWindow, false)
		if g_ClassSelectionInfo and g_ClassSelectionInfo.gui then
			showCursor(true)
		else
			showCursor(false)
		end
		listDialog = nil
		clearListItem()
	end
end

function OnListDialogButton2Click(button, state)
	if button == 'left' then
		local row, column = guiGridListGetSelectedItem(listGrid)
		local text = guiGridListGetItemText(listGrid, row, column)
		triggerServerEvent('onDialogResponse_Ev', localPlayer, listDialog, 0, row, text)
		guiSetVisible(listWindow, false)
		if g_ClassSelectionInfo and g_ClassSelectionInfo.gui then
			showCursor(true)
		else
			showCursor(false)
		end
		listDialog = nil
		clearListItem()
	end
end

function OnInputDialogButton1Click(button, state)
	if button == 'left' then
		triggerServerEvent('onDialogResponse_Ev', localPlayer, inputDialog, 1, -1, guiGetText(inputEdit))
		guiSetVisible(inputWindow, false)
		if g_ClassSelectionInfo and g_ClassSelectionInfo.gui then
			showCursor(true)
		else
			showCursor(false)
		end
		inputDialog = nil
	end
end

function OnInputDialogButton2Click(button, state)
	if button == 'left' then
		triggerServerEvent('onDialogResponse_Ev', localPlayer, inputDialog, 0, -1, guiGetText(inputEdit))
		guiSetVisible(inputWindow, false)
		if g_ClassSelectionInfo and g_ClassSelectionInfo.gui then
			showCursor(true)
		else
			showCursor(false)
		end
		inputDialog = nil
	end
end

function OnMessageDialogButton1Click(button, state)
	if button == 'left' then
		triggerServerEvent('onDialogResponse_Ev', localPlayer, msgDialog, 1, -1, '')
		guiSetVisible(msgWindow, false)
		if g_ClassSelectionInfo and g_ClassSelectionInfo.gui then
			showCursor(true)
		else
			showCursor(false)
		end
		msgDialog = nil
	end
end

function OnMessageDialogButton2Click(button, state)
	if button == 'left' then
		triggerServerEvent('onDialogResponse_Ev', localPlayer, msgDialog, 0, -1, '')
		guiSetVisible(msgWindow, false)
		if g_ClassSelectionInfo and g_ClassSelectionInfo.gui then
			showCursor(true)
		else
			showCursor(false)
		end
		msgDialog = nil
	end
end

function ShowPlayerDialog(dialogid, dialogtype, caption, info, button1, button2)
	if msgDialog then
		guiSetVisible(msgWindow, false)
		msgDialog = nil
	end
	if inputDialog then
		guiSetVisible(inputWindow, false)
		inputDialog = nil
	end
	if listDialog then
		guiSetVisible(listWindow, false)
		listDialog = nil
		clearListItem()
	end

	if dialogid == -1 then
		if g_ClassSelectionInfo and g_ClassSelectionInfo.gui then
			showCursor(true)
		else
			showCursor(false)
		end
		return true
	end

	showCursor(true)
	caption = caption:gsub('(=?{[0-9A-Fa-f]*})', '')

	if dialogtype == 0 then
		createMessageDialog(caption, colorizeString(info), button1, button2)
		guiSetVisible(msgWindow, true)
		msgDialog = dialogid
	elseif dialogtype == 1 or dialogtype == 3 then
		createInputDialog(caption, colorizeString(info), button1, button2)
		guiEditSetMasked(inputEdit, dialogtype == 3)
		guiSetVisible(inputWindow, true)
		inputDialog = dialogid
	elseif dialogtype == 2 or dialogtype == 4 or dialogtype == 5 then -- DIALOG_STYLE_LIST, DIALOG_STYLE_TABLIST, DIALOG_STYLE_TABLIST_HEADER
		info = info:gsub('(=?{[0-9A-Fa-f]*})', '')

		-- Setup the UI
		createListDialog(caption, info, button1, button2)
		guiSetVisible(listWindow, true)
		listDialog = dialogid
		-- Done

		-- Process each
		-- DIALOG_STYLE_LIST
		if dialogtype == 2 then
			local items = info:gsub('\t', '        ')
			items = items:split('\n')
			listColumn = guiGridListAddColumn(listGrid, 'List', 0.85)
			for k, v in ipairs(items) do
				local row = guiGridListAddRow(listGrid)
				guiGridListSetItemText(listGrid, row, listColumn, v, false, true)
			end
			return true
		end

		-- DIALOG_STYLE_TABLIST, DIALOG_STYLE_TABLIST_HEADER
		-- Add the columns
		local items = info:split('\n') -- Get the first one which is the header
		if #items < 1 then
			outputConsole('Error, your dialog either has no items, its format is wrong or you\'re missing a newline character in the string')
			outputConsole('The raw string was: ' .. info)
			return false -- Abort if there's no items
		end

		-- Create the header
		local headerCols = items[1]:split('\t')
		for k, v in ipairs(headerCols) do
			local colIdx = guiGridListAddColumn(listGrid, (dialogtype == 5 and v or ''), 0.5) -- If it's the DIALOG_STYLE_TABLIST_HEADER add the name, otherwise leave it blank
			--outputConsole('headerCols - colidx: ' .. colIdx .. 'k: ' .. k .. 'v: ' .. v)
		end

		if dialogtype == 5 then -- Only remove if it's a DIALOG_STYLE_TABLIST_HEADER
			table.remove(items, 1) -- remove the first item which is the header
		end

		-- Add the rows ordered under each column
		for k, v in ipairs(items) do -- rows
			local row = guiGridListAddRow(listGrid) -- add the row
			-- Now process every individual column (columns are tabulated)
			for hk, hv in ipairs(v:split('\t')) do -- header key, header value
				--outputConsole('hk: ' .. hk .. 'hv: ' .. hv)
				guiGridListSetItemText(listGrid, row, hk, hv, false, true)
			end
		end
	end
	return true
end

-- depends on scoreboard resource
local function clientPlayerScoreboardClick(selected, cX, cY, clickedColumn)
	if getElementType(source) ~= 'player' then return end
	triggerServerEvent('onPlayerClickPlayer_Ev', localPlayer, source)
end
addEventHandler('onClientPlayerScoreboardClick', root, clientPlayerScoreboardClick)
