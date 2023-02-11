//	The original exploit fix was made by backwards.
//	This fork hopes to maintain the gamedata,
//	and merges some of the various plugins scattered around.

//	Original sources:
//	https://forums.alliedmods.net/showthread.php?t=321932
//	https://forums.alliedmods.net/showthread.php?t=332721

#include <sourcemod>
#include "no_op.sp"

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo =
{
	name = "[SourceForks] [CSGO] Server Exploit Fix [5/28/2021 & 3/7/2020]",
	author = "backwards",
	description = "Fixes Several Server Lag Exploits",
	version = PLUGIN_VERSION,
	url = "http://www.steamcommunity.com/id/mypassword"
}

#define GAMEDATA_FILE "sourceforks_antilag.games.txt"

GameData Config;

public OnPluginStart()
{
	NoOpInit();

	Config = LoadGameConfigFile(GAMEDATA_FILE);

	if (GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is only compatible with CS:GO.");

	//	Ratelimit spam
	NoOpFunction(Config, "Ratelimiter", "RatelimiterSize");

	//	Corrupted packet spam
	NoOpFunction(Config, "CorruptedPacket", "CorruptedPacketSize");

	//	Invalid reliable stats spam
	NoOpFunction(Config, "InvalidReliableState", "InvalidReliableStateSize");

}

public OnPluginEnd()
{
	RecoverFunction(Config, "Ratelimiter", "RatelimiterSize");
	RecoverFunction(Config, "CorruptedPacket", "CorruptedPacketSize");
	RecoverFunction(Config, "InvalidReliableState", "InvalidReliableStateSize");
}