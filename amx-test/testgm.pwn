#include <a_samp>
#include <a_amx>

new bot, bots;

main()
{
	print("\n----------------------------------");
	print("       AMX test gamemode");
	print("----------------------------------\n");
}

public OnGameModeInit()
{
	SetGameModeText("AMX test gamemode");
	print("This gamemode doesn't do anything.");
	print("It is simply an example of a gamemode resource.");

	new File:handle = fopen("file.txt", io_read);
	if(handle)
	{
		new buffer[512];
		fread(handle, buffer, sizeof(buffer));
		printf("%s", buffer);
		fclose(handle);
	}
	else
	{
		printf("There is a problem with opening the file.");
	}

	AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);

	new buf[64];
	SetServerRule("nya", "test");
	GetServerRule("nya", buf, sizeof(buf));
	printf("rule: %s", buf);

	bot = CreateBot(0, 0.5, 0.5, 0.5, "Nyashk");
	GetBotName(bot, buf, sizeof(buf));
	printf("bot: %s", buf);

	printf("wave height: %d", GetWaveHeight());
	SetWaveHeight(15);
	printf("wave height: %d", GetWaveHeight());
	SetWaterLevel(-15);
	return 1;
}

public OnGameModeExit()
{
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	SetPlayerPos(playerid, 1958.3783, 1343.1572, 15.3746);
	SetPlayerCameraPos(playerid, 1958.3783, 1343.1572, 15.3746);
	SetPlayerCameraLookAt(playerid, 1958.3783, 1343.1572, 15.3746);
	return 1;
}

public OnPlayerConnect(playerid)
{
	SetPlayerHealth(playerid, 50.0);
	SetPlayerBlurLevel(playerid, 0);

	new listitems[] = "1\tDeagle\n2\tSawnoff\n3\tPistol\n4\tGrenade\n5\tParachute\n6\tLorikeet";
 	ShowPlayerDialog(playerid, 2, DIALOG_STYLE_LIST, "List of weapons:", listitems, "Select", "Cancel");
	// ShowPlayerDialog(playerid, 1, DIALOG_STYLE_LIST, "testcapt", "info", "Ok", "Cancel");
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == 0) // Our example msgbox
	{
		if(response)
		{
			SendClientMessage(playerid, 0xFFFFFFFF, "You selected Ok");
		}
		else
		{
			SendClientMessage(playerid, 0xFFFFFFFF, "You selected Cancel");
		}
		return 1; // no need for other filterscripts to process it
	}

	if(dialogid == 1) // Our example inputbox
	{
		if(response)
		{
			new message[256];
			format(message, sizeof(message), "You replied: %s", inputtext);
			SendClientMessage(playerid, 0xFFFFFFFF, message);
		}
		else
		{
			SendClientMessage(playerid, 0xFFFFFFFF, "You selected Cancel");
		}
		return 1; // we processed it
	}

	if(dialogid == 2) // Our example listbox
	{
		if(response)
		{
			new message[64];
			if(listitem != 5)
			{
				format(message, sizeof(message), "You selected item %d:", listitem);
				SendClientMessage(playerid, 0xFFFFFFFF, message);
				SendClientMessage(playerid, 0xFFFFFFFF, inputtext);
			}
			else
			{
				SendClientMessage(playerid, 0x5555FFFF, "A Lorikeet is NOT a weapon!");
			}
		}
		else
		{
			SendClientMessage(playerid, 0xFFFFFFFF, "You selected Cancel");
		}
		return 1; // we processed it
	}

	return 0; // we didn't handle anything
}

public OnPlayerDisconnect(playerid, reason)
{
	return 1;
}

public OnMarkerCreate(markerid)
{
	printf("OnMarkerCreate(%d)", markerid);
	return 1;
}

public OnMarkerHit(markerid, type[], id, worldid)
{
	printf("OnMarkerHit(%d, %s, %d)", markerid, type, id);
	return 1;
}

public OnPlayerSpawn(playerid)
{
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
	CreateMarker(x, y, z, "checkpoint", 3.0, 255, 0, 0, 250);

	SetBotPos(bot, x, y, z);
	SetBotHealth(bot, 100.0);
	SetBotArmour(bot, 5.0);

	SetPlayerHealth(playerid, 50.0);
	GivePlayerWeapon(playerid, 32, 500);
	return 1;
}

public OnBotCreate(botid, name[])
{
	bots++;
	printf("Bot created: %d [%s]", botid, name);
	return 1;
}

public OnBotEnterVehicle(botid, vehicleid, ispassenger)
{
	return 1;
}

public OnBotExitVehicle(botid, vehicleid)
{
	return 1;
}

public OnBotDeath(botid, killerid, reason, bodypart)
{
	printf("OnBotDeath(%d, %d, %d, %d)", botid, killerid, reason, bodypart);
	return 1;
}

public OnBotStateChange(botid, newstate, oldstate)
{
	return 1;
}

public OnPlayerWeaponSwitch(playerid, newweaponid, oldweaponid)
{
	printf("OnPlayerWeaponSwitch(%d, %d, %d)", playerid, newweaponid, oldweaponid);
	return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	printf("OnPlayerWeaponShot(%d, %d, %d, %d, %f, %f, %f)", playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ);
	return 1;
}

public OnVehicleDamageStatusUpdate(vehicleid, playerid)
{
	printf("OnVehicleDamageStatusUpdate(%d, %d)", vehicleid, playerid);
	return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
	new cmd[128], idx;
	cmd = strtok(cmdtext, idx);

	if(strcmp(cmd, "/testmsgbox", true) == 0)
	{
		ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, "Welcome", "Welcome to SA-MP 0.3 server. This is /testmsgbox\nHope it's useful to you.", "Ok", "Cancel");
		return 1;
	}

	if(strcmp(cmd, "/testmsgbox2", true) == 0)
	{
		ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, "Welcome", "Welcome:\tInfo\nTest:\t\tTabulated\nLine:\t\tHello", "Ok", "Cancel");
		return 1;
	}

	if(strcmp(cmd, "/testinputbox", true) == 0)
	{
		new loginmsg[128], loginname[MAX_PLAYER_NAME + 1];
		GetPlayerName(playerid, loginname, MAX_PLAYER_NAME);
		format(loginmsg, sizeof(loginmsg), "Welcome to SA-MP 0.3 server.\n\nAccount:\t%s\n\nPlease enter your password below:", loginname);
		ShowPlayerDialog(playerid, 1, DIALOG_STYLE_INPUT, "Login to SA-MP", loginmsg, "Login", "Cancel");
		return 1;
	}

	if(strcmp(cmd, "/testlistbox", true) == 0)
	{
		new listitems[] = "1\tDeagle\n2\tSawnoff\n3\tPistol\n4\tGrenade\n5\tParachute\n6\tLorikeet";
		ShowPlayerDialog(playerid, 2, DIALOG_STYLE_LIST, "List of weapons:", listitems, "Select", "Cancel");
		return 1;
	}
	return 0;
}

strtok(const string[], &index)
{
	new length = strlen(string);
	while((index < length) && (string[index] <= ' '))
	{
		index++;
	}

	new offset = index;
	new result[20];
	while((index < length) && (string[index] > ' ') && ((index - offset) < (sizeof(result) - 1)))
	{
		result[index - offset] = string[index];
		index++;
	}
	result[index - offset] = EOS;
	return result;
}
