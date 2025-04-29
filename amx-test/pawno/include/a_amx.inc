/*  MTA AMX compatibility layer
 *
 *  Extension functions
 */

#if defined _amx_included
	#endinput
#endif
#define _amx_included

// MTA
native lua(const fn[], {Float,_}:...);
native amxRegisterPawnPrototypes(const prototype[][]);
native amxVersionString(buffer[], maxsize = sizeof(buffer));
native amxVersion(&Float:ver);

// Events
forward OnBotConnect(botid, name[]);
forward OnBotEnterVehicle(botid, vehicleid, ispassenger);
forward OnBotExitVehicle(botid, vehicleid);
forward OnBotDeath(botid, killerid, weaponid, bodypart);
forward OnBotStateChange(botid, newstate, oldstate);
forward OnMarkerCreate(markerid);
forward OnMarkerHit(markerid, hittype[], hitid, worldid);
forward OnMarkerLeave(markerid, type[], id, worldid);
forward OnPlayerClickWorld(playerid, button, updown, worldX, worldY, worldZ);
forward OnPlayerClickWorldPlayer(playerid, button, updown, clickedid, worldX, worldY, worldZ);
forward OnPlayerClickWorldObject(playerid, button, updown, clickedid, worldX, worldY, worldZ);
forward OnPlayerClickWorldVehicle(playerid, button, updown, clickedid, worldX, worldY, worldZ);
forward OnPlayerWeaponSwitch(playerid, oldweaponid, newweaponid);
forward OnPlayerKeyDown(playerid, key);
forward OnPlayerKeyUp(playerid, key);

// World
native Float:GetGameSpeed();
native SetGameSpeed(Float:speed);
native GetSkyGradient(&topRed, &topGreen, &topBlue, &bottomRed, &bottomGreen, &bottomBlue);
native SetSkyGradient(topRed = 0, topGreen = 0, topBlue = 0, bottomRed = 0, bottomGreen = 0, bottomBlue = 0);
native ResetSkyGradient();
native GetCloudsEnabled();
native SetCloudsEnabled(enable);
native GetInteriorSoundsEnabled();
native SetInteriorSoundsEnabled(enable);
native IsGarageOpen(garageid);
native SetGarageOpen(garageid, open);
native IsGlitchEnabled(name[]);
native SetGlitchEnabled(name[], enable);
native GetFPSLimit();
native SetFPSLimit(fps);
native GetRandomPlayer();
native GetPlayerCount();

// Water
native Float:GetWaveHeight();
native SetWaveHeight(Float:height);
native SetWaterLevel(Float:level);

// Pickups
native GetPickupType(pickupid);
native SetPickupType(pickupid, type, model, ammo = 500);
native GetPickupAmount(pickupid);
native GetPickupWeapon(pickupid);
native GetPickupAmmo(pickupid);

// Native Markers
native CreateMarker(Float:X, Float:Y, Float:Z, type[], Float:size, red, green, blue, alpha);
native DestroyMarker(markerid);
native GetMarkerColor(markerid, colorid); // Color IDs: 0 = Red, 1 = Green, 2 = Blue, 3 = Alpha
native GetMarkerIcon(markerid); // 0 = No icon, 1 = Arrow, 2 = Race finish
native GetMarkerSize(markerid, &Float:size);
native GetMarkerTarget(markerid, &Float:X, &Float:Y, &Float:Z);
native GetMarkerType(markerid); // 0 = Checkpoint, 1 = Ring, 2 = Cylinder, 3 = Arrow, 4 = Corona
native SetMarkerColor(markerid, red, green, blue, alpha);
native SetMarkerIcon(markerid, iconid); // 0 = No icon, 1 = Arrow, 2 = Race finish
native SetMarkerSize(markerid, Float:size);
native SetMarkerTarget(markerid, Float:X, Float:Y, Float:Z);
native SetMarkerType(markerid, type); // 0 = Checkpoint, 1 = Ring, 2 = Cylinder, 3 = Arrow, 4 = Corona
native IsPlayerInMarker(markerid, playerid);
native IsBotInMarker(markerid, botid);
native IsVehicleInMarker(markerid, vehicleid);

// Rules
native IsValidServerRule(name[]);
native GetServerRule(name[], buf[], bufsize = sizeof(buf));
native SetServerRule(name[], value[]);
native RemoveServerRule(name[]);

// Objects
native IsObjectBreakable(objectid);
native SetObjectBreakable(objectid, breakable);
native GetObjectScale(objectid, &Float:X, &Float:Y, &Float:Z);
native SetObjectScale(objectid, Float:X, Float:Y, Float:Z);
native GetObjectAlpha(objectid);
native SetObjectAlpha(objectid, alpha);

// Players
native AddPlayerClothes(playerid, type, index);
native GetPlayerClothes(playerid, type);
native RemovePlayerClothes(playerid, type);
native ShowPlayerMarker(playerid, mode);
native IsPlayerInWater(playerid);
native IsPlayerOnFire(playerid);
native SetPlayerOnFire(playerid, fire);
native IsPlayerDucked(playerid);
native IsPlayerOnGround(playerid);
native IsPlayerChoking(playerid);
native SetPlayerChoking(playerid, choking);
native GetPlayerWalkingStyle(playerid);
native SetPlayerWalkingStyle(playerid, style);
native GetPlayerStat(playerid, statid);
native SetPlayerStat(playerid, statid, Float:value);
native GetPlayerDoingDriveBy(playerid);
native SetPlayerDoingDriveBy(playerid, driveBy);
native GetPlayerCanBeKnockedOffBike(playerid);
native SetPlayerCanBeKnockedOffBike(playerid, knockedOff);
native GetPlayerWeaponSlot(playerid);
native SetPlayerWeaponSlot(playerid, slotid);
native GetPlayerAmmoInClip(playerid);
native IsPlayerHeadless(playerid);
native SetPlayerHeadless(playerid, headState);
native GetPlayerBlurLevel(playerid);
native SetPlayerBlurLevel(playerid, level);
native FadePlayerCamera(playerid, fadeIn, Float:timeToFade = 1.0, red = 0, green = 0, blue = 0);
native SetPlayerControlState(playerid, control[], controlState);
native IsPlayerCursorShowing(playerid);
native ShowPlayerCursor(playerid, show, controls);
native GetPlayerAlpha(playerid);
native SetPlayerAlpha(playerid, alpha);
native RemovePlayerWeapon(playerid, weaponid);
native Float:GetPlayerGravity(playerid);
native SetPlayerGravity(playerid, Float:gravity);
native GetPlayerSkillLevel(playerid, skill);

// Vehicles
native IsVehicleInWater(vehicleid);
native IsVehicleOnGround(vehicleid);
native SetVehicleModel(vehicleid, model);
native GetVehicleMaxPassengers(vehicleid);
native GetVehicleEngineState(vehicleid);
native SetVehicleEngineState(vehicleid, engineState);
native GetVehicleSirenState(vehicleid);
native SetVehicleSirenState(vehicleid, sirenState);
native GetVehicleDoorState(vehicleid, door);
native SetVehicleDoorState(vehicleid, door, doorState);
native GetVehicleLightState(vehicleid, light);
native SetVehicleLightState(vehicleid, light, lightState);
native GetVehicleOverrideLights(vehicleid);
native SetVehicleOverrideLights(vehicleid, override);
native GetVehicleWheelState(vehicleid, wheel);
native SetVehicleWheelState(vehicleid, frontLeft = -1, rearLeft = -1, frontRight = -1, rearRight = -1);
native GetVehiclePanelState(vehicleid, panel);
native SetVehiclePanelState(vehicleid, panel, panelState);
native GetVehicleVariant(vehicleid, &var1, &var2);
native SetVehicleVariant(vehicleid, var1, var2);
native GetVehicleAlpha(vehicleid);
native SetVehicleAlpha(vehicleid, alpha);
native IsTrainDerailable(vehicleid);
native SetTrainDerailable(vehicleid, derailable);
native IsTrainDerailed(vehicleid);
native SetTrainDerailed(vehicleid, derailed);
native GetTrainDirection(vehicleid);
native SetTrainDirection(vehicleid, clockwise);
native GetTrainSpeed(vehicleid, &Float:speed);
native SetTrainSpeed(vehicleid, Float:speed);
native GetVehicleDriver(vehicleid);
native GetVehicleNumberPlate(vehicleid, plate[], len = sizeof(plate));
native GetVehicleColor(vehicleid, &color1, &color2);
native GetVehiclePaintjob(vehicleid);
native GetVehicleInterior(vehicleid);

// Bots
native CreateBot(modelid, Float:x, Float:y, Float:z, name[] = "Bot");
native DestroyBot(botid);
native AddBotClothes(botid, type, index);
native GetBotClothes(botid, type);
native RemoveBotClothes(botid, type);
native IsBotInWater(botid);
native IsBotOnFire(botid);
native SetBotOnFire(botid, fire);
native IsBotDucked(botid);
native IsBotOnGround(botid);
native IsBotChoking(botid);
native SetBotChoking(botid, choking);
native GetBotHealth(botid, &Float:health);
native SetBotHealth(botid, Float:health);
native GetBotArmour(botid, &Float:armour);
native SetBotArmour(botid, Float:armour);
native GetBotPos(botid, &Float:X, &Float:Y, &Float:Z);
native SetBotPos(botid, Float:X, Float:Y, Float:Z);
native GetBotRot(botid, &Float:rX, &Float:rY, &Float:rZ);
native SetBotRot(botid, Float:rX, Float:rY, Float:rZ);
native GetBotVelocity(botid, &Float:X, &Float:Y, &Float:Z);
native SetBotVelocity(botid, Float:X, Float:Y, Float:Z);
native GetBotInterior(botid);
native SetBotInterior(botid, interiorid);
native GetBotVirtualWorld(botid);
native SetBotVirtualWorld(botid, worldid);
native GetBotFightingStyle(botid);
native SetBotFightingStyle(botid, style);
native GetBotWalkingStyle(botid);
native SetBotWalkingStyle(botid, style);
native GetBotSkin(botid);
native SetBotSkin(botid, skinid);
native GetBotSkillLevel(botid, skill);
native SetBotSkillLevel(botid, skill, level);
native GetBotStat(botid, statid);
native SetBotStat(botid, statid, Float:value);
native GetBotState(botid);
native PutBotInVehicle(botid, vehicleid, seatid);
native RemoveBotFromVehicle(botid);
native GetBotVehicleID(botid);
native GetBotVehicleSeat(botid);
native IsBotInVehicle(botid, vehicleid);
native IsBotInAnyVehicle(botid);
native SetBotControlState(botid, control[], controlState);
native SetBotAimTarget(botid, Float:X, Float:Y, Float:Z);
native GetBotDoingDriveBy(botid);
native SetBotDoingDriveBy(botid, driveBy);
native GetBotCanBeKnockedOffBike(botid);
native SetBotCanBeKnockedOffBike(botid, knockedOff);
native GetBotAmmo(botid);
native GetBotWeaponState(botid);
native GetBotWeapon(botid);
native GetBotWeaponSlot(botid);
native SetBotWeaponSlot(botid, slotid);
native GetBotAmmoInClip(botid);
native IsBotHeadless(botid);
native SetBotHeadless(botid, headState);
native IsBotDead(botid);
native KillBot(botid);
native GetBotName(botid, buf[], bufsize = sizeof(buf));
native GetBotAlpha(botid);
native SetBotAlpha(botid, alpha);

// Scoreboard
native AddScoreBoardColumn(column[]);
native SetPlayerScoreBoardData(playerid, column[], data[]);
native RemoveScoreBoardColumn(column[]);

// Player Data
native SetPlayerIntData(playerid, key[], value);
native GetPlayerIntData(playerid, key[]);
native SetPlayerFloatData(playerid, key[], Float:value);
native Float:GetPlayerFloatData(playerid, key[]);
native SetPlayerBoolData(playerid, key[], value);
native GetPlayerBoolData(playerid, key[]);
native SetPlayerStringData(playerid, key[], value[]);
native GetPlayerStringData(playerid, key[], buf[], bufsize = sizeof(buf));
native ResetPlayerData(playerid, key[]);

// Misc
native AddEventHandler(event[], func[]);
native RemoveEventHandler(func[]);
native IsPluginLoaded(plugin[]);
