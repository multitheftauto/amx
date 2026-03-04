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

function drawBorderText(text, x, y, color, scalex, scaley, font, outlinesize, outlinecolor)
	local alpha = bitExtract(color, 24, 8)
	outlinecolor = outlinecolor or tocolor(0, 0, 0, alpha)

	if outlinesize > 0 then
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
	if type(index) == 'function' then
		table.insert(arg, 1, callback)
		callback = index
		index = false
	end
	for k, v in pairs(t) do
		callback(index and v[index] or v, unpack(arg))
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

function setcoloralpha(color, alpha)
	local a = bitExtract(color, 24, 8)
	return bitReplace(color, alpha, 24, 8)
end

DEFAULT_SCREEN_WIDTH = 640.0
DEFAULT_SCREEN_HEIGHT = 448.0
DEFAULT_ASPECT_RATIO = 4.0 / 3.0

screenWidth, screenHeight = guiGetScreenSize()

-- This scales from PS2 pixel coordinates to the real resolution
function SCREEN_STRETCH_X(a)
	return ((a) * screenWidth / DEFAULT_SCREEN_WIDTH)
end

function SCREEN_STRETCH_Y(a)
	return ((a) * screenHeight / DEFAULT_SCREEN_HEIGHT)
end

function getAspectRatio()
	return screenWidth / screenHeight
end

function SCREEN_SCALE_AR(a)
	return ((a) * DEFAULT_ASPECT_RATIO / getAspectRatio())
end

-- This scales from PS2 pixel coordinates while optionally maintaining the aspect ratio
function SCREEN_SCALE_X(a)
	return SCREEN_SCALE_AR(SCREEN_STRETCH_X(a))
end

function SCREEN_SCALE_Y(a)
	return SCREEN_STRETCH_Y(a)
end
