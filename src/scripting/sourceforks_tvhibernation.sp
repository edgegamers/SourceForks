#include <sourcemod>
#include <dhooks>
#include "sourceforks_admin_utils.sp"
#include "asm_patch.sp"
#include "asm_x86.sp"
#include "sourceforks_version.sp"

public Plugin myinfo =
{
	name		= "[SourceForks] [CSGO] GOTV Hibernation Fix",
	author		= "EdgeGamers Development",
	description = "Prevents kicking GOTV bots during server hibernation.",
	version		= PLUGIN_VERSION,
	url			= "https://edgegamers.com"

}

#define GAMEDATA_FILE "sourceforks_tvhibernation"
#define ADMINFLAG_ALERT		 (ADMFLAG_KICK)


GameData Config;
Address	 OffsetIsHltv;
DynamicDetour DetourDisconnect

public MRESReturn Detour_Disconnect(Address client, DHookParam parameters)
{
	int isHltv = LoadFromAddress(client + OffsetIsHltv, NumberType_Int8);

	if (isHltv == 0)
		return MRES_Ignored;

	//	only need the first few bytes to see if it's 'override'
	char reason[16];
	parameters.GetString(1, reason, sizeof(reason));

	CPrintToAdminsNoServer("{darkred}If you are seeing this message, this is a severe bug.",ADMINFLAG_ALERT);
	CPrintToAdminsNoServer("{darkred}Tell a server administrator to immediately disable 'sourceforks_tvhibernation.smx', and to wait for a patch at github.com/edgegamers/sourceforks",ADMINFLAG_ALERT);
	CPrintToAdminsNoServer("Use the reason 'override' when kicking players or the kick will not succeed.",ADMINFLAG_ALERT);

	//	if reason == override, then this is likely an admin performing a kick, and this->isHLTV is likely a bad offset.
	//	go through with the disconnect.
	if (StrEqual(reason, "override"))
		return MRES_Ignored;

	CPrintToAdmins("{darkred}!! THE PREVIOUS DISCONNECT WAS NOT EXECUTED !!",ADMINFLAG_ALERT);

	//	Do not call original implementation if this is a HLTV server.
	PrintToServer("[SourceForks Server] Blocked disconnect of GOTV client. If you want to remove this bot, restart the server with tv_enabled set to 0.");
	return MRES_Supercede;
}

public OnPluginStart()
{
	PatchInit();

	Config = LoadGameConfigFile(GAMEDATA_FILE);

	if (GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is only compatible with CS:GO.");

	OffsetIsHltv	 = Address: Config.GetOffset("CBaseClient->IsHLTV");
	DetourDisconnect = DynamicDetour.FromConf(Config, "CBaseClient::Disconnect");
	DetourDisconnect.Enable(Hook_Pre, Detour_Disconnect);
}

public OnPluginEnd()
{
	DetourDisconnect.Disable(Hook_Pre, Detour_Disconnect);
}