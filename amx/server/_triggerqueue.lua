_triggerClientEvent = triggerClientEvent

local playerData = {}			-- { player = { loaded = bool, pending = {...} } }

local function joinHandler(player)
	playerData[player or source] = { loaded = false, pending = {} }
end

addEventHandler('onResourceStart', resourceRoot,
	function()
		for i,player in ipairs(getElementsByType('player')) do
			joinHandler(player)
		end
	end,
	false
)

addEventHandler('onPlayerJoin', root, joinHandler)

addEvent('onLoadedAtClient', true)
addEventHandler('onLoadedAtClient', resourceRoot,
	function(player)
		playerData[player].loaded = true
		for i,event in ipairs(playerData[player].pending) do
			_triggerClientEvent(player, event.name, event.source, unpack(event.args))
		end
		playerData[player].pending = nil
	end,
	false
)

addEventHandler('onPlayerQuit', root,
	function()
		playerData[source] = nil
	end
)

local function addToQueue(player, name, source, args)
	for i,a in pairs(args) do
		if type(a) == 'table' then
			args[i] = table.deepcopy(a)
		end
	end
	table.insert(playerData[player].pending, { name = name, source = source, args = args })
end


function triggerClientEvent(...)
	local args = { ... }
	local triggerFor, name, source
	if type(args[1]) == 'userdata' then
		triggerFor = table.remove(args, 1)
	else
		triggerFor = root
	end
	name = table.remove(args, 1)
	source = table.remove(args, 1)

	if triggerFor == root then
		-- trigger for everyone
		local triggerNow = true
		for player,data in pairs(playerData) do
			if not data.loaded then
				triggerNow = false
				break
			end
		end
		if triggerNow then
			_triggerClientEvent(root, name, source, unpack(args))
		else
			for player,data in pairs(playerData) do
				addToQueue(player, name, source, args)
			end
		end
	elseif playerData[triggerFor] then
		-- trigger for single player
		if playerData[triggerFor].loaded then
			_triggerClientEvent(triggerFor, name, source, unpack(args))
		else
			addToQueue(triggerFor, name, source, args)
		end
	end
end
