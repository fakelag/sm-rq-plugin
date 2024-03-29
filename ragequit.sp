#include <sourcemod>
#include <sdktools>
#include <morecolors>

float g_flLastDeathTime[MAXPLAYERS+1] = -1.0;

ConVar rq_seconds;
ConVar rq_filename;
ConVar rq_volume;

char g_szReasons[][] = {
	"{red}Raged by user{default}",
	"{red}Couldn't handle all the feelings{default}",
	"{red}Ragequit ¯\\_(ツ)_/¯{default}"
};

public Plugin:HvtPluginInfo =
{
	name = "Rage Quit",
	author = "FL",
	description = "Distinguishes innocent, regular disconnects from rage inflicted ones.",
	version = "1.0",
	url = ""
};

public PlaySound()
{
	new String:szSoundPath[256];
	GetConVarString(rq_filename, szSoundPath, sizeof(szSoundPath));

	EmitSoundToAll(szSoundPath, _, _, _, _, GetConVarFloat(rq_volume), _, _, _, _, _, _);
}

public Action Command_TestSound(int nClient, int args)
{
	PlaySound();
	return Plugin_Handled;
}

public void OnPluginStart()
{
		rq_seconds = CreateConVar("rq_seconds", "10", "Amount of seconds from death to a disconnect to consider the player ragequitted");
		rq_filename = CreateConVar("rq_filename", "rq/rq1.mp3", "Ragequit sound file path");
		rq_volume = CreateConVar("rq_volume", "0.1", "Ragequit sound volume");

		HookEvent("player_death", Event_PlayerDeath);
		HookEventEx("player_disconnect", Event_Disconnect, EventHookMode_Pre);
		HookEvent("player_connect", Event_Connect);
		HookEvent("server_spawn", Event_ServerSpawn);
		
		RegAdminCmd("rqtest", Command_TestSound, Admin_Generic);

		PrintToServer("[RQ] Rage Quit plugin loaded successfully!");
}

public void OnMapStart()
{
		new String:szSoundPath[256];
		GetConVarString(rq_filename, szSoundPath, sizeof(szSoundPath));

		new String:szFullPath[256];
		Format(szFullPath, sizeof(szFullPath), "sound/%s", szSoundPath);

		if (!PrecacheSound(szSoundPath, true))
		{
			PrintToServer("[RQ] Failed to precache %s", szSoundPath);
		}

		AddFileToDownloadsTable(szFullPath);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	int nVictim = GetEventInt(event, "userid");
	int nVictimId = GetClientOfUserId(nVictim);

	if (nVictimId > 0 && nVictimId <= MAXPLAYERS)
		g_flLastDeathTime[nVictimId] = GetGameTime();

	return Plugin_Continue;
}

public Action:Event_Connect(Handle:event, const String:name[], bool:dontBroadcast) 
{
	int nUserId = GetEventInt(event, "userid");
	int nClient = GetClientOfUserId(nUserId);

	if (nClient > 0 && nClient <= MAXPLAYERS)
		g_flLastDeathTime[nClient] = -1.0;

	return Plugin_Continue;
}

public Action:Event_Disconnect(Handle:event, const String:name[], bool:dontBroadcast) 
{
	int nUserId = GetEventInt(event, "userid");
	int nClient = GetClientOfUserId(nUserId);

	if (nClient > 0 && nClient <= MAXPLAYERS)
	{
		if (g_flLastDeathTime[nClient] != -1.0 && GetGameTime() < g_flLastDeathTime[nClient] + GetConVarFloat(rq_seconds))
		{
			// ragequit
			// Player {name} left the game (Disconnect by user.)
			PlaySound();

			new String:szClientName[64];
			GetEventString(event, "name", szClientName, sizeof(szClientName));
			CPrintToChatAll("{default}Player %s left the game (%s)", szClientName, g_szReasons[GetRandomInt(0, sizeof(g_szReasons) - 1)]);

			g_flLastDeathTime[nClient] = -1.0;
			return Plugin_Handled;
		}

		g_flLastDeathTime[nClient] = -1.0;
	}

	return Plugin_Continue;
}

public Action:Event_ServerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (int i = 1; i < MaxClients; ++i)
		g_flLastDeathTime[i] = -1.0;
}
