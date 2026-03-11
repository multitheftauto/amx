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
			colorArgs[i] = { bitExtract(val, 24, 8), bitExtract(val, 16, 8), bitExtract(val, 8, 8) }		-- r, g, b
			val = bitExtract(val, 0, 8)			-- a
		elseif vartype == 'p' then		-- player
			val = g_Players[val] and g_Players[val].elem
		elseif vartype == 'z' then		-- bot/ped
			val = g_Bots[val] and g_Bots[val].elem
		elseif vartype == 't' then		-- team
			val = val >= 0 and g_Teams[val % 256]
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
		elseif vartype == 'y' then		-- actor
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
		result = 1
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

function toggleUninmplementedErrors(playerSource, commandName)
	if not isPlayerInACLGroup(playerSource, 'Console') then
		return
	end
	ShowUnimplementedErrors = not ShowUnimplementedErrors
	outputDebugString('[INFO]: ShowUnimplementedErrors is now ' .. (ShowUnimplementedErrors and 'Enabled' or 'Disabled'))
end
addCommandHandler('showunimplementederrors', toggleUninmplementedErrors)
-----------------------------------------------------
-- List of the functions and their argument types

g_SAMPSyscallPrototypes = {
	Broadcast = {'s'},

	AddMenuItem = {'m', 'i', 's'},
	AddPlayerClass = {'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i'},
	AddPlayerClassEx = {'t', 'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i'},
	AddStaticPickup = {'i', 'i', 'f', 'f', 'f', 'i'},
	AddStaticVehicle = {'i', 'f', 'f', 'f', 'f', 'i', 'i'},
	AddStaticVehicleEx = {'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'b'},
	AddVehicleComponent = {'v', 'i'},
	AllowAdminTeleport = {'b'},
	AllowInteriorWeapons = {'b'},
	AllowPlayerTeleport = {'p', 'b'},
	ApplyAnimation = {'p', 's', 's', 'f', 'b', 'b', 'b', 'b', 'i', 'i'},
	AttachCameraToObject = {'p', 'o', client = true},
	AttachCameraToPlayerObject = {'p', 'i', client = true},
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
	ClearAnimations = {'p', 'i'},
	CreateExplosion = {'f', 'f', 'f', 'i', 'f'},
	CreateExplosionForPlayer = {'p', 'f', 'f', 'f', 'i', 'f'},
	CreateMenu = {'s', 'i', 'f', 'f', 'f', 'f'},
	CreateObject = {'i', 'f', 'f', 'f', 'f', 'f', 'f', 'f'},
	CreatePickup = {'i', 'i', 'f', 'f', 'f', 'i'},
	CreatePlayerObject = {'p', 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'f'},
	CreateVehicle = {'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'b'},

	DeletePVar = {'p', 's'},
	DeleteSVar = {'s'},

	DestroyMenu = {'m'},
	DestroyObject = {'o'},
	DestroyPickup = {'u'},
	DestroyPlayerObject = {'p', 'i'},
	DestroyVehicle = {'v'},
	DetachTrailerFromVehicle = {'v'},
	DisableInteriorEnterExits = {},
	DisableMenu = {'i'},
	DisableMenuRow = {'i', 'i'},
	DisableNameTagLOS = {},
	DisablePlayerCheckpoint = {'p'},
	DisablePlayerRaceCheckpoint = {'p'},

	EnableTirePopping = {'b'},
	EnableVehicleFriendlyFire = {},
	EnableZoneNames = {'b'},

	ForceClassSelection = {'p'},

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
	GetAnimationName = {'i', 'r', 'i', 'r', 'i'},
	GetConsoleVarAsBool = {'s'},
	GetConsoleVarAsInt = {'s'},
	GetConsoleVarAsString = {'s', 'r', 'i'},
	GetGravity = {},
	GetMaxPlayers = {},
	GetNetworkStats = {'r', 'i'},
	GetObjectModel = {'o'},
	GetObjectPos = {'o', 'r', 'r', 'r'},
	GetObjectRot = {'o', 'r', 'r', 'r'},
	GetPlayerAmmo = {'p'},
	GetPlayerArmedWeapon = {'p'},
	GetPlayerArmour = {'p', 'r'},
	GetPlayerCameraPos = {'p', 'r', 'r', 'r'},
	GetPlayerCameraFrontVector = {'p', 'r', 'r', 'r'},
	GetPlayerColor = {'p'},
	GetPlayerDistanceFromPoint = {'p', 'f', 'f', 'f'},
	GetPlayerDrunkLevel = {'p'},
	GetPlayerFacingAngle = {'p', 'r'},
	GetPlayerFightingStyle = {'p'},
	GetPlayerHealth = {'p', 'r'},
	GetPlayerInterior = {'p'},
	GetPlayerIp = {'p', 'r', 'i'},
	GetPlayerKeys = {'p', 'r', 'r', 'r'},
	GetPlayerLastShotVectors = {'p', 'r', 'r', 'r', 'r', 'r', 'r'},
	GetPlayerMenu = {'p'},
	GetPlayerMoney = {'p'},
	GetPlayerName = {'p', 'r', 'i'},
	GetPlayerNetworkStats = {'p', 'r', 'i'},
	GetPlayerObjectModel = {'p', 'i'},
	GetPlayerObjectPos = {'p', 'i', 'r', 'r', 'r'},
	GetPlayerObjectRot = {'p', 'i', 'r', 'r', 'r'},
	GetPlayerPing = {'p'},
	GetPlayerPoolSize = {},
	GetPlayerPos = {'p', 'r', 'r', 'r'},
	GetPlayerScore = {'p'},
	GetPlayerSkin = {'p'},
	GetPlayerSpecialAction = {'p'},
	GetPlayerState = {'p'},
	GetPlayerSurfingVehicleID = {'p'},
	GetPlayerSurfingObjectID = {'p'},
	GetPlayerTargetPlayer = {'p'},
	GetPlayerTeam = {'p'},
	GetPlayerTime = {'p', 'r', 'r'},
	GetPlayerVehicleID = {'p'},
	GetPlayerVehicleSeat = {'p'},
	GetPlayerVelocity = {'p', 'r', 'r', 'r'},
	GetPlayerVersion = {'p', 'r', 'i'},
	GetPlayerVirtualWorld = {'p'},
	GetPlayerWantedLevel = {'p'},
	GetPlayerWeapon = {'p'},
	GetPlayerWeaponData = {'p', 'i', 'r', 'r'},
	GetPlayerWeaponState = {'p'},
	GetServerVarAsBool = {'s'},
	GetServerVarAsInt = {'s'},
	GetServerVarAsString = {'s', 'r', 'i'},
	GetTickCount = {},
	GetVehicleComponentInSlot = {'v', 'i'},
	GetVehicleComponentType = {'i'},
	GetVehicleDamageStatus = {'v', 'r', 'r', 'r', 'r'},
	GetVehicleDistanceFromPoint = {'v', 'f', 'f', 'f'},
	GetVehicleHealth = {'v', 'r'},
	GetVehicleModel = {'v'},
	GetVehicleModelInfo = {'i', 'i', 'r', 'r', 'r'},
	GetVehicleParamsCarDoors = {'v', 'r', 'r', 'r', 'r'},
	GetVehicleParamsCarWindows = {'v', 'r', 'r', 'r', 'r'},
	GetVehicleParamsEx = {'v', 'r', 'r', 'r', 'r', 'r', 'r', 'r'},
	GetVehicleParamsSirenState = {'v'},
	GetVehiclePoolSize = {},
	GetVehiclePos = {'v', 'r', 'r', 'r'},
	GetVehicleRotationQuat = {'v', 'r', 'r', 'r', 'r'},
	GetVehicleTrailer = {'v'},
	GetVehicleVelocity = {'v', 'r', 'r', 'r' },
	GetVehicleVirtualWorld = {'v'},
	GetVehicleZAngle = {'v', 'r'},
	GetWeaponName = {'i', 'r', 'i'},
	GivePlayerMoney = {'p', 'i'},
	GivePlayerWeapon = {'p', 'i', 'i'},

	GetPVarFloat = {'p', 's'},
	GetPVarInt = {'p', 's'},
	GetPVarNameAtIndex = {'p', 'i', 'r', 'i'},
	GetPVarString = {'p', 's', 'r', 'i'},
	GetPVarType = {'p', 's'},
	GetPVarsUpperIndex = {'p'},
	GetSVarFloat = {'s'},
	GetSVarInt = {'s'},
	GetSVarNameAtIndex = {'i', 'r', 'i'},
	GetSVarString = {'s', 'r', 'i'},
	GetSVarType = {'s'},
	GetSVarsUpperIndex = {},

	HTTP = {'i', 'i', 's', 's', 's'},
	HideMenuForPlayer = {'m', 'p'},

	InterpolateCameraLookAt = {'p', 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i', client = true},
	InterpolateCameraPos = {'p', 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i', client = true},

	IsObjectMoving = {'o'},
	IsPlayerAdmin = {'p'},
	IsPlayerAttachedObjectSlotUsed = {'p', 'i'},
	IsPlayerConnected = {'i'},
	IsPlayerInAnyVehicle = {'p'},
	IsPlayerInCheckpoint = {'p'},
	IsPlayerInRaceCheckpoint = {'p'},
	IsPlayerInRangeOfPoint = {'p', 'f', 'f', 'f', 'f'},
	IsPlayerInVehicle = {'p', 'v'},
	IsPlayerObjectMoving = {'p', 'i'},
	IsPlayerStreamedIn = {'p', 'p'},
	IsTrailerAttachedToVehicle = {'v'},
	IsValidMenu = {'i'},
	IsValidObject = {'i'},
	IsValidPlayerObject = {'p', 'i'},
	IsValidVehicle = {'i'},
	IsVehicleStreamedIn = {'v', 'p'},

	Kick = {'p'},
	KillTimer = {'i'},

	LimitGlobalChatRadius = {'f'},
	LimitPlayerMarkerRadius = {'f'},
	LinkVehicleToInterior = {'v', 'i'},

	ManualVehicleEngineAndLights = {},
	MoveObject = {'o', 'f', 'f', 'f', 'f', 'f', 'f', 'f'},
	MovePlayerObject = {'p', 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'f'},

	PlayAudioStreamForPlayer = {'p', 's', 'f', 'f', 'f', 'f', 'b', client = true},
	PlayerPlaySound = {'p', 'i', 'f', 'f', 'f', client = true},
	PlayerSpectatePlayer = {'p', 'p', 'i'},
	PlayerSpectateVehicle = {'p', 'v', 'i'},
	PutPlayerInVehicle = {'p', 'v', 'i'},

	RemoveBuildingForPlayer = {'p', 'i', 'f', 'f', 'f', 'f', client = true},
	RemovePlayerAttachedObject = {'p', 'i'},
	RemovePlayerFromVehicle = {'p'},
	RemovePlayerMapIcon = {'p', 'i', client = true},
	RemoveVehicleComponent = {'v', 'i'},
	RepairVehicle = {'v'},
	ResetPlayerMoney = {'p'},
	ResetPlayerWeapons = {'p'},

	SendClientMessage = {'p', 'c', 's'},
	SendClientMessageToAll = {'c', 's'},
	SendDeathMessage = {'i', 'p', 'i'},
	SendDeathMessageToPlayer = {'p', 'i', 'p', 'i'},
	SendPlayerMessageToAll = {'p', 's'},
	SendPlayerMessageToPlayer = {'p', 'p', 's'},
	SendRconCommand = {'s'},
	SetCameraBehindPlayer = {'p'},
	SetDeathDropAmount = {'i'},
	SetDisabledWeapons = {},
	SetGameModeText = {'s'},
	SetGravity = {'f'},
	SetMenuColumnHeader = {'m', 'i', 's'},
	SetNameTagDrawDistance = {'f'},
	SetObjectPos = {'o', 'f', 'f', 'f'},
	SetObjectRot = {'o', 'f', 'f', 'f'},
	SetPlayerAmmo = {'p', 'i', 'i'},
	SetPlayerArmedWeapon = {'p', 'i'},
	SetPlayerArmour = {'p', 'f'},
	SetPlayerAttachedObject = {'p', 'i', 'i', 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i'},
	SetPlayerCameraLookAt = {'p', 'f', 'f', 'f', 'i'},
	SetPlayerCameraPos = {'p', 'f', 'f', 'f'},
	SetPlayerCheckpoint = {'p', 'f', 'f', 'f', 'f'},
	SetPlayerColor = {'p', 'c'},
	SetPlayerDisabledWeapons = {'p'},
	SetPlayerDrunkLevel = {'p', 'i'},
	SetPlayerFacingAngle = {'p', 'f'},
	SetPlayerFightingStyle = {'p', 'i'},
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
	SetPlayerSkillLevel = {'p', 'i', 'i'},
	SetPlayerSkin = {'p', 'i'},
	SetPlayerSpecialAction = {'p', 'i'},
	SetPlayerTeam = {'p', 't'},
	SetPlayerTime = {'p', 'i', 'i'},
	SetPlayerVelocity = {'p', 'f', 'f', 'f'},
	SetPlayerVirtualWorld = {'p', 'i'},
	SetPlayerWantedLevel = {'p', 'i'},
	SetPlayerWeather = {'p', 'i'},
	SetPlayerWorldBounds = {'p', 'f', 'f', 'f', 'f', client = true},
	SetSpawnInfo = {'p', 't', 'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i'},
	SetTeamCount = {'i'},
	SetTimer = {'s', 'i', 'b'},
	SetTimerEx = {'s', 'i', 'b', 's'},
	SetVehicleAngularVelocity = {'v', 'f', 'f', 'f'},
	SetVehicleHealth = {'v', 'f'},
	SetVehicleNumberPlate = {'v', 's'},
	SetVehicleParamsCarDoors = {'v', 'b', 'b', 'b', 'b'},
	SetVehicleParamsCarWindows = {'v', 'b', 'b', 'b', 'b'},
	SetVehicleParamsEx = {'v', 'b', 'b', 'b', 'b', 'b', 'b', 'b'},
	SetVehicleParamsForPlayer = {'v', 'p', 'b', 'b', client = true},
	SetVehiclePos = {'v', 'f', 'f', 'f'},
	SetVehicleToRespawn = {'v'},
	SetVehicleVelocity = {'v', 'f', 'f', 'f'},
	SetVehicleVirtualWorld = {'v', 'i'},
	SetVehicleZAngle = {'v', 'f'},
	SetWeather = {'i'},
	SetWorldTime = {'i'},
	SHA256_PassHash = {'s', 's', 'r', 'i'},
	ShowMenuForPlayer = {'m', 'p'},
	ShowNameTags = {'b'},
	ShowPlayerDialog = {'p', 'i', 'i', 's', 's', 's', 's', client = true},
	ShowPlayerMarkers = {'i'},
	ShowPlayerNameTagForPlayer = {'p', 'p', 'b'},
	SpawnPlayer = {'p'},
	StopAudioStreamForPlayer = {'p', client = true},
	StopObject = {'o'},
	StopPlayerObject = {'p', 'i'},

	SetPVarInt = {'p', 's', 'i'},
	SetPVarFloat = {'p', 's', 'f'},
	SetPVarString = {'p', 's', 's'},
	SetSVarInt = {'s', 'i'},
	SetSVarFloat = {'s', 'f'},
	SetSVarString = {'s', 's'},

	TogglePlayerClock = {'p', 'b', client = true},
	TogglePlayerControllable = {'p', 'b'},
	TogglePlayerSpectating = {'p', 'b'},

	UpdateVehicleDamageStatus = {'v', 'i', 'i', 'i', 'i'},
	UsePlayerPedAnims = {},

	VectorSize = {'f', 'f', 'f'},

	acos = {'f'},
	asin = {'f'},
	atan = {'f'},
	atan2 = {'f', 'f'},

	db_close = {'i'},
	db_debug_openfiles = {},
	db_debug_openresults = {},
	db_free_result = {'d'},
	db_field_name = {'d', 'i', 'r', 'i'},
	db_get_field = {'d', 'i', 'r', 'i'},
	db_get_field_float = {'d', 'i'},
	db_get_field_int = {'d', 'i'},
	db_get_field_assoc = {'d', 's', 'r', 'i'},
	db_get_field_assoc_float = {'d', 's'},
	db_get_field_assoc_int = {'d', 's'},
	db_get_mem_handle = {'i'},
	db_get_result_mem_handle = {'d'},
	db_next_row = {'d'},
	db_num_fields = {'d'},
	db_num_rows = {'d'},
	db_open = {'s'},
	db_query = {'i', 's'},

	floatstr = {'s'},
	format = {'r', 'i', 's'},

	gpci = {'p', 'r', 'i'},

	-- bots
	CreateBot = {'i', 'f', 'f', 'f', 's'},
	IsValidBot = {'i'},
	IsBotStreamedIn = {'z', 'p'},
	DestroyBot = {'z'},
	AddBotClothes = {'z', 'i', 'i'},
	GetBotClothes = {'z', 'i'},
	RemoveBotClothes = {'z', 'i'},
	IsBotInWater = {'z'},
	IsBotOnFire = {'z'},
	SetBotOnFire = {'z', 'b'},
	IsBotDucked = {'z'},
	IsBotOnGround = {'z'},
	IsBotChoking = {'z'},
	SetBotChoking = {'z', 'b'},
	GetBotHealth = {'z', 'r'},
	SetBotHealth = {'z', 'f'},
	GetBotArmour = {'z', 'r'},
	SetBotArmour = {'z', 'f'},
	GetBotPos = {'z', 'r', 'r', 'r'},
	SetBotPos = {'z', 'f', 'f', 'f'},
	GetBotFacingAngle = {'z', 'r'},
	SetBotFacingAngle = {'z', 'f'},
	GetBotRot = {'z', 'r', 'r', 'r'},
	SetBotRot = {'z', 'f', 'f', 'f'},
	GetBotVelocity = {'z', 'r', 'r', 'r'},
	SetBotVelocity = {'z', 'f', 'f', 'f'},
	GetBotInterior = {'z'},
	SetBotInterior = {'z', 'i'},
	GetBotVirtualWorld = {'z'},
	SetBotVirtualWorld = {'z', 'i'},
	GetBotFightingStyle = {'z'},
	SetBotFightingStyle = {'z', 'i'},
	GetBotWalkingStyle = {'z'},
	SetBotWalkingStyle = {'z', 'i'},
	GetBotSkin = {'z'},
	SetBotSkin = {'z', 'i'},
	GetBotSkillLevel = {'z', 'i'},
	SetBotSkillLevel = {'z', 'i', 'i'},
	GetBotStat = {'z', 'i'},
	SetBotStat = {'z', 'i', 'f'},
	GetBotState = {'z'},
	PutBotInVehicle = {'z', 'v', 'i'},
	RemoveBotFromVehicle = {'z'},
	GetBotVehicleID = {'z'},
	GetBotVehicleSeat = {'z'},
	IsBotInVehicle = {'z', 'v'},
	IsBotInAnyVehicle = {'z'},
	SetBotControlState = {'z', 's', 'b'},
	SetBotLookAt = {'z', 'f', 'f', 'f', 'i', 'i'},
	SetBotAimTarget = {'z', 'f', 'f', 'f'},
	IsBotDoingDriveBy = {'z'},
	SetBotDoingDriveBy = {'z', 'b'},
	GetBotAmmo = {'z'},
	SetBotAmmo = {'z', 'i', 'i'},
	GetBotWeaponState = {'z'},
	GetBotWeapon = {'z'},
	GiveBotWeapon = {'z', 'i', 'i'},
	ResetBotWeapons = {'z'},
	SetBotArmedWeapon = {'z', 'i'},
	GetBotWeaponSlot = {'z'},
	SetBotWeaponSlot = {'z', 'i'},
	GetBotAmmoInClip = {'z'},
	ReloadBotWeapon = {'z'},
	RemoveBotWeapon = {'z', 'i'},
	IsBotHeadless = {'z'},
	SetBotHeadless = {'z', 'b'},
	IsBotDead = {'z'},
	KillBot = {'z', 'i', 'i', 'i'},
	ShowBotNameTag = {'z', 'b'},
	GetBotColor = {'z'},
	SetBotColor = {'z', 'c'},
	GetBotName = {'z', 'r', 'i'},
	SetBotName = {'z', 's'},
	GetBotAlpha = {'z'},
	SetBotAlpha = {'z', 'i'},

	-- players
	AddPlayerClothes = {'p', 'i', 'i'},
	GetPlayerClothes = {'p', 'i'},
	RemovePlayerClothes = {'p', 'i'},
	ShowPlayerMarker = {'p', 'i'},
	IsPlayerInWater = {'p'},
	IsPlayerOnFire = {'p'},
	SetPlayerOnFire = {'p', 'b'},
	IsPlayerDucked = {'p'},
	IsPlayerOnGround = {'p'},
	IsPlayerChoking = {'p'},
	SetPlayerChoking = {'p', 'b'},
	GetPlayerWalkingStyle = {'p'},
	SetPlayerWalkingStyle = {'p', 'i'},
	GetPlayerStat = {'p', 'i'},
	SetPlayerStat = {'p', 'i', 'f'},
	IsPlayerDoingDriveBy = {'p'},
	SetPlayerDoingDriveBy = {'p', 'b'},
	GetPlayerWeaponSlot = {'p'},
	SetPlayerWeaponSlot = {'p', 'i'},
	GetPlayerAmmoInClip = {'p'},
	ReloadPlayerWeapon = {'p'},
	GetPlayerIdleTime = {'p'},
	IsPlayerHeadless = {'p'},
	SetPlayerHeadless = {'p', 'b'},
	IsPlayerDead = {'p'},
	KillPlayer = {'p', 'i', 'i', 'i'},
	GetPlayerBlurLevel = {'p'},
	SetPlayerBlurLevel = {'p', 'i'},
	IsPlayerMapForced = {'p'},
	ForcePlayerMap = {'p', 'b'},
	FadePlayerCamera = {'p', 'b', 'f', 'i', 'i', 'i'},
	SetPlayerControlState = {'p', 's', 'b'},
	IsPlayerCursorShowing = {'p'},
	ShowPlayerCursor = {'p', 'b', 'b'},
	ShowPlayerChat = {'p', 'b', 'b'},
	GetPlayerAlpha = {'p'},
	SetPlayerAlpha = {'p', 'i'},
	RemovePlayerWeapon = {'p', 'i'},
	GetPlayerGravity = {'p'},
	SetPlayerGravity = {'p', 'f'},
	GetPlayerSkillLevel = {'p', 'i'},

	-- vehicles
	IsVehicleInWater = {'v'},
	IsVehicleOnGround = {'v'},
	SetVehicleModel = {'v', 'i'},
	GetVehicleMaxPassengers = {'v'},
	GetVehicleEngineState = {'v'},
	SetVehicleEngineState = {'v', 'b'},
	GetVehicleSirenState = {'v'},
	SetVehicleSirenState = {'v', 'b'},
	GetVehicleDoorState = {'v', 'i'},
	SetVehicleDoorState = {'v', 'i', 'i'},
	GetVehicleLightState = {'v', 'i'},
	SetVehicleLightState = {'v', 'i', 'i'},
	GetVehicleOverrideLights = {'v'},
	SetVehicleOverrideLights = {'v', 'i'},
	GetVehicleWheelState = {'v', 'i'},
	SetVehicleWheelState = {'v', 'i', 'i', 'i', 'i'},
	GetVehiclePanelState = {'v', 'i'},
	SetVehiclePanelState = {'v', 'i', 'i'},
	GetVehicleVariant = {'v', 'r', 'r'},
	SetVehicleVariant = {'v', 'i', 'i'},
	IsVehicleBlown = {'v'},
	BlowVehicle = {'v', 'b'},
	GetVehicleAlpha = {'v'},
	SetVehicleAlpha = {'v', 'i'},
	IsTrainDerailable = {'v'},
	SetTrainDerailable = {'v', 'b'},
	IsTrainDerailed = {'v'},
	SetTrainDerailed = {'v', 'b'},
	GetTrainDirection = {'v'},
	SetTrainDirection = {'v', 'b'},
	GetTrainSpeed = {'v', 'r'},
	SetTrainSpeed = {'v', 'f'},
	GetVehicleCab = {'v'},
	GetVehicleOccupant = {'v', 'i'},
	GetVehicleNumberPlate = {'v', 'r', 'i'},
	GetVehicleColor = {'v', 'r', 'r'},
	GetVehiclePaintjob = {'v'},
	GetVehicleInterior = {'v'},

	-- objects
	BreakObject = {'o'},
	RespawnObject = {'o'},
	SetObjectBreakable = {'o', 'b'},
	ToggleObjectRespawn = {'o', 'b'},
	IsObjectBreakable = {'o'},
	IsObjectRespawnable = {'o'},
	GetObjectScale = {'o', 'r', 'r', 'r'},
	SetObjectScale = {'o', 'f', 'f', 'f'},
	GetObjectAlpha = {'o'},
	SetObjectAlpha = {'o', 'i'},

	-- pickups
	GetPickupType = {'u'},
	SetPickupType = {'u', 'i', 'i', 'i', 'i'},
	GetPickupAmount = {'u'},
	GetPickupWeapon = {'u'},
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
	IsVehicleInMarker = {'k', 'v'},
	IsActorInMarker = {'k', 'y'},
	IsBotInMarker = {'k', 'z'},

	-- world
	GetFPSLimit = {},
	SetFPSLimit = {'i'},
	GetGameSpeed = {},
	SetGameSpeed = {'f'},
	GetRainLevel = {},
	SetRainLevel = {'f'},
	ResetRainLevel = {},
	GetSkyGradient = {'r', 'r', 'r', 'r', 'r', 'r'},
	SetSkyGradient = {'i', 'i', 'i', 'i', 'i', 'i'},
	ResetSkyGradient = {},
	GetFogDistance = {},
	SetFogDistance = {'f'},
	ResetFogDistance = {},
	SetWeatherBlended = {'i'},
	GetMinuteDuration = {},
	SetMinuteDuration = {'i'},
	GetCloudsEnabled = {},
	SetCloudsEnabled = {'b'},
	GetInteriorSoundsEnabled = {},
	SetInteriorSoundsEnabled = {'b'},
	GetOcclusionsEnabled = {},
	SetOcclusionsEnabled = {'b'},
	IsGarageOpen = {'i'},
	SetGarageOpen = {'i', 'b'},
	IsGlitchEnabled = {'s'},
	SetGlitchEnabled = {'s', 'b'},
	IsJetpackWeaponEnabled = {'i'},
	SetJetpackWeaponEnabled = {'i', 'b'},
	GetJetpackMaxHeight = {},
	SetJetpackMaxHeight = {'f'},
	GetAircraftMaxVelocity = {},
	SetAircraftMaxVelocity = {'f'},
	GetAircraftMaxHeight = {},
	SetAircraftMaxHeight = {'f'},
	GetPlayerIDFromName = {'s'},
	GetWeaponSlot = {'i'},
	GetRandomPlayer = {},
	GetPlayerCount = {},

	-- water
	GetWaveHeight = {},
	SetWaveHeight = {'f'},
	SetWaterLevel = {'f'},

	-- traffic lights
	GetTrafficLightsLocked = {},
	SetTrafficLightsLocked = {'b'},
	GetTrafficLightState = {},
	SetTrafficLightState = {'i'},

	-- rules
	IsValidServerRule = {'s'},
	GetServerRule = {'s', 'r', 'i'},
	SetServerRule = {'s', 's'},
	RemoveServerRule = {'s'},

	-- scoreboard
	AddScoreBoardColumn = {'s'},
	GetPlayerScoreBoardData = {'p', 's', 'r', 'i'},
	SetPlayerScoreBoardData = {'p', 's', 's'},
	RemoveScoreBoardColumn = {'s'},

	-- player data
	SetPlayerIntData = {'p', 's', 'i'},
	GetPlayerIntData = {'p', 's'},
	SetPlayerFloatData = {'p', 's', 'f'},
	GetPlayerFloatData = {'p', 's', 'r'},
	SetPlayerBoolData = {'p', 's', 'b'},
	GetPlayerBoolData = {'p', 's'},
	SetPlayerStringData = {'p', 's', 's'},
	GetPlayerStringData = {'p', 's', 'r', 'i'},
	RemovePlayerData = {'p', 's'},
	HasPlayerData = {'p', 's'},

	-- misc
	AddEventHandler = {'s', 's'},
	RemoveEventHandler = {'s'},
	IsPluginLoaded = {'s'},

	-- actors
	CreateActor = {'i', 'f', 'f', 'f', 'f'},
	IsValidActor = {'i'},
	IsActorStreamedIn = {'y', 'p'},
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

	-- labels
	Create3DTextLabel = {'s', 'c', 'f', 'f', 'f', 'f', 'i', 'b'},
	CreatePlayer3DTextLabel = {'p', 's', 'c', 'f', 'f', 'f', 'f', 'i', 'i', 'b'},
	Delete3DTextLabel = {'a'},
	DeletePlayer3DTextLabel = {'p', 'a'},
	Attach3DTextLabelToPlayer = {'a', 'p', 'f', 'f', 'f'},
	Attach3DTextLabelToVehicle = {'a', 'v', 'f', 'f', 'f'},
	Update3DTextLabelText = {'a', 'c', 's'},
	UpdatePlayer3DTextLabelText = {'p', 'a', 'c', 's'},

	-- textdraws
	TextDrawCreate = {'f', 'f', 's'},
	TextDrawDestroy = {'i'},
	TextDrawShowForAll = {'i'},
	TextDrawShowForPlayer = {'p', 'i'},
	TextDrawHideForAll = {'i'},
	TextDrawHideForPlayer = {'p', 'i'},
	TextDrawBoxColor = {'x', 'c'},
	TextDrawUseBox = {'x', 'b'},
	TextDrawTextSize = {'x', 'f', 'f'},
	TextDrawLetterSize = {'x', 'f', 'f'},
	TextDrawAlignment = {'x', 'i'},
	TextDrawBackgroundColor = {'x', 'c'},
	TextDrawFont = {'x', 'i'},
	TextDrawColor = {'x', 'c'},
	TextDrawSetOutline = {'x', 'i'},
	TextDrawSetShadow = {'x', 'i'},
	TextDrawSetString = {'x', 's'},

	-- player textdraws
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
	PlayerTextDrawSetShadow = {'p', 'i', 'i'},
	PlayerTextDrawSetString = {'p', 'i', 's'},

	-- network stats
	NetStats_BytesReceived = {'p'},
	NetStats_BytesSent = {'p'},
	NetStats_GetConnectedTime = {'p'},
	NetStats_GetIpPort = {'p', 'r', 'i'},
	NetStats_PacketLossPercent = {'p'},

	-- dummy (unimplemented)
	EnableStuntBonusForAll = {'b'},
	EnableStuntBonusForPlayer = {'p', 'b'},
	SetObjectsDefaultCameraCol = {'b'},
	SetPlayerChatBubble = {'p', 's', 'i', 'f', 'i'},
	SetObjectMaterial = {'o', 'i', 'i', 's', 's', 'i'},
	SetObjectMaterialText = {'o', 's', 'i', 'i', 's', 'i', 'b', 'i', 'i', 'i'},
	SetObjectNoCameraCol = {'o'},
	SetPlayerObjectMaterial = {'p', 'i', 'i', 'i', 's', 's', 'i'},
	SetPlayerObjectMaterialText = {'p', 'i', 's', 'i', 'i', 's', 'i', 'b', 'i', 'i', 'i'},
	SetPlayerObjectNoCameraCol = {'p', 'i'},
	TextDrawSetPreviewModel = {'x', 'i'},
	TextDrawSetPreviewVehCol = {'x', 'i', 'i'},
	TextDrawSetPreviewRot = {'x', 'f', 'f', 'f', 'f'},
	TextDrawSetSelectable = {'x', 'b'},
	TextDrawSetProportional = {'x', 'b'},
	PlayerTextDrawSetPreviewModel = {'p', 'i', 'i'},
	PlayerTextDrawSetPreviewVehCol = {'p', 'i', 'i', 'i'},
	PlayerTextDrawSetPreviewRot = {'p', 'i', 'f', 'f', 'f', 'f'},
	PlayerTextDrawSetSelectable = {'p', 'i', 'b'},
	PlayerTextDrawSetProportional = {'p', 'i', 'b'},
	DisableRemoteVehicleCollisions = {'p', 'b'},
	PlayCrimeReportForPlayer = {'p', 'i', 'i'},
	SetPlayerShopName = {'p', 's'},
	GetPlayerCameraMode = {'p'},
	GetPlayerCameraAspectRatio = {'p'},
	GetPlayerCameraZoom = {'p'},
	SelectObject = {'p'},
	CancelEdit = {'p'},
	EditAttachedObject = {'p', 'i'},
	EditObject = {'p', 'i'},
	EditPlayerObject = {'p', 'i'},
	SendClientCheck = {'p', 'i', 'i', 'i', 'i'},
	GetPlayerAnimationIndex = {'p'},
	SelectTextDraw = {'p', 'c'},
	CancelSelectTextDraw = {'p'},
	EnablePlayerCameraTarget = {'p', 'b'},
	GetPlayerCameraTargetPlayer = {'p'},
	GetPlayerCameraTargetVehicle = {'p'},
	GetPlayerCameraTargetObject = {'p'},
	GetPlayerCameraTargetActor = {'p'},
	BlockIpAddress = {'s', 'i'},
	UnBlockIpAddress = {'s'},
	NetStats_ConnectionStatus = {'p'},
	NetStats_MessagesReceived = {'p'},
	NetStats_MessagesRecvPerSecond = {'p'},
	NetStats_MessagesSent = {'p'},
	GetServerTickRate = {},

	-- NPCs dummy
	ConnectNPC = {'s', 's'},
	IsPlayerNPC = {'p'},
	StartRecordingPlayerData = {'p', 'i', 's'},
	StopRecordingPlayerData = {'p'},
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
