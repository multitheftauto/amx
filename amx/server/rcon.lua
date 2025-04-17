g_ServerVars = {
	announce = {
		get = function()
			return getServerConfigSetting('donotbroadcastlan') == 0 or true
		end
	},
	bind = {
		get = function(bindIp)
			bindIp = getServerConfigSetting('serverip') or ''
			return bindIp ~= 'auto' and bindIp or ''
		end
	},
	filterscripts = get('amx.filterscripts') or '',
	gamemode0 = '',
	gamemode1 = '',
	gamemode2 = '',
	gamemode3 = '',
	gamemode4 = '',
	gamemode5 = '',
	gamemode6 = '',
	gamemode7 = '',
	gamemode8 = '',
	gamemode9 = '',
	gamemode10 = '',
	gamemode11 = '',
	gamemode12 = '',
	gamemode13 = '',
	gamemode14 = '',
	gamemode15 = '',
	gamemodetext = {
		get = function()
			return getGameType() or 'Unknown'
		end,
		set = function(gmN)
			gmN = gmN:len() >= 1 and gmN or 'Unknown'
			return setGameType(gmN)
		end
	},
	gravity = {
		get = function()
			return tostring(getGravity())
		end,
		set = function(grav)
			grav = grav and tonumber(grav)
			if grav then
				setGravity(grav)
			end
		end
	},
	hostname = { get = getServerName },
	lagcomp = 'On',
	lagcompmode = 1,
	language = {
		get = function()
			return getRuleValue('language') or ''
		end,
		set = function(lang)
			lang = lang:len() >= 1 and lang or ''
			return setRuleValue('language', lang)
		end
	},
	lanmode = false,
	mapname = {
		get = function(mapN)
			mapN = getMapName()
			return (mapN and mapN ~= 'None') and mapN or 'San Andreas'
		end,
		set = function(mapN)
			mapN = mapN:len() >= 1 and mapN or 'San Andreas'
			return setMapName(mapN)
		end
	},
	maxplayers = { get = getMaxPlayers },
	password = {
		get = function()
			return getServerPassword() or ''
		end,
		set = function(pass)
			pass = pass:len() >= 1 and pass or ''
			return setServerPassword(pass)
		end
	},
	plugins = get('amx.plugins') or '',
	port = { get = getServerPort },
	query = true,
	rcon_password = {
		get = function()
			return get('amx.rcon_password') or ''
		end,
		set = function(pass)
			return set('amx.rcon_password', pass)
		end
	},
	timestamp = true,
	version = amxVersionString(),
	weather = {
		get = function()
			return tostring(getWeather())
		end,
		set = function(weather)
			weather = weather and tonumber(weather)
			if weather then
				setWeather(weather)
			end
		end
	},
	weburl = 'www.mtasa.com',
	worldtime = {
		get = function()
			local h = getTime()
			return string.format('%02d:00', h)
		end,
		set = function(str)
			local h = str:match('^(%d+):$')
			if h then
				setTime(tonumber(h), 0)
			end
		end
	}
}

local readOnlyVars = table.create({ 'announce', 'bind', 'filterscripts', 'hostname', 'lagcomp', 'lagcompmode', 'maxplayers', 'plugins', 'port', 'version' }, true)
g_ServerVars = { shadow = g_ServerVars }
setmetatable(
	g_ServerVars,
	{
		__index = function(t, k)
			local v = g_ServerVars.shadow[k]
			if v == nil then
				return
			end
			if type(v) == 'function' then
				return v()
			elseif type(v) == 'table' then
				return v.get()
			else
				return v
			end
		end,
		__newindex = function(t, k, v)
			local oldV = g_ServerVars.shadow[k]
			if oldV == nil then
				return
			end
			if type(oldV) == 'table' then
				if oldV.set then
					oldV.set(v)
				end
			else
				g_ServerVars.shadow[k] = v
			end
		end
	}
)

local function presentServerVar(k)
	local v = g_ServerVars[k]
	local t = type(v)
	if t == 'boolean' then
		v = v and 1 or 0
	elseif t == 'string' then
		v = '"' .. v .. '"'
	end
	local result = ('  %15s = %s (%s)'):format(k, v, t)
	if readOnlyVars[k] then
		result = result .. ' (read-only)'
	end
	return result
end

local function cmdBan(id)
	if not id then
		return 'ban <playerid>'
	end
	id = tonumber(id)
	if not id or not g_Players[id] then
		return
	end
	local name = getPlayerName(g_Players[id].elem)
	if banPlayer(g_Players[id].elem) then
		return name .. ' <' .. id .. '> has been banned.'
	else
		return 'Failed to ban ' .. name .. ' <' .. id .. '>'
	end
end

local function cmdBanIP(ip)
	if not ip then
		return 'banip <ip>'
	end
	if addBan(ip) then
		return 'IP ' .. ip .. ' has been banned.'
	else
		return 'Failed to ban ' .. ip
	end
end

local function cmdCmdList()
	return table.concat(table.sort(table.keys(g_RCONCommands)), '\n')
end

local function cmdEcho(str)
	print(str or '')
end

local function cmdExec(fname)
	if not fname then
		return 'exec <filename>'
	end
	fname = fname .. '.cfg'
	return doRCONFromFile(fname) or ('Unable to exec file \'' .. fname .. '\'.')
end

local function cmdChangeMode(mode)
	if not mode then
		return 'changemode <modename>'
	end
	local newRes = getResourceFromName('amx-' .. mode)
	if not newRes then
		return 'Unable to load gamemode \'' .. mode .. '\'.'
	end
	local amx = getRunningGameMode(mode)
	if amx then
		unloadAMX(amx)
	end
	startResource(newRes)
end

local function cmdGMX()
	local mapcycler = getResourceFromName('mapcycler')
	if not mapcycler then
		return 'The mapcycler resource, which is required for amx mode cycling, is not installed'
	end
	if getResourceState(mapcycler) == 'running' then
		restartResource(mapcycler)
	else
		startResource(mapcycler)
	end
end

local function cmdGravity(grav)
	grav = grav and tonumber(grav)
	if not grav then
		return 'gravity <grav>'
	end
	setGravity(grav)
end

local function cmdKick(id)
	if not id then
		return 'kick <id>'
	end
	id = tonumber(id)
	if not id or not g_Players[id] then
		return 'Invalid player id'
	end
	local name = getPlayerName(g_Players[id].elem)
	if kickPlayer(g_Players[id].elem) then
		return name .. ' <' .. id .. '> has been kicked.'
	else
		return 'Failed to kick ' .. name .. ' <' .. id .. '>'
	end
end

local function cmdLoadFS(fsname)
	if not fsname then
		return 'loadfs <fsname>'
	end
	local res = getResourceFromName('amx-fs-' .. fsname)
	if not res then
		return 'Filterscript \'' .. fsname .. '\' load failed.'
	end
	startResource(res)
end

local function cmdLoadPlugin(pluginName)
	if not pluginName then
		return 'loadplugin <pluginname>'
	end
	if amxIsPluginLoaded(pluginName) then
		return 'Plugin \'' .. pluginName .. '\' is already loaded.'
	end
	if amxLoadPlugin(pluginName) then
		return 'Plugin \'' .. pluginName .. '\' loaded.'
	else
		return 'Unable to load plugin \'' .. pluginName .. '\'.'
	end
end

local function cmdPlayers()
	local counter = 0
	local result = '\nID\tName\tPing\tIP'
	for id, data in pairs(g_Players) do
		result = result .. ('\n%d\t%s\t%d\t%s'):format(id, getPlayerName(data.elem), getPlayerPing(data.elem), getPlayerIP(data.elem))
		counter = counter + 1
	end
	if counter < 1 then return '' end
	return result
end

local function cmdReloadFS(fsname)
	if not fsname then
		return 'reloadfs <fsname>'
	end
	local res = getResourceFromName('amx-fs-' .. fsname)
	if not res then
		return 'Filterscript \'' .. fsname .. '\' load failed.'
	end
	restartResource(res)
end

local function cmdUnbanIP(ip)
	if not ip then
		return 'unbanip <ip>'
	end
	for banID, ban in ipairs (getBans()) do
		if getBanIP(ban) == ip then
			if removeBan(ban) then
				return 'IP ' .. ip .. ' has been unbanned.'
			else
				return 'Failed to unban ' .. ip
			end
		end
	end
	return 'Failed to unban ' .. ip
end

local function cmdUnloadFS(fsname)
	if not fsname then
		return 'unloadfs <fsname>'
	end
	local res = getResourceFromName('amx-fs-' .. fsname)
	if not res then
		return 'Filterscript \'' .. fsname .. '\' unload failed.'
	end
	stopResource(res)
end

local function cmdVarList()
	local result = ''
	local keys = table.sort(table.keys(g_ServerVars.shadow))
	for i, k in ipairs(keys) do
		result = result .. presentServerVar(k) .. '\n'
	end
	return result
end

g_RCONCommands = {
	ban = cmdBan,
	banip = cmdBanIP,
	changemode = cmdChangeMode,
	cmdlist = cmdCmdList,
	echo = cmdEcho,
	exec = cmdExec,
	gravity = cmdGravity,
	gmx = cmdGMX,
	kick = cmdKick,
	loadfs = cmdLoadFS,
	loadplugin = cmdLoadPlugin,
	players = cmdPlayers,
	reloadfs = cmdReloadFS,
	unbanip = cmdUnbanIP,
	unloadfs = cmdUnloadFS,
	varlist = cmdVarList
}

function doRCON(str, overrideReadOnly)
	local cmd, args = str:match('^([^%s]+)%s*(.*)$')
	if not cmd then
		return
	end
	if #args == 0 then
		args = false
	end
	if g_RCONCommands[cmd] then
		return g_RCONCommands[cmd](args)
	elseif g_ServerVars[cmd] ~= nil then
		local oldV = g_ServerVars[cmd]
		local newV = args
		if not newV then
			return presentServerVar(cmd)
		elseif overrideReadOnly or not readOnlyVars[cmd] then
			local t = type(oldV)
			if t == 'boolean' then
				if newV == '0' then
					newV = false
				elseif newV == '1' then
					newV = true
				else
					return
				end
			elseif t == 'number' then
				newV = tonumber(newV)
				if not newV then
					return
				end
			end
			g_ServerVars[cmd] = newV
		end
	end
end

function doRCONFromFile(fname)
	local hFile = fileOpen(fname)
	if not hFile then
		return false
	end
	local result = ''
	local line
	while true do
		line = fileReadLine(hFile)
		if not line then
			break
		end
		line = doRCON(line, true)
		if line then
			result = result .. line .. '\n'
		end
	end
	fileClose(hFile)
	return result
end

addCommandHandler('rcon',
	function(player, command, ...)
		if not isPlayerInACLGroup(player, 'Admin') then
			return
		end
		local str = table.concat({ ... }, ' ')
		local result = doRCON(str)
		if result then
			local lines = result:split('\n')
			for i, line in ipairs(lines) do
				outputConsole(line)
			end
		end
	end
)

addEventHandler('onConsole', root,
	function(str)
		if getAccountName(getPlayerAccount(source)) ~= 'Console' then
			return
		end
		local result = doRCON(str)
		if result then
			print(result)
		end
	end
)
