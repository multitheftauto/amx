function argsToMTA(amx, prototype, ...)
	if type(amx) == 'userdata' then
		local amxName = table.find(g_LoadedAMXs, 'cptr', amx)
		if not amxName then
			print('argsToMTA: No amx found for provided cptr')
			return 0
		end
		amx = g_LoadedAMXs[amxName]
	end

	local args = { ... }
	local val
	local argMissing = false
	local colorArgs
	for i, val in ipairs(args) do
		vartype = prototype[i]
		if vartype == 'b' then			-- boolean
			val = val ~= 0
		elseif vartype == 'c' then		-- color
			if not colorArgs then
				colorArgs = {}
			end
			colorArgs[i] = { binshr(val, 24) % 0x100, binshr(val, 16) % 0x100, binshr(val, 8) % 0x100 }		-- r, g, b
			val = val % 0x100			-- a
		elseif vartype == 'p' then		-- player
			val = g_Players[val] and g_Players[val].elem
		elseif vartype == 'z' then		-- bot/ped
			val = g_Bots[val] and g_Bots[val].elem
		elseif vartype == 't' then		-- team
			val = val ~= 0 and g_Teams[val]
		elseif vartype == 'v' then		-- vehicle
			val = g_Vehicles[val] and g_Vehicles[val].elem
		elseif vartype == 'o' then		-- object
			val = g_Objects[val] and g_Objects[val].elem
		elseif vartype == 'u' then		-- pickup
			val = g_Pickups[val] and g_Pickups[val].elem
		elseif vartype == 'x' then		-- textdraw
			val = g_TextDraws[val]
		elseif vartype == 'm' then		-- menu
			val = g_Menus[val]
		elseif vartype == 'g' then		-- gang zone
			val = g_GangZones[val] and g_GangZones[val].elem
		elseif vartype == 'k' then		-- native marker
			val = g_Markers[val] and g_Markers[val].elem
		elseif vartype == 'a' then		-- 3D text label
			val = g_TextLabels[val]
		elseif vartype == 'y' then		-- Actor
			val = g_Actors[val] and g_Actors[val].elem
		end
		if val == nil then
			val = false
			argMissing = true
		end
		args[i] = val
	end
	if colorArgs then
		local indexOffset = 0
		for i, colorArg in pairs(colorArgs) do
			for j, color in ipairs(colorArg) do
				table.insert(args, i + j - 1 + indexOffset, color)
			end
			indexOffset = indexOffset + 3
		end
	end

	return args, argMissing
end
local argsToMTA = argsToMTA

function argsToSAMP(amx, prototype, ...)
	if type(amx) == 'userdata' then
		local amxName = table.find(g_LoadedAMXs, 'cptr', amx)
		if not amxName then
			print('argsToSAMP: No amx found for provided cptr')
			return 0
		end
		amx = g_LoadedAMXs[amxName]
	end

	local args = { ... }
	for i, v in ipairs(args) do
		if type(v) == 'nil' then
			args[i] = 0
		elseif type(v) == 'boolean' then
			args[i] = v and 1 or 0
		elseif type(v) == 'string' then
			-- keep unmodified
		elseif type(v) == 'number' then
			if prototype[i] == 'f' then
				args[i] = float2cell(v)
			end
		elseif type(v) == 'userdata' then
			args[i] = isElement(v) and getElemID(v)
		else
			args[i] = 0
		end
	end
	return args
end

function syscall(amx, svc, prototype, ...)		-- svc = service number (= index in native functions table) or name of native function
	if type(amx) == 'userdata' then
		local amxName = table.find(g_LoadedAMXs, 'cptr', amx)
		if amxName then
			amx = g_LoadedAMXs[amxName]
		else
			local dynamicAmx = {name = 'dynamicAmx', res = 'dynamicAmx', cptr = amx }
			dynamicAmx.memCOD = setmetatable({ amx = dynamicAmx.cptr }, { __index = amxMTReadCODCell })
			dynamicAmx.memDAT = setmetatable({ amx = dynamicAmx.cptr }, { __index = amxMTReadDATCell, __newindex = amxMTWriteDATCell })

			amx = dynamicAmx
		end
	end
	local fnName = type(svc) == 'number' and amx.natives[svc] or svc
	local fn = prototype.fn or _G[fnName]
	if not fn and not prototype.client then
		outputDebugString('syscall: function ' .. tostring(fn) .. ' (' .. fnName .. ') doesn\'t exist', 1)
		return
	end

	local args, argMissing = argsToMTA(amx, prototype, ...)

	if argMissing then
		return 0
	end
	--[[
	local logstr = fnName .. '('
	for i, argval in ipairs(args) do
		if i > 1 then
			logstr = logstr .. ', '
		end
		logstr = logstr .. tostring(argval)
	end
	logstr = logstr .. ')'
	print(logstr)
	outputConsole(logstr)
	--]]

	local result
	if prototype.client then
		local player = table.remove(args, 1)
		clientCall(player, fnName, unpack(args))
	else
		result = fn(amx, unpack(args))
		if type(result) == 'boolean' then
			result = result and 1 or 0
		end
	end
	--print('syscall returned ' .. tostring(result or 0))
	return result or 0
end

function Dummy(amx, text)
	return 0
end
Broadcast = Dummy

function toggleUninmplementedErrors ( playerSource, commandName )
	if not isPlayerInACLGroup(playerSource, 'Console') then
		return
	end
	ShowUnimplementedErrors = not ShowUnimplementedErrors
	outputDebugString('[INFO]: ShowUnimplementedErrors is now ' .. (ShowUnimplementedErrors and "Enabled" or "Disabled"))
end
addCommandHandler ( "showunimplementederrors", toggleUninmplementedErrors )
-----------------------------------------------------
-- List of the functions and their argument types

g_SAMPSyscallPrototypes = {
	Broadcast = {'s'},

	AddMenuItem = {'m', 'i', 's'},
	AddPlayerClass = {'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i'},
	AddPlayerClassEx = {'t', 'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i'},
	AddPlayerClothes = {'p', 'i', 'i'},
	AddStaticPickup = {'i', 'i', 'f', 'f', 'f'},
	AddStaticVehicle = {'i', 'f', 'f', 'f', 'f', 'i', 'i'},
	AddStaticVehicleEx = {'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'b'},
	AddVehicleComponent = {'v', 'i'},
	AllowAdminTeleport = {'b'},
	AllowInteriorWeapons = {'b'},
	AllowPlayerTeleport = {'p', 'b'},
	ApplyAnimation = {'p', 's', 's', 'f', 'b', 'b', 'b', 'b', 'i'},
	AttachObjectToPlayer = {'o', 'p', 'f', 'f', 'f', 'f', 'f', 'f'},
	AttachPlayerObjectToPlayer = {'p', 'i', 'p', 'f', 'f', 'f', 'f', 'f', 'f', client = true},
	AttachObjectToObject = {'o', 'o', 'f', 'f', 'f', 'f', 'f', 'f', 'b'},
	AttachObjectToVehicle = {'o', 'v', 'f', 'f', 'f', 'f', 'f', 'f'},
	AttachPlayerObjectToVehicle = {'p', 'i', 'v', 'f', 'f', 'f', 'f', 'f', 'f', client = true},
	AttachTrailerToVehicle = {'v', 'v'},

	Ban = {'p'},
	BanEx = {'p', 's'},

	CallLocalFunction = {'s', 's'},
	CallRemoteFunction = {'s', 's'},
	ChangeVehicleColor = {'v', 'i', 'i'},
	ChangeVehiclePaintjob = {'v', 'i'},
	ClearAnimations = {'p'},
	CreateExplosion = {'f', 'f', 'f', 'i', 'f'},
	CreateMenu = {'s', 'i', 'f', 'f', 'f', 'f'},
	CreateObject = {'i', 'f', 'f', 'f', 'f', 'f', 'f'},
	CreatePickup = {'i', 'i', 'f', 'f', 'f'},
	CreatePlayerObject = {'p', 'i', 'f', 'f', 'f', 'f', 'f', 'f'},
	CreateVehicle = {'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'b'},

	DestroyMenu = {'m'},
	DestroyObject = {'o'},
	DestroyPickup = {'u'},
	DestroyPlayerObject = {'p', 'i'},
	DestroyVehicle = {'v'},
	DetachTrailerFromVehicle = {'v'},
	DisableMenu = {'i'},
	DisableMenuRow = {'i', 'i'},
	DisablePlayerCheckpoint = {'p'},
	DisablePlayerRaceCheckpoint = {'p'},

	EnableTirePopping = {'b'},
	EnableZoneNames = {'b'},

	ForceClassSelection = {'i'},

	GameModeExit = {},
	GameTextForAll = {'s', 'i', 'i'},
	GameTextForPlayer = {'p', 's', 'i', 'i'},
	GangZoneCreate = {'f', 'f', 'f', 'f'},
	GangZoneDestroy = {'g'},
	GangZoneShowForPlayer = {'p', 'g', 'c'},
	GangZoneShowForAll = {'g', 'c'},
	GangZoneHideForPlayer = {'p', 'g'},
	GangZoneHideForAll = {'g'},
	GangZoneFlashForPlayer = {'p', 'g', 'c'},
	GangZoneFlashForAll = {'g', 'c'},
	GangZoneStopFlashForPlayer = {'p', 'g'},
	GangZoneStopFlashForAll = {'g'},
	GetConsoleVarAsBool = {'s'},
	GetConsoleVarAsInt = {'s'},
	GetConsoleVarAsString = {'s', 'r', 'i'},
	GetGravity = {},
	GetMaxPlayers = {},
	GetPlayerObjectModel = {'p', 'i'},
	GetObjectModel = {'o'},
	GetObjectPos = {'o', 'r', 'r', 'r'},
	GetObjectRot = {'o', 'r', 'r', 'r'},
	GetPlayerAmmo = {'p'},
	GetPlayerArmour = {'p', 'r'},
	GetPlayerCameraPos = {'p', 'r', 'r', 'r'},
	GetPlayerCameraFrontVector = {'p', 'r', 'r', 'r'},
	GetPlayerColor = {'p'},
	GetPlayerClothes = {'p', 'i'},
	GetPlayerFacingAngle = {'p', 'r'},
	GetPlayerHealth = {'p', 'r'},
	GetPlayerInterior = {'p'},
	GetPlayerIp = {'p', 'r', 'i'},
	GetPlayerKeys = {'p', 'r', 'r', 'r'},
	GetPlayerMenu = {'p'},
	GetPlayerMoney = {'p'},
	GetPlayerName = {'p', 'r', 'i'},
	GetPlayerObjectPos = {'p', 'i', 'r', 'r', 'r'},
	GetPlayerObjectRot = {'p', 'i', 'r', 'r', 'r'},
	GetPlayerPing = {'p'},
	GetPlayerPos = {'p', 'r', 'r', 'r'},
	GetPlayerScore = {'p'},
	GetPlayerSkin = {'p'},
	GetPlayerSpecialAction = {'p'},
	GetPlayerState = {'p'},
	GetPlayerSurfingVehicleID = {'p'},
	GetPlayerSurfingObjectID = {'p'},
	GetPlayerTeam = {'p'},
	GetPlayerTime = {'p', 'r', 'r'},
	GetPlayerFightingStyle = {'p'},
	GetPlayerVehicleSeat = {'p'},
	GetPlayerVelocity = {'p', 'r', 'r', 'r'},
	GetPlayerVehicleID = {'p'},
	GetPlayerVirtualWorld = {'p'},
	GetPlayerWantedLevel = {'p'},
	GetPlayerWeapon = {'p'},
	GetPlayerArmedWeapon = {'p'},
	GetPlayerWeaponData = {'p', 'i', 'r', 'r'},
	GetPlayerTargetPlayer = {'p'},
	GetServerVarAsBool = {'s'},
	GetServerVarAsInt = {'s'},
	GetServerVarAsString = {'s', 'r', 'i'},
	GetTickCount = {},
	GetVehicleHealth = {'v', 'r'},
	GetVehicleModel = {'v'},
	GetVehiclePos = {'v', 'r', 'r', 'r'},
	GetVehicleTrailer = {'v'},
	GetVehicleVelocity = {'v', 'r', 'r', 'r' },
	GetVehicleVirtualWorld = {'v'},
	GetVehicleZAngle = {'v', 'r'},
	GetVehicleRotationQuat = {'v', 'r', 'r', 'r', 'r'},
	GetVehicleModelInfo = {'i', 'i', 'r', 'r', 'r'},
	GetWeaponName = {'i', 'r', 'i'},
	GetPlayerLastShotVectors = {'p', 'r', 'r', 'r', 'r', 'r', 'r'},
	GetPlayerVersion = {'p', 'r', 'i'},
	GetPlayerWeaponState = {'p'},
	GivePlayerMoney = {'p', 'i'},
	GivePlayerWeapon = {'p', 'i', 'i'},

	GetPVarInt = {'p', 's'},
	GetPVarFloat = {'p', 's'},
	GetPVarString = {'p', 's', 'r', 'i'},
	GetPVarType = {'p', 's'},
	GetPVarNameAtIndex = {'p', 'i', 'r', 'i'},
	GetPVarsUpperIndex = {'p'},
	DeletePVar = {'p', 's'},

	GetSVarInt = {'s'},
	GetSVarFloat = {'s'},
	GetSVarString = {'s', 'r', 'i'},
	GetSVarType = {'s'},
	GetSVarNameAtIndex = {'i', 'r', 'i'},
	GetSVarsUpperIndex = {},
	DeleteSVar = {'s'},

	HideMenuForPlayer = {'m', 'p'},

	IsPlayerAdmin = {'p'},
	IsPlayerConnected = {'i'},
	IsPlayerInAnyVehicle = {'p'},
	IsPlayerInCheckpoint = {'p'},
	IsPlayerInRaceCheckpoint = {'p'},
	IsPlayerInVehicle = {'p', 'v'},
	IsPluginLoaded = {'s'},
	IsTrailerAttachedToVehicle = {'v'},
	IsValidMenu = {'i'},
	IsValidObject = {'i'},
	IsValidPlayerObject = {'p', 'i'},
	IsValidVehicle = {'i'},

	Kick = {'p'},
	KillTimer = {'i'},

	LimitGlobalChatRadius = {'f'},
	LimitPlayerMarkerRadius = {'f'},
	LinkVehicleToInterior = {'v', 'i'},

	MoveObject = {'o', 'f', 'f', 'f', 'f', 'f', 'f', 'f'},
	MovePlayerObject = {'p', 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'f'},

	IsObjectMoving = {'o'},
	IsPlayerObjectMoving = {'p', 'i'},

	PlayerSpectatePlayer = {'p', 'p', 'i'},
	PlayerSpectateVehicle = {'p', 'v', 'i'},
	PutPlayerInVehicle = {'p', 'v', 'i'},
	RepairVehicle = {'v'},

	RemovePlayerClothes = {'p', 'i'},
	RemovePlayerFromVehicle = {'p'},
	RemovePlayerMapIcon = {'p', 'i', client = true},
	RemoveVehicleComponent = {'v', 'i'},
	ResetPlayerMoney = {'p'},
	ResetPlayerWeapons = {'p'},

	SendClientMessage = {'p', 'c', 's'},
	SendClientMessageToAll = {'c', 's'},
	SendDeathMessage = {'p', 'p', 'i'},
	SendDeathMessageToPlayer = {'p', 'p', 'p', 'i'},
	SendPlayerMessageToAll = {'p', 's'},
	SendPlayerMessageToPlayer = {'p', 'p', 's'},
	SendRconCommand = {'s'},
	SetCameraBehindPlayer = {'p'},
	SetDeathDropAmount = {'i'},
	SetDisabledWeapons = {},
	SetGameModeText = {'s'},
	SetGravity = {'f'},
	SetMenuColumnHeader = {'m', 'i', 's'},
	SetObjectPos = {'o', 'f', 'f', 'f'},
	SetObjectRot = {'o', 'f', 'f', 'f'},
	SetPlayerAmmo = {'p', 'i', 'i'},
	SetPlayerArmour = {'p', 'f'},
	SetPlayerCameraLookAt = {'p', 'f', 'f', 'f'},
	SetPlayerCameraPos = {'p', 'f', 'f', 'f'},
	SetPlayerCheckpoint = {'p', 'f', 'f', 'f', 'f'},
	SetPlayerColor = {'p', 'c'},
	SetPlayerDisabledWeapons = {'p'},
	SetPlayerFacingAngle = {'p', 'f'},
	SetPlayerGravity = {'p', 'f'},
	SetPlayerHealth = {'p', 'f'},
	SetPlayerInterior = {'p', 'i'},
	SetPlayerMapIcon = {'p', 'i', 'f', 'f', 'f', 'i', 'c', 'i', client = true},
	SetPlayerMarkerForPlayer = {'p', 'p', 'c', client = true},
	SetPlayerName = {'p', 's'},
	SetPlayerObjectPos = {'p', 'i', 'f', 'f', 'f'},
	SetPlayerObjectRot = {'p', 'i', 'f', 'f', 'f'},
	SetPlayerPos = {'p', 'f', 'f', 'f'},
	SetPlayerPosFindZ = {'p', 'f', 'f', 'f'},
	SetPlayerRaceCheckpoint = {'p', 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'f'},
	SetPlayerScore = {'p', 'i'},
	SetPlayerSkin = {'p', 'i'},
	SetPlayerSpecialAction = {'p', 'i'},
	SetPlayerTeam = {'p', 't'},
	SetPlayerTime = {'p', 'i', 'i'},
	SetPlayerArmedWeapon = {'p', 'i'},
	SetPlayerFightingStyle = {'p', 'i'},
	SetPlayerVirtualWorld = {'p', 'i'},
	SetPlayerVelocity = {'p', 'f', 'f', 'f'},
	SetPlayerSkillLevel = {'p', 'i', 'i'},
	SetPlayerWantedLevel = {'p', 'i'},
	SetPlayerWeather = {'p', 'i'},
	SetPlayerWorldBounds = {'p', 'f', 'f', 'f', 'f', client = true},
	SetSpawnInfo = {'p', 't', 'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i'},
	SetTeamCount = {'i'},
	SetTimer = {'s', 'i', 'b'},
	SetTimerEx = {'s', 'i', 'b', 's'},
	SetVehicleHealth = {'v', 'f'},
	SetVehicleNumberPlate = {'v', 's'},
	SetVehicleParamsForPlayer = {'v', 'p', 'b', 'b'},
	SetVehiclePos = {'v', 'f', 'f', 'f'},
	SetVehicleToRespawn = {'v'},
	SetVehicleVelocity = {'v', 'f', 'f', 'f'},
	SetVehicleAngularVelocity = {'v', 'f', 'f', 'f'},
	SetVehicleVirtualWorld = {'v', 'i'},
	SetVehicleZAngle = {'v', 'f'},
	SetWeather = {'i'},
	SetWorldTime = {'i'},
	ShowMenuForPlayer = {'m', 'p'},
	ShowNameTags = {'b'},
	ShowPlayerMarker = {'p', 'i'},
	ShowPlayerMarkers = {'i'},
	ShowPlayerNameTagForPlayer = {'p', 'p', 'b'},
	SpawnPlayer = {'p'},
	StopObject = {'o'},
	StopPlayerObject = {'p', 'i'},

	SetPVarInt = {'p', 's', 'i'},
	SetPVarFloat = {'p', 's', 'f'},
	SetPVarString = {'p', 's', 's'},

	SetSVarInt = {'s', 'i'},
	SetSVarFloat = {'s', 'f'},
	SetSVarString = {'s', 's'},

	TextDrawAlignment = {'x', 'i'},
	TextDrawBackgroundColor = {'x', 'c'},
	TextDrawBoxColor = {'x', 'c'},
	TextDrawColor = {'x', 'c'},
	TextDrawCreate = {'f', 'f', 's'},
	TextDrawDestroy = {'i'},
	TextDrawFont = {'x', 'i'},
	TextDrawHideForAll = {'i'},
	TextDrawHideForPlayer = {'p', 'i'},
	TextDrawLetterSize = {'x', 'f', 'f'},
	TextDrawSetOutline = {'x', 'i'},
	TextDrawSetProportional = {'x', 'b'},
	TextDrawSetShadow = {'x', 'i'},
	TextDrawSetString = {'x', 's'},
	TextDrawShowForAll = {'i'},
	TextDrawShowForPlayer = {'p', 'i'},
	TextDrawTextSize = {'x', 'f', 'f'},
	TextDrawUseBox = {'x', 'b'},

	-- Player textdraws
	CreatePlayerTextDraw = {'p', 'f', 'f', 's'},
	PlayerTextDrawDestroy = {'p', 'i'},
	PlayerTextDrawShow = {'p', 'i'},
	PlayerTextDrawHide = {'p', 'i'},
	PlayerTextDrawBoxColor = {'p', 'i', 'c'},
	PlayerTextDrawUseBox = {'p', 'i', 'b'},
	PlayerTextDrawTextSize = {'p', 'i', 'f', 'f'},
	PlayerTextDrawLetterSize = {'p', 'i', 'f', 'f'},
	PlayerTextDrawAlignment = {'p', 'i', 'i'},
	PlayerTextDrawBackgroundColor = {'p', 'i', 'c'},
	PlayerTextDrawFont = {'p', 'i', 'i'},
	PlayerTextDrawColor = {'p', 'i', 'c'},
	PlayerTextDrawSetOutline = {'p', 'i', 'i'},
	PlayerTextDrawSetProportional = {'p', 'i', 'b'},
	PlayerTextDrawSetShadow = {'p', 'i', 'i'},
	PlayerTextDrawSetString = {'p', 'i', 's'},
	PlayerTextDrawSetPreviewModel = {'p', 'i', 'i'},
	PlayerTextDrawSetPreviewVehCol = {'p', 'i', 'i', 'i'},
	PlayerTextDrawSetSelectable = {'p', 'i', 'b'},
	PlayerTextDrawSetPreviewRot = {'p', 'i', 'f', 'f', 'f', 'f'},

	TogglePlayerClock = {'p', 'b', client = true},
	TogglePlayerControllable = {'p', 'b'},
	TogglePlayerSpectating = {'p', 'b'},

	CreateBot = { 'i', 'f', 'f', 'f', 's'},
	DestroyBot = {'z'},
	IsBotInWater = {'z'},
	IsBotOnFire = {'z'},
	IsBotDucked = {'z'},
	IsBotOnGround = {'z'},
	GetBotHealth = {'z', 'r'},
	SetBotHealth = {'z', 'f'},
	GetBotArmour = {'z', 'r'},
	SetBotArmour = {'z', 'f'},
	GetBotPos = {'z', 'r', 'r', 'r'},
	SetBotPos = {'z', 'f', 'f', 'f'},
	GetBotRot = {'z', 'r', 'r', 'r'},
	SetBotRot = {'z', 'f', 'f', 'f'},
	GetBotFightingStyle = {'z'},
	SetBotFightingStyle = {'z', 'i'},
	SetBotOnFire = {'z', 'b'},
	GetBotSkin = {'z'},
	SetBotSkin = {'z', 'i'},
	GetBotStat = {'z', 'i'},
	SetBotStat = {'z', 'i', 'f'},
	GetBotState = {'z'},
	PutBotInVehicle = {'z', 'v', 'i'},
	RemoveBotFromVehicle = {'z'},
	SetBotControlState = {'z', 's', 'b'},
	SetBotAimTarget = {'z', 'f', 'f', 'f'},
	GetBotDoingDriveBy = {'z'},
	SetBotDoingDriveBy = {'z', 'b'},
	GetBotCanBeKnockedOffBike = {'z'},
	SetBotCanBeKnockedOffBike = {'z', 'b'},
	SetBotWeaponSlot = {'z', 'i'},
	SetBotHeadless = {'z', 'b'},
	IsBotDead = {'z'},
	KillBot = {'z'},
	GetBotAlpha = {'z'},
	SetBotAlpha = {'z', 'i'},
	GetBotName = {'z', 'r', 'i'},
	GetBotVehicleSeat = {'z'},
	GetBotVelocity = {'z', 'r', 'r', 'r'},
	SetBotVelocity = {'z', 'f', 'f', 'f'},

	-- players
	IsPlayerInWater = {'p'},
	IsPlayerOnFire = {'p'},
	IsPlayerDucked = {'p'},
	IsPlayerOnGround = {'p'},
	SetPlayerOnFire = {'p', 'b'},
	GetPlayerStat = {'p', 'i'},
	SetPlayerStat = {'p', 'i', 'f'},
	GetPlayerCanBeKnockedOffBike = {'p'},
	SetPlayerCanBeKnockedOffBike = {'p', 'b'},
	GetPlayerDoingDriveBy = {'p'},
	SetPlayerDoingDriveBy = {'p', 'b'},
	SetPlayerWeaponSlot = {'p', 'i'},
	SetPlayerHeadless = {'p', 'b'},
	GetPlayerBlurLevel = {'p'},
	SetPlayerBlurLevel = {'p', 'i'},
	GetPlayerAlpha = {'p'},
	SetPlayerAlpha = {'p', 'i'},
	FadePlayerCamera = {'p', 'b', 'f', 'i', 'i', 'i'},
	SetPlayerControlState = {'p', 's', 'b'},
	GetPlayerSkillLevel = {'p', 'i'},

	-- vehicles
	SetVehicleModel = {'v', 'i'},
	GetVehicleEngineState = {'v'},
	SetVehicleEngineState = {'v', 'b'},
	GetVehicleDoorState = {'v', 'i'},
	SetVehicleDoorState = {'v', 'i', 'i'},
	GetVehicleDamageStatus = {'v', 'r', 'r', 'r', 'r'},
	UpdateVehicleDamageStatus = {'v', 'i', 'i', 'i', 'i'},
	GetVehicleMaxPassengers = {'v'},
	GetVehicleParamsCarDoors = {'v', 'r', 'r', 'r', 'r'},
	SetVehicleParamsCarDoors = {'v', 'b', 'b', 'b', 'b'},
	GetVehicleParamsEx = {'v', 'r', 'r', 'r', 'r', 'r', 'r', 'r'},
	SetVehicleParamsEx = {'v', 'b', 'b', 'b', 'b', 'b', 'b', 'b'},
	GetVehicleLightState = {'v', 'i'},
	SetVehicleLightState = {'v', 'i', 'i'},
	GetVehicleOverrideLights = {'v'},
	SetVehicleOverrideLights = {'v', 'i'},
	GetVehicleWheelState = {'v', 'i'},
	SetVehicleWheelState = {'v', 'i', 'i', 'i', 'i'},
	GetVehicleParamsSirenState = {'v'},
	GetVehicleSirenState = {'v'},
	SetVehicleSirenState = {'v', 'b'},
	GetVehicleAlpha = {'v'},
	SetVehicleAlpha = {'v', 'i'},
	GetVehiclePaintjob = {'v'},
	GetVehicleComponentInSlot = {'v', 'i'},
	GetVehicleComponentType = {'i'},
	IsTrainDerailable = {'v'},
	IsTrainDerailed = {'v'},
	SetTrainDerailable = {'v', 'b'},
	SetTrainDerailed = {'v', 'b'},
	GetTrainDirection = {'v'},
	SetTrainDirection = {'v', 'b'},
	GetTrainSpeed = {'v', 'r'},
	SetTrainSpeed = {'v', 'f'},

	-- pickups
	GetPickupType = {'u'},
	SetPickupType = {'u', 'i', 'i', 'i', 'i'},
	GetPickupWeapon = {'u'},
	GetPickupAmount = {'u'},
	GetPickupAmmo = {'u'},

	-- markers
	CreateMarker = {'f', 'f', 'f', 's', 'f', 'i', 'i', 'i', 'i'},
	DestroyMarker = {'k'},
	GetMarkerColor = {'k', 'i'},
	GetMarkerIcon = {'k'},
	GetMarkerSize = {'k', 'r'},
	GetMarkerTarget = {'k', 'r', 'r', 'r'},
	GetMarkerType = {'k'},
	SetMarkerColor = {'k', 'i', 'i', 'i', 'i'},
	SetMarkerIcon = {'k', 'i'},
	SetMarkerSize = {'k', 'f'},
	SetMarkerTarget = {'k', 'f', 'f', 'f'},
	SetMarkerType = {'k', 'i'},
	IsPlayerInMarker = {'k', 'p'},
	IsBotInMarker = {'k', 'z'},
	IsVehicleInMarker = {'k', 'v'},

	-- misc
	ShowCursor = {'p', 'b', 'b'},
	SetSkyGradient = {'i', 'i', 'i', 'i', 'i', 'i'},
	ResetSkyGradient = {},
	GetCloudsEnabled = {},
	SetCloudsEnabled = {'b'},
	IsGarageOpen = {'i'},
	SetGarageOpen = {'i', 'b'},
	IsGlitchEnabled = {'s'},
	SetGlitchEnabled = {'s', 'b'},
	GetFPSLimit = {},
	SetFPSLimit = {'i'},
	GetRandomPlayer = {},
	GetPlayerCount = {},
	GetObjectAlpha = {'o'},
	SetObjectAlpha = {'o', 'i'},
	GetWaveHeight = {},
	SetWaveHeight = {'f'},
	SetWaterLevel = {'f'},

	-- rules
	SetServerRule = {'s', 's'},
	GetServerRule = {'s', 'r', 'i'},
	RemoveServerRule = {'s'},

	-- dialogs
	ShowPlayerDialog = {'p', 'i', 'i', 's', 's', 's', 's', client = true},

	-- scoreboard
	AddScoreboardColumn = {'s'},
	RemoveScoreboardColumn = {'s'},
	SetScoreboardData = {'p', 's', 's'},

	HTTP = {'i', 'i', 's', 's', 's'},

	Create3DTextLabel = {'s', 'c', 'f', 'f', 'f', 'f', 'i', 'b'},
	CreatePlayer3DTextLabel = {'p', 's', 'c', 'f', 'f', 'f', 'f', 'i', 'i', 'b'},
	Delete3DTextLabel = {'a'},
	DeletePlayer3DTextLabel = {'p', 'a'},
	Attach3DTextLabelToPlayer = {'a', 'p', 'f', 'f', 'f'},
	Attach3DTextLabelToVehicle = {'a', 'v', 'f', 'f', 'f'},
	Update3DTextLabelText = {'a', 'c', 's'},
	UpdatePlayer3DTextLabelText = {'p', 'a', 'c', 's'},

	-- network stats
	NetStats_BytesReceived = {'p'},
	NetStats_BytesSent = {'p'},
	NetStats_ConnectionStatus = {'p'},
	NetStats_GetConnectedTime = {'p'},
	NetStats_GetIpPort = {'p', 'r', 'i'},
	NetStats_MessagesReceived = {'p'},
	NetStats_MessagesRecvPerSecond = {'p'},
	NetStats_MessagesSent = {'p'},
	NetStats_PacketLossPercent = {'p'},

	-- player data
	SetPlayerDataInt = {'p', 's', 'i'},
	GetPlayerDataInt = {'p', 's'},
	SetPlayerDataFloat = {'p', 's', 'f'},
	GetPlayerDataFloat = {'p', 's'},
	SetPlayerDataBool = {'p', 's', 'b'},
	GetPlayerDataBool = {'p', 's'},
	SetPlayerDataString = {'p', 's', 's'},
	GetPlayerDataString = {'p', 's', 'r', 'i'},
	ResetPlayerData = {'p', 's'},

	AddEventHandler = {'s', 's'},
	RemoveEventHandler = {'s'},

	gpci = {'p', 'r', 'i'},

	acos = {'f'},
	asin = {'f'},
	atan = {'f'},
	atan2 = {'f', 'f'},

	db_close = {'i'},
	db_free_result = {'i'},
	db_field_name = {'d', 'i', 'r', 'i'},
	db_get_field = {'d', 'i', 'r', 'i'},
	db_get_field_assoc = {'d', 's', 'r', 'i'},
	db_next_row = {'d'},
	db_num_fields = {'d'},
	db_num_rows = {'d'},
	db_open = {'s'},
	db_query = {'i', 's'},

	floatstr = {'s'},
	format = {'r', 'i', 's'},

	memcpy = {'r', 'r', 'i', 'i', 'i'},
	CreateExplosionForPlayer = {'p', 'f', 'f', 'f', 'i', 'f'},
	RemoveBuildingForPlayer = {'p', 'i', 'f', 'f', 'f', 'f'},
	ManualVehicleEngineAndLights = {},
	InterpolateCameraPos = {'p', 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i'},
	InterpolateCameraLookAt = {'p', 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i'},
	PlayAudioStreamForPlayer = {'p', 's', 'f', 'f', 'f', 'f', 'b'},
	StopAudioStreamForPlayer = {'p'},
	SetPlayerAttachedObject = {'p', 'i', 'i', 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i'},
	RemovePlayerAttachedObject = {'p', 'i'},
	AttachCameraToPlayerObject = {'p', 'i', client = true},
	AttachCameraToObject = {'p', 'o', client = true},

	-- new impl
	IsVehicleStreamedIn = {'v', 'p'},
	IsPlayerStreamedIn = {'p', 'p'},

	GetVehiclePoolSize = {},
	GetPlayerPoolSize = {},

	GetPlayerDistanceFromPoint = {'p', 'f', 'f', 'f'},
	GetVehicleDistanceFromPoint = {'v', 'f', 'f', 'f'},
	IsPlayerInRangeOfPoint = {'p', 'f', 'f', 'f', 'f'},

	VectorSize = {'f', 'f', 'f'},

	-- actors
	CreateActor = {'i', 'f', 'f', 'f', 'f'},
	IsValidActor = {'i'},
	IsActorStreamedIn = {'i'},
	DestroyActor = {'y'},
	ApplyActorAnimation = {'y', 's', 's', 'f', 'b', 'b', 'b', 'b', 'i'},
	ClearActorAnimations = {'y'},
	GetActorFacingAngle = {'y', 'r'},
	GetActorHealth = {'y', 'r'},
	GetActorPoolSize = {},
	GetActorVirtualWorld = {'y'},
	GetPlayerTargetActor = {'p'},
	IsActorInvulnerable = {'y'},
	SetActorFacingAngle = {'y', 'f'},
	SetActorHealth = {'y', 'f'},
	SetActorInvulnerable = {'y', 'b'},
	GetActorPos = {'y', 'r', 'r', 'r'}, -- r since the vals should be passed by ref
	SetActorPos = {'y', 'f', 'f', 'f'},
	SetActorVirtualWorld = {'y', 'i'},

	-- security
	SHA256_PassHash = {'s', 's', 'r', 'i'},

	-- dummy (unimplemented)
	ConnectNPC = {'s', 's'},
	IsPlayerNPC = {'p'},
	EnableStuntBonusForAll = {'b'},
	EnableStuntBonusForPlayer = {'p', 'b'},
	SetNameTagDrawDistance = {'f'},
	SetObjectsDefaultCameraCol = {'b'},
	SetPlayerChatBubble = {'p', 's', 'i', 'f', 'i'},
	SetObjectMaterial = {'o', 'i', 'i', 's', 's', 'i'},
	SetObjectMaterialText = {'o', 's', 'i', 'i', 's', 'i', 'b', 'i', 'i', 'i'},
	SetObjectNoCameraCol = {'o'},
	SetPlayerObjectMaterial = {'p', 'i', 'i', 'i', 's', 's', 'i'},
	SetPlayerObjectMaterialText = {'p', 'i', 's', 'i', 'i', 's', 'i', 'b', 'i', 'i', 'i'},
	SetPlayerObjectNoCameraCol = {'p', 'i'},
	EditPlayerObject = {'p', 'i'},
	TextDrawSetPreviewModel = {'x', 'i'},
	TextDrawSetPreviewVehCol = {'x', 'i', 'i'},
	TextDrawSetPreviewRot = {'x', 'f', 'f', 'f', 'f'},
	TextDrawSetSelectable = {'x', 'b'},
	GetVehicleParamsCarWindows = {'v', 'r', 'r', 'r', 'r'},
	SetVehicleParamsCarWindows = {'v', 'b', 'b', 'b', 'b'},
	PlayerPlaySound = {'p', 'i', 'f', 'f', 'f'},
	PlayCrimeReportForPlayer = {'p', 'i', 'i'},
	GetPlayerCameraMode = {'p'},
	EnableVehicleFriendlyFire = {},
	DisableRemoteVehicleCollisions = {'p', 'b'},
	DisableInteriorEnterExits = {},
	SelectObject = {'p'},
	CancelEdit = {'p'},
	EditAttachedObject = {'p', 'i'},
	EditObject = {'p', 'i'},
	IsPlayerAttachedObjectSlotUsed = {'p', 'i'},
	SendClientCheck = {'p', 'i', 'i', 'i', 'i'},
	GetPlayerNetworkStats = {'p', 'r', 'i'},
	GetNetworkStats = {'r', 'i'},
	StartRecordingPlayerData = {'p', 'i', 's'},
	StopRecordingPlayerData = {'p'},
	GetAnimationName = {'i', 'r', 'i', 'r', 'i'},
	GetPlayerAnimationIndex = {'p'},
	GetPlayerDrunkLevel = {'p'},
	SetPlayerDrunkLevel = {'p', 'i'},
	SelectTextDraw = {'p', 'c'},
	CancelSelectTextDraw = {'p'},
	EnablePlayerCameraTarget = {'p', 'b'},
	GetPlayerCameraTargetPlayer = {'p'},
	GetPlayerCameraTargetVehicle = {'p'},
	GetPlayerCameraTargetObject = {'p'},
	GetPlayerCameraTargetActor = {'p'},
	BlockIpAddress = {'s', 'i'},
	UnBlockIpAddress = {'s'},
	UsePlayerPedAnims = {},

	SendChat = {'s'},
	SendCommand = {'s'},
	StartRecordingPlayback = {'i', 's'},
	StopRecordingPlayback = {},
	PauseRecordingPlayback = {},
	ResumeRecordingPlayback = {},
	GetDistanceFromMeToPoint = {'f', 'f', 'f', 'r'},
	GetMyPos = {'r', 'r', 'r'},
	SetMyPos = {'f', 'f', 'f'},
	GetMyFacingAngle = {'r'},
	SetMyFacingAngle = {'f'}
}
