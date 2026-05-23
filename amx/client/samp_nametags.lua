local showNameTags = true
local nameTagsRadius = 70
local nameTagsLOS = true

local nameTagShowing = {}
local chatBubble = {}

local font = 'arial' -- default font

local borderWidth = 40
local borderHeight = 6

local innerWidth = 38
local innerHeight = 4

function drawChatBubble(x, y, z, text, r, g, b, a, distance)
	if not r or not g or not b or not a then
		r, g, b, a = 255, 255, 255, 255
	end

	z = (distance * 0.025) + z + 0.4

	local screenCoordsX, screenCoordsY = getScreenFromWorldPosition(x, y, z)
	if not screenCoordsX then return end

	-- Chat bubble outline
	local outlinecolor = tocolor(0, 0, 0, a)
	local rect = {
		left = screenCoordsX - (dxGetTextSize(text, 0, 1, 1, font) / 2),
		top = screenCoordsY,
		right = screenCoordsX + 1,
		bottom = screenCoordsY + 1
	}

	dxDrawText(text, rect.left + 1, rect.top, rect.right, rect.bottom, outlinecolor, 1, font)
	dxDrawText(text, rect.left - 1, rect.top, rect.right, rect.bottom, outlinecolor, 1, font)
	dxDrawText(text, rect.left, rect.top - 1, rect.right, rect.bottom, outlinecolor, 1, font)
	dxDrawText(text, rect.left, rect.top + 1, rect.right, rect.bottom, outlinecolor, 1, font)

	-- Chat bubble text
	dxDrawText(text, rect.left, rect.top, rect.right, rect.bottom, tocolor(r, g, b, a), 1, font)
end

function drawNameTag(x, y, z, nameText, r, g, b, a, health, armor, distance)
	if not r or not g or not b or not a then
		r, g, b, a = 255, 255, 255, 255
	end

	z = (distance * 0.025) + z + 0.3

	local screenCoordsX, screenCoordsY = getScreenFromWorldPosition(x, y, z)
	if not screenCoordsX then return end

	-- Name tag outline
	local outlinecolor = tocolor(0, 0, 0, a)
	local rect = {
		left = screenCoordsX - (dxGetTextSize(nameText, 0, 1, 1, font) / 2),
		top = screenCoordsY,
		right = screenCoordsX + 1,
		bottom = screenCoordsY + 1
	}

	dxDrawText(nameText, rect.left + 1, rect.top, rect.right, rect.bottom, outlinecolor, 1, font)
	dxDrawText(nameText, rect.left - 1, rect.top, rect.right, rect.bottom, outlinecolor, 1, font)
	dxDrawText(nameText, rect.left, rect.top - 1, rect.right, rect.bottom, outlinecolor, 1, font)
	dxDrawText(nameText, rect.left, rect.top + 1, rect.right, rect.bottom, outlinecolor, 1, font)

	-- Name tag text
	dxDrawText(nameText, rect.left, rect.top, rect.right, rect.bottom, tocolor(r, g, b, a), 1, font)

	-- Health bar
	local borderX = screenCoordsX - 20
	local borderY = screenCoordsY + 18

	if armor > 0 then borderY = borderY + 8 end

	local innerX = borderX + 1
	local innerY = borderY + 1

	dxDrawRectangle(borderX, borderY, borderWidth, borderHeight, outlinecolor)
	dxDrawRectangle(innerX, innerY, innerWidth, innerHeight, tocolor(90, 12, 14, a))

	if health > 0 then
		health = (math.min(health, 100) / 100) * innerWidth
		dxDrawRectangle(innerX, innerY, health, innerHeight, tocolor(180, 25, 29, a))
	end

	-- Armor bar
	if armor > 0 then
		borderY = borderY - 8

		dxDrawRectangle(borderX, borderY, borderWidth, borderHeight, outlinecolor)
		dxDrawRectangle(innerX, borderY + 1, innerWidth, innerHeight, tocolor(112, 112, 112, a))

		armor = (math.min(armor, 100) / 100) * innerWidth
		dxDrawRectangle(innerX, borderY + 1, armor, innerHeight, tocolor(225, 225, 225, a))
	end
end

addEventHandler('onClientRender', root,
	function()
		if not showNameTags then return end
		local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)

		for k, player in pairs(getElementsByType('player')) do
			if player ~= localPlayer and isElementOnScreen(player) and nameTagShowing[player] ~= false then
				local fPosX, fPosY, fPosZ = getPedBonePosition(player, 8)
				local distance = getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, fPosX, fPosY, fPosZ)
				local a = getElementAlpha(player)

				if distance < nameTagsRadius and a > 0 then
					local cx, cy, cz = getCameraMatrix()

					if not nameTagsLOS or isLineOfSightClear(cx, cy, cz, fPosX, fPosY, fPosZ, true, false, false, true, true) then
						local r, g, b = getPlayerNametagColor(player)

						drawNameTag(
							fPosX, fPosY, fPosZ,
							getPlayerName(player) .. ' (' .. getElemID(player) .. ')',
							r, g, b, a,
							getElementHealth(player), getPedArmor(player),
							distance
						)

						if chatBubble[player] and distance < chatBubble[player].drawdist then
							if getTickCount() <= chatBubble[player].exptime then
								if chatBubble[player].a < a then
									a = chatBubble[player].a
								end

								drawChatBubble(
									fPosX, fPosY, fPosZ,
									chatBubble[player].text,
									chatBubble[player].r, chatBubble[player].g, chatBubble[player].b, a,
									distance
								)
							else
								chatBubble[player] = nil
							end
						end
					end
				end
			end
		end

		for k, bot in pairs(getElementsByType('ped')) do
			if isElementOnScreen(bot) and getElementData(bot, 'ShowNameTag') then
				local fPosX, fPosY, fPosZ = getPedBonePosition(bot, 8)
				local distance = getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, fPosX, fPosY, fPosZ)
				local a = getElementAlpha(bot)

				if distance < nameTagsRadius and a > 0 then
					local cx, cy, cz = getCameraMatrix()

					if not nameTagsLOS or isLineOfSightClear(cx, cy, cz, fPosX, fPosY, fPosZ, true, false, false, true, true) then
						local botName = getElementData(bot, 'BotName')
						if not botName or botName:len() < 1 then botName = 'Bot' end

						local r = getElementData(bot, 'BotColorR') or 255
						local g = getElementData(bot, 'BotColorG') or 255
						local b = getElementData(bot, 'BotColorB') or 255

						drawNameTag(
							fPosX, fPosY, fPosZ,
							botName .. ' (' .. getElemID(bot) .. ')',
							r, g, b, a,
							getElementHealth(bot), getPedArmor(bot),
							distance
						)
					end
				end
			end
		end
	end
)

function updateChatBubble(player, msg, color, dist, time)
	if not isElement(player) then return end

	local red, green, blue, alpha
	red = bitExtract(color, 24, 8)
	green = bitExtract(color, 16, 8)
	blue = bitExtract(color, 8, 8)
	alpha = bitExtract(color, 0, 8)

	chatBubble[player] = {
		text = msg,
		r = red, g = green, b = blue, a = alpha,
		drawdist = dist,
		exptime = getTickCount() + time
	}
end

function updateNameTagGlobals(settings)
	if settings.status ~= nil then
		showNameTags = settings.status
	end
	if settings.radius ~= nil then
		nameTagsRadius = settings.radius
	end
	if settings.los ~= nil then
		nameTagsLOS = settings.los
	end
end

-- ShowPlayerNameTagForPlayer
function updateNameTagShowing(playerToShow, show)
	nameTagShowing[playerToShow] = show
end
