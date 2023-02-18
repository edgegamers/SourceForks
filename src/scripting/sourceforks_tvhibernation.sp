#include <sourcemod>
#include "asm_patch.sp"
#include "asm_x86.sp"
#include "sourceforks_version.sp"

public Plugin myinfo = {
	name		= "[SourceForks] GOTV Hibernation Fix",
	author		= "EdgeGamers Development",
	description = "Prevents kicking GOTV bots during server hibernation.",
	version		= PLUGIN_VERSION,
	url			= "https://edgegamers.com"
}

#define GAMEDATA_FILE "sourceforks_tvhibernation.games"

GameData Config;

public OnPluginStart()
{
	PatchInit();

	Config = LoadGameConfigFile(GAMEDATA_FILE);

	if (GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is only compatible with CS:GO.");

	PatchCommand("noop_tvhibernation");

	NoOpFunction(Config, "PuntBot", "PuntBotSize");
}

public OnPluginEnd()
{
	RecoverFunction(Config, "PuntBot", "PuntBotSize");
}