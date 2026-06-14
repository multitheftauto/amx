local SPECIAL_ACTION_NONE = 0
local SPECIAL_ACTION_DUCK = 1
local SPECIAL_ACTION_USEJETPACK = 2
local SPECIAL_ACTION_DANCE1 = 5
local SPECIAL_ACTION_DANCE2 = 6
local SPECIAL_ACTION_DANCE3 = 7
local SPECIAL_ACTION_DANCE4 = 8
local SPECIAL_ACTION_HANDSUP = 10
local SPECIAL_ACTION_USECELLPHONE = 11
local SPECIAL_ACTION_STOPUSECELLPHONE = 13
local SPECIAL_ACTION_DRINK_BEER = 20
local SPECIAL_ACTION_SMOKE_CIGGY = 21
local SPECIAL_ACTION_DRINK_WINE = 22
local SPECIAL_ACTION_DRINK_SPRUNK = 23
local SPECIAL_ACTION_CARRY = 25
local SPECIAL_ACTION_PISSING = 68

local drinkData = {
	[SPECIAL_ACTION_DRINK_BEER] = {
		model = 1543,
		offset = { x = 0.05, y = 0.02, z = -0.3 }
	},
	[SPECIAL_ACTION_SMOKE_CIGGY] = {
		model = 1485,
		offset = { x = 0.0, y = 0.0, z = 0.0 }
	},
	[SPECIAL_ACTION_DRINK_WINE] = {
		model = 1486,
		offset = { x = 0.05, y = 0.02, z = -0.05 }
	},
	[SPECIAL_ACTION_DRINK_SPRUNK] = {
		model = 1546,
		offset = { x = 0.03, y = 0.04, z = -0.01 }
	}
}

local danceStyles = {
	[SPECIAL_ACTION_DANCE1] = { group = 'wop', idle = 'dance_loop' },
	[SPECIAL_ACTION_DANCE2] = { group = 'gfunk', idle = 'dance_loop' },
	[SPECIAL_ACTION_DANCE3] = { group = 'runningman', idle = 'dance_loop' },
	[SPECIAL_ACTION_DANCE4] = { group = 'strip', idle = 'str_loop_b' }
}

local danceMoves = {
	male = {
		'dance_b1', 'dance_b2', 'dance_b3', 'dance_b4',
		'dance_b5', 'dance_b6', 'dance_b7', 'dance_b8',
		'dance_b9', 'dance_b10', 'dance_b11', 'dance_b12',
		'dance_b13', 'dance_b14', 'dance_b15', 'dance_b16'
	},
	female = {
		'dance_g1', 'dance_g2', 'dance_g3', 'dance_g4',
		'dance_g5', 'dance_g6', 'dance_g7', 'dance_g8',
		'dance_g9', 'dance_g10', 'dance_g11', 'dance_g12',
		'dance_g13', 'dance_g14', 'dance_g15', 'dance_g16'
	},
	strip = {
		'strip_a', 'strip_b', 'strip_c', 'strip_d',
		'strip_e', 'strip_f', 'strip_g', 'str_a2b',
		'str_b2a', 'str_b2c', 'str_c1', 'str_c2',
		'str_c2b', 'str_a2b', 'str_b2c', 'str_c2'
	}
}

-- list of MTA female skins
local femaleSkins = {
	6, 9, 10, 11, 12, 13, 31, 38, 39, 40, 41, 53, 54,
	55, 56, 63, 64, 69, 75, 76, 77, 85, 86, 87, 88, 89,
	90, 91, 92, 93, 129, 130, 131, 138, 139, 140, 141,
	145, 148, 150, 151, 152, 157, 169, 172, 178, 190,
	191, 192, 193, 194, 195, 196, 197, 198, 199, 201,
	205, 207, 211, 214, 215, 216, 218, 219, 224, 225,
	226, 231, 232, 233, 237, 238, 243, 244, 245, 246,
	251, 256, 257, 263, 298, 304
}
local femaleSkinSet = {}
for _, id in ipairs(femaleSkins) do
	femaleSkinSet[id] = true
end

local lastDanceMove = {}
local lastDanceAnim = {}

local playerAction = {}

local drinkObject = {}
local jetEffect = {}

function isFemaleSkin(skinID)
	return femaleSkinSet[skinID] or false
end

function resetSpecialAction(player)
	player = player or localPlayer
	local isLocal = (player == localPlayer)

	local currentAction = playerAction[player] or SPECIAL_ACTION_NONE
	if currentAction == SPECIAL_ACTION_NONE then return end

	if isLocal then
		toggleControl('fire', true)
		toggleControl('aim_weapon', true)
		toggleControl('jump', true)
		toggleControl('sprint', true)
		toggleControl('crouch', true)
	end

	if currentAction >= SPECIAL_ACTION_DANCE1 and currentAction <= SPECIAL_ACTION_DANCE4 then
		if isLocal then removeEventHandler('onClientRender', root, processDance) end

		lastDanceAnim[player] = nil
		lastDanceMove[player] = nil
	elseif currentAction >= SPECIAL_ACTION_DRINK_BEER and currentAction <= SPECIAL_ACTION_DRINK_SPRUNK then
		if isLocal then unbindKey('fire', 'down', onDrinkKey) end

		if isElement(drinkObject[player]) then
			destroyElement(drinkObject[player])
		end
		drinkObject[player] = nil
	end

	if isElement(jetEffect[player]) then
		destroyElement(jetEffect[player])
	end
	jetEffect[player] = nil

	setPedAnimation(player, false)
	playerAction[player] = SPECIAL_ACTION_NONE
end

function onDrinkKey(key, keyState)
	local group, name = getPedAnimation(localPlayer)
	local currentAction = playerAction[localPlayer] or SPECIAL_ACTION_NONE

	-- player should hold a drink in hands instead of any weapon
	setPedWeaponSlot(localPlayer, 0)

	if currentAction == SPECIAL_ACTION_SMOKE_CIGGY then
		if name == 'smkcig_prtl' then return end
		setPedAnimation(localPlayer, 'gangs', 'smkcig_prtl', -1, false, true, false, false, 250, true)
	else
		if name == 'dnk_stndm_loop' or name == 'dnk_stndf_loop' then return end
		if isFemaleSkin(getElementModel(localPlayer)) then
			setPedAnimation(localPlayer, 'bar', 'dnk_stndf_loop', -1, false, true, false, false, 250, true)
		else
			setPedAnimation(localPlayer, 'bar', 'dnk_stndm_loop', -1, false, true, false, false, 250, true)
		end
	end

	-- request to add drunk camera effects
	triggerServerEvent('onDrunkLevelRequest', localPlayer)
end

function applyRemoteDrinkAnim(player)
	local currentAction = playerAction[player] or SPECIAL_ACTION_NONE
	if currentAction < SPECIAL_ACTION_DRINK_BEER or currentAction > SPECIAL_ACTION_DRINK_SPRUNK then return end

	if currentAction == SPECIAL_ACTION_SMOKE_CIGGY then
		setPedAnimation(player, 'gangs', 'smkcig_prtl', -1, false, true, false, false, 250, true)
	elseif isFemaleSkin(getElementModel(player)) then
		setPedAnimation(player, 'bar', 'dnk_stndf_loop', -1, false, true, false, false, 250, true)
	else
		setPedAnimation(player, 'bar', 'dnk_stndm_loop', -1, false, true, false, false, 250, true)
	end
end

function processDance()
	local up = getPedControlState('forwards')
	local down = getPedControlState('backwards')
	local left = getPedControlState('left')
	local right = getPedControlState('right')

	local upDown = 0
	if up and not down then
		upDown = 1
	elseif down and not up then
		upDown = -1
	end

	local leftRight = 0
	if right and not left then
		leftRight = 1
	elseif left and not right then
		leftRight = -1
	end

	local move = nil
	if upDown > 0 and leftRight == 0 then
		move = 1 -- up
	elseif upDown < 0 and leftRight == 0 then
		move = 2 -- down
	elseif upDown == 0 and leftRight < 0 then
		move = 3 -- left
	elseif upDown == 0 and leftRight > 0 then
		move = 4 -- right
	elseif upDown > 0 and leftRight < 0 then
		move = 5 -- up / left
	elseif upDown > 0 and leftRight > 0 then
		move = 6 -- up / right
	elseif upDown < 0 and leftRight < 0 then
		move = 7 -- down / left
	elseif upDown < 0 and leftRight > 0 then
		move = 8 -- down / right
	end

	local currentAction = playerAction[localPlayer] or SPECIAL_ACTION_NONE

	if not move then
		if not lastDanceMove[localPlayer] then return end

		local anim = danceStyles[currentAction]
		setPedAnimation(localPlayer, anim.group, anim.idle, -1, true, false, false, false, 250, false)

		lastDanceAnim[localPlayer] = nil
		lastDanceMove[localPlayer] = nil

		triggerServerEvent('onDanceMoveRequest', localPlayer, nil)
	else
		if getPedControlState('sprint') then
			move = move + 8
		end

		if move ~= lastDanceMove[localPlayer] then
			local animName = danceMoves.male[move]
			local animGroup = danceStyles[currentAction].group

			if currentAction == SPECIAL_ACTION_DANCE4 then
				animName = danceMoves.strip[move]
			elseif isFemaleSkin(getElementModel(localPlayer)) then
				animName = danceMoves.female[move]
			end

			setPedAnimation(localPlayer, animGroup, animName, -1, false, false, false, false, 250, false)
			lastDanceAnim[localPlayer] = { group = animGroup, name = animName }

			triggerServerEvent('onDanceMoveRequest', localPlayer, move)
		elseif lastDanceAnim[localPlayer] then
			local group, name = getPedAnimation(localPlayer)

			if group ~= lastDanceAnim[localPlayer].group or name ~= lastDanceAnim[localPlayer].name then
				local anim = danceStyles[currentAction]

				setPedAnimation(localPlayer, anim.group, anim.idle, -1, true, false, false, false, 250, false)
				lastDanceAnim[localPlayer] = nil

				triggerServerEvent('onDanceMoveRequest', localPlayer, nil)
			end
		end
		lastDanceMove[localPlayer] = move
	end
end

function applyRemoteDanceMove(player, move)
	local currentAction = playerAction[player] or SPECIAL_ACTION_NONE
	if currentAction < SPECIAL_ACTION_DANCE1 or currentAction > SPECIAL_ACTION_DANCE4 then return end

	if not move then
		local anim = danceStyles[currentAction]
		setPedAnimation(player, anim.group, anim.idle, -1, true, false, false, false, 250, false)
		return
	end

	local animName = danceMoves.male[move]
	local animGroup = danceStyles[currentAction].group

	if currentAction == SPECIAL_ACTION_DANCE4 then
		animName = danceMoves.strip[move]
	elseif isFemaleSkin(getElementModel(player)) then
		animName = danceMoves.female[move]
	end

	setPedAnimation(player, animGroup, animName, -1, false, false, false, false, 250, false)
end

function handleSpecialAction(player, action)
	player = player or localPlayer
	local currentAction = playerAction[player] or SPECIAL_ACTION_NONE
	local isLocal = (player == localPlayer)

	if currentAction ~= SPECIAL_ACTION_USECELLPHONE and
	   currentAction ~= SPECIAL_ACTION_CARRY then
		resetSpecialAction(player)
	else
		if isLocal then
			toggleControl('fire', true)
			toggleControl('aim_weapon', true)
			toggleControl('jump', true)
			toggleControl('sprint', true)
			toggleControl('crouch', true)
		end

		if currentAction == SPECIAL_ACTION_USECELLPHONE and action == SPECIAL_ACTION_NONE then
			-- stop using cellphone with extra animation
			setPedAnimation(player, 'ped', 'phone_out', -1, false, true, false, false, 250, true)
		elseif action == SPECIAL_ACTION_NONE or
		       (action >= SPECIAL_ACTION_DRINK_BEER and action <= SPECIAL_ACTION_DRINK_SPRUNK) then
			-- tricks to properly stop such looping animations
			setPedAnimation(player, 'fat', 'fatidle', 1, false, false, true, false, 250, true)
			setTimer(setPedAnimation, 10, 1, player, false)
		end
	end

	if action >= SPECIAL_ACTION_DANCE1 and action <= SPECIAL_ACTION_DANCE4 then
		local anim = danceStyles[action]
		setPedAnimation(player, anim.group, anim.idle, -1, true, false, false, false, 250, false)

		if isLocal then addEventHandler('onClientRender', root, processDance) end
	elseif action == SPECIAL_ACTION_HANDSUP then
		setPedAnimation(player, 'ped', 'handsup', -1, false, false, false, true, 250, false)
	elseif action == SPECIAL_ACTION_USECELLPHONE or action == SPECIAL_ACTION_CARRY then
		if isLocal then
			toggleControl('fire', false)
			toggleControl('aim_weapon', false)
			toggleControl('jump', false)
			toggleControl('sprint', false)
			toggleControl('crouch', false)
		end

		if action == SPECIAL_ACTION_USECELLPHONE then
			setPedAnimation(player, 'ped', 'phone_in', 1, false, true, false, true, 250, true)
		else
			setPedAnimation(player, 'carry', 'crry_prtial', 1, true, true, false, true, 250, true)
		end
	elseif action >= SPECIAL_ACTION_DRINK_BEER and action <= SPECIAL_ACTION_DRINK_SPRUNK then
		if isLocal then
			toggleControl('fire', false)
			bindKey('fire', 'down', onDrinkKey)
		end

		-- player should hold a drink in hands instead of any weapon
		setPedWeaponSlot(player, 0)

		local data = drinkData[action]

		drinkObject[player] = createObject(data.model, 0.0, 0.0, 0.0)
		if drinkObject[player] then
			attachElementToBone(drinkObject[player], player, 24, data.offset.x, data.offset.y, data.offset.z, 0.0, 0.0, 0.0)
		end
	elseif action == SPECIAL_ACTION_PISSING then
		setPedAnimation(player, 'paulnmac', 'piss_loop', -1, true, false, false, false, 250, false)

		-- how could we do without a strong jet?
		jetEffect[player] = createEffect('petrolcan', 0.0, 0.0, 0.0)
		if jetEffect[player] then
			attachElementToBone(jetEffect[player], player, 2, -0.1, 0.2, 0.0, 270.0, 0.0, 0.0)
		end
	end
	playerAction[player] = action
end

addEventHandler('onClientPlayerWeaponSwitch', localPlayer,
	function(prev, current)
		local currentAction = playerAction[localPlayer] or SPECIAL_ACTION_NONE
		if currentAction >= SPECIAL_ACTION_DRINK_BEER and currentAction <= SPECIAL_ACTION_DRINK_SPRUNK then
			-- as we set weapon to 0 previously, don't let switching
			if getSlotFromWeapon(current) ~= 0 then cancelEvent() end
		end
	end
)

addEventHandler('onClientElementDataChange', root,
	function(key, oldval, newval)
		if key == 'SpecialAction' then
			handleSpecialAction(source, newval or SPECIAL_ACTION_NONE)
		elseif key == 'DanceMove' and source ~= localPlayer then
			applyRemoteDanceMove(source, newval)
		elseif key == 'DrinkAnim' and source ~= localPlayer then
			applyRemoteDrinkAnim(source)
		end
	end
)

-- unbind keys, destroy temp objects
addEventHandler('onClientPlayerSpawn', root,
	function()
		resetSpecialAction(source)
	end
)

addEventHandler('onClientPlayerWasted', root,
	function()
		resetSpecialAction(source)
	end
)

addEventHandler('onClientResourceStop', resourceRoot,
	function()
		for player, _ in pairs(playerAction) do
			resetSpecialAction(player)
		end
	end
)

addEventHandler('onClientPlayerQuit', root,
	function()
		resetSpecialAction(source)
		playerAction[source] = nil

		drinkObject[source] = nil
		jetEffect[source] = nil

		lastDanceMove[source] = nil
		lastDanceAnim[source] = nil
	end
)
