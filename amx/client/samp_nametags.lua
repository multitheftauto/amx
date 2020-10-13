
local font = dxCreateFont('client/arial.ttf', 10, true, 'default') or 'default' -- fallback to default

HealthBarBorderVertices =
{
	{x=0, y=0, z=0, c=tocolor(0, 0, 0, 255)},
	{x=0, y=0, z=0, c=tocolor(0, 0, 0, 255)},
	{x=0, y=0, z=0, c=tocolor(0, 0, 0, 255)},
	{x=0, y=0, z=0, c=tocolor(0, 0, 0, 255)}
}

HealthBarBackgroundVertices =
{
	{x=0, y=0, z=0, c=tocolor(75, 11, 20, 255)},
	{x=0, y=0, z=0, c=tocolor(75, 11, 20, 255)},
	{x=0, y=0, z=0, c=tocolor(75, 11, 20, 255)},
	{x=0, y=0, z=0, c=tocolor(75, 11, 20, 255)}
}

HealthBarInnerVertices =
{
	{x=0, y=0, z=0, c=tocolor(185, 34, 40, 255)},
	{x=0, y=0, z=0, c=tocolor(185, 34, 40, 255)},
	{x=0, y=0, z=0, c=tocolor(185, 34, 40, 255)},
	{x=0, y=0, z=0, c=tocolor(185, 34, 40, 255)}
}

function applyColorAlpha(color,alpha)
	if color < 0 then
		color = 0x100000000+color
	end
	local rgb = color%0x1000000
	local a = (color-rgb)/0x1000000*alpha
	a = a-a%1
	return rgb+a*0x1000000
end

function drawNameTag(position, nameText, health, armor, distance)
	position.z = (distance * 0.025) + position.z + 0.3

	local screenCoordsX, screenCoordsY = getScreenFromWorldPosition(position.x, position.y, position.z)

	if not screenCoordsX then
		return
	end

	local rect = {left = screenCoordsX, top = screenCoordsY, right = screenCoordsX+1, bottom = screenCoordsY+1}
	local textSizeX, textSizeY = dxGetTextSize(nameText, 0, 1, 1, font)

	rect.left = rect.left - (textSizeX/2)

	--doOutline(nameText, 1, 1, rect.left, rect.top)
	dxDrawText(
		nameText, rect.left + 1, rect.top, rect.right, rect.bottom,
		tocolor( 0, 0, 0, 255 ), 1, 1,

		font, "left", "top", false, false,
		false, false, false,
		0, 0, 0
	)

	dxDrawText(
		nameText, rect.left - 1, rect.top, rect.right, rect.bottom,
		tocolor( 0, 0, 0, 255 ), 1, 1,

		font, "left", "top", false, false,
		false, false, false,
		0, 0, 0
	)

	dxDrawText(
		nameText, rect.left, rect.top - 1, rect.right, rect.bottom,
		tocolor( 0, 0, 0, 255 ), 1, 1,

		font, "left", "top", false, false,
		false, false, false,
		0, 0, 0
	)

	dxDrawText(
		nameText, rect.left, rect.top +1, rect.right, rect.bottom,
		tocolor( 0, 0, 0, 255 ), 1, 1,

		font, "left", "top", false, false,
		false, false, false,
		0, 0, 0
	)

	dxDrawText(
		nameText, rect.left, rect.top, rect.right, rect.bottom,
		tocolor( 255, 255, 255, 255 ), 1, 1,

		font, "left", "top", false, false,
		false, false, false,
		0, 0, 0
	)

	HealthBarBorderVertices[1].x = screenCoordsX - 20 -- Top left
	HealthBarBorderVertices[1].y = screenCoordsY + 18
	HealthBarBorderVertices[2].x = screenCoordsX - 20 -- Bottom left
	HealthBarBorderVertices[2].y = screenCoordsY + 24
	HealthBarBorderVertices[3].x = screenCoordsX + 21 -- Bottom right
	HealthBarBorderVertices[3].y = screenCoordsY + 24
	HealthBarBorderVertices[4].x = screenCoordsX + 21 -- Top Right
	HealthBarBorderVertices[4].y = screenCoordsY + 18

	HealthBarInnerVertices[1].x = screenCoordsX - 19 -- Top left
	HealthBarInnerVertices[1].y = screenCoordsY + 19
	HealthBarInnerVertices[2].x = screenCoordsX - 19 -- Bottom left
	HealthBarInnerVertices[2].y = screenCoordsY + 23
	HealthBarInnerVertices[3].x = screenCoordsX + 19 -- Bottom right
	HealthBarInnerVertices[3].y = screenCoordsY + 23
	HealthBarInnerVertices[4].x = screenCoordsX + 19 -- Top Right
	HealthBarInnerVertices[4].y = screenCoordsY + 19

	HealthBarBackgroundVertices[1].x = HealthBarInnerVertices[1].x
	HealthBarBackgroundVertices[1].y = HealthBarInnerVertices[1].y
	HealthBarBackgroundVertices[2].x = HealthBarInnerVertices[2].x
	HealthBarBackgroundVertices[2].y = HealthBarInnerVertices[2].y
	HealthBarBackgroundVertices[3].x = HealthBarInnerVertices[3].x
	HealthBarBackgroundVertices[3].y = HealthBarInnerVertices[3].y
	HealthBarBackgroundVertices[4].x = HealthBarInnerVertices[4].x
	HealthBarBackgroundVertices[4].y = HealthBarInnerVertices[4].y

	if health > 100 then
		health = 100
	end
	health = health / 2.6
	health = health - 19

	HealthBarInnerVertices[3].x = screenCoordsX + health -- Bottom right
	HealthBarInnerVertices[4].x = screenCoordsX + health -- Top Right

	if armor > 0 then
		for i = 1,4 do
			HealthBarBorderVertices[i].y = HealthBarBorderVertices[i].y + 8
			HealthBarBackgroundVertices[i].y = HealthBarBackgroundVertices[i].y + 8
			HealthBarInnerVertices[i].y = HealthBarInnerVertices[i].y + 8
		end
	end

	local healthBarBordersDxVertices = {}
	local healthBarBackgroundDxVertices = {}
	local healthBarInnerDxVertices = {}
	for i = 1,4 do
		table.insert(healthBarBordersDxVertices, {HealthBarBorderVertices[i].x, HealthBarBorderVertices[i].y, HealthBarBorderVertices[i].c})
		table.insert(healthBarBackgroundDxVertices, {HealthBarBackgroundVertices[i].x, HealthBarBackgroundVertices[i].y, HealthBarBackgroundVertices[i].c})
		table.insert(healthBarInnerDxVertices, {HealthBarInnerVertices[i].x, HealthBarInnerVertices[i].y, HealthBarInnerVertices[i].c})
	end

	dxDrawPrimitive("trianglefan", false, unpack(healthBarBordersDxVertices))
	dxDrawPrimitive("trianglefan", false, unpack(healthBarBackgroundDxVertices))
    dxDrawPrimitive("trianglefan", false, unpack(healthBarInnerDxVertices))
    
    -- Armor Bar
	if armor > 0 then
		for i = 1,4 do
			HealthBarBorderVertices[i].y = HealthBarBorderVertices[i].y - 8
			HealthBarBackgroundVertices[i].y = HealthBarBackgroundVertices[i].y - 8
			HealthBarInnerVertices[i].y = HealthBarInnerVertices[i].y - 8
        end

        for i = 1,4 do
			HealthBarInnerVertices[i].c = tocolor(200, 200, 200, 255)
			HealthBarBackgroundVertices[i].c = tocolor(40, 40, 40, 255)
		end

		if armor > 100 then
            armor = 100
        end
		armor = armor / 2.6
		armor = armor - 19

		HealthBarInnerVertices[3].x = screenCoordsX + armor -- Bottom right
        HealthBarInnerVertices[4].x = screenCoordsX + armor -- Top Right

		local armorBarBordersDxVertices = {}
		local armorBarBackgroundDxVertices = {}
		local armorBarInnerDxVertices = {}
		for i = 1,4 do
			table.insert(armorBarBordersDxVertices, {HealthBarBorderVertices[i].x, HealthBarBorderVertices[i].y, HealthBarBorderVertices[i].c})
			table.insert(armorBarBackgroundDxVertices, {HealthBarBackgroundVertices[i].x, HealthBarBackgroundVertices[i].y, HealthBarBackgroundVertices[i].c})
			table.insert(armorBarInnerDxVertices, {HealthBarInnerVertices[i].x, HealthBarInnerVertices[i].y, HealthBarInnerVertices[i].c})
		end

		dxDrawPrimitive("trianglefan", false, unpack(armorBarBordersDxVertices))
        dxDrawPrimitive("trianglefan", false, unpack(armorBarBackgroundDxVertices))
        dxDrawPrimitive("trianglefan", false, unpack(armorBarInnerDxVertices))

        for i = 1,4 do
			HealthBarInnerVertices[i].c = tocolor(185, 34, 40, 255)
			HealthBarBackgroundVertices[i].c = tocolor(75, 11, 20, 255)
		end
	end
end

addEventHandler( "onClientRender", root,
	function()
		local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
		for k, player in pairs( getElementsByType("player") ) do
			if player ~= localPlayer and isElementOnScreen( player ) then
				--local fPosX, fPosY, fPosZ = getElementPosition(player)
				local fPosX, fPosY, fPosZ = getPedBonePosition(player, 8)
				local distance = getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, fPosX, fPosY, fPosZ)
				if distance < 45 then
					local cx,cy,cz = getCameraMatrix(localPlayer)
					if isLineOfSightClear(cx,cy,cz, fPosX, fPosY, fPosZ, true, true, false, true, true, false, false) then
						drawNameTag({x = fPosX, y = fPosY, z = fPosZ}, getPlayerName(player) .. " (" .. getElemID(player) .. ")", getElementHealth(player), getPedArmor(player), distance)
					end
				end
			end
		end
	end
)
