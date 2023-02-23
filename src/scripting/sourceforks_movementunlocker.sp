#include <sourcemod>
#include "asm_patch.sp"
#include "sourceforks_version.sp"

public Plugin myinfo = {
	name		= "[SourceForks] [CSGO] Movement Unlocker",
	author		= "Peace-Maker",
	description = "Removes max speed limitation from players on the ground. Feels like CS:S.",
	version		= PLUGIN_VERSION,
	url			= "http://www.wcfan.de/"
}

#define GAMEDATA_FILE "sourceforks_movementunlocker"

		 GameData Config;

public OnPluginStart()
{
	PatchInit();

	Config = LoadGameConfigFile(GAMEDATA_FILE);

	if (GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is only compatible with CS:GO.");

	PatchCommand("noop_movementunlocker");
	NoOpFunction(Config, "WalkMoveMaxSpeed", "WalkMoveMaxSpeedSize");
}

public OnPluginEnd()
{
	RecoverFunction(Config, "WalkMoveMaxSpeed", "WalkMoveMaxSpeedSize");
}