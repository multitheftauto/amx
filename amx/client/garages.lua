local playerGarages = {
	-- Open/close logic only for CJ house garages
	5, 9, 13, 14, 17, 21, 25, 28, 34, 37, 38, 39, 42, 43, 48, 49
}

addEventHandler('onClientResourceStart', resourceRoot,
	function()
		for _, garage in ipairs(playerGarages) do
			local gx, gy, gz = getGaragePosition(garage)
			local colshape = createColSphere(gx, gy, gz, 20)
			setElementData(colshape, 'GarageID', garage, false)

			-- Check initial proximity
			if isElementWithinColShape(localPlayer, colshape) then
				server.setGarageOpen(garage, true)
			end
		end

		-- Airport hangars are always opened
		server.setGarageOpen(30, true)
		server.setGarageOpen(45, true)
	end
)

addEventHandler('onClientColShapeHit', resourceRoot,
	function(hitElement, matchingDimension)
		if hitElement == localPlayer and matchingDimension then
			local garage = getElementData(source, 'GarageID')
			if garage and not isGarageOpen(garage) then
				server.setGarageOpen(garage, true)
			end
		end
	end
)

addEventHandler('onClientColShapeLeave', resourceRoot,
	function(hitElement, matchingDimension)
		if hitElement == localPlayer and matchingDimension then
			local garage = getElementData(source, 'GarageID')
			if garage and isGarageOpen(garage) then
				server.setGarageOpen(garage, false)
			end
		end
	end
)
