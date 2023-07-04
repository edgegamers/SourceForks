#include <sourcemod>
#include "asm_patch.sp"
#include "sourceforks_version.sp"

public Plugin myinfo = {
	name		= "[SourceForks] [CSGO] Spawn Bug Fix",
	author		= "EdgeGamers Development",
	description = "Patches an issue where players are able to spawn in enemy spawn zones.",
	version		= PLUGIN_VERSION,
	url			= PLUGIN_WEBSITE
}

#define GAMEDATA_FILE "sourceforks_spawnbug"

GameData Config;

public OnPluginStart()
{
	PatchInit();

	Config = LoadGameConfigFile(GAMEDATA_FILE);

	if (GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is only compatible with CS:GO.");

	PatchCommand("noop_spawnbug");

	//  Just disable the whole thing
	any spawnbug_patch[] = { RET_NEAR };
	PatchFunction(Config, "Spawnbug", "SpawnbugSize", spawnbug_patch, sizeof(spawnbug_patch));
}

public OnPluginEnd()
{
	RecoverFunction(Config, "Spawnbug", "SpawnbugSize");
}