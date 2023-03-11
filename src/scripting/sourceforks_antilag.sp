//	The original exploit fix was made by backwards.
//	This fork hopes to maintain the gamedata,
//	and merges some of the various plugins scattered around.

//	Original sources:
//	https://forums.alliedmods.net/showthread.php?t=321932
//	https://forums.alliedmods.net/showthread.php?t=332721

//	Punishment behavior:
//	Each player will receive a "heat" upon entering the server.
//	This heat is decremented by 1 every time an exploit attempt is detected.
//	(This gives players with, say, bad connections a safety buffer)
//	When the heat reaches 0, the player is punished.
//	However, if 30 seconds have passed and no expoit attempts were detected,
//	the player is exonerated of suspicion.

//	I'm not sure it's even possible to trigger this exploit on a vanilla client.
//	But I don't want to use the scream test on that.

#include <banning>
#include <sourcemod>
#include <dhooks>
#include "asm_patch.sp"
#include "sourceforks_admin_utils.sp"
#include "sourceforks_version.sp"

public Plugin myinfo =
{
	name		= "[SourceForks] [CSGO] Server Exploit Fix [5/28/2021 & 3/7/2020]",
	author		= "backwards",
	description = "Fixes Several Server Lag Exploits",
	version		= PLUGIN_VERSION,
	url			= "http://www.steamcommunity.com/id/mypassword"


}

#define DEBUG				 2

#define ARR_MAXPLAYERS		 MAXPLAYERS + 1

#define GAMEDATA_FILE		 "sourceforks_antilag"
#define TICKRATE			 128

//	How many seconds before the state is refreshed and attacking players are banned
#define TIMER_REFRESH		 5
#define TIMER_REFRESH_FLOAT	 5.0
//	How many seconds after an attack a player should be exonerated
#define TIMER_CLEAN			 15

#define DEFAULT_HEAT		 (TIMER_CLEAN * TICKRATE)
#define HEAT_BUMP_ON_REFRESH (TIMER_REFRESH * TICKRATE)
//	It should be impossible for a normal client to reach HEAT_SUSPICIOUS
#define HEAT_SUSPICIOUS		 ((TIMER_CLEAN - TIMER_REFRESH + 1) * TICKRATE)
//	It is impossible for a normal client to reach HEAT_ATTACKER on 128-tick or below servers.
#define HEAT_ATTACKER		 ((TIMER_CLEAN - TIMER_REFRESH - 1) * TICKRATE)

//	Flag that describes admins to alert
#define ADMINFLAG_ALERT		 (ADMFLAG_BAN)

GameData Config;
ConVar	 ConPunishment;
int		 ClientHeat[ARR_MAXPLAYERS];

enum Punishment
{
	Punish_None	 = 0,
	Punish_Alert = 1,
	Punish_Kick	 = 2,
	Punish_Ban	 = 3,
};

// 	==================================================================================
//	STOCKS
//	==================================================================================

stock void BlameIP(const char[] ip)
{
#if DEBUG == 2
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

#if DEBUG == 2
		PrintToServer("Found client %i", i);
#endif

		if (ClientHeat[i] > 0)
			ClientHeat[i]--;
	}
}

stock void BlameClient(int index)
{
	if (ClientHeat[index] > 0)
		ClientHeat[index]--;
}

// 	==================================================================================
//	DHOOKS DETOURS
//	==================================================================================
public MRESReturn Mitigate_IPArg(DHookParam Params)
{
	char ip[32];
	Params.GetString(1, ip, sizeof(ip));

	BlameIP(ip);

	return MRES_Handled;
}

//	Don't use this.
//	For some reason dhooks creates a new stack frame before saving registers
//	So "ebp" is not the detoured func's ebp, but the ebp of a new frame on *TOP* of our detour.
//	Yay!!!!
//
//	And I'm not in the mood to stalkwalk this--after all, what point is an exploit fix if the fix crashes the server?
//	If multiple IPs sharing the same netchan becomes an issue maybe we can dust this off.
//	~Mooshua Feb 22 2023
/*
public MRESReturn Mitigate_InvalidPacket(DHookParam Params)
{
	//	Read "this" from stack
	Address ebp = Params.GetAddress(1);
	Address var_self = ebp + Offset_ProcessPacketHeader_this;
	Address self = LoadFromAddress(var_self, NumberType_Int32);

	PrintToServer("Got self of %X, ebp %X", self, ebp);

	Address IClient;
	int	client
	if (SdkClients_GetClientFromNetChan(self, IClient, client))
	{
		BlameClient(client);
		return MRES_Handled;
	}

	return MRES_Handled;
}
*/

// 	==================================================================================
//	TIMERS
//	==================================================================================
public Action Timer_CoolDownPlayers(Handle self)
{
#if DEBUG
	PrintToServer("DEFAULT_HEAT = %i; HEAT_SUSPICIOUS = %i, HEAT_ATTACKER = %i, HEAT_BUMP_ON_REFRESH = %i", DEFAULT_HEAT, HEAT_SUSPICIOUS, HEAT_ATTACKER, HEAT_BUMP_ON_REFRESH);
#endif
	Punishment punishment = Punishment: ConPunishment.IntValue;
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
			if (ClientHeat[i] < HEAT_SUSPICIOUS)
			{
				if (ClientHeat[i] > HEAT_ATTACKER)
					CPrintToAdmins("{orange}Client '%N' ({default}#%i{orange}) has unusual network activity.", ADMINFLAG_ALERT, i, GetClientUserId(i));

				if (ClientHeat[i] <= HEAT_ATTACKER)
					CPrintToAdmins("{darkred}Client '%N' ({default}#%i{darkred}) is attempting to DDOS the server.", ADMINFLAG_ALERT, i, GetClientUserId(i));

				if (ClientHeat[i] <= 0 && punishment >= Punish_Kick)
					CPrintToAdmins("{darkred}Punishing client {default}%L{darkred} for attempted DDOS.", ADMINFLAG_ALERT, i);
			}
		}

		//	=================
		//	Punish players.
		if (ClientHeat[i] <= 0)
		{
			if (punishment == Punish_Kick)
				KickClientEx(i, "[SourceForks] Attempted DDOS");

			//	If greater than 3, treat as ban.
			if (punishment >= Punish_Ban)
				BanClient(i, 0, BANFLAG_AUTO, "[SourceForks] Attempted DDOS", "[SourceForks] Attempted DDOS", "Sourceforks", 0);
		}
	}

	//	Exonerate logic does not depend on users being in/game non-fake, etc.
	//	So it runs here.
	for (int i = 1; i < MAXPLAYERS; i++)
	{
#if DEBUG
		int before = ClientHeat[i];
#endif
		//	================
		//	Bump player heat to exonerate
		ClientHeat[i] = ClientHeat[i] + HEAT_BUMP_ON_REFRESH;
		//	Don't go to infinity!
		if (ClientHeat[i] > DEFAULT_HEAT)
			ClientHeat[i] = DEFAULT_HEAT;

#if DEBUG
		if (!IsClientInGame(i))
			continue;

		if (IsFakeClient(i))
			continue;

		PrintToServer("Client %i Heat %i + %i = %i", i, before, HEAT_BUMP_ON_REFRESH, ClientHeat[i]);
#endif
	}

	return Plugin_Continue;
}

// 	==================================================================================
//	FORWARDS
//	==================================================================================

DynamicDetour Detour_InvalidReliableState;

public OnPluginStart()
{
	//	Reset existing client's heat
	for (int i = 1; i < MAXPLAYERS; i++)
	{
		ClientHeat[i] = DEFAULT_HEAT;
	}

	//	Setup patch library
	PatchInit();

	if (GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is only compatible with CS:GO.");

	ConPunishment = CreateConVar("sourceforks_antilag_punishment",
								 "3",
								 "0 = None, 1 = Alert Admins, 2 = Kick, 3 = Permanent Ban (Default)",
								 FCVAR_PROTECTED | FCVAR_HIDDEN);

	Config		  = LoadGameConfigFile(GAMEDATA_FILE);

	//	Ratelimit spam
	NoOpFunction(Config, "Ratelimiter", "RatelimiterSize");

	//	Corrupted packet spam
	NoOpFunction(Config, "CorruptedPacket", "CorruptedPacketSize");

	//	Invalid reliable stats spam
	NoOpFunction(Config, "InvalidReliableState", "InvalidReliableStateSize");

	//	Teleport trigger cannot find destination span
	NoOpFunction(Config, "TeleportNoDestination", "TeleportNoDestinationSize");

	//	Teleport cannot find "clear" destination spam
	NoOpFunction(Config, "TeleportNoClearDestination", "TeleportNoClearDestinationSize");

	PatchCommand("noop_antilag");

	//	Now, mitigations:
	//	InvalidReliableState

	//	I shouldn't have to wonder why this is doesn't work.
	//	But for some ungodly reason it fails to fetch the IP from EAX if I don't hardcode it.
	//	Saving this around as a comment for when I do finally figure out why this awfulness is happening
	/*{
		Detour_InvalidReliableState = DynamicDetour.FromConf(Config, "Detour_InvalidReliableState");
		Detour_InvalidReliableState.Enable(Hook_Pre, Mitigate_IPArg);
	}*/
	{
		Address invalid				= Config.GetAddress("InvalidReliableState");
		Detour_InvalidReliableState = DHookCreateDetour(invalid, CallConv_CDECL, ReturnType_Void, ThisPointer_Ignore);

		//	EAX contains IP
		Detour_InvalidReliableState.AddParam(HookParamType_CharPtr, -1, DHookPass_ByVal, DHookRegister_EAX);
		Detour_InvalidReliableState.Enable(Hook_Pre, Mitigate_IPArg);
	}

	//	Load configuration
	AutoExecConfig(true, "sourceforks_antilag");

	CreateTimer(TIMER_REFRESH_FLOAT, Timer_CoolDownPlayers, 0, TIMER_REPEAT);
	// CreateTimer(30.0, Timer_WarmUpPlayers, 0, TIMER_REPEAT)
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
	RecoverFunction(Config, "TeleportNoDestination", "TeleportNoDestinationSize");
	RecoverFunction(Config, "TeleportNoClearDestination", "TeleportNoClearDestinationSize");
}