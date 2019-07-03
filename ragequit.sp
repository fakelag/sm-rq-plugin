#include <sourcemod>
#include <sdktools>
#include <morecolors>

float g_flLastDeathTime[MAXPLAYERS+1] = -1.0;

ConVar rq_seconds;
ConVar rq_filename;

char g_szReasons[][] = {
	"{red}Raged by user{default}.",
	"{red}Couldn't handle all the feelings{default}.",
	"{red}Ragequitted ¯\\_(ツ)_/¯{default}."
};

public Plugin:HvtPluginInfo =
{
	name = "Rage Quit",
	author = "FL",
	description = "Replaces disconnect reason & sound in the case of a RQ",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
		rq_seconds = CreateConVar("rq_seconds", "10", "Amount of seconds from death to a disconnect to consider the player ragequitted");
		rq_filename = CreateConVar("rq_filename", "rq/rq1.mp3", "Ragequit sound file path");

		HookEvent("player_death", Event_PlayerDeath);
		HookEventEx("player_disconnect", Event_Disconnect, EventHookMode_Pre);
		HookEvent("player_connect", Event_Connect);
		HookEvent("server_spawn", Event_ServerSpawn);

		new String:szSoundPath[256];
		GetConVarString(rq_filename, szSoundPath, sizeof(szSoundPath));

		new String:szFullPath[256];
		Format(szFullPath, sizeof(szFullPath), "sound/%s", szSoundPath);

		PrecacheSound(szSoundPath, true);
		AddFileToDownloadsTable(szFullPath);  

		PrintToServer("[RQ] Rage Quit plugin loaded successfully!");
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

			new String:szSoundPath[256];
			GetConVarString(rq_filename, szSoundPath, sizeof(szSoundPath));

			EmitSoundToAll(szSoundPath);

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
