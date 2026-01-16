local g_Players = {}
local screenW, screenH = guiGetScreenSize()

local function getPlayerData(player)
    if not g_Players[player] then
        g_Players[player] = { pvars = {} }
    end
    return g_Players[player]
end

addEvent("onChatBubbleRequested", true)
addEventHandler("onChatBubbleRequested", root, function(player, text, colour, dist, exptime)
    if not isElement(player) then return end

    local data = getPlayerData(player)

    data.pvars["_chtbbl" .. tostring(getElemID(player))] = {
        text = text,
        color = colour,
        expires = getTickCount() + (exptime or 5000),
        zOffset = 0.7,
		drawDist = dist
    }
end)

addEventHandler("onClientRender", root, function()
    local text, colour, dist, exptime, zOffset = nil
    for targetPlayer, data in pairs(g_Players) do
        if isElement(targetPlayer) and isElementStreamedIn(targetPlayer) then
            for key, bubble in pairs(data.pvars) do
                if getTickCount() > bubble.expires then
                    data.pvars[key] = nil
                else
				    text = bubble.text
					colour = bubble.colour
					zOffset = bubble.zOffset
					exptime = bubble.expires
					dist = bubble.drawDist
                end
			end
		end
	end
	local chatBubbleTimer = nil
	local function destroyDisplay(serverDisplay, dspText, targetPlayer, forPlayer)
	    textDisplayRemoveObserver(serverDisplay, forPlayer)
	    textDisplayRemoveText(serverDisplay, dspText)
	    textDestroyDisplay(serverDisplay)
		g_Players[forPlayer].pvars["_chtbbl" .. tostring(getElemID(targetPlayer))] = nil
		g_Players[forPlayer].pvars["_chtbbl2" .. tostring(getElemID(targetPlayer))] = nil
		if chatBubbleTimer and isTimer(chatBubbleTimer) then
		    killTimer(chatBubbleTimer)
		end
	end
	
	chatBubbleTimer = setTimer(function()
		local bx, by, bz = getPedBonePosition(localPlayer, 8)
		local sx, sy = getScreenFromWorldPosition(bx, by, bz + zOffset)
		local targetPos = Vector3(sx, sy, sz)
		for _, plr in ipairs(getElementsByType('player')) do
		    if isElementStreamedIn(plr) then
				local cx, cy, cz = getCameraMatrix(plr)
				local camPos = Vector3(cx, cy, cz)

				g_Players[plr].pvars = {}	
				if targetPos.x and targetPos.y then
					local distance = (camPos - targetPos).length
					if distance <= dist and isLineOfSightClear(camPos.x, camPos.y, camPos.z, targetPos.x, targetPos.y, targetPos.z, true, true, true, true, true, false, false) then
						local scale = math.max(0.6, (15 / distance * 1.0))
						if not g_Players[plr].pvars["_chtbbl" .. tostring(getElemID(player))].txtDisplay == nil then
							g_Players[plr].pvars["_chtbbl" .. tostring(getElemID(player))].txtDisplay = textCreateDisplay()
							g_Players[plr].pvars["_chtbbl" .. tostring(getElemID(player))].serverText = textCreateTextItem(text, 0.5, 0.5)
						    local r = bitAnd(bitRShift(colour, 24), 0xFF)
						    local g = bitAnd(bitRShift(colour, 16), 0xFF)
						    local b = bitAnd(bitRShift(colour, 8), 0xFF)
						    local a = bitAnd(colour, 0xFF)
   						    textItemSetColor(g_Players[plr].pvars["_chtbbl" .. tostring(getElemID(player))].serverText, r, g, b, a)
							textDisplayAddText(g_Players[plr].pvars["_chtbbl" .. tostring(getElemID(player))].txtDisplay, g_Players[plr].pvars["_chtbbl" .. tostring(getElemID(player))].serverText)
							local normX = targetPos.x / screenW
							local normY = targetPos.y / screenH
							textItemSetPosition(g_Players[plr].pvars["_chtbbl" .. tostring(getElemID(player))].serverText, normX, normY)

							textItemSetScale(g_Players[plr].pvars["_chtbbl" .. tostring(getElemID(player))].serverText, scale)
						end
						
						if not textDisplayIsObserver(g_Players[plr].pvars["_chtbbl" .. tostring(getElemID(player))].txtDisplay, plr) then
							textDisplayAddObserver(g_Players[plr].pvars["_chtbbl" .. tostring(getElemID(player))].txtDisplay, plr)
						end
					end
				else
					if textDisplayIsObserver(g_Players[plr].pvars["_chtbbl" .. tostring(getElemID(player))].txtDisplay) then
						destroyDisplay(g_Players[plr].pvars["_chtbbl" .. tostring(getElemID(player))].txtDisplay, g_Players[plr].pvars["_chtbbl" .. tostring(getElemID(player))].serverText, plr)
					end
				end
				setTimer(destroyDisplay, exptime, 1, g_Players[plr].pvars["_chtbbl" .. tostring(getElemID(player))].txtDisplay, g_Players[plr].pvars["_chtbbl" .. tostring(getElemID(player))].serverText, plr)
			end
		end
	end, 500, 0)
end)
