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
    
	local bubbleID = "chatbubble_" .. tostring(getElementID(player) or "temp")
    data.pvars[bubbleID] = {
        text = text,
        color = colour,
        expires = getTickCount() + (exptime or 5000),
        zOffset = 0.7
		drawDist = dist
    }
end)

addEventHandler("onClientRender", root, function()
    local text, colour, dist, exptime, zOffset = nil
    for targetPlayer, data in pairs(g_Players) do
        if isElement(targetPlayer) and isElementStreamedIn(targetPlayer) then
            for key, bubble in pairs(data.pvars) do
                if now > bubble.expires then
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
		g_Players[getElemID(forPlayer)].pvars["_chtbbl" .. getElemID(targetPlayer)] = nil
		g_Players[getElemID(forPlayer)].pvars["_chtbbl2" .. getElemID(targetPlayer)] = nil
		if chatBubbleTimer and isTimer(chatBubbleTimer) then
		    killTimer(chatBubbleTimer)
		end
	end
	
	chatBubbleTimer = setTimer(function()
		for _, plr in ipairs(getElementsByType('player')) do
		    if not isElementStreamedIn(plr) then
			    goto continue
			end
			local cx, cy, cz = getCameraMatrix(plr)
            local camPos = Vector3(cx, cy, cz)
			local bx, by, bz = getPedBonePosition(player, 8)
			local sx, sy = getScreenFromWorldPosition(bx, by, bz + zOffset)
			local targetPos = Vector3(sx, sy, sz)

			g_Players[getElemID(plr)].pvars = {}
			local txtDisplay = g_Players[getElemID(plr)].pvars["_chtbbl" .. getElemID(player)]
			local serverText = g_Players[getElemID(plr)].pvars["_chtbbl2" .. getElemID(player)]		
			if targetPos.x and targetPos.y then
			    local distance = (camPos - targetPos).length)
				if distance <= dist and isLineOfSightClear(camPos.x, camPos.y, camPos.z, targetPos.x, targetPos.y, targetPos.z, true, true, true, true, true, false, false) then
					local scale = math.max(0.6, (15 / distance * 1.0)
					if not txtDisplay == nil then
						txtDisplay = textCreateDisplay()
						serverText = textCreateTextItem(text, 0.5, 0.5)
						textItemSetColor(serverText, (colour >> 24) & 0xFF, (colour >> 16) & 0xFF, (colour >> 8) & 0xFF, colour & 0xFF)
						textDisplayAddText(txtDisplay, serverText)
                        local normX = sx / screenW
                        local normY = sy / screenH
                        textItemSetPosition(serverText, normX, normY)

						textItemSetScale(serverText, scale)
					end
					
					if not textDisplayIsObserver(txtDisplay, plr) then
						textDisplayAddObserver(txtDisplay, plr)
					end
				end
			else
				if textDisplayIsObserver(txtDisplay) then
					destroyDisplay(txtDisplay, serverText, plr)
				end
			end
			setTimer(destroyDisplay, exptime, 1, txtDisplay, serverText, plr)
			
			::continue::
		end
	end, 500, 0)
end)
