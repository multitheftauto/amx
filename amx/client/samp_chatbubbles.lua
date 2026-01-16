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
		local text, colour, dist, exptime, zOffset
		local data = getPlayerData(localPlayer)
		for key, bubble in pairs(data.pvars) do
			if getTickCount() > bubble.expires then
				data.pvars[key] = nil
			else
		        local bx, by, bz = getPedBonePosition(localPlayer, 8)
		        local sx, sy = getScreenFromWorldPosition(bx, by, bz + (bubble.zOffset or 0.7))
		        local targetPos = Vector3(sx, sy, sz)
				local cx, cy, cz = getCameraMatrix(localPlayer)
				local camPos = Vector3(cx, cy, cz)

				if targetPos.x and targetPos.y then
					local distance = (camPos - targetPos).length
					if distance <= bubble.drawDist and isLineOfSightClear(camPos.x, camPos.y, camPos.z, targetPos.x, targetPos.y, targetPos.z, true, true, true, true, true, false, false) then
						local scale = math.max(0.6, (15 / distance * 1.0))
						if not data.pvars["_chtbbl" .. tostring(getElemID(player))].txtDisplay == nil then
							data.pvars["_chtbbl" .. tostring(getElemID(player))].txtDisplay = textCreateDisplay()
							data.pvars["_chtbbl" .. tostring(getElemID(player))].serverText = textCreateTextItem(bubble.text, 0.5, 0.5)
							local r = bitAnd(bitRShift(bubble.colour, 24), 0xFF)
							local g = bitAnd(bitRShift(bubble.colour, 16), 0xFF)
							local b = bitAnd(bitRShift(bubble.colour), 0xFF)
							local a = bitAnd(bubble.colour, 0xFF)
							textItemSetColor(data.pvars["_chtbbl" .. tostring(getElemID(player))].serverText, r, g, b, a)
							textDisplayAddText(data.pvars["_chtbbl" .. tostring(getElemID(player))].txtDisplay, data.pvars["_chtbbl" .. tostring(getElemID(player))].serverText)
							local normX = targetPos.x / screenW
							local normY = targetPos.y / screenH
							textItemSetPosition(data.pvars["_chtbbl" .. tostring(getElemID(player))].serverText, normX, normY)

							textItemSetScale(data.pvars["_chtbbl" .. tostring(getElemID(player))].serverText, scale)
						end
						
						if not textDisplayIsObserver(data.pvars["_chtbbl" .. tostring(getElemID(player))].txtDisplay, localPlayer) then
							textDisplayAddObserver(data.pvars["_chtbbl" .. tostring(getElemID(player))].txtDisplay, localPlayer)
						end
					end
				else
					if textDisplayIsObserver(data.pvars["_chtbbl" .. tostring(getElemID(player))].txtDisplay) then
						destroyDisplay(data.pvars["_chtbbl" .. tostring(getElemID(player))].txtDisplay, data.pvars["_chtbbl" .. tostring(getElemID(player))].serverText, localPlayer)
					end
				end
				setTimer(destroyDisplay, bubble.expires, 1, data.pvars["_chtbbl" .. tostring(getElemID(player))].txtDisplay, data.pvars["_chtbbl" .. tostring(getElemID(player))].serverText, localPlayer)
			end
		end
	end, 500, 0)
end)
