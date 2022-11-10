g_ServerVars = {
	announce = true,
	anticheat = false,
	bind = '',
	filterscripts = get(getResourceName(getThisResource()) .. '.filterscripts') or '',
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
            return getGameType() or ''
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
        get = getServerName
    },
    language = 'Sorry, but \'language\' is not implemented.'
	-- instagib = false,
	lanmode = false,
	mapname = {
        get = function()
            return getMapName() or ''
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
        get = getMaxPlayers
    },
	password = {
        get = function()
            return getServerPassword() or ''
        end,
        set = function(pass)
            pass = pass:len() >= 3 and pass or nil
            return setServerPassword(pass)
        end
    },
	plugins = get(getResourceName(getThisResource()) .. '.plugins') or '',
	port = {
        get = getServerPort
    },
	query = true,
	rcon_password = {
        get: function ()
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

local readOnlyVars = table.create({ 'announce', 'anticheat', 'bind', 'filterscripts', 'hostname', 'maxplayers', 'nosign',
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
        local newRes = getResourceFromName('amx-' .. mode)
        if not newRes then
            return 'No gamemode named ' .. mode
        end
        local amx = getRunningGameMode(mode)
        if amx then
            unloadAMX(amx)
        end
        startResource(newRes)
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
        return 'Sorry, but \'reloadbans\' is not implemented.'
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
