g_WeaponIDMapping = setmetatable({
	[330] = 0,	-- Melee
	[331] = 1,	-- Brass knuckles
	[333] = 2,	-- Golf club
	[334] = 3,	-- Nightstick
	[335] = 4,	-- Knife
	[336] = 5,	-- Baseball bat
	[337] = 6,	-- Shovel
	[338] = 7,	-- Pool cue
	[339] = 8,	-- Katana
	[341] = 9,	-- Chainsaw
	[321] = 10,	-- Purple dildo
	[322] = 11,	-- Short dildo
	[323] = 12,	-- Vibrator
	[324] = 13,	-- Silver vibrator
	[325] = 14,	-- Flowers
	[326] = 15,	-- Cane
	[342] = 16,	-- Grenade
	[343] = 17,	-- Tear gas
	[344] = 18,	-- Molotov
	[346] = 22,	-- Pistol
	[347] = 23,	-- Silenced
	[348] = 24,	-- Desert eagle
	[349] = 25,	-- Shotgun
	[350] = 26,	-- Sawnoff
	[351] = 27,	-- Combat shotgun
	[352] = 28,	-- Uzi
	[353] = 29,	-- MP5
	[355] = 30,	-- AK47
	[356] = 31,	-- M4
	[372] = 32,	-- Tec9
	[357] = 33,	-- Country sniper
	[358] = 34,	-- Sniper rifle
	[359] = 35,	-- Rocket launcher
	[360] = 36,	-- Heatseaking rocket launcher
	[361] = 37,	-- Flamethrower
	[362] = 38,	-- Minigun
	[363] = 39,	-- Satchel
	[364] = 40,	-- Detonator
	[365] = 41,	-- Spray can
	[366] = 42,	-- Fire extinguisher
	[367] = 43,	-- Camera
	[368] = 44,	-- Night vision
	[369] = 45,	-- Infrared
	[371] = 46	-- Parachute
}, {
	__index = function(t, k)
		if k >= 0 and k <= 46 then
			return k
		end
	end
})

g_CommandMapping = setmetatable({
	['?']     = 'help',
	['auth']  = 'login',
	['speak'] = 'say',
	['leave'] = 'exit',
	['out']   = 'quit',
	['mstart'] = 'start',
	['mstop'] = 'stop',
	['reg'] = 'register'
}, {
	__index = function(t, k)
		return table.find(t, k) or nil
	end
})

local controlMappingMT = {
	__index = function(t, k)
		for samp, mta in pairs(t) do
			if type(mta) == 'table' then
				if table.find(mta, k) then
					return samp
				end
			elseif mta == k then
				return samp
			end
		end
	end
}

g_KeyMapping = setmetatable({
	[1] = 'action',
	[2 ^ 1] = { 'crouch', 'horn' },
	[2 ^ 2] = { 'fire', 'vehicle_fire' },
	[2 ^ 3] = 'sprint',
	[2 ^ 4] = { 'enter_exit', 'vehicle_secondary_fire' },
	[2 ^ 5] = 'jump',
	[2 ^ 6] = 'vehicle_look_right',
	[2 ^ 7] = { 'handbrake', 'aim_weapon' },
	[2 ^ 8] = 'vehicle_look_left',
	[2 ^ 9] = { 'look_behind', 'sub_mission' },
	[2 ^ 10] = 'walk',
	[2 ^ 11] = 'special_control_up',
	[2 ^ 12] = 'special_control_down',
	[2 ^ 13] = 'special_control_left',
	[2 ^ 14] = 'special_control_right',
	[2 ^ 15] = 'not_used',
	[2 ^ 16] = 'conversation_yes',
	[2 ^ 17] = 'conversation_no',
	[2 ^ 18] = 'group_control_back',
	[2 ^ 19] = 'enter_passenger' -- This one's undefined
}, controlMappingMT)

g_LeftRightMapping = setmetatable({
	[-128] = { 'left', 'vehicle_left' },
	[128] = { 'right', 'vehicle_right' }
}, controlMappingMT)

g_UpDownMapping = setmetatable({
	[-128] = { 'forwards', 'accelerate' },
	[128] = { 'backwards', 'brake_reverse' }
}, controlMappingMT)

g_DamageTypes = {
	[19] = 51,	-- Rocket
	[59] = 51,	-- Tank Grenade
	[63] = 255	-- Blown
}

g_PickupAmmo = {
	[16] = 8,	-- Grenade
	[17] = 8,	-- Tear gas
	[18] = 8,	-- Molotov
	[22] = 30,	-- Pistol
	[23] = 10,	-- Silenced
	[24] = 10,	-- Desert eagle
	[25] = 15,	-- Shotgun
	[26] = 10,	-- Sawnoff
	[27] = 10,	-- Combat shotgun
	[28] = 60,	-- Uzi
	[29] = 60,	-- MP5
	[30] = 80,	-- AK47
	[31] = 80,	-- M4
	[32] = 60,	-- Tec9
	[33] = 20,	-- Country sniper
	[34] = 10,	-- Sniper rifle
	[35] = 4,	-- Rocket launcher
	[36] = 3,	-- Heatseaking rocket launcher
	[37] = 100,	-- Flamethrower
	[38] = 500,	-- Minigun
	[39] = 5,	-- Satchel
	[41] = 500,	-- Spray can
	[42] = 500,	-- Fire extinguisher
	[43] = 36	-- Camera
}

g_RCVehicles = {
	[441] = true,
	[464] = true,
	[465] = true,
	[501] = true,
	[564] = true
}

g_PoliceVehicles = {
	[416] = true,
	[433] = true,
	[427] = true,
	[470] = true,
	[490] = true,
	[528] = true,
	[596] = true,
	[597] = true,
	[598] = true,
	[599] = true,
	[601] = true
}

g_SkinReplace = {
	[3] = 303,	-- andre
	[4] = 310,	-- bbthin
	[6] = 302,	-- emmet
	[8] = 309,	-- janitor
	[42] = 305,	-- jethro
	[65] = 304,	-- kendl
	[74] = 0,	-- unused
	[86] = 301,	-- ryder3
	[119] = 308,	-- sindaco
	[149] = 311,	-- smokev
	[208] = 42,	-- suzie
	[273] = 307,	-- tbone
	[289] = 306,	-- zero
	[300] = 280,	-- lapd1
	[301] = 281,	-- sfpd1
	[302] = 282,	-- lvpd1
	[303] = 280,	-- lapd1
	[304] = 280,	-- lapd1
	[305] = 282,	-- lvpd1
	[306] = 211,	-- wfyclot
	[307] = 11,	-- vbfycrp
	[308] = 211,	-- wfyclot
	[309] = 211,	-- wfyclot
	[310] = 283,	-- csher
	[311] = 288	-- dsher
}

-- Left is SA-MP, right is MTA
g_BoneMapping = setmetatable({
	[1] = 3,	-- Spine
	[2] = 8,	-- Head
	[3] = 32,	-- Left upper arm
	[4] = 22,	-- Right upper arm
	[5] = 34,	-- Left hand
	[6] = 24,	-- Right hand
	[7] = 41,	-- Left thigh (SA-MP doesn't really have hips)
	[8] = 51,	-- Right thigh
	[9] = 43,	-- Left foot
	[10] = 53,	-- Right foot
	[11] = 52,	-- Right calf
	[12] = 42,	-- Left calf
	[13] = 33,	-- Left forearm
	[14] = 23,	-- Right forearm
	[15] = 31,	-- Left clavicle
	[16] = 21,	-- Right clavicle
	[17] = 4	-- Neck
}, {
	__index = function(t, k)
		if k == 18 then -- Since 18 is jaw in SA-MP
			k = 8 -- Default to head
		end
		if k >= 1 and k <= 17 then
			return k
		end
	end
})

PLAYER_STATE_NONE = 0
PLAYER_STATE_ONFOOT = 1
PLAYER_STATE_DRIVER = 2
PLAYER_STATE_PASSENGER = 3
PLAYER_STATE_WASTED = 7
PLAYER_STATE_SPAWNED = 8
PLAYER_STATE_SPECTATING = 9

SPECIAL_ACTION_NONE = 0
SPECIAL_ACTION_DUCK = 1
SPECIAL_ACTION_USEJETPACK = 2
SPECIAL_ACTION_DANCE1 = 5
SPECIAL_ACTION_DANCE2 = 6
SPECIAL_ACTION_DANCE3 = 7
SPECIAL_ACTION_DANCE4 = 8
SPECIAL_ACTION_HANDSUP = 10
SPECIAL_ACTION_USECELLPHONE = 11
SPECIAL_ACTION_STOPUSECELLPHONE = 13
SPECIAL_ACTION_DRINK_BEER = 20
SPECIAL_ACTION_SMOKE_CIGGY = 21
SPECIAL_ACTION_DRINK_WINE = 22
SPECIAL_ACTION_DRINK_SPRUNK = 23
SPECIAL_ACTION_PISSING = 68

g_SpecialActions = {
	[SPECIAL_ACTION_NONE] = true,
	[SPECIAL_ACTION_USEJETPACK] = true,
	[SPECIAL_ACTION_DANCE1] = true,
	[SPECIAL_ACTION_DANCE2] = true,
	[SPECIAL_ACTION_DANCE3] = true,
	[SPECIAL_ACTION_DANCE4] = true,
	[SPECIAL_ACTION_HANDSUP] = true,
	[SPECIAL_ACTION_USECELLPHONE] = true,
	[SPECIAL_ACTION_STOPUSECELLPHONE] = true,
	[SPECIAL_ACTION_DRINK_BEER] = true,
	[SPECIAL_ACTION_SMOKE_CIGGY] = true,
	[SPECIAL_ACTION_DRINK_WINE] = true,
	[SPECIAL_ACTION_DRINK_SPRUNK] = true,
	[SPECIAL_ACTION_PISSING] = true
}

PLAYER_VARTYPE_NONE = 0
PLAYER_VARTYPE_INT = 1
PLAYER_VARTYPE_STRING = 2
PLAYER_VARTYPE_FLOAT = 3

SERVER_VARTYPE_NONE = 0
SERVER_VARTYPE_INT = 1
SERVER_VARTYPE_STRING = 2
SERVER_VARTYPE_FLOAT = 3

INVALID_ACTOR_ID = 0xFFFF
INVALID_OBJECT_ID = 0xFFFF
INVALID_PLAYER_ID = 0xFFFF
INVALID_VEHICLE_ID = 0xFFFF

ManualVehEngineAndLights = false
ShowUnimplementedErrors = false

-- Just add <setting name="amx.debug" value="true"></setting> in settings.xml
-- if you want to see debug infromation
if get('amx.debug') == 'true' then
	ShowUnimplementedErrors = true
end
