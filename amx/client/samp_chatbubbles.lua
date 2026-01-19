local g_Players = {}
local screenW, screenH = guiGetScreenSize()

local function getPlayerData(player)
    if not g_Players[player] then
        g_Players[player] = { pvars = {} }
    end
    return g_Players[player]
end

addEvent("onChatBubbleRequested", true)
addEventHandler("onChatBubbleRequested", root, function(player, text, colour, dist, exptime, cameraMatrix)
    if not isElement(player) then return end

    local data = getPlayerData(player)

    data.pvars["_chtbbl" .. tostring(getElemID(player))] = {
        text = text,
        colour = colour,
        expires = getTickCount() + (exptime or 5000),
        zOffset = 0.7,
		drawDist = dist,
		targetPlayer = player,
		camMatrix = cameraMatrix
    }
end)

addEventHandler("onClientRender", root, function()
	local function destroyDisplay(serverDisplay, dspText, targetPlayer, forPlayer)
	    textDisplayRemoveObserver(serverDisplay, forPlayer)
	    textDisplayRemoveText(serverDisplay, dspText)
	    textDestroyDisplay(serverDisplay)
		g_Players[forPlayer].pvars["_chtbbl" .. tostring(getElemID(targetPlayer))].txtDisplay = nil
		g_Players[forPlayer].pvars["_chtbbl" .. tostring(getElemID(targetPlayer))].serverText = nil
	end

	local text, colour, dist, exptime, zOffset
	local data = getPlayerData(localPlayer)
	for key, bubble in pairs(data.pvars) do
	    if type(bubble) == "table" then
			if getTickCount() > bubble.expires then
				data.pvars[key] = nil
			else
				local bx, by, bz = getPedBonePosition(bubble.targetPlayer, 8)
				local worldPos = Vector3(bx, by, bz + (bubble.zOffset or 0.7))
				local sx, sy = getScreenFromWorldPosition(worldPos.x, worldPos.y, worldPos.z)
				local targetPos = Vector2(sx, sy)
				local camPos = Vector3(camMatrix.x, camMatrix.y, camMatrix.z)

				if targetPos.x and targetPos.y then
					print("worldPos.x and worldPos.y : TRUE")
					local distance = (camPos - worldPos).length
					if distance <= bubble.drawDist and isLineOfSightClear(camPos.x, camPos.y, camPos.z, worldPos.x, worldPos.y, worldPos.z, true, true, true, true, true, false, false) then
						if data.pvars["_chtbbl" .. tostring(getElemID(bubble.targetPlayer))].txtDisplay == nil then
							data.pvars["_chtbbl" .. tostring(getElemID(bubble.targetPlayer))].txtDisplay = textCreateDisplay()
							data.pvars["_chtbbl" .. tostring(getElemID(bubble.targetPlayer))].serverText = textCreateTextItem(bubble.text, 0.5, 0.5)
							local r = bitAnd(bitRShift(bubble.colour, 24), 0xFF)
							local g = bitAnd(bitRShift(bubble.colour, 16), 0xFF)
							local b = bitAnd(bitRShift(bubble.colour), 0xFF)
							local a = bitAnd(bubble.colour, 0xFF)
							if a == 0 then a = 255 end
							textItemSetColor(data.pvars["_chtbbl" .. tostring(getElemID(bubble.targetPlayer))].serverText, r, g, b, a)
							textDisplayAddText(data.pvars["_chtbbl" .. tostring(getElemID(bubble.targetPlayer))].txtDisplay, data.pvars["_chtbbl" .. tostring(getElemID(bubble.targetPlayer))].serverText)
						end
						print("distance <= bubble.drawDist : TRUE")
						
						local normX = targetPos.x -- / screenW
						local normY = targetPos.y -- / screenH
						textItemSetPosition(data.pvars["_chtbbl" .. tostring(getElemID(bubble.targetPlayer))].serverText, normX, normY)
						
						local scale = math.max(0.6, (15 / distance * 1.0))
						textItemSetScale(data.pvars["_chtbbl" .. tostring(getElemID(bubble.targetPlayer))].serverText, scale)
					
						if not textDisplayIsObserver(data.pvars["_chtbbl" .. tostring(getElemID(bubble.targetPlayer))].txtDisplay, localPlayer) then
							textDisplayAddObserver(data.pvars["_chtbbl" .. tostring(getElemID(bubble.targetPlayer))].txtDisplay, localPlayer)
						end
					end
				else
					if textDisplayIsObserver(data.pvars["_chtbbl" .. tostring(getElemID(bubble.targetPlayer))].txtDisplay) then
						destroyDisplay(data.pvars["_chtbbl" .. tostring(getElemID(bubble.targetPlayer))].txtDisplay, data.pvars["_chtbbl" .. tostring(getElemID(bubble.targetPlayer))].serverText, localPlayer)
					end
					print("worldPos.x and worldPos.y : FALSE")
				end
				setTimer(destroyDisplay, bubble.expires, 1, data.pvars["_chtbbl" .. tostring(getElemID(bubble.targetPlayer))].txtDisplay, data.pvars["_chtbbl" .. tostring(getElemID(bubble.targetPlayer))].serverText, localPlayer)
			end
		end
	end
end)
