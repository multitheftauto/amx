addEventHandler('onClientResourceStart', resourceRoot,
	function()
		for i = 0, 49 do
			local gx, gy, gz = getGaragePosition(i)
			local colshape = createColSphere(gx, gy, gz, 20)
			setElementData(colshape, 'GarageID', i)

			-- Check initial proximity
			if isElementWithinColShape(localPlayer, colshape) then
				server.setGarageOpen(i, true)
			end
		end
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
