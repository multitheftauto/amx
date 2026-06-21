--[[
local function fndebug(...)
	local args = { ... }
	for i, name in ipairs(args) do
		local fn = _G[name]
		_G[name] = function(...)
			local args = { ... }
			local result = fn(...)

			local logstr = 'Client: ' .. name .. '('
			for i, a in ipairs(args) do
				if i > 1 then
					logstr = logstr .. ', '
				end
				if type(a) == 'userdata' then
					if getElementType(a) == 'player' then
						a = getPlayerName(a)
					else
						a = 'element:' .. getElementType(a)
					end
				elseif type(a) == 'string' then
					a = '"' .. a .. '"'
				else
					a = tostring(a)
				end
				logstr = logstr .. a
			end
			logstr = logstr .. ') = ' .. tostring(result)
			outputConsole(logstr)
			return result
		end
	end
end
fndebug(
--	'setCameraMatrix',
--	'setCameraInterior',
--	'setCameraTarget',
--	'setElementInterior'
	'createObject'
)
--]]

addEvent('onClientCall', true)
addEventHandler('onClientCall', resourceRoot,
	function(fnName, ...)
		if _G[fnName] then
			_G[fnName](...)
		else
			outputDebugString('amx: client: attempt to call unknown function ' .. tostring(fnName), 1)
		end
	end,
	false
)

server = setmetatable(
	{},
	{
		__index = function(self, k)
			self[k] = function(...) triggerServerEvent('onCall', resourceRoot, k, ...) end
			return self[k]
		end
	}
)

g_TextDrawColorMapping = {
	r = { 180, 25, 29 },
	g = { 54, 104, 44 },
	b = { 50, 60, 127 },
	o = { 215, 146, 24 },
	w = { 225, 225, 225 },
	y = { 226, 192, 99 },
	p = { 168, 110, 252 },
	l = { 10, 10, 10 }
}

g_TextDrawFonts = {
	[0] = 'beckett',
	[1] = 'default-bold',
	[2] = 'bankgothic',
	[3] = 'pricedown'
}

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

function getSAMPBoundKey(control)
	control = controlNames[control] or control
	local keys = getBoundKeys(control)
	if keys and #keys > 0 then
		return keys[1]
	else
		return control
	end
end

function drawBorderText(text, x, y, color, scalex, scaley, font, outlinesize, outlinecolor)
	local alpha = bitExtract(color, 24, 8)
	outlinecolor = outlinecolor or tocolor(0, 0, 0, alpha)

	if outlinesize and outlinesize ~= 0 then
		outlinesize = outlinesize * 2
		for offsetX = -outlinesize, outlinesize, outlinesize do
			for offsetY = -outlinesize, outlinesize, outlinesize do
				if not (offsetX == 0 and offsetY == 0) then
					dxDrawText(text, x + offsetX, y + offsetY, x + offsetX, y + offsetY, outlinecolor, scalex, scaley, font)
				end
			end
		end
	end
	dxDrawText(text, x, y, x, y, color, scalex, scaley, font)
end

function drawShadowText(text, x, y, color, scale, font, shadowDist, width, align)
	scale = scale or 1
	font = font or 'default'
	shadowDist = shadowDist or 1
	align = align or 'center'

	local alpha = bitExtract(color, 24, 8)
	dxDrawText(text, x + shadowDist, y + shadowDist, x + shadowDist + (width or 0), 0, tocolor(0, 0, 0, alpha), scale, font, width and align or 'left')
	dxDrawText(text, x, y, x + (width or 0), 0, color, scale, font, width and align or 'left')
end

-- Originally by UAEpro from here: https://forum.multitheftauto.com/topic/33149-colorcodes-in-labels/#comment-335358
function guiCreateColoredLabel(ax, ay, bx, by, str, parent, relative) -- x, y, width, height
	if not relative then
		relative = true
	end

	local scrollpane = guiCreateScrollPane(ax, ay, bx, by, relative, parent)
	--outputConsole('main string:' .. str)

	local pat = '(.-)#(%x%x%x%x%x%x)'
	local s, e, cap, col = str:find(pat, 1)
	local labels = {}
	local r, g, b = 255, 255, 255
	local incx, incy = 0, 0
	local last = 1

	while s do
		if cap == '' then
			r, g, b = tonumber('0x' .. col:sub(1, 2)), tonumber('0x' .. col:sub(3, 4)), tonumber('0x' .. col:sub(5, 6))
		end
		if (s ~= 1) or cap ~= '' then
			--outputConsole('guiCreateColoredLabel: ' .. cap)

			local lbl = guiCreateLabel(ax + incx, ay + incy, bx, by, cap, relative, scrollpane)
			guiLabelSetHorizontalAlign(lbl, 'left')
			table.insert(labels, lbl)
			guiLabelSetColor(lbl, r, g, b)
			r, g, b = tonumber('0x' .. col:sub(1, 2)), tonumber('0x' .. col:sub(3, 4)), tonumber('0x' .. col:sub(5, 6))

			if cap:find('\n') then
				local xtxtsize, ytxtsize = guiGetSize(lbl, true) -- not relative
				incy = incy + (ytxtsize / 8) -- We found a \n so send it further down on the next line
				incx = 0 -- Don't add spaces on new lines
				--outputConsole('found a new line')
			elseif r ~= 255 or g ~= 255 or b ~= 255 then -- It's colored so separate it
				incy = 0
				local xsize, ysize = guiGetSize(scrollpane, false) -- not relative
				incx = incx + (guiLabelGetTextExtent(lbl) / xsize) -- Make space for the next word, relative to the parent width
				--outputConsole('Separating string')
			else
				incx = 0
				incy = 0
			end
		end
		last = e + 1
		s, e, cap, col = str:find(pat, last)
	end
	if last <= #str then
		local lbl2 = guiCreateLabel(ax + incx, ay + incy, bx, by, str:sub(last), relative, scrollpane)
		table.insert(labels, lbl2)
		guiLabelSetColor(lbl2, r, g, b)
	end
	return labels
end

function displayFadingMessage(text, r, g, b, fadeInTime, stayTime, fadeOutTime)
	local lineHeight = 40
	local label = guiCreateLabel(screenWidth, screenHeight, 500, lineHeight, text, false)
	local width = guiLabelGetTextExtent(label)
	guiSetPosition(label, screenWidth / 2 - width / 2, 3 * screenHeight / 4, false)
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

function destroyBlipsAttachedTo(elem)
	table.each(table.filter(getAttachedElements(elem) or {}, getElementType, 'blip'), destroyElement)
end

local _bindKey = bindKey
function bindKey(key, ...)
	if type(key) == 'string' then
		return _bindKey(key, ...)
	elseif type(key) == 'table' then
		local result = true
		for i, k in ipairs(key) do
			result = result and _bindKey(k, ...)
		end
		return result
	end
end

function isVehicleEmpty(vehicle)
	local numPassengers = getVehicleMaxPassengers(vehicle)
	if not numPassengers then
		return true
	end
	for seat = 0, numPassengers do
		if getVehicleOccupant(vehicle, seat) then
			return false
		end
	end
	return true
end

function getElemID(elem)
	return elem and isElement(elem) and getElementData(elem, 'amx.id')
end

function table.find(t, ...)
	local args = { ... }
	if #args == 0 then
		for k, v in pairs(t) do
			if v then
				return k, v
			end
		end
		return false
	end

	local value = table.remove(args)
	if value == '[nil]' then
		value = nil
	end
	for k, v in pairs(t) do
		for i, index in ipairs(args) do
			if type(index) == 'function' then
				v = index(v)
			else
				if index == '[last]' then
					index = #v
				end
				v = v[index]
			end
		end
		if v == value then
			return k, t[k]
		end
	end
	return false
end

function table.removevalue(t, val)
	for i, v in ipairs(t) do
		if v == val then
			table.remove(t, i)
			return i
		end
	end
	return false
end

function table.random(t)
	return t[math.random(#t)]
end

function table.each(t, index, callback, ...)
	local args = { ... }
	if type(index) == 'function' then
		table.insert(args, 1, callback)
		callback = index
		index = false
	end
	for k, v in pairs(t) do
		if index then
			v = v[index]
		end
		callback(v, unpack(args))
	end
	return t
end

function table.filter(t, callback, cmpval)
	if cmpval == nil then
		cmpval = true
	end
	for k, v in pairs(t) do
		if callback(v) ~= cmpval then
			t[k] = nil
		end
	end
	return t
end

function table.shallowcopy(t)
	local result = {}
	for k, v in pairs(t) do
		result[k] = v
	end
	return result
end

function table.dump(t, caption, depth)
	if not depth then
		depth = 1
	end
	if depth == 1 and caption then
		outputConsole(caption .. ':')
	end
	if not t then
		outputConsole('Table is nil')
	elseif type(t) ~= 'table' then
		outputConsole('Argument passed is of type ' .. type(t))
		local str = tostring(t)
		if str then
			outputConsole(str)
		end
	else
		local braceIndent = string.rep('  ', depth - 1)
		local fieldIndent = braceIndent .. '  '
		outputConsole(braceIndent .. '{')
		for k, v in pairs(t) do
			if type(v) == 'table' and k ~= 'siblings' and k ~= 'parent' then
				outputConsole(fieldIndent .. tostring(k) .. ' = ')
				table.dump(v, nil, depth + 1)
			else
				outputConsole(fieldIndent .. tostring(k) .. ' = ' .. tostring(v))
			end
		end
		outputConsole(braceIndent .. '}')
	end
end

function string:split(sep, plain)
	if #self == 0 then
		return {}
	end
	sep = sep or '%s+'
	local result = {}
	local from = 1
	local to, nextfrom
	repeat
		to, nextfrom = self:find(sep, from, plain)
		result[#result + 1] = self:sub(from, to and to - 1)
		from = nextfrom and nextfrom + 1
	until not to
	return result
end

function colorizeString(string)
	return string:gsub('(=?{[0-9A-Fa-f]*})',
	function(colorMatches)
		-- replace the curly brackets with nothing
		colorMatches = colorMatches:gsub('[{}]+', '')

		-- Append to the beginning
		colorMatches = '#' .. colorMatches

		return colorMatches
	end)
end

function colorToRGB(val)
	return {
		bitExtract(val, 16, 8),
		bitExtract(val, 8, 8),
		bitExtract(val, 0, 8)
	}
end

DEFAULT_SCREEN_WIDTH = 640.0
DEFAULT_SCREEN_HEIGHT = 448.0

screenWidth, screenHeight = guiGetScreenSize()

-- This scales from PS2 pixel coordinates to the real resolution
function posStretchX(a)
	return ((a) * screenWidth / DEFAULT_SCREEN_WIDTH)
end

function posStretchY(a)
	return ((a) * screenHeight / DEFAULT_SCREEN_HEIGHT)
end

MINIMAL_SCREEN_WIDTH = 640.0
MINIMAL_SCREEN_HEIGHT = 480.0

function sizeScaleX(a)
	return ((a) * screenWidth / MINIMAL_SCREEN_WIDTH)
end

function sizeScaleY(a)
	return ((a) * screenHeight / MINIMAL_SCREEN_HEIGHT)
end
