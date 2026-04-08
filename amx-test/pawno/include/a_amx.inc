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
forward OnBotCreate(botid, name[]);
forward OnBotStreamIn(botid, forplayerid);
forward OnBotStreamOut(botid, forplayerid);
forward OnBotEnterVehicle(botid, vehicleid, ispassenger);
forward OnBotExitVehicle(botid, vehicleid);
forward OnBotTakeDamage(botid, issuerid, Float:amount, weaponid, bodypart);
forward OnBotGiveDamage(botid, damagedid, Float:amount, weaponid, bodypart);
forward OnBotDeath(botid, killerid, reason, bodypart);
forward OnBotStateChange(botid, newstate, oldstate);
forward OnMarkerCreate(markerid);
forward OnMarkerHit(markerid, type[], id, worldid);
forward OnMarkerLeave(markerid, type[], id, worldid);
forward OnPlayerClickWorld(playerid, button, updown, type[], id, Float:x, Float:y, Float:z);
forward OnPlayerStunt(playerid, vehicleid, stunt[], time, Float:distance);
forward OnPlayerWeaponSwitch(playerid, newweaponid, oldweaponid);
forward OnPlayerWeaponReload(playerid, weaponid, clip, ammo);
forward OnPlayerKeyDown(playerid, key);
forward OnPlayerKeyUp(playerid, key);

// World
native GetFPSLimit();
native SetFPSLimit(fps);
native Float:GetGameSpeed();
native SetGameSpeed(Float:speed);
native Float:GetRainLevel();
native SetRainLevel(Float:level);
native GetSkyGradient(&topColor, &bottomColor);
native SetSkyGradient(topColor = 255, bottomColor = 255);
native GetWindVelocity(&Float:X, &Float:Y, &Float:Z);
native SetWindVelocity(Float:X, Float:Y, Float:Z);
native Float:GetFogDistance();
native SetFogDistance(Float:distance);
native SetWeatherBlended(weatherid);
native GetMinuteDuration();
native SetMinuteDuration(timems);
native GetCloudsEnabled();
native SetCloudsEnabled(bool:enable);
native GetInteriorSoundsEnabled();
native SetInteriorSoundsEnabled(bool:enable);
native GetOcclusionsEnabled();
native SetOcclusionsEnabled(bool:enable);
native IsGarageOpen(garageid);
native SetGarageOpen(garageid, bool:open);
native IsGlitchEnabled(const name[]);
native SetGlitchEnabled(const name[], bool:enable);
native IsJetpackWeaponEnabled(weaponid);
native SetJetpackWeaponEnabled(weaponid, bool:enable);
native Float:GetJetpackMaxHeight();
native SetJetpackMaxHeight(Float:height);
native Float:GetAircraftMaxVelocity();
native SetAircraftMaxVelocity(Float:velocity);
native Float:GetAircraftMaxHeight();
native SetAircraftMaxHeight(Float:height);

// Water
native GetWaterColor();
native SetWaterColor(color);
native Float:GetWaveHeight();
native SetWaveHeight(Float:height);
native SetWaterLevel(Float:level);

// Traffic lights
native GetTrafficLightsLocked();
native SetTrafficLightsLocked(bool:locked);
native GetTrafficLightState();
native SetTrafficLightState(lightState);

// Pickups
native GetPickupType(pickupid);
native SetPickupType(pickupid, type, model, ammo = 0);
native GetPickupAmount(pickupid);
native GetPickupWeapon(pickupid);
native GetPickupAmmo(pickupid);

// Native Markers
native CreateMarker(Float:X, Float:Y, Float:Z, const type[], Float:size, color);
native DestroyMarker(markerid);
native GetMarkerColor(markerid);
native GetMarkerIcon(markerid); // 0 = No icon, 1 = Arrow, 2 = Race finish
native GetMarkerSize(markerid, &Float:size);
native GetMarkerTarget(markerid, &Float:X, &Float:Y, &Float:Z);
native GetMarkerType(markerid); // 0 = Checkpoint, 1 = Ring, 2 = Cylinder, 3 = Arrow, 4 = Corona
native SetMarkerColor(markerid, color);
native SetMarkerIcon(markerid, iconid); // 0 = No icon, 1 = Arrow, 2 = Race finish
native SetMarkerSize(markerid, Float:size);
native SetMarkerTarget(markerid, Float:X, Float:Y, Float:Z);
native SetMarkerType(markerid, type); // 0 = Checkpoint, 1 = Ring, 2 = Cylinder, 3 = Arrow, 4 = Corona
native IsPlayerInMarker(markerid, playerid);
native IsVehicleInMarker(markerid, vehicleid);
native IsActorInMarker(markerid, actorid);
native IsBotInMarker(markerid, botid);

// Objects
native BreakObject(objectid);
native SetObjectBreakable(objectid, bool:breakable);
native IsObjectBreakable(objectid);
native RespawnObject(objectid);
native SetObjectRespawnable(objectid, bool:respawnable);
native IsObjectRespawnable(objectid);
native GetObjectScale(objectid, &Float:X, &Float:Y, &Float:Z);
native SetObjectScale(objectid, Float:X, Float:Y, Float:Z);
native GetObjectAlpha(objectid);
native SetObjectAlpha(objectid, alpha);

// Buildings
native RemoveBuilding(modelid, Float:X, Float:Y, Float:Z, Float:radius);
native RestoreBuildingForPlayer(playerid, modelid, Float:X, Float:Y, Float:Z, Float:radius);
native RestoreAllBuildingsForPlayer(playerid);
native RestoreBuilding(modelid, Float:X, Float:Y, Float:Z, Float:radius);
native RestoreAllBuildings();

// Players
native AddPlayerClothes(playerid, type, index);
native GetPlayerClothes(playerid, type);
native RemovePlayerClothes(playerid, type);
native ShowPlayerMarker(playerid, mode); // 0 = Off, 1 = Global, 2 = Streamed
native IsPlayerInWater(playerid);
native IsPlayerOnFire(playerid);
native SetPlayerOnFire(playerid, bool:fire);
native IsPlayerDucked(playerid);
native IsPlayerOnGround(playerid);
native IsPlayerChoking(playerid);
native SetPlayerChoking(playerid, bool:choking);
native Float:GetPlayerGravity(playerid);
native SetPlayerGravity(playerid, Float:gravity);
native GetPlayerWalkingStyle(playerid);
native SetPlayerWalkingStyle(playerid, style);
native GetPlayerSkillLevel(playerid, skill);
native GetPlayerStat(playerid, statid);
native SetPlayerStat(playerid, statid, Float:value);
native IsPlayerDoingDriveBy(playerid);
native SetPlayerDoingDriveBy(playerid, bool:driveBy);
native GetPlayerWeaponSlot(playerid);
native SetPlayerWeaponSlot(playerid, slot);
native GetPlayerAmmoInClip(playerid);
native ReloadPlayerWeapon(playerid);
native RemovePlayerWeapon(playerid, weaponid);
native GetPlayerIdleTime(playerid);
native IsPlayerHeadless(playerid);
native SetPlayerHeadless(playerid, bool:headless);
native IsPlayerDead(playerid);
native KillPlayer(playerid, killerid, reason = 255, bodypart = 3);
native GetPlayerBlurLevel(playerid);
native SetPlayerBlurLevel(playerid, level);
native IsPlayerMapForced(playerid);
native ForcePlayerMap(playerid, bool:forceOn);
native FadePlayerCamera(playerid, bool:fadeIn, Float:timeToFade = 1.0, color = 255);
native SetPlayerControlState(playerid, const control[], bool:controlState);
native IsPlayerCursorShowing(playerid);
native ShowPlayerCursor(playerid, bool:show, bool:controls = true);
native ShowPlayerChat(playerid, bool:show, bool:input);
native GetPlayerAlpha(playerid);
native SetPlayerAlpha(playerid, alpha);

// Vehicles
native IsVehicleInWater(vehicleid);
native IsVehicleOnGround(vehicleid);
native SetVehicleModel(vehicleid, model);
native GetVehicleInterior(vehicleid);
native GetVehicleOccupant(vehicleid, seatid);
native GetVehicleMaxPassengers(vehicleid);
native GetVehicleEngineState(vehicleid);
native SetVehicleEngineState(vehicleid, bool:engine);
native GetVehicleSirenState(vehicleid);
native SetVehicleSirenState(vehicleid, bool:siren);
native GetVehicleDoorState(vehicleid, door);
native SetVehicleDoorState(vehicleid, door, doorState, flyingComponent = true);
native GetVehicleLightState(vehicleid, light);
native SetVehicleLightState(vehicleid, light, lightState);
native GetVehicleTaxiLightState(vehicleid);
native SetVehicleTaxiLightState(vehicleid, bool:light);
native GetVehicleWheelState(vehicleid, wheel);
native SetVehicleWheelState(vehicleid, frontLeft = -1, rearLeft = -1, frontRight = -1, rearRight = -1);
native GetVehiclePanelState(vehicleid, panel);
native SetVehiclePanelState(vehicleid, panel, panelState, flyingComponent = true);
native GetVehicleLandingGearState(vehicleid);
native SetVehicleLandingGearState(vehicleid, bool:gear);
native GetVehicleOverrideLights(vehicleid);
native SetVehicleOverrideLights(vehicleid, override);
native GetVehicleHeadLightColor(vehicleid);
native SetVehicleHeadLightColor(vehicleid, color);
native GetVehicleColor(vehicleid, &color1, &color2);
native GetVehiclePaintjob(vehicleid);
native GetVehicleVariant(vehicleid, &var1, &var2);
native SetVehicleVariant(vehicleid, var1 = 255, var2 = 255);
native IsVehicleBlown(vehicleid);
native BlowVehicle(vehicleid, bool:explode = true);
native GetVehicleRotation(vehicleid, &Float:rX, &Float:rY, &Float:rZ);
native GetVehicleNumberPlate(vehicleid, plate[], len = sizeof(plate));
native GetVehicleCab(vehicleid);
native IsTrainDerailable(vehicleid);
native SetTrainDerailable(vehicleid, bool:derailable);
native IsTrainDerailed(vehicleid);
native SetTrainDerailed(vehicleid, bool:derailed);
native GetTrainDirection(vehicleid);
native SetTrainDirection(vehicleid, bool:clockwise);
native GetTrainSpeed(vehicleid, &Float:speed);
native SetTrainSpeed(vehicleid, Float:speed);
native GetVehicleAlpha(vehicleid);
native SetVehicleAlpha(vehicleid, alpha);

// Bots
native CreateBot(modelid, Float:x, Float:y, Float:z, const name[] = "");
native IsValidBot(botid);
native IsBotStreamedIn(botid, playerid);
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
native GetBotFacingAngle(botid, &Float:angle);
native SetBotFacingAngle(botid, Float:angle);
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
native SetBotLookAt(botid, Float:X, Float:Y, Float:Z, time = 3000, blend = 1000);
native SetBotAimTarget(botid, Float:X, Float:Y, Float:Z);
native IsBotDoingDriveBy(botid);
native SetBotDoingDriveBy(botid, bool:driveBy);
native GetBotAmmo(botid);
native SetBotAmmo(botid, weaponid, ammo);
native GetBotWeaponState(botid);
native GetBotWeapon(botid);
native GiveBotWeapon(botid, weaponid, ammo);
native ResetBotWeapons(botid);
native SetBotArmedWeapon(botid, weaponid);
native GetBotWeaponSlot(botid);
native SetBotWeaponSlot(botid, slot);
native GetBotAmmoInClip(botid);
native ReloadBotWeapon(botid);
native RemoveBotWeapon(botid, weaponid);
native IsBotHeadless(botid);
native SetBotHeadless(botid, bool:headless);
native IsBotDead(botid);
native KillBot(botid, killerid, reason = 255, bodypart = 3);
native ShowBotNameTag(botid, bool:show);
native GetBotColor(botid);
native SetBotColor(botid, color);
native GetBotName(botid, buf[], bufsize = sizeof(buf));
native SetBotName(botid, const name[]);
native GetBotAlpha(botid);
native SetBotAlpha(botid, alpha);

// Rules
native IsValidServerRule(const name[]);
native GetServerRule(const name[], buf[], bufsize = sizeof(buf));
native SetServerRule(const name[], const value[]);
native RemoveServerRule(const name[]);

// Scoreboard
native AddScoreBoardColumn(const column[]);
native GetPlayerScoreBoardData(playerid, const column[], buf[], bufsize = sizeof(buf));
native SetPlayerScoreBoardData(playerid, const column[], const value[]);
native RemoveScoreBoardColumn(const column[]);

// Player Data
native SetPlayerIntData(playerid, const key[], value);
native GetPlayerIntData(playerid, const key[]);
native SetPlayerFloatData(playerid, const key[], Float:value);
native GetPlayerFloatData(playerid, const key[], &Float:result);
native SetPlayerBoolData(playerid, const key[], bool:value);
native GetPlayerBoolData(playerid, const key[]);
native SetPlayerStringData(playerid, const key[], const value[]);
native GetPlayerStringData(playerid, const key[], buf[], bufsize = sizeof(buf));
native RemovePlayerData(playerid, const key[]);
native HasPlayerData(playerid, const key[]);

// Misc
native GetWeaponSlot(weaponid);
native AddEventHandler(const event[], const func[]);
native RemoveEventHandler(const func[]);
native IsPluginLoaded(const plugin[]);
native GetPlayerIDFromName(const name[]);
native GetRandomPlayer();
native GetPlayerCount();
