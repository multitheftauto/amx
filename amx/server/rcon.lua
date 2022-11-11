g_ServerVars = {
	announce = {
        get = function()
            return getServerConfigSetting('donotbroadcastlan') and (getServerConfigSetting('donotbroadcastlan') == 0) or true
    },
	anticheat = true,
	bind = {
        get = function()
            return getServerConfigSetting("serverip") or '127.0.0.1'
        end
    },
	filterscripts = get(getResourceName(getThisResource()) .. '.filterscripts') or '',
	gamemode0 = {
        get = function()
            gamemodes = get(getResourceName(getThisResource()) .. '.gamemodes')
            return gamemodes and gamemodes:split()[1] or ''
        end
    },
	gamemode1 = {
        get = function()
            gamemodes = get(getResourceName(getThisResource()) .. '.gamemodes')
            return gamemodes and gamemodes:split()[2] or ''
        end
    },
	gamemode2 = {
        get = function()
            gamemodes = get(getResourceName(getThisResource()) .. '.gamemodes')
            return gamemodes and gamemodes:split()[3] or ''
        end
    },
	gamemode3 = {
        get = function()
            gamemodes = get(getResourceName(getThisResource()) .. '.gamemodes')
            return gamemodes and gamemodes:split()[4] or ''
        end
    },
	gamemode4 = {
        get = function()
            gamemodes = get(getResourceName(getThisResource()) .. '.gamemodes')
            return gamemodes and gamemodes:split()[5] or ''
        end
    },
	gamemode5 = {
        get = function()
            gamemodes = get(getResourceName(getThisResource()) .. '.gamemodes')
            return gamemodes and gamemodes:split()[6] or ''
        end
    },
	gamemode6 = {
        get = function()
            gamemodes = get(getResourceName(getThisResource()) .. '.gamemodes')
            return gamemodes and gamemodes:split()[7] or ''
        end
    },
	gamemode7 = {
        get = function()
            gamemodes = get(getResourceName(getThisResource()) .. '.gamemodes')
            return gamemodes and gamemodes:split()[8] or ''
        end
    },
	gamemode8 = {
        get = function()
            gamemodes = get(getResourceName(getThisResource()) .. '.gamemodes')
            return gamemodes and gamemodes:split()[9] or ''
        end
    },
	gamemode9 = {
        get = function()
            gamemodes = get(getResourceName(getThisResource()) .. '.gamemodes')
            return gamemodes and gamemodes:split()[10] or ''
        end
    },
	gamemode10 = {
        get = function()
            gamemodes = get(getResourceName(getThisResource()) .. '.gamemodes')
            return gamemodes and gamemodes:split()[11] or ''
        end
    },
	gamemode11 = {
        get = function()
            gamemodes = get(getResourceName(getThisResource()) .. '.gamemodes')
            return gamemodes and gamemodes:split()[12] or ''
        end
    },
	gamemode12 = {
        get = function()
            gamemodes = get(getResourceName(getThisResource()) .. '.gamemodes')
            return gamemodes and gamemodes:split()[13] or ''
        end
    },
	gamemode13 = {
        get = function()
            gamemodes = get(getResourceName(getThisResource()) .. '.gamemodes')
            return gamemodes and gamemodes:split()[14] or ''
        end
    },
	gamemode14 = {
        get = function()
            gamemodes = get(getResourceName(getThisResource()) .. '.gamemodes')
            return gamemodes and gamemodes:split()[15] or ''
        end
    },
	gamemode15 = {
        get = function()
            gamemodes = get(getResourceName(getThisResource()) .. '.gamemodes')
            return gamemodes and gamemodes:split()[16] or ''
        end
    },
	gamemodetext = {
        get = function()
            return getGameType() or 'Unknown'
        end,
        set = function(gmN)
            gmN = gmN:len() >= 1 and gmN or nil
            if gmN == nil then
                return 0
            end
            if gmN:len() > 30 then
                return setGameType(gmN:sub(1, 30))
            end
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
    hostname = {
        get = function ()
            hostN = getServerName() or 'Multi theft Auto Server'
            return hostN:len() > 50 and hostN:sub(1, 50) or hostN
        end
    },
    language = {
        get = function()
            return getRuleValue('language') or ''
        end,
        set = function(lang)
            lang = not lang == nil and (lang:len() >= 2 and lang or '') or lang
            if lang == nil then
                return removeRuleValue('language')
            else if lang == '' then
                return 0
            end
            return setRuleValue('language', lang)
        end
    },
	mapname = {
        get = function()
            return getMapName() or 'San Andreas'
        end,
        set = function(mapN)
            mapN = mapN:len() >= 1 and mapN or nil
            if mapN == nil then
                return 0
            end
            if mapN:len() > 30 then
                return setMapName(mapN:sub(1, 30))
            end
            return setMapName(mapN)
        end
    },
	maxplayers = {
        get = function()
            return getMaxPlayers() or 0
        end
    },
	password = {
        get = function()
            return getServerPassword() or ''
        end,
        set = function(pass)
            pass = pass:len() >= 3 and pass or nil
            if pass == nil then
                outputDebugString('Server password has been removed.');
            else
                outputDebugString('Setting server password to: "' .. pass .. '"');
            end
            return setServerPassword(pass)
        end
    },
	plugins = {
        get = function ()
            return get(getResourceName(getThisResource()) .. '.plugins') or ''
        end
    },
	port = {
        get = function()
            return getServerConfigSetting("serverport") or 0
        end
    },
	query = true,
	rcon_password = {
        get: function()
            return get(getResourceName(getThisResource()) .. '.rcon_password') or 'changeme',
        end,
        set = function (pass)
            if pass:len() > 3 then
                return 0
            end
            return set(getResourceName(getThisResource()) .. '.rcon_password', pass)
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
			local h, m = getTime()
			return h .. ':' .. m
		end,
		set = function(str)
			local h, m = str:match('^(%d+):(%d+)$')
			if h then
				setTime(tonumber(h), tonumber(m))
			end
		end
	},
    artwork = true
}

local readOnlyVars = table.create({ 'announce', 'anticheat', 'bind', 'filterscripts', 'hostname', 'maxplayers',
	'plugins', 'port', 'version' }, true)
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

g_RCONCommands = {
	banip = function (ip)
        if not ip then
            return 'banip <ip>'
        end
        if addBan(ip) then
            return 'IP ' .. ip .. ' has been banned.'
        else
            return 'Failed to ban ' .. ip
        end
    end,
	ban = function (id)
        if not id then
            return 'ban <playerid>'
        end
        id = tonumber(id)
        if not id or not g_Players[id] then
            return
        end
        local name = getPlayerName(g_Players[id].elem)
        if banPlayer(g_Players[id].elem) then
            return name .. ' < ' .. id .. '> has been banned.'
        else
            return 'Failed to ban ' .. id .. ' (' .. name .. ')'
        end
    end,
	changemode = function (mode)
        if not mode then
            return 'changemode <modename>'
        end
        for name, amx in pairs(g_LoadedAMXs) do
            if amx.type == 'gamemode' then
                if amx.name == mode then
                    return 'gamemode \'' .. mode .. '\' is already loded!'
                else
                    unloadAMX(amx)
                    if not loadAMX(mode .. '.amx', true) then
                        return 'Unable to load gamemode \'' .. mode .. '\''
                    end
                end
            end
        end
    end,
	cmdlist = function ()
        return table.concat(table.sort(table.keys(g_RCONCommands)), '\n')
    end,
	echo = function (str)
        print(str or '')
    end,
	exec = function (fname)
        if not fname then
            return 'exec <filename>'
        end
        return doRCONFromFile(fname) or ('Unable to exec file \'' .. fname .. '\'')
    end,
	gravity = function (grav)
        grav = grav and tonumber(grav)
        if not grav then
            return 'gravity <grav>'
        end
        setGravity(grav)
    end,
	gmx = function ()
        local mapcycler = getResourceFromName('mapcycler')
        if not mapcycler then
            return 'The mapcycler resource, which is required for amx mode cycling, is not installed'
        end
        if getResourceState(mapcycler) == 'running' then
            restartResource(mapcycler)
        else
            startResource(mapcycler)
        end
    end,
	kick = function (id)
        if not id then
            return 'kick <id>'
        end
        id = tonumber(id)
        if not id or not g_Players[id] then
            return 'Invalid playerid'
        end
        local name = getPlayerName(g_Players[id].elem)
        if kickPlayer(g_Players[id].elem) then
            return name .. ' <' .. id .. '> has been kicked.'
        else
            return 'Failed to kick ' .. name .. ' (' .. id .. ')'
        end
    end,
	loadfs = function (fsname)
        if not fsname then
            return 'loadfs <fsname>'
        end
        local res = getResourceFromName('amx-fs-' .. fsname)
        if not res then
            return 'No such filterscript: ' .. fsname
        end
        startResource(res)
    end,
	loadplugin = function (pluginName)
        if not pluginName then
            return 'loadplugin <pluginname>'
        end
        if amxIsPluginLoaded(pluginName) then
            return 'Plugin ' .. pluginName .. ' is already loaded'
        end
        if not amxLoadPlugin(pluginName) then
            return '  Failed loading plugin ' .. pluginName .. '!'
        end
    end,
	players = function ()
        local result = ''
        for id, data in pairs(g_Players) do
            result = result .. ('%s(%5d)|Ping:%d|IP:%s\n'):format(getPlayerName(data.elem), id, getPlayerPing(data.elem), getPlayerIP(data.elem)
        end
        return result
    end,
	reloadfs = function (fsname)
        if not fsname then
            return 'reloadfs <fsname>'
        end
        local res = getResourceFromName('amx-fs-' .. fsname)
        if not res then
            return 'No such filterscript: ' .. fsname
        end
        restartResource(res)
    end,
	unbanip = function (ip)
        if not ip then
            return 'unbanip <ip>'
        end
        for banID, ban in ipairs(getBans()) do
            if getBanIP(ban) == ip then
                if removeBan(ban) then
                    return 'Removed ' .. ip .. ' from the ban list'
                else
                    return 'Failed to unban ' .. ip
                end
            end
        end
        return 'Failed to unban ' .. ip
    end,
	unloadfs = function (fsname)
        if not fsname then
            return 'unloadfs <fsname>'
        end
        local res = getResourceFromName('amx-fs-' .. fsname)
        if not res then
            return 'No such filterscript: ' .. fsname
        end
        stopResource(res)
    end,
    varlist = function ()
        local result = ''
        local keys = table.sort(table.keys(g_ServerVars.shadow))
        for i, k in ipairs(keys) do
            result = result .. presentServerVar(k) .. '\n'
        end
        return result
    end,
    sleep = function()
        return 'Sorry, but \'sleep\' is not implemented.'
    end,
    say = function(msg)
        if not msg then
            return 'say <message>'
        end
        for i,player in ipairs(getElementsByType("player")) do
            outputChatBox("* Admin: " .. msg, player, 0, 0, 170)
        end
        return 'Sorry, but \'say\' is not implemented.'
    end,
    tickrate = function()
        return 'Sorry, but \'tickrate\' is not implemented.'
    end,
    dynticks = function()
        return 'Sorry, but \'dynticks\' is not implemented.'
    end,
    messageslimit = function()
        return 'Sorry, but \'messageslimit\' is not implemented.'
    end,
    playertimeout = function()
        return 'Sorry, but \'playertimeout\' is not implemented.'
    end,
    rcon = function()
        return 'Sorry, but \'rcon\' is not implemented.'
    end,
    messageholelimit = function()
        return 'Sorry, but \'worldtime\' is not implemented.'
    end,
    reloadbans = function()
        if (reloadBans()) then
            return 'Bans has been reloaded successfully.'
        else
            return 'Failed to Reload Bans.'
        end
    end,
    ackslimit = function()
        return 'Sorry, but \'ackslimit\' is not implemented.'
    end,
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
		if not isObjectInACLGroup("rcon." .. getPlayerName(player), aclGetGroup("Admin")) and not isPlayerInACLGroup(player, 'Admin') then
			outputChatBox('Access Denied!', player, 255, 0, 0)
            return
        end
		local str = table.concat({ ... }, ' ')
        local cmd, args = str:match('^([^%s]+)%s*(.*)$')
        if cmd == 'login' then
            if not args then
                outputChatBox('You forgot the RCON command!', player, 255, 0, 0)
                return
            end
            if args == get(getResourceName(getThisResource()) .. '.rcon_password') then
                aclGroupAddObject(aclGetGroup("Admin"), "rcon." .. getPlayerName(player))
                outputDebugString('RCON (In-Game): Player \'' .. getPlayerName(player) .. '\' has logged in.')
                outputChatBox('SERVER: You are logged in as admin.', player, 255, 255, 255)
            else
                outputDebugString('RCON (In-Game): Player \'' .. getPlayerName(player) .. '\' <' .. args .. '> failed login.')
                outputChatBox('SERVER: Bad admin password. Repeated attempts will get you banned.')
            end
        else
            local result = doRCON(str)
            if result then
                local lines = result:split('\n')
                for i, line in ipairs(lines) do
                    outputConsole(line)
                end
                outputDebugString('RCON (In-Game): Player [' .. getPlayerName(player) .. '] sent command: ' .. str)
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
            outputDebugString('Console input: ' .. str)
			print(result)
		end
	end
)
