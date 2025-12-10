local targetBlipIcon = 41
local targetBlip

local screenSize = Vector2(guiGetScreenSize())
local wasLMBPressed, wasRMBPressed = false, false
local wasMapOpened = false

local function handleMapTargetBlip()
	if not isPlayerMapVisible() then
		if wasMapOpened then
			if g_ClassSelectionInfo and g_ClassSelectionInfo.gui then
				showCursor(true)
			else
				showCursor(false, false)
			end
			wasLMBPressed, wasRMBPressed = false, false
			wasMapOpened = false
		end
		return
	end

	if not isCursorShowing() then
		showCursor(true, false)
	end

	local isLMBPressed = getKeyState('mouse1')
	if isLMBPressed and isLMBPressed ~= wasLMBPressed then
		local cursorPos, mapMin, mapMax = Vector2(getCursorPosition())
		cursorPos.x, cursorPos.y = cursorPos.x * screenSize.x, cursorPos.y * screenSize.y

		do
			local mx, my, Mx, My = getPlayerMapBoundingBox()
			mapMin = Vector2(mx, my)
			mapMax = Vector2(Mx, My)
		end

		if cursorPos.x >= mapMin.x and cursorPos.y >= mapMin.y and cursorPos.x <= mapMax.x and cursorPos.y <= mapMax.y then
			local relPos = Vector2((cursorPos.x - mapMin.x) / (mapMax.x - mapMin.x), (cursorPos.y - mapMin.y) / (mapMax.y - mapMin.y))
			local worldPlanePos = Vector2(6000 * (relPos.x - 0.5), 3000 - (relPos.y * 6000))
			local worldPos = Vector3(worldPlanePos.x, worldPlanePos.y, getGroundPosition(worldPlanePos.x, worldPlanePos.y, 3000))

			triggerServerEvent('onPlayerClickMap_Ev', localPlayer, worldPos.x, worldPos.y, worldPos.z)
			playSoundFrontEnd(1)

			if not targetBlip then
				targetBlip = createBlip(worldPos, targetBlipIcon)
			else
				setElementPosition(targetBlip, worldPos)
			end
		end
	end

	local isRMBPressed = getKeyState('mouse2')
	if targetBlip and isRMBPressed and isRMBPressed ~= wasRMBPressed then
		playSoundFrontEnd(2)
		destroyElement(targetBlip)
		targetBlip = nil
	end

	wasLMBPressed, wasRMBPressed = isLMBPressed, isRMBPressed
	wasMapOpened = true
end
addEventHandler('onClientRender', root, handleMapTargetBlip)
