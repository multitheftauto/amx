local dxDrawText = dxDrawText
local tocolor = tocolor
local SPEED_EPSILON = 0.005
local VEHICLE_DROP_TRY_INTERVAL = 100
local VEHICLE_DROP_MAX_TRIES = 50

local MENU_ITEM_HEIGHT = 25
local MENU_TOP_PADDING = MENU_ITEM_HEIGHT*2
local MENU_BOTTOM_PADDING = 10
local MENU_SIDE_PADDING = 20

local BOATS = {
	[472] = true,
	[473] = true,
	[493] = true,
	[595] = true,
	[484] = true,
	[430] = true,
	[453] = true,
	[452] = true,
	[446] = true,
	[454] = true
}

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
g_TextDraws = {}
g_TextLabels = {}
g_Blips = {}
g_PlayerObjects = {}

local screenWidth, screenHeight = guiGetScreenSize()

addEventHandler('onClientResourceStart', resourceRoot,
	function()
		triggerServerEvent('onLoadedAtClient', resourceRoot, localPlayer)
		InitDialogs()
		setTimer(checkTextLabels, 500, 0)
	end,
	false
)

addEventHandler('onClientResourceStop', resourceRoot,
	function()
		TogglePlayerClock(false, true)
	end,
	false
)

function setAMXVersion(ver)
	g_AMXVersion = ver
end

function gamemodeLoad()
	setTime(12, 0)
end

function destroyGlobalElements()
	for id, data in pairs(g_Vehicles) do
		g_Vehicles[id] = nil
	end

	for id, data in pairs(g_Menus) do
		DestroyMenu(id)
	end

	for id, textdraw in pairs(g_TextDraws) do
		destroyTextDraw(textdraw)
	end

	for id, textlabel in pairs(g_TextLabels) do
		destroyTextLabel(textlabel)
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
	destroyGameText()
	destroyClassSelGUI()
	if g_WorldBounds and g_WorldBounds.handled then
		removeEventHandler('onClientRender', root, checkWorldBounds)
		g_WorldBounds = nil
	end
	destroyGlobalElements()
	setElementAlpha(localPlayer, 255)
end

function setPlayerID(id)
	g_PlayerID = id
end
-----------------------------
-- MTA Key Handling
function HandleMTAKey( key, keyState )
	outputServerLog("handlemtakey: " .. key)
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
	setGravity(0)
	setElementCollisionsEnabled(localPlayer, false)

	-- interaction
	setPlayerHudComponentVisible('radar', false)
	if not g_ClassSelectionInfo.selectedclass then
		g_ClassSelectionInfo.selectedclass = 0
	end
	g_ClassSelectionInfo.gui = {
		img = guiCreateStaticImage(35, screenHeight - 410, 205, 236, 'client/logo_small.png', false),
		btnLeft = guiCreateButton(screenWidth/2-145-70,screenHeight-100,140,20,"<<<",false),
		btnRight = guiCreateButton(screenWidth/2-70,screenHeight-100,140,20,">>>",false),
		btnSpawn = guiCreateButton(screenWidth/2+145-70,screenHeight-100,140,20,"Spawn",false)
	}
	addEventHandler ( "onClientGUIClick", g_ClassSelectionInfo.gui.btnLeft, ClassSelLeft )
	addEventHandler ( "onClientGUIClick", g_ClassSelectionInfo.gui.btnRight, ClassSelRight )
	addEventHandler ( "onClientGUIClick", g_ClassSelectionInfo.gui.btnSpawn, ClassSelSpawn )
	showCursor(true)
	addEventHandler('onClientRender', root, renderClassSelText)
end

function ClassSelLeft ()
	server.requestClass(localPlayer, false, false, -1)
end

function ClassSelRight ()
	server.requestClass(localPlayer, false, false, 1)
end

function ClassSelSpawn ()
	server.requestSpawn(localPlayer, false, false)
end

function renderClassSelText()
	drawShadowText(g_AMXVersion, 20, screenHeight - 170, tocolor(39, 171, 250), 1, 'default-bold', 1, 230)
	drawShadowText('Use left and right arrow keys to select class.', 20, screenHeight - 150, tocolor(240, 240, 240))
	drawShadowText('Press SHIFT when ready to spawn.', 20, screenHeight - 136, tocolor(240, 240, 240))

	if not g_ClassSelectionInfo or not g_ClassSelectionInfo.selectedclass then
		return
	end
	drawShadowText('Class ' .. g_ClassSelectionInfo.selectedclass .. ' weapons:', 20, screenHeight - 110, tocolor(240, 240, 240))
	local weapon, ammo, linenum, line
	linenum = 0
	for i,weapondata in ipairs(g_ClassSelectionInfo[g_ClassSelectionInfo.selectedclass].weapons) do
		weapon, ammo = weapondata[1], weapondata[2]
		if weapon ~= 0 and weapon ~= -1 and ammo ~= -1 then
			linenum = linenum + 1
			if ammo ~= 0 then
				line = ammo .. 'x '
			else
				line = ''
			end
			line = line .. (getWeaponNameFromID(weapon) or weapon)
			drawShadowText(line, 25, screenHeight - 110 + 14*linenum, tocolor(240, 240, 240))
		end
	end
end

function selectClass(classid)
	fadeCamera(true)
	g_ClassSelectionInfo.selectedclass = classid
end

function destroyClassSelGUI()
	if g_ClassSelectionInfo and g_ClassSelectionInfo.gui then
		for i,elem in pairs(g_ClassSelectionInfo.gui) do
			destroyElement(elem)
		end
		g_ClassSelectionInfo.gui = nil
		removeEventHandler('onClientRender', root, renderClassSelText)
	end
	setPlayerHudComponentVisible('radar', true)
	setCameraTarget(localPlayer)
	setGravity(0.008)
	setElementCollisionsEnabled(localPlayer, true)
	showCursor(false)
	if g_ClassSelectionInfo then
		removeEventHandler ( "onClientGUIClick", g_ClassSelectionInfo.gui.btnLeft, ClassSelLeft )
		removeEventHandler ( "onClientGUIClick", g_ClassSelectionInfo.gui.btnRight, ClassSelRight )
		removeEventHandler ( "onClientGUIClick", g_ClassSelectionInfo.gui.btnSpawn, ClassSelSpawn )
	end
end

addEventHandler('onClientResourceStop', resourceRoot,
	function()
		destroyClassSelGUI()
		removeEventHandler('onClientRender', root, renderTextDraws)
		removeEventHandler('onClientRender', root, renderMenu)
	end
)

function requestSpawn()
	triggerServerEvent('onRequestSpawn', localPlayer, g_ClassSelectionInfo.selectedclass)
end

addEventHandler('onClientPlayerWeaponFire', resourceRoot,
	function(weapon, ammo, ammoInClip, hitX, hitY, hitZ)
		--if localPlayer ~= source then return end
		serverAMXEvent('OnPlayerShoot', getElemID(source), weapon, ammo, ammoInClip, hitX, hitY, hitZ)
	end,
	false
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
	setPlayerHudComponentVisible('area_name', false)
	setPlayerHudComponentVisible('radar', false)
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
-- Camera related
function removeCamHandlers()
	removeInterpCamHandler()
	removeCamAttachHandler()
end

-- Camera attachments
--Based on https://forum.mtasa.com/topic/36692-move-camera-by-mouse-like-normal/?do=findComment&comment=368670
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
	outputConsole('removeCamAttachHandler was called')
	if(ca.active == 1) then
		outputConsole('Destroying cam attach handler...')
		ca.active = 0
	end
end

function camAttachRender()
	if (ca.active == 1) then
		local x1,y1,z1 = 0.0, 0.0, 0.0
		if ca.objCamPos ~= nil then
			x1,y1,z1 = getElementPosition(ca.objCamPos)
		end
		local camDist = ca.dist 
		local cosZ = math.cos(ca.z) 
		local camX = x1 + math.cos(ca.x)*camDist*cosZ 
		local camY = y1 + math.sin(ca.y)*camDist*cosZ 
		local camZ = z1 + math.sin(ca.z)*camDist 
		setCameraMatrix(camX, camY, camZ, x1, y1, z1) 

		--If aiming, set the target (does nothing, todo fix)
		if getPedTask(localPlayer, "secondary", 0) == "TASK_SIMPLE_USE_GUN" or isPedDoingGangDriveby(localPlayer) then
			setPedAimTarget ( localPlayer, camX, camY, camZ )
			setPlayerHudComponentVisible ( localPlayer, "crosshair", true )
			outputConsole('ped is aiming')
		end
		
		--outputConsole(string.format("camAttachRender - Camera Matrix is: CamPos: %f %f %f CamLookAt: %f %f %f", camX, camY, camZ, x1,y1,z1))
	else
		removeEventHandler("onClientPreRender", root, camAttachRender)
	end
end

function cursorMouseMoveHandler(curX, curY, absX, absY)
	if (ca.active == 1) then
		local diffX = curX - 0.5 
		local diffY = curY - 0.5 
		local camX = ca.x - diffX*ca.speed 
		local camY = ca.y - diffX*ca.speed 
		local camZ = ca.z + (diffY*ca.speed)/math.pi 
		if(camZ > ca.maxZ) then 
			camZ = ca.maxZ 
		end 
		if(camZ < ca.minZ) then 
			camZ = ca.minZ 
		end 
		ca.x = camX 
		ca.y = camY 
		ca.z = camZ 
	else
		removeEventHandler("onClientCursorMove", root, cursorMouseMoveHandler)
	end
end

function AttachCameraToObject(camObj)
	outputConsole('AttachCameraToObject was called')
	ca.active = 1
	ca.objCamPos = camObj
	addEventHandler("onClientPreRender", root, camAttachRender)
	addEventHandler("onClientCursorMove", root, cursorMouseMoveHandler)
end

-- Camera Interpolation
--Originally from https://wiki.multitheftauto.com/wiki/SmoothMoveCamera
local sm = {}
sm.moov = 0
sm.objCamPos,sm.objLookAt = nil,nil
 
function removeInterpCamHandler()
	outputConsole('removeInterpCamHandler was called')
	if(sm.moov == 1) then
		outputConsole('Destroying cam handler...')
		sm.moov = 0
	end
end
 
function camRender()
	if (sm.moov == 1) then
		local x1,y1,z1,x2,y2,z2 = 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
		if sm.objCamPos ~= nil then
			x1,y1,z1 = getElementPosition(sm.objCamPos)
		end
		if sm.objLookAt ~= nil then
			x2,y2,z2 = getElementPosition(sm.objLookAt)
		end
		--outputConsole(string.format("Current Camera Matrix is: CamPos: %f %f %f CamLookAt: %f %f %f", x1,y1,z1,x2,y2,z2))
		setCameraMatrix(x1,y1,z1,x2,y2,z2)
	else
		removeEventHandler("onClientPreRender", root, camRender)
	end
end

function setupCameraObject(camObj, FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut)
	sm.moov = 1
	camObj = createObject(1337, FromX, FromY, FromZ)
	setElementCollisionsEnabled (camObj, false) 
	setElementAlpha(camObj, 0)
	setObjectScale(camObj, 0.01)
	moveObject(camObj, time, ToX, ToY, ToZ, ToX, ToY, ToZ, "InOutQuad")
	setTimer(removeInterpCamHandler,time,1)
	setTimer(destroyElement,time,1,camObj)
	return camObj
end

function InterpolateCameraPos(FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut)
	outputConsole(string.format("InterpolateCameraPos called with args %f %f %f %f %f %f %d %d", FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut))
	sm.objCamPos = setupCameraObject(sm.objCamPos, FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut)
	addEventHandler("onClientPreRender", root, camRender)
	return true
end
function InterpolateCameraLookAt(FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut)
	outputConsole(string.format("InterpolateCameraLookAt called with args %f %f %f %f %f %f %d %d", FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut))
	sm.objLookAt = setupCameraObject(sm.objLookAt, FromX, FromY, FromZ, ToX, ToY, ToZ, time, cut)
	addEventHandler("onClientPreRender", root, camRender)
	return true
end
-----------------------------
-- Player objects
function RemoveBuildingForPlayer(model, x, y, z, radius)
	if model == -1 then
		for i=550,20000 do --Remove all world models around radius if they sent -1
			removeWorldModel(i, radius, x, y, z)
		end
		return true --Don't run the rest of the code
	end
	removeWorldModel(model, radius, x, y, z)
	return true
end

function AttachPlayerObjectToPlayer(objID, attachPlayer, offsetX, offsetY, offsetZ, rX, rY, rZ)
	local obj = g_PlayerObjects[objID]
	if not obj then
		return
	end
	attachElements(obj, attachPlayer, offsetX, offsetY, offsetZ, rX, rY, rZ)
end

function CreatePlayerObject(objID, model, x, y, z, rX, rY, rZ)
	g_PlayerObjects[objID] = createObject(model, x, y, z, rX, rY, rZ)
end

function DestroyPlayerObject(objID)
	local obj = g_PlayerObjects[objID]
	if not obj then
		return
	end
	destroyElement(obj)
	g_PlayerObjects[objID] = nil
end

function MovePlayerObject(objID, x, y, z, speed)
	local obj = g_PlayerObjects[objID]
	local rX, rY, rZ = getElementRotation(obj)
	local distance = getDistanceBetweenPoints3D(x, y, z, getElementPosition(obj))
	local time = distance/speed*1000
	moveObject(obj, time, x, y, z)
	setElementRotation(obj, rX, rY, rZ)
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

--- Audio
local pAudioStreamSound = nil --samp can only do one stream at a time anyway
function PlayAudioStreamForPlayer(url, posX, posY, posZ, distance, usepos)
	--outputConsole(string.format("PlayAudioStreamForPlayer called with args %s %f %f %f %f %d", url, posX, posY, posZ, distance, usepos))
	if pAudioStreamSound ~= nil then --If there's one already playing, stop it
		--outputConsole("PlayAudioStreamForPlayer is stopping an audio stream")
		StopAudioStreamForPlayer()
	end
	if usepos == nil or usepos == 0 then
		--outputConsole(string.format("PlayAudioStreamForPlayer now playing non-3d sound %s", url))
		pAudioStreamSound = playSound(url)
	else
		--outputConsole(string.format("PlayAudioStreamForPlayer now playing 3d sound %s with max dist %d", url, distance))
		pAudioStreamSound = playSound3D(url, posX, posY, posZ)
		setSoundMaxDistance(pAudioStreamSound, distance)
	end
	if pAudioStreamSound ~= nil then
		setSoundVolume(pAudioStreamSound, 1.0)
	end
	return true
end
function StopAudioStreamForPlayer()
    stopSound(pAudioStreamSound)
end
-----------------------------
-- Checkpoints

function OnPlayerEnterCheckpoint(elem)
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if (vehicle and elem == vehicle) or (not vehicle and elem == localPlayer) then
		serverAMXEvent('OnPlayerEnterCheckpoint', g_PlayerID)
	end
end

function OnPlayerLeaveCheckpoint(elem)
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if (vehicle and elem == vehicle) or (not vehicle and elem == localPlayer) then
		serverAMXEvent('OnPlayerLeaveCheckpoint', g_PlayerID)
	end
end

function DisablePlayerCheckpoint()
	if not g_PlayerCheckpoint then
		return
	end
	removeEventHandler('onClientColShapeHit', g_PlayerCheckpoint.colshape, OnPlayerEnterCheckpoint)
	removeEventHandler('onClientColShapeLeave', g_PlayerCheckpoint.colshape, OnPlayerLeaveCheckpoint)
	for k,elem in pairs(g_PlayerCheckpoint) do
		destroyElement(elem)
	end
	g_PlayerCheckpoint = nil
end

function SetPlayerCheckpoint(x, y, z, size)
	if g_PlayerCheckpoint then
		DisablePlayerCheckpoint()
	end
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
		serverAMXEvent('OnPlayerEnterRaceCheckpoint', g_PlayerID)
	end
end

function OnPlayerLeaveRaceCheckpoint(elem)
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if (vehicle and elem == vehicle) or (not vehicle and elem == localPlayer) then
		serverAMXEvent('OnPlayerLeaveRaceCheckpoint', g_PlayerID)
	end
end

function DisablePlayerRaceCheckpoint()
	if not g_PlayerRaceCheckpoint then
		return
	end
	removeEventHandler('onClientColShapeHit', g_PlayerRaceCheckpoint.colshape, OnPlayerEnterRaceCheckpoint)
	removeEventHandler('onClientColShapeLeave', g_PlayerRaceCheckpoint.colshape, OnPlayerLeaveRaceCheckpoint)
	for k,elem in pairs(g_PlayerRaceCheckpoint) do
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
		colshape = type < 2 and createColCircle(x, y, size) or createColSphere(x, y, z, size*1.5),
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

function SetPlayerPosFindZ(x, y, z)
	setElementPosition(localPlayer, x, y, getGroundPosition(x, y, z) + 1)
end

function SetVehicleParamsForPlayer(vehicle, isObjective, doorsLocked)
	local vehID = getElemID(vehicle)
	if not vehID then
		return
	end
	local vehInfo = g_Vehicles[vehID]
	if isObjective then
		if vehInfo.blip then
			destroyElement(vehInfo.blip)
			vehInfo.blip = nil
		end
		vehInfo.blip = createBlipAttachedTo(vehicle, 0, 2, 222, 188, 97)
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
		if dropdata.tries < VEHICLE_DROP_MAX_TRIES then
			killTimer(dropdata.timer)
		end
		vehicleDrops[vehicle] = nil
		return
	end

	local left, back, bottom, right, front, top = getElementBoundingBox(vehicle)
	if not bottom then
		top = getElementDistanceFromCentreOfMassToBaseOfModel(vehicle)
		if not top then
			return
		end
		bottom = -top
	end
	local x, y, z = getElementPosition(vehicle)
	local rx, ry, rz = getElementRotation(vehicle)

	local hit, hitX, hitY, hitZ = processLineOfSight(x, y, z + top, x, y, z - 10, true, false)
	if hitZ then
		setElementCollisionsEnabled(vehicle, true)
		if z < hitZ - bottom - 0.5 or top > 2 then
			setElementPosition(vehicle, x, y, hitZ + 2*math.abs(bottom))
			setElementRotation(vehicle, 0, ry, rz)
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

addEventHandler('onClientElementStreamIn', root,
	function()
		if getElementType(source) == 'vehicle' then
			-- drop floating/underground vehicles
			if not vehicleDrops[source] and isVehicleEmpty(source) and not BOATS[getElementModel(source)] then
				setElementCollisionsEnabled(source, false)
				local timer = setTimer(dropVehicle, VEHICLE_DROP_TRY_INTERVAL, VEHICLE_DROP_MAX_TRIES, source)
				vehicleDrops[source] = { timer = timer, tries = 0 }
			end

			local vehID = getElemID(source)
			local vehInfo = vehID and g_Vehicles[vehID]
			if vehInfo and not vehInfo.blip then
				vehInfo.blip = createBlipAttachedTo(source, 0, 1, 136, 136, 136, 150, 0, 500)
				setElementParent(vehInfo.blip, source)
			end
			triggerServerEvent('onAmxClientVehicleStream', localPlayer, getElemID(source), true)
		elseif getElementType(source) == 'player' then
			triggerServerEvent('onAmxClientPlayerStream', localPlayer, getElemID(source), true)
		elseif getElementType(source) == 'ped' and getElementData(source, 'amx.actorped') then
			triggerServerEvent('onAmxClientActorStream', localPlayer, getElemID(source), true)
		end
	end
)

addEventHandler('onClientElementStreamOut', root,
	function()
		if getElementType(source) ~= 'vehicle' then
			local vehID = getElemID(source)
			local vehInfo = vehID and g_Vehicles[vehID]
			if vehInfo and vehInfo.blip and not vehInfo.blippersistent then
				if isElement(vehInfo.blip) then
					destroyElement(vehInfo.blip)
				end
				vehInfo.blip = nil
			end
			triggerServerEvent('onAmxClientVehicleStream', localPlayer, getElemID(source), false)
		elseif getElementType(source) == 'player' then
			triggerServerEvent('onAmxClientPlayerStream', localPlayer, getElemID(source), false)
		elseif getElementType(source) == 'ped' and getElementData(source, 'amx.actorped') then
			triggerServerEvent('onAmxClientActorStream', localPlayer, getElemID(source), false)
		end
	end
)

-- emulate SA-MP behaviour: block enter attempts as driver to locked vehicles
addEventHandler('onClientVehicleStartEnter', root,
	function(player, seat, door)
		if (player == localPlayer and seat == 0 and isVehicleLocked(source)) then
			cancelEvent()
		end
	end
)

function DestroyVehicle(vehID)
	g_Vehicles[vehID] = nil
end

-----------------------------
-- Text

local controlNames = {
	VEHICLE_TURRETLEFT = 'special_control_left',
	VEHICLE_TURRETRIGHT = 'special_control_right',
	VEHICLE_TURRETUP = 'special_control_up',
	VEHICLE_TURRETDOWN = 'special_control_down',
	VEHICLE_HORN = 'horn',
	VEHICLE_LOOKLEFT = 'vehicle_look_left',
	VEHICLE_LOOKRIGHT = 'vehicle_look_right',
	VEHICLE_ENTER_EXIT = 'enter_exit',
	VEHICLE_ACCELERATE = 'accelerate',
	VEHICLE_BRAKE = 'brake_reverse',
	VEHICLE_HANDBRAKE = 'handbrake',
	VEHICLE_STEERDOWN = 'steer_forward',
	VEHICLE_STEERUP = 'steer_backward',
	VEHICLE_STEERLEFT = 'vehicle_left',
	VEHICLE_STEERRIGHT = 'vehicle_right',
	VEHICLE_FIREWEAPON_ALT = 'vehicle_secondary_fire',
	VEHICLE_RADIO_STATION_UP = 'radio_next',
	VEHICLE_RADIO_STATION_DOWN = 'radio_previous',

	PED_SPRINT = 'sprint',
	PED_FIREWEAPON = 'fire',
	PED_ANSWER_PHONE = 'action',
	PED_LOCK_TARGET = 'aim_weapon',
	PED_LOOKBEHIND = 'look_behind',
	PED_SNIPER_ZOOM_IN = 'zoom_in',
	PED_SNIPER_ZOOM_OUT = 'zoom_out',
	PED_CYCLE_WEAPON_LEFT = 'previous_weapon',
	PED_CYCLE_WEAPON_RIGHT = 'next_weapon',
	PED_DUCK = 'crouch',
	PED_JUMPING = 'jump',

	GO_LEFT = 'left',
	GO_RIGHT = 'right',
	GO_BACK = 'backwards',
	GO_FORWARD = 'forwards',

	CONVERSATION_NO = 'conversation_no',
	CONVERSATION_YES = 'conversation_yes',

	GROUP_CONTROL_BWD = 'group_control_back',
	GROUP_CONTROL_FWD = 'group_control_forwards'
}

local function getSAMPBoundKey(control)
	control = controlNames[control] or control
	local keys = getBoundKeys(control)
	if keys and #keys > 0 then
		return keys[1]
	else
		return control
	end
end

local textDrawColorMapping = {
	r = {180, 25, 29},
	g = {53, 101, 43},
	b = {50, 60, 127},
	o = {239, 141, 27},
	w = {255, 255, 255},
	y = {222, 188, 97},
	p = {180, 25, 180},
	l = {10, 10, 10}
}

local textDrawFonts = {
	[0] = { font = 'beckett', lsizemul = 1.25 },			-- TextDraw letter size -> dxDrawText scale multiplier
	[1] = { font = 'default-bold', lsizemul = 1.25 },
	[2] = { font = 'bankgothic',   lsizemul = 1.5 },
	[3] = { font = 'default-bold', lsizemul = 1.25 }
}

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

function hudGetVerticalScale()
	return 0.002232143
end

function hudGetHorizontalScale()
	return 0.0015625
end

function initTextDraw(textdraw)
	textdraw.id = textdraw.id or (#g_TextDraws + 1)
	g_TextDraws[textdraw.id] = textdraw

	-- GTA replaces underscores with spaces
	textdraw.text = string.gsub(textdraw.text, "_", " ")

	local scale = (textdraw.lwidth or 0.5)
	local tWidth, tHeight = dxGetTextSize(textdraw.text, scale)
	local lineHeight = (tHeight or 0.25) / 2 --space between lines (vertical) also used to calculate size of the box if any
	local lineWidth = (textdraw.lwidth or 0.25) --space between words (horizontal)

	--Set the height based on the text size
	textdraw.theight = tHeight
	textdraw.twidth = tWidth
	
	local text = textdraw.text:gsub('~k~~(.-)~', getSAMPBoundKey)
	local lines = {}
	local pos, stop, c
	stop = 0
	while true do
		pos, stop, c = text:find('~(%a)~', stop + 1)
		if c == 'n' then --If we found a new line
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
	textdraw.width = 0
	local font = textDrawFonts[textdraw.font and textdraw.font >= 0 and textdraw.font <= #textDrawFonts and textdraw.font or 0]
	font = font.font

	local TDXPos = textdraw.x or 640 - #lines*lineWidth
	local TDYPos = textdraw.y or 448 - #lines*lineHeight

	--Process the lines we previously found
	for i,line in ipairs(lines) do
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
				if textDrawColorMapping[c] then
					color = textDrawColorMapping[c]
				elseif c == 'h' then
					extrabright = extrabright + 1
				else
					break
				end
			end
			if color or extrabright > 0 then
				if extrabright > 0 then
					color = color and table.shallowcopy(color) or { 255, 255, 255 }
					for i=1,3 do
						color[i] = math.min(color[i] + extrabright*40, 255)
					end
				end
				line = line:sub(1, start-1) .. ('#%02X%02X%02X'):format(unpack(color)) .. line:sub(colorpos)
			end
		end

		local textWidth = dxGetTextWidth(line:gsub('#%x%x%x%x%x%x', ''), scale, font)
		textdraw.width = math.max(textdraw.width, textWidth)
		if textdraw.align == 1 then
			-- left
			TDXPos = textdraw.x
		elseif textdraw.align == 2 or not textdraw.align then
			-- center
			--outputConsole(string.format("Got centered text %d %d %s", TDXPos, TDYPos, textdraw.text))
			TDXPos = 640/2 - textWidth/2
		elseif textdraw.align == 3 then
			-- right
			TDXPos = textdraw.x - textWidth
		end

		color = textdraw.color or tocolor(255, 255, 255)
		colorpos = 1
		local nextcolorpos
		while colorpos < line:len()+1 do
			local r, g, b = line:sub(colorpos, colorpos+6):match('#(%x%x)(%x%x)(%x%x)')
			if r then
				color = tocolor(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
				colorpos = colorpos + 7
			end
			nextcolorpos = line:find('#%x%x%x%x%x%x', colorpos) or line:len() + 1
			local part = { text = line:sub(colorpos, nextcolorpos - 1), x = TDXPos, y = TDYPos, color = color }
			table.insert(textdraw.parts, part)
			TDXPos = TDXPos + dxGetTextWidth(part.text, scale, font)
			colorpos = nextcolorpos
		end
		TDYPos = TDYPos + lineHeight
	end
	textdraw.absheight = tHeight*#lines
end

function renderTextDraws()
	for id,textdraw in pairs(g_TextDraws) do
		if textdraw.visible and textdraw.parts and not (textdraw.text:match('^%s*$')) then-- and not textdraw.usebox) then
			local font = textDrawFonts[textdraw.font and textdraw.font >= 0 and textdraw.font <= #textDrawFonts and textdraw.font or 0]
			if textdraw.upscalex == nil then
				textdraw.upscalex = 1.0
			end
			if textdraw.upscaley == nil then
				textdraw.upscaley = 1.0
			end

			local letterHeight = (textdraw.lheight * textdraw.upscaley or 0.25)
			local letterWidth = (textdraw.lwidth * textdraw.upscalex or 0.5)

			local vertHudScale = hudGetVerticalScale()
			local horHudScale = hudGetHorizontalScale()

			local scaley = SCREEN_SCALE_Y(screenHeight * vertHudScale *  letterHeight * 0.175) --This should replicate what the game does
			local scalex = SCREEN_SCALE_X(screenWidth * horHudScale *  letterWidth * 0.35)
			
			local sourceY = screenHeight - ((DEFAULT_SCREEN_HEIGHT - textdraw.y) * (screenHeight * vertHudScale))
			local sourceX = screenWidth - ((DEFAULT_SCREEN_WIDTH - textdraw.x) * (screenWidth * horHudScale))

			font = font.font
			--Process box alignments
			if textdraw.usebox then
				local boxcolor = textdraw.boxcolor or tocolor(0, 0, 0, 120*(textdraw.alpha or 1))
				local x, y, w, h
				if textdraw.align == 1 then --left
					x = textdraw.x
					if textdraw.boxsize then
						w = textdraw.boxsize[1]-- - x
					else
						w = textdraw.width
					end
				elseif textdraw.align == 2 then --centered
					x = textdraw.x
					if textdraw.boxsize then
						w = textdraw.boxsize[1]
					else
						w = textdraw.width
					end
				elseif textdraw.align == 3 then --right
					x = textdraw.x - w
					if textdraw.boxsize then
						w = textdraw.x - textdraw.boxsize[1]
					else
						w = textdraw.width
					end
				end
				y = textdraw.y
				
				--Calculates box height
				if textdraw.boxsize and textdraw.text:match('^%s*$') then
					h = textdraw.boxsize[2]
				else
					h = textdraw.absheight
				end

				dxDrawRectangle(sourceX, sourceY, w * getAspectRatio(), h * getAspectRatio(), boxcolor)
				--outputConsole(string.format("Drawing textdraw box: sourceX: %f, sourceY: %f %s", sourceX, sourceY, textdraw.text))
			end
				
			for i,part in pairs(textdraw.parts) do

				sourceY = screenHeight - ((DEFAULT_SCREEN_HEIGHT - part.y) * (screenHeight * vertHudScale))
				sourceX = screenWidth - ((DEFAULT_SCREEN_WIDTH - part.x) * (screenWidth * horHudScale))

				--outputConsole(string.format("text: %s partx: %f, party: %f sourceX: %f, sourceY: %f", part.text, part.x, part.y, sourceX, sourceY))

				if textdraw.shade and textdraw.shade > 0 then --Draw the shadow
					dxDrawText(part.text, sourceX + 5, sourceY + 5, sourceX + 5, sourceY + 5, tocolor(0, 0, 0, 100*(textdraw.alpha or 1)), scalex, scaley, font)
				end
				--Draw the actual text
				drawBorderText(
					part.text, sourceX, sourceY,
					textdraw.alpha and setcoloralpha(part.color, math.floor(textdraw.alpha*255)) or part.color,
					scalex, scaley, font, textdraw.outlinesize,
					textdraw.outlinecolor
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
	table.removevalue(g_TextDraws, textdraw)
end

local gameText = {}
local gIndex = 1

function destroyAllGameTextsWithStyle(stylePassed)
	for i = 1, gIndex do
		if gameText[i] ~= nil and gameText[i].style == stylePassed then
			destroyGameText(i)
		end
	end
end

function GameTextForPlayer(text, time, style)
	if gameText[gIndex] then
		destroyGameText(gIndex)
	end

	destroyAllGameTextsWithStyle(style) --So same styles don't overlap

	gameText[gIndex] = { text = text, font = 2 }
	if style == 1 then
		gameText[gIndex].x = 0.9 * 640
		gameText[gIndex].y = 0.8 * 448
		gameText[gIndex].lheight = 0.5
		gameText[gIndex].lwidth = 1.0
		gameText[gIndex].align = 3
		gameText[gIndex].upscaley = 3.0
		gameText[gIndex].upscalex = 1.0
		time = 8000 --Fades out after 8 seconds regardless of time set according to the wiki
	elseif style == 2 then
		gameText[gIndex].x = 0.9 * 640
		gameText[gIndex].y = 0.7 * 448
		gameText[gIndex].align = 3
	elseif style >= 3 then
		--★
		-- GTA replaces these with stars
		gameText[gIndex].text = string.gsub(text, "]", "★")
		gameText[gIndex].x = 0.5 * 640
		gameText[gIndex].y = 0.2 * 448
		gameText[gIndex].lheight = 0.5
		gameText[gIndex].lwidth = 1.0
		gameText[gIndex].align = 2
		gameText[gIndex].upscaley = 2.5
	end
	gameText[gIndex].style = style
	initTextDraw(gameText[gIndex])
	showTextDraw(gameText[gIndex])
	gameText[gIndex].timer = setTimer(destroyGameText, time, 1, gIndex)
	gIndex = gIndex > 100 and 1 or gIndex + 1 --Limit to 100
end

function destroyGameText(gIndex)
	if gameText[gIndex] == nil then
		return
	end
	destroyTextDraw(gameText[gIndex])
	if gameText[gIndex].timer then
		killTimer(gameText[gIndex].timer)
		gameText[gIndex].timer = nil
	end
	gameText[gIndex] = nil
end

function renderTextLabels()
	for id,textlabel in pairs(g_TextLabels) do
		if textlabel.enabled then
			if textlabel.attached then
				local oX, oY, oZ = getElementPosition(textlabel.attachedTo)
				oX = oX + textlabel.offX
				oY = oY + textlabel.offY
				oZ = oZ + textlabel.offZ
				textlabel.X = oX
				textlabel.Y = oY
				textlabel.Z = oZ
			end

			local screenX, screenY = getScreenFromWorldPosition(textlabel.X, textlabel.Y, textlabel.Z, textlabel.dist, false)
			local pX, pY, pZ = getElementPosition(localPlayer)
			local dist = getDistanceBetweenPoints3D(pX, pY, pZ, textlabel.X, textlabel.Y, textlabel.Z)
			local vw = getElementDimension(localPlayer)
			--[[if textlabel.attached then
				local LOS = isLineOfSightClear(pX, pY, pZ, textlabel.X, textlabel.Y, textlabel.Z, true, true, true, true, true, false, false, textlabel.attachedTo)
			else]] --Ã­Ã¥Ã°Ã Ã¡Ã®Ã²Ã Ã¥Ã², Ã¯Ã®ÃµÃ®Ã¦Ã¥ Ã´Ã³Ã­ÃªÃ¶Ã¨Ã¿ isLineOfSightClearÃ­Ã¥ Ã°Ã Ã¡Ã®Ã²Ã Ã¥Ã² Ã± Ã Ã°Ã£Ã³Ã¬Ã¥Ã­Ã²Ã®Ã¬ ignoredElement.
				local LOS = isLineOfSightClear(pX, pY, pZ, textlabel.X, textlabel.Y, textlabel.Z, true, false, false)--Ã¯Ã®ÃªÃ  Ã²Ã Ãª, Ã¯Ã®Ã²Ã®Ã¬ Ã°Ã Ã§Ã¡Ã¥Ã°Ã³Ã²Ã±Ã¿ Ã± Ã´Ã³Ã­ÃªÃ¶Ã¨Ã¥Ã© Ã±Ã¤Ã¥Ã«Ã Ã¥ÃªÃ Ãª Ã­Ã³Ã¦Ã­Ã® :)
			--end
			local len = string.len(textlabel.text)
			if screenX and dist <= textlabel.dist and vw == textlabel.vw then
				if not textlabel.los then
					--dxDrawText(textlabel.text, screenX, screenY, screenWidth, screenHeight, tocolor ( 0, 0, 0, 255 ), 1, "default")--, "center", "center")--, true, false)
					dxDrawText(textlabel.text, screenX, screenY, screenWidth, screenHeight, tocolor(textlabel.color.r, textlabel.color.g, textlabel.color.b, textlabel.color.a), 1, "default-bold")--, "center", "center", true, false)
				elseif LOS then
					--dxDrawText(textlabel.text, screenX, screenY, screenWidth, screenHeight, tocolor ( 0, 0, 0, 255 ), 1, "default")--, "center", "center")--, true, false)
					dxDrawText(textlabel.text, screenX - (len), screenY, screenWidth, screenHeight, tocolor(textlabel.color.r, textlabel.color.g, textlabel.color.b, textlabel.color.a), 1, "default-bold")--, "center", "center", true, false)
				end
			end
		end
	end
end
addEventHandler("onClientRender", root, renderTextLabels)

function checkTextLabels()
	for id,textlabel in pairs(g_TextLabels) do

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
	textlabel.enabled = false
	g_TextLabels[id] = textlabel
end

function Delete3DTextLabel(id)
	textlabel = g_TextLabels[id]
	table.removevalue(g_TextLabels, textlabel)
end

function Attach3DTextLabel(textlabel)
	local id = textlabel.id
	g_TextLabels[id] = textlabel
end

function TextDrawCreate(id, textdraw)
	textdraw.id = id
	textdraw.visible = false
	--outputConsole('Got TextDrawCreate, textdraw.visible is ' .. textdraw.visible)

	g_TextDraws[id] = textdraw
	if textdraw.x then
		textdraw.x = textdraw.x
		textdraw.y = textdraw.y
	end
	for prop,val in pairs(textdraw) do
		TextDrawPropertyChanged(id, prop, val, true)
	end
	initTextDraw(textdraw)
end

function TextDrawDestroy(id)
	destroyTextDraw(g_TextDraws[id])
end

function TextDrawHideForPlayer(id)
	hideTextDraw(g_TextDraws[id])
end

function TextDrawPropertyChanged(id, prop, newval, skipInit)
	if g_TextDraws == nil then
		outputConsole('Error: g_TextDraws is nil')
		return
	end

	if g_TextDraws[id] == nil then
		outputConsole('Error: g_TextDraws is nil at index: ' .. id)
		return
	end

	local textdraw = g_TextDraws[id]
	textdraw[prop] = newval
	if prop == 'boxsize' then
		textdraw.boxsize[1] = textdraw.boxsize[1]
		textdraw.boxsize[2] = textdraw.boxsize[2]
	elseif prop:match('color') then
		textdraw[prop] = tocolor(unpack(newval))
	end
	if not skipInit then
		initTextDraw(textdraw)
	end
end

function TextDrawShowForPlayer(id)
	--outputConsole(string.format("TextDrawShowForPlayer trying to show textdraw with id %d", id))
	--outputConsole(string.format("TextDrawShowForPlayer trying to show textdraw with text %s", g_TextDraws[id].text))
	
	showTextDraw(g_TextDraws[id])
end

function displayFadingMessage(text, r, g, b, fadeInTime, stayTime, fadeOutTime)
	local lineHeight = 40
	local label = guiCreateLabel(screenWidth, screenHeight, 500, lineHeight, text, false)
	local width = guiLabelGetTextExtent(label)
	guiSetPosition(label, screenWidth/2 - width/2, 3*screenHeight/4, false)
	guiSetSize(label, width, lineHeight, false)
	guiSetAlpha(label, 0)
	if r and g and b then
		guiLabelSetColor(label, r, g, b)
	end
	local anim = Animation.createNamed('fadingLabels')
	anim:addPhase(
		{ elem = label,
			Animation.presets.guiFadeIn(fadeInTime or 1000),
			{ time = stayTime or 3000 },
			Animation.presets.guiFadeOut(fadeOutTime or 1000),
			destroyElement
		}
	)
	anim:play()
end

-----------------------------
-- Menus

local function updateMenuSize(menu)
	menu.width = (#menu.items[1] > 0 and (menu.leftColumnWidth + menu.rightColumnWidth) or (menu.leftColumnWidth)) + 2*MENU_SIDE_PADDING
	menu.height = MENU_ITEM_HEIGHT*math.max(#menu.items[0], #menu.items[1]) + MENU_TOP_PADDING + MENU_BOTTOM_PADDING
end

function AddMenuItem(id, column, caption)
	local menu = g_Menus[id]
	table.insert(menu.items[column], caption)
	updateMenuSize(menu)
end

function CreateMenu(id, menu)
	menu.x = math.floor(menu.x * screenWidth / 640)
	menu.y = math.floor(menu.y * screenHeight / 480)
	menu.leftColumnWidth = math.floor(menu.leftColumnWidth * screenWidth / 640)
	menu.rightColumnWidth = math.floor(menu.rightColumnWidth * screenWidth / 480)
	local id = 1
	while g_TextDraws['m' .. id] do
		id = id + 1
	end
	menu.titletextdraw = { text = menu.title, id = 'm' .. id, x = menu.x + MENU_SIDE_PADDING, y = menu.y - 0.5*MENU_ITEM_HEIGHT, align = 1, font = 2 }
	initTextDraw(menu.titletextdraw)
	hideTextDraw(menu.titletextdraw)
	updateMenuSize(menu)
	g_Menus[id] = menu
end

function DisableMenuRow(menuID, rowID)
	local menu = g_Menus[menuID]
	menu.disabledrows = menu.disabledrows or {}
	table.insert(menu.disabledrows, rowID)
end

function SetMenuColumnHeader(menuID, column, text)
	g_Menus[menuID].items[column][13] = text
end

function ShowMenuForPlayer(menuID)
	if g_CurrentMenu and g_CurrentMenu.anim then
		g_CurrentMenu.anim:remove()
		g_CurrentMenu.anim = nil
	end

	local prevMenu = g_CurrentMenu
	g_CurrentMenu = g_Menus[menuID]
	local closebtnSide = screenWidth*(30/1024)
	if not prevMenu then
		g_CurrentMenu.alpha = 0
		g_CurrentMenu.titletextdraw.alpha = 0

		g_CurrentMenu.closebtn = guiCreateStaticImage(g_CurrentMenu.x + g_CurrentMenu.width - closebtnSide, g_CurrentMenu.y, closebtnSide, closebtnSide, 'client/closebtn.png', false, nil)
		guiSetAlpha(g_CurrentMenu.closebtn, 0)
		addEventHandler('onClientMouseEnter', g_CurrentMenu.closebtn,
			function()
				guiSetVisible(g_CurrentMenu.closebtn, false)
				guiSetVisible(g_CurrentMenu.closebtnhover, true)
			end,
			false
		)

		g_CurrentMenu.closebtnhover = guiCreateStaticImage(g_CurrentMenu.x + g_CurrentMenu.width - closebtnSide, g_CurrentMenu.y, closebtnSide, closebtnSide, 'client/closebtn_hover.png', false, nil)
		guiSetVisible(g_CurrentMenu.closebtnhover, false)
		guiSetAlpha(g_CurrentMenu.closebtnhover, .75)
		addEventHandler('onClientMouseLeave', g_CurrentMenu.closebtnhover,
			function()
				guiSetVisible(g_CurrentMenu.closebtnhover, false)
				guiSetVisible(g_CurrentMenu.closebtn, true)
			end,
			false
		)

		addEventHandler('onClientGUIClick', g_CurrentMenu.closebtnhover,
			function()
				if not g_CurrentMenu.anim then
					HideMenuForPlayer()
				end
			end,
			false
		)

		g_CurrentMenu.anim = Animation.createAndPlay(
			g_CurrentMenu,
			{ time = 500, from = 0, to = 1, fn = setMenuAlpha },
			function()
				setMenuAlpha(g_CurrentMenu, 1)
				g_CurrentMenu.titletextdraw.alpha = nil
				g_CurrentMenu.anim = nil
			end
		)

		addEventHandler('onClientRender', root, renderMenu)
		addEventHandler('onClientClick', root, menuClickHandler)
		showCursor(true)
	else
		hideTextDraw(prevMenu.titletextdraw)
		g_CurrentMenu.closebtn = prevMenu.closebtn
		prevMenu.closebtn = nil
		guiSetPosition(g_CurrentMenu.closebtn, g_CurrentMenu.x + g_CurrentMenu.width - closebtnSide, g_CurrentMenu.y, false)
		g_CurrentMenu.closebtnhover = prevMenu.closebtnhover
		prevMenu.closebtnhover = nil
		guiSetPosition(g_CurrentMenu.closebtnhover, g_CurrentMenu.x + g_CurrentMenu.width - closebtnSide, g_CurrentMenu.y, false)
		g_CurrentMenu.alpha = 1
	end
	showTextDraw(g_CurrentMenu.titletextdraw)
	bindKey('enter', 'down', OnKeyPress)
end

function HideMenuForPlayer(menuID)
	if g_CurrentMenu and (not menuID or g_CurrentMenu.id == menuID) then
		if g_CurrentMenu.anim then
			g_CurrentMenu.anim:remove()
			g_CurrentMenu.anim = nil
		end
		g_CurrentMenu.anim = Animation.createAndPlay(g_CurrentMenu, { time = 500, from = 1, to = 0, fn = setMenuAlpha }, exitMenu)
	end
end

function DestroyMenu(menuID)
	destroyTextDraw(g_Menus[menuID].titletextdraw)
	if g_CurrentMenu and menuID == g_CurrentMenu.id then
		exitMenu()
	end
	g_Menus[menuID] = nil
end

function setMenuAlpha(menu, alpha)
	menu.alpha = alpha
	menu.titletextdraw.alpha = alpha
	guiSetAlpha(menu.closebtn, .75*alpha)
	guiSetAlpha(menu.closebtnhover, .75*alpha)
end

function closeMenu()
	removeEventHandler('onClientRender', root, renderMenu)
	hideTextDraw(g_CurrentMenu.titletextdraw)
	g_CurrentMenu.titletextdraw.alpha = nil
	removeEventHandler('onClientClick', root, menuClickHandler)
	g_CurrentMenu.anim = nil
	destroyElement(g_CurrentMenu.closebtn)
	g_CurrentMenu.closebtn = nil
	destroyElement(g_CurrentMenu.closebtnhover)
	g_CurrentMenu.closebtnhover = nil
	g_CurrentMenu = nil
	showCursor(false)
	unbindKey('enter', 'down', OnKeyPress)
end

function exitMenu()
	closeMenu()
	serverAMXEvent('OnPlayerExitedMenu', g_PlayerID)
end

function renderMenu()
	local menu = g_CurrentMenu
	if not menu then
		return
	end

	-- background
	dxDrawRectangle(menu.x, menu.y, menu.width, menu.height, tocolor(0, 0, 0, 128*menu.alpha))

	local cursorX, cursorY = getCursorPosition()
	cursorY = screenHeight*cursorY
	-- selected row
	local selectedRow
	if cursorY >= menu.y + MENU_TOP_PADDING and cursorY < menu.y + menu.height - MENU_BOTTOM_PADDING then
		selectedRow = math.floor((cursorY - menu.y - MENU_TOP_PADDING) / MENU_ITEM_HEIGHT)
		dxDrawRectangle(menu.x, menu.y + MENU_TOP_PADDING + selectedRow*MENU_ITEM_HEIGHT, menu.width, MENU_ITEM_HEIGHT, tocolor(98, 152, 219, 192*menu.alpha))
	end

	-- menu items
	for column=0,1 do
		for i,text in pairs(menu.items[column]) do
			local x = menu.x + MENU_SIDE_PADDING + column*menu.leftColumnWidth
			local y
			local color, scale
			if i < 13 then
				-- regular item
				y = menu.y + MENU_TOP_PADDING + (i-1)*MENU_ITEM_HEIGHT
				if menu.disabledrows and table.find(menu.disabledrows, i-1) then
					color = tocolor(100, 100, 100, 255*menu.alpha)
				else
					color = (i-1) == selectedRow and tocolor(255, 255, 255, 255*menu.alpha) or tocolor(180, 180, 180, 255*menu.alpha)
				end
				scale = 0.7
			else
				-- column header
				y = menu.y + MENU_TOP_PADDING - MENU_ITEM_HEIGHT
				color = tocolor(228, 190, 57, 255*menu.alpha)
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
	cursorY = screenHeight*cursorY
	if cursorY < g_CurrentMenu.y + MENU_TOP_PADDING or cursorY > g_CurrentMenu.y + MENU_TOP_PADDING + math.max(#g_CurrentMenu.items[0], #g_CurrentMenu.items[1])*MENU_ITEM_HEIGHT then
		return
	end
	local selectedRow = math.floor((clickY - g_CurrentMenu.y - MENU_TOP_PADDING) / MENU_ITEM_HEIGHT)
	if not (g_CurrentMenu.disabledrows and table.find(g_CurrentMenu.disabledrows, selectedRow)) then
		serverAMXEvent('OnPlayerSelectedMenuRow', g_PlayerID, selectedRow)
		exitMenu()
	end
end

function OnKeyPress(key, keyState)
	if ( keyState == "down" ) then
		exitMenu()
	end
end

-----------------------------
-- Others

function enableWeaponSyncing(enable)
	if enable and not g_WeaponSyncTimer then
		g_WeaponSyncTimer = setTimer(sendWeapons, 5000, 0)
	elseif not enable and g_WeaponSyncTimer then
		killTimer(g_WeaponSyncTimer)
		g_WeaponSyncTimer = nil
	end
end

local prevWeapons
function sendWeapons()
	local weapons = {}
	local needResync = false
	for slot=0,12 do
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
	if g_Blips[blipID] then
		destroyElement(g_Blips[blipID])
		g_Blips[blipID] = nil
	end
end

function SetPlayerMapIcon(blipID, x, y, z, type, r, g, b, a)
	if g_Blips[blipID] then
		destroyElement(g_Blips[blipID])
		g_Blips[blipID] = nil
	end
	g_Blips[blipID] = createBlip(x, y, z, type, 2, r, g, b, a)
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
		if isVehicle then
			setElementVelocity(elem, vx, vy, vz)
		else
			setElementPosition(elem, x, y, z)
		end
		if not gameText then
			GameTextForPlayer('Don\'t leave the ~r~world boundaries!', 2000)
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
end

function createListDialog()
		listDialog = nil
		listWindow = guiCreateWindow(screenWidth/2 - 541/2,screenHeight/2 - 352/2,541,352,"",false)
		guiWindowSetMovable(listWindow,false)
		guiWindowSetSizable(listWindow,false)
		listGrid = guiCreateGridList(0.0, 0.1, 1.0, 0.8,true,listWindow)
		guiGridListSetSelectionMode(listGrid,2)
		guiGridListSetScrollBars(listGrid, true, true)
		listColumn = guiGridListAddColumn(listGrid, "List", 0.85)
		listButton1 = guiCreateButton(10,323,256,20,"",false,listWindow)
		listButton2 = guiCreateButton(281,323,256,20,"",false,listWindow)
		guiSetVisible(listWindow, false)
		addEventHandler("onClientGUIClick", listButton1, OnListDialogButton1Click, false)
		addEventHandler("onClientGUIClick", listButton2, OnListDialogButton2Click, false)
end

function createInputDialog()
		inputDialog = nil
		inputWindow = guiCreateWindow(screenWidth/2 - 541/2,screenHeight/2 - 352/2,541,352,"",false)
		guiWindowSetMovable(listWindow,false)
		guiWindowSetSizable(listWindow,false)
		inputLabel = guiCreateLabel(0.1, 0.1, 1.0, 0.8, "", true, inputWindow)
		inputEdit = guiCreateEdit(0.0, 0.7, 1.0, 0.1,"",true,inputWindow)
		inputButton1 = guiCreateButton(0.3, 0.9, 0.15, 0.1,"",true,inputWindow) --x, y, width, height
		inputButton2 = guiCreateButton(0.5, 0.9, 0.15, 0.1,"",true,inputWindow)
		guiSetVisible(inputWindow, false)
		addEventHandler("onClientGUIClick", inputButton1, OnInputDialogButton1Click, false)
		addEventHandler("onClientGUIClick", inputButton2, OnInputDialogButton2Click, false)
end

function createMessageDialog()
		msgDialog = nil
		msgWindow = guiCreateWindow(screenWidth/2 - 541/2,screenHeight/2 - 352/2,541,352,"",false)
		guiWindowSetMovable(msgWindow,false)
		guiWindowSetSizable(msgWindow,false)
		msgLabel = guiCreateLabel(0.0, 0.1, 1.0, 0.7, "", true, msgWindow)
		msgButton1 = guiCreateButton(0.3, 0.9, 0.15, 0.1,"",true,msgWindow) --x, y, width, height
		msgButton2 = guiCreateButton(0.5, 0.9, 0.15, 0.1,"",true,msgWindow)
		guiSetVisible(msgWindow, false)
		addEventHandler("onClientGUIClick", msgButton1, OnMessageDialogButton1Click, false)
		addEventHandler("onClientGUIClick", msgButton2, OnMessageDialogButton2Click, false)
end

function InitDialogs()
	createListDialog()
	createInputDialog()
	createMessageDialog()
end

function OnListDialogButton1Click( button, state )
	if button == "left" then
		local row, column = guiGridListGetSelectedItem(listGrid)
		local text = guiGridListGetItemText(listGrid, row, column)
		serverAMXEvent("OnDialogResponse", getElemID(localPlayer), listDialog, 1, row, text);
		guiSetVisible(listWindow, false)
		guiGridListClear(listGrid)
		showCursor(false)
		listDialog = nil
	end
end

function OnListDialogButton2Click( button, state )
	if button == "left" then
		local row, column = guiGridListGetSelectedItem(listGrid)
		local text = guiGridListGetItemText(listGrid, row, column)
		serverAMXEvent("OnDialogResponse", getElemID(localPlayer), listDialog, 0, row, text);
		guiSetVisible(listWindow, false)
		guiGridListClear(listGrid)
		showCursor(false)
		listDialog = nil
	end
end

function OnInputDialogButton1Click( button, state )
	if button == "left" then
		serverAMXEvent("OnDialogResponse", getElemID(localPlayer), inputDialog, 1, 0, guiGetText(inputEdit));
		guiSetVisible(inputWindow, false)
		showCursor(false)
		inputDialog = nil
	end
end

function OnInputDialogButton2Click( button, state )
	if button == "left" then
		serverAMXEvent("OnDialogResponse", getElemID(localPlayer), inputDialog, 0, 0, guiGetText(inputEdit));
		guiSetVisible(inputWindow, false)
		showCursor(false)
		inputDialog = nil
	end
end

function OnMessageDialogButton1Click( button, state )
	if button == "left" then
		serverAMXEvent("OnDialogResponse", getElemID(localPlayer), msgDialog, 1, 0, "");
		guiSetVisible(msgWindow, false)
		showCursor(false)
		msgDialog = nil
	end
end

function OnMessageDialogButton2Click( button, state )
	if button == "left" then
		serverAMXEvent("OnDialogResponse", getElemID(localPlayer), msgDialog, 0, 0, "");
		guiSetVisible(msgWindow, false)
		msgDialog = nil
		showCursor(false)
	end
end


function ShowPlayerDialog(dialogid, dialogtype, caption, info, button1, button2)
	if dialogtype == 0 then
		guiSetText(msgButton1, button1)
		guiSetText(msgButton2, button2)
		guiSetText(msgWindow, caption)
		guiSetText(msgLabel, info)
		guiSetVisible(msgWindow, true)
		msgDialog = dialogid
		showCursor(true)
	elseif dialogtype == 1 or dialogtype == 3 then
		guiSetText(inputButton1, button1)
		guiSetText(inputButton2, button2)
		guiSetText(inputWindow, caption)
		guiSetText(inputEdit, "")
		guiEditSetMasked(inputEdit, dialogtype == 3)
		guiSetText(inputLabel, info)
		guiSetVisible(inputWindow, true)
		inputDialog = dialogid
		showCursor(true)
	elseif dialogtype == 2 then
		guiSetText(listButton1, button1)
		guiSetText(listButton2, button2)
		guiSetText(listWindow, caption)
		guiSetVisible(listWindow, true)
		listDialog = dialogid
		showCursor(true)
		local items = string.gsub(info, "\t", "        ")
		items = string.split(items, "\n")
		for k,v in ipairs(items) do
			local row = guiGridListAddRow ( listGrid )
			guiGridListSetItemText ( listGrid, row, listColumn, v, false, true)
		end
	end
end

addEvent ( "onPlayerClickPlayer" )
function OnPlayerClickPlayer ( element )
	serverAMXEvent('OnPlayerClickPlayer', getElemID(localPlayer), getElemID(element), 0)
end
addEventHandler ( "onPlayerClickPlayer", root, OnPlayerClickPlayer )
