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
forward OnMarkerHit(markerid, type[], id, worldid);
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
native SetCloudsEnabled(bool:enable);
native GetInteriorSoundsEnabled();
native SetInteriorSoundsEnabled(bool:enable);
native IsGarageOpen(garageid);
native SetGarageOpen(garageid, bool:open);
native IsGlitchEnabled(const name[]);
native SetGlitchEnabled(const name[], bool:enable);
native Float:GetAircraftMaxVelocity();
native SetAircraftMaxVelocity(Float:velocity);
native Float:GetAircraftMaxHeight();
native SetAircraftMaxHeight(Float:height);
native Float:GetJetpackMaxHeight();
native SetJetpackMaxHeight(Float:height);
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
native CreateMarker(Float:X, Float:Y, Float:Z, const type[], Float:size, red, green, blue, alpha);
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
native IsValidServerRule(const name[]);
native GetServerRule(const name[], buf[], bufsize = sizeof(buf));
native SetServerRule(const name[], const value[]);
native RemoveServerRule(const name[]);

// Objects
native IsObjectBreakable(objectid);
native SetObjectBreakable(objectid, bool:breakable);
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
native SetPlayerOnFire(playerid, bool:fire);
native IsPlayerDucked(playerid);
native IsPlayerOnGround(playerid);
native IsPlayerChoking(playerid);
native SetPlayerChoking(playerid, bool:choking);
native GetPlayerWalkingStyle(playerid);
native SetPlayerWalkingStyle(playerid, style);
native GetPlayerStat(playerid, statid);
native SetPlayerStat(playerid, statid, Float:value);
native GetPlayerDoingDriveBy(playerid);
native SetPlayerDoingDriveBy(playerid, bool:driveBy);
native GetPlayerCanBeKnockedOffBike(playerid);
native SetPlayerCanBeKnockedOffBike(playerid, bool:knockOff);
native GetPlayerWeaponSlot(playerid);
native SetPlayerWeaponSlot(playerid, slotid);
native GetPlayerAmmoInClip(playerid);
native GetPlayerIdleTime(playerid);
native IsPlayerHeadless(playerid);
native SetPlayerHeadless(playerid, bool:headless);
native GetPlayerBlurLevel(playerid);
native SetPlayerBlurLevel(playerid, level);
native FadePlayerCamera(playerid, bool:fadeIn, Float:timeToFade = 1.0, red = 0, green = 0, blue = 0);
native SetPlayerControlState(playerid, const control[], bool:controlState);
native IsPlayerCursorShowing(playerid);
native ShowPlayerCursor(playerid, bool:show, bool:controls);
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
native SetVehicleEngineState(vehicleid, bool:engine);
native GetVehicleSirenState(vehicleid);
native SetVehicleSirenState(vehicleid, bool:siren);
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
native SetTrainDerailable(vehicleid, bool:derailable);
native IsTrainDerailed(vehicleid);
native SetTrainDerailed(vehicleid, bool:derailed);
native GetTrainDirection(vehicleid);
native SetTrainDirection(vehicleid, bool:clockwise);
native GetTrainSpeed(vehicleid, &Float:speed);
native SetTrainSpeed(vehicleid, Float:speed);
native GetVehicleOccupant(vehicleid, seatid);
native GetVehicleNumberPlate(vehicleid, plate[], len = sizeof(plate));
native GetVehicleColor(vehicleid, &color1, &color2);
native GetVehiclePaintjob(vehicleid);
native GetVehicleInterior(vehicleid);

// Bots
native CreateBot(modelid, Float:x, Float:y, Float:z, const name[] = "Bot");
native DestroyBot(botid);
native AddBotClothes(botid, type, index);
native GetBotClothes(botid, type);
native RemoveBotClothes(botid, type);
native IsBotInWater(botid);
native IsBotOnFire(botid);
native SetBotOnFire(botid, bool:fire);
native IsBotDucked(botid);
native IsBotOnGround(botid);
native IsBotChoking(botid);
native SetBotChoking(botid, bool:choking);
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
native SetBotControlState(botid, const control[], bool:controlState);
native SetBotAimTarget(botid, Float:X, Float:Y, Float:Z);
native GetBotDoingDriveBy(botid);
native SetBotDoingDriveBy(botid, bool:driveBy);
native GetBotCanBeKnockedOffBike(botid);
native SetBotCanBeKnockedOffBike(botid, bool:knockOff);
native GetBotAmmo(botid);
native GetBotWeaponState(botid);
native GetBotWeapon(botid);
native GetBotWeaponSlot(botid);
native SetBotWeaponSlot(botid, slotid);
native GetBotAmmoInClip(botid);
native IsBotHeadless(botid);
native SetBotHeadless(botid, bool:headless);
native IsBotDead(botid);
native KillBot(botid);
native GetBotName(botid, buf[], bufsize = sizeof(buf));
native GetBotAlpha(botid);
native SetBotAlpha(botid, alpha);

// Scoreboard
native AddScoreBoardColumn(const column[]);
native SetPlayerScoreBoardData(playerid, const column[], const data[]);
native RemoveScoreBoardColumn(const column[]);

// Player Data
native SetPlayerIntData(playerid, const key[], value);
native GetPlayerIntData(playerid, const key[]);
native SetPlayerFloatData(playerid, const key[], Float:value);
native Float:GetPlayerFloatData(playerid, const key[]);
native SetPlayerBoolData(playerid, const key[], bool:value);
native GetPlayerBoolData(playerid, const key[]);
native SetPlayerStringData(playerid, const key[], const value[]);
native GetPlayerStringData(playerid, const key[], buf[], bufsize = sizeof(buf));
native ResetPlayerData(playerid, const key[]);

// Misc
native AddEventHandler(const event[], const func[]);
native RemoveEventHandler(const func[]);
native IsPluginLoaded(const plugin[]);
