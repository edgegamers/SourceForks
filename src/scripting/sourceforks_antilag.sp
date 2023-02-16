//	The original exploit fix was made by backwards.
//	This fork hopes to maintain the gamedata,
//	and merges some of the various plugins scattered around.

//	Original sources:
//	https://forums.alliedmods.net/showthread.php?t=321932
//	https://forums.alliedmods.net/showthread.php?t=332721

#include <banning>
#include <sourcemod>
#include <dhooks>
#include "no_op.sp"

#define PLUGIN_VERSION "1.1"
#define ARR_MAXPLAYERS MAXPLAYERS+1

public Plugin:myinfo =
{
	name = "[SourceForks] [CSGO] Server Exploit Fix [5/28/2021 & 3/7/2020]",
	author = "backwards",
	description = "Fixes Several Server Lag Exploits",
	version = PLUGIN_VERSION,
	url = "http://www.steamcommunity.com/id/mypassword"
}

#define DEBUG 0

#define GAMEDATA_FILE "sourceforks_antilag.games"
#define DEFAULT_HEAT (6*60)
#define HEAT_SUSPICIOUS (5 * 60)
#define HEAT_ATTACKER (2 * 60)

GameData Config;
ConVar ConPunishment;
int ClientHeat[ARR_MAXPLAYERS];

enum Punishment
{
	Punish_None = 0,
	Punish_Alert = 1,
	Punish_Kick = 2,
	Punish_Ban = 3,
};

// 	==================================================================================
//	STOCKS
//	==================================================================================

stock void Blame(const char[] ip)
{
	#if DEBUG
	PrintToServer("Blaming '%s'", ip);
	#endif

	for (int i = 1; i < MAXPLAYERS; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if (IsFakeClient(i))
			continue;

		char clientIp[32];
		GetClientIP(i, clientIp, sizeof(clientIp), false);

		if (!StrEqual(ip, clientIp))
			continue;
		
		#if DEBUG
		PrintToServer("Found client %i", i);
		#endif

		if (ClientHeat[i] > 0)
			ClientHeat[i]--;
	}
}

// 	==================================================================================
//	DHOOKS DETOURS
//	==================================================================================
public MRESReturn Mitigate_IPArg(DHookParam Params)
{
	char ip[32];
	Params.GetString(1, ip, sizeof(ip))

	Blame(ip);

	//Return.SetString(ip);
	return MRES_Handled;
}

// 	==================================================================================
//	TIMERS
//	==================================================================================
public Action Timer_CoolDownPlayers(Handle self)
{
	Punishment punishment = Punishment:ConPunishment.IntValue;
	for (int i = 1; i < MAXPLAYERS; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if (IsFakeClient(i))
			continue;

		#if DEBUG
		PrintToServer("Client %i Heat %i", i, ClientHeat[i]);
		#endif

		//	=================
		//	Alert adminstrators to suspicious network activity.
		if (ClientHeat[i] != DEFAULT_HEAT && punishment >= Punish_Alert)
		{
			for (int admin = 1; admin < MAXPLAYERS; admin++)
			{
				if (!CheckCommandAccess(admin, "", ADMFLAG_GENERIC | ADMFLAG_KICK, true))
					continue;

				if (ClientHeat[i] >= HEAT_SUSPICIOUS)
					continue;

				if (ClientHeat[i] > HEAT_ATTACKER)
					PrintToChat(admin, "[SourceForks] Client '%N' (#%i) has unusual network activity.", i, GetClientUserId(i));

				if (ClientHeat[i] <= HEAT_ATTACKER)
					PrintToChat(admin, "[SourceForks] Client '%N' (#%i) is attempting to DDOS the server.", i, GetClientUserId(i));
				
				if (ClientHeat[i] <= 0 && punishment >= Punish_Kick)
					PrintToChat(admin, "[SourceForks] Punishing client %L for attempted DDOS.", i);
			}
		}

		//	=================
		//	Punish players.
		if (ClientHeat[i] <= 0)
		{
			if (punishment == Punish_Kick)
				KickClientEx(i, "[SourceForks] Attempted DDOS");

			if (punishment == Punish_Ban)
				BanClient(i, 0, BANFLAG_AUTO, "[SourceForks] Attempted DDOS", "[SourceForks] Attempted DDOS", "Sourceforks", 0);
		}

	}

	return Plugin_Continue;
}

public Action Timer_WarmUpPlayers(Handle self)
{
	#if DEBUG
	PrintToServer("Warming up");
	#endif

	for (int i = 1; i < MAXPLAYERS; i++)
	{
		ClientHeat[i] = DEFAULT_HEAT;
	}

	return Plugin_Continue;
}

// 	==================================================================================
//	FORWARDS
//	==================================================================================

DynamicDetour Detour_InvalidReliableState;

public OnPluginStart()
{
	NoOpInit();

	if (GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is only compatible with CS:GO.");

	ConPunishment = CreateConVar("sourceforks_antilag_punishment", "3", "Sets punishment for players attempting to DDOS the server. 0 = None, 1 = Alert Admins (Default), 2 = Kick, 3 = Permanent Ban")
	Config = LoadGameConfigFile(GAMEDATA_FILE);

	//	Ratelimit spam
	NoOpFunction(Config, "Ratelimiter", "RatelimiterSize");

	//	Corrupted packet spam
	NoOpFunction(Config, "CorruptedPacket", "CorruptedPacketSize");

	//	Invalid reliable stats spam
	NoOpFunction(Config, "InvalidReliableState", "InvalidReliableStateSize");

	//	Now, mitigations:
	//	InvalidReliableState
	{
		Address invalid = Config.GetAddress("InvalidReliableState");
		Detour_InvalidReliableState = DHookCreateDetour(invalid, CallConv_CDECL, ReturnType_Void, ThisPointer_Ignore);

		//	EAX contains IP
		Detour_InvalidReliableState.AddParam(HookParamType_CharPtr, -1, DHookPass_ByVal, DHookRegister_EAX);
		Detour_InvalidReliableState.Enable(Hook_Pre, Mitigate_IPArg);
	}

	for (int i = 1; i < MAXPLAYERS; i++)
	{
		ClientHeat[i] = DEFAULT_HEAT;
	}

	CreateTimer(5.0, Timer_CoolDownPlayers, 0, TIMER_REPEAT);
	CreateTimer(30.0, Timer_WarmUpPlayers, 0, TIMER_REPEAT)

}

public OnClientConnected(int client)
{
	ClientHeat[client] = DEFAULT_HEAT;
}

public OnPluginEnd()
{
	Detour_InvalidReliableState.Disable(Hook_Pre, Mitigate_IPArg);

	RecoverFunction(Config, "Ratelimiter", "RatelimiterSize");
	RecoverFunction(Config, "CorruptedPacket", "CorruptedPacketSize");
	RecoverFunction(Config, "InvalidReliableState", "InvalidReliableStateSize");
}