g_LoadedAMXs = {}
g_Events = {}

g_Players = {}
g_Bots = {}
g_Vehicles = {}
g_Objects = {}
g_Pickups = {}
g_Markers = {}
g_Actors = {}
g_PlayerTextDraws = {}
g_GangZones = {}
g_DBResults = {}
g_Menus = {}
g_TextDraws = {}
g_TextLabels = {}
g_PlayerObjects = {}

MAX_FILTERSCRIPTS = 16
MAX_GAMEMODES = 16

function initGameModeGlobals()
	g_PlayerClasses = {}
	g_Teams = setmetatable({}, { __index = function(t, k) t[k] = createTeam('Team ' .. (k + 1)) return t[k] end })
	g_ShowPlayerMarkers = true
	g_ShowZoneNames = true
	g_GlobalChatRadius = false
end

function loadAMX(fileName, isGamemode)
	isGamemode = isGamemode or true
	amx.type = isGamemode == false and 'filterscript' or 'gamemode'

    outputDebugString('  Loading \'' .. fileName .. '.amx\' ' .. amx.type)
	local hAMX = fileOpen(':' .. getResourceName(getThisResource()) .. '/' .. amx.type .. 's/' .. fileName .. '.amx', true)
	if hAMX then
		outputDebugString('  "' .. fileName .. '.amx" ' .. amx.type .. ' is being loaded')
	else
		outputDebugString('  Failed to open ' .. amx.type .. ' "' .. fileName .. '.amx"', 1)
		return false
	end

	-- read header
	amx.flags = readWORDAt(hAMX, 8)
	amx.COD = readDWORDAt(hAMX, 0xC)
	amx.DAT = readDWORD(hAMX)
	amx.HEA = readDWORD(hAMX)
	amx.STP = readDWORD(hAMX)
	amx.main = readDWORD(hAMX)
	amx.publics = readDWORD(hAMX)
	amx.natives = readDWORD(hAMX)
	amx.libraries = readDWORD(hAMX)

	-- read tables with names of public and syscall functions
	amx.publics = readPrefixTable(hAMX, amx.publics, amx.natives - amx.publics, true)
	amx.natives = readPrefixTable(hAMX, amx.natives, amx.libraries - amx.natives, false)
	amx.libraries = nil

	fileClose(hAMX)

	local alreadyGameModeRunning = getRunningGameMode() and true
	local alreadySyncingWeapons = isWeaponSyncingNeeded()
	if alreadyGameModeRunning and amx.type == 'gamemode' then
		outputDebugString('  Unable to load ' .. fileName .. '.amx since there is already a running gamemode', 1)
		return false
	end

	amx.cptr = amxLoad(getResourceName(getThisResource()), amx.name .. '.amx')
	if amx.cptr then
		outputDebugString('"' .. fileName .. '.amx" ' .. amx.type .. ' is loaded')
	else
		outputDebugString('  Unable to load "' .. fileName .. '.amx" ' .. amx.type, 1)
		return false
	end

	-- set up reading/writing of code and data section
	amx.memCOD = setmetatable({ amx = amx.cptr }, { __index = amxMTReadCODCell })
	amx.memDAT = setmetatable({ amx = amx.cptr }, { __index = amxMTReadDATCell, __newindex = amxMTWriteDATCell })

	g_LoadedAMXs[amx.name] = amx

	amx.timers = {}


	-- run initialization
	if amx.type == 'gamemode' then
		clientCall(root, 'gamemodeLoad')
		setWeather(10)
		initGameModeGlobals()
		ShowPlayerMarkers(amx, true)
		procCallOnAll('OnGameModeInit')
		table.each(g_Players, 'elem', gameModeInit)
	else
		procCallInternal(amx, 'OnFilterScriptInit')
	end
	procCallInternal(amx, amx.main)

	for id, player in pairs(g_Players) do
		procCallInternal(amx, 'OnPlayerConnect', id)
	end

	if not alreadySyncingWeapons and isWeaponSyncingNeeded(amx) then
		clientCall(root, 'enableWeaponSyncing', true)
	end
	triggerEvent('onAMXStart', getResourceRootElement(res), amx.res, amx.name)
	return amx
end

addEvent('onAMXStart')

function destroyGlobalElements()
	for i, vehinfo in pairs(g_Vehicles) do
		if vehinfo.respawntimer then
			killTimer(vehinfo.respawntimer)
			vehinfo.respawntimer = nil
		end
	end

	for i, elemtype in ipairs({ g_TextDraws, g_TextLabels }) do
		for id, data in pairs(elemtype) do
			elemtype[id] = nil
		end
	end

	for i, elemtype in ipairs({ g_Vehicles, g_Pickups, g_Objects, g_GangZones, g_Markers, g_Bots }) do
		for id, data in pairs(elemtype) do
			removeElem(elemtype, data.elem)
			destroyElement(data.elem)
		end
	end
end

function unloadAMX(amx, notifyClient)
	outputDebugString('Unloading ' .. amx.name .. '.amx')

	if amx.type == 'gamemode' then
		procCallInternal(amx, 'OnGameModeExit')
		fadeCamera(root, false, 0)
		ShowPlayerMarkers(amx, false)
		destroyGlobalElements()

		if notifyClient == nil or notifyClient == true then
			clientCall(root, 'gamemodeUnload')
		end

	elseif amx.type == 'filterscript' then
		procCallInternal(amx, 'OnFilterScriptExit')
	end

	amxUnload(amx.cptr)

	table.each(amx.timers, killTimer)

	if amx.boundkeys then
		for i, key in ipairs(amx.boundkeys) do
			table.each(g_Players, 'elem', unbindKey, g_ControlMapping[key], 'down', procCallInternal)
		end
	end

	g_LoadedAMXs[amx.name] = nil
	if not isWeaponSyncingNeeded() then
		clientCall(root, 'enableWeaponSyncing', false)
	end
	if getResourceState(amx.res) == 'running' then
		stopResource(amx.res)
	end
	triggerEvent('onAMXStop', getResourceRootElement(amx.res), amx.res, amx.name)
end

addEvent('onAMXStop')

gamemodeIndex = 0
addEventHandler('onResourceStart', resourceRoot,
	function()
		if not amxVersion then
			outputDebugString('The AMX module isn\'t loaded. It is required for Pawn Language to function. Please add it to your server config and restart your server.', 1)
			return
		end

		table.each(getElementsByType('player'), joinHandler)

		local plugins = get(getResourceName(getThisResource()) .. '.plugins')
		if plugins then
			local pluginCount
			for pluginName in plugins:split() do
                if amxLoadPlugin(pluginName) then
                    pluginCount = pluginCount + 1
                else
                    outputDebugString('  Failed loading plugin ' .. pluginName .. '!', 1)
                end
			end
			outputDebugString("  Loaded " .. pluginCount .. " plugins.")
		end

		local gamemodes = get(getResourceName(getThisResource()) .. '.gamemodes')
		if gamemodes then
			gamemodes = gamemodes:split()
			gamemodesCount = 0
			for i, gamemode in ipairs(gamemodes) do
                if gamemodesCount < MAX_GAMEMODES then
					if loadAMX(gamemode, true) then
						gamemodesCount = gamemodesCount + 1
					end
				else
                    outputDebugString('  Gamemodes Limit is already reached. Failed to load ' .. gamemode .. '.amx"', 2)
                    break
				end
            end
        else
            outputDebugString('I couldn\'t load any gamemode scripts. Please verify your meta.xml', 1)
		end

		local filterscripts = get(getResourceName(getThisResource()) .. '.filterscripts')
		if filterscripts then
			filterscripts = filterscripts:split()
			filterscriptsCount = 0
			for i, filterscript in ipairs(filterscripts) do
				if filterscriptsCount < MAX_FILTERSCRIPTS then
					if loadAMX(filterscript, false) then
						filterscriptsCount = filterscriptsCount + 1
					end
				else
					outputDebugString('  Filterscripts Limit is already reached. Failed to load ' .. filterscript .. '.amx"', 2)
                    break
				end
			end
            outputDebugString("  Loaded " .. filterscriptsCount .. " filterscripts.")
        end

        if get(getResourceName(getThisResource()) .. '.rcon_password') == 'changeme' then
            outputDebugString('Error: Your password must be changed from the default password, please change it.', 1)
            stopResource(getThisResource())
        end

		-- TODO(q): this needs to be added back later
		-- exports.amxscoreboard:addScoreboardColumn('Score')
	end,
	false
)

addEventHandler('onResourceStop', resourceRoot,
	function()
		-- TODO(q): this needs to be added back later
		-- exports.amxscoreboard:removeScoreboardColumn('Score')
		table.each(g_LoadedAMXs, unloadAMX, false)
		amxUnloadAllPlugins()
		for i = 0, 49 do
			setGarageOpen(i, false)
		end
		setWeather(0)
	end
)

function getRunningGameMode()
	for name, amx in pairs(g_LoadedAMXs) do
		if amx.type == 'gamemode' then
			return amx
		end
	end
	return false
end

function getRunningFilterScripts()
	local result = {}
	for name, amx in pairs(g_LoadedAMXs) do
		if amx.type == 'filterscript' then
			result[#result + 1] = amx
		end
	end
	return result
end

function isWeaponSyncingNeeded(amx)
	local fns = { 'GetPlayerWeaponData', 'RemovePlayerFromVehicle', 'SetVehicleToRespawn' }
	if amx then
		for i, fn in ipairs(fns) do
			if table.find(amx.natives, fn) then
				return true
			end
			return false
		end
	else
		for name, amx in pairs(g_LoadedAMXs) do
			if isWeaponSyncingNeeded(amx) then
				return true
			end
		end
		return false
	end
end

function readPrefixTable(hFile, offset, length, nameAsKey)
	-- build a name lookup table {name = offset} or {index = name}
	local entryOffset, entryNameOffset
	local result = {}
	for i = 0, length / 8 - 1 do
		entryOffset = readDWORDAt(hFile, offset)
		entryName = readString(hFile, readDWORD(hFile))
		if nameAsKey then
			result[entryName] = entryOffset
		else
			result[i] = entryName
		end
		offset = offset + 8
	end
	return result
end

function procCallInternal(amx, nameOrOffset, ...)
	if type(amx) ~= 'table' then
		amx = g_LoadedAMXs[amx]
	end
	if not amx then
		outputDebugString('procCallInternal called with amx=nil, proc name=' .. nameOrOffset, 2)
		return
	end

	local prevProc = amx.proc
	amx.proc = nameOrOffset
	local ret
	if type(nameOrOffset) == 'number' then
		if nameOrOffset == amx.main then
			ret = amxCall(amx.cptr, -1, ...)
		end
	else
		if (g_EventNames[nameOrOffset]) then
			for k, v in pairs(g_Events) do
				if v == nameOrOffset then
					amxCall(amx.cptr, k, ...)
				end
			end
		end
		ret = amxCall(amx.cptr, nameOrOffset, ...)
	end
	amx.proc = prevProc
	return ret or 0
end

function procCallOnAll(fnName, ...)
	for name, amx in pairs(g_LoadedAMXs) do
		if amx.type == 'filterscript' and procCallInternal(amx, fnName, ...) ~= 0 and fnName == 'OnPlayerCommandText' then
			return true
		end
	end
	local gamemode = getRunningGameMode()
	if gamemode and gamemode.publics[fnName] and procCallInternal(gamemode, fnName, ...) == 0 then
		return false
	end
	return true
end
