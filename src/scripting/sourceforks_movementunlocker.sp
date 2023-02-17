#include <sourcemod>
#include "no_op.sp"
#include "version.sp"

public Plugin: myinfo = {
	name		= "[SourceForks] [CSGO] Movement Unlocker",
	author		= "Peace-Maker",
	description = "Removes max speed limitation from players on the ground. Feels like CS:S.",
	version		= PLUGIN_VERSION,
	url			= "http://www.wcfan.de/"
}

#define GAMEDATA_FILE "sourceforks_movementunlocker.games"

		 GameData Config;

public OnPluginStart()
{
	NoOpInit();

	Config = LoadGameConfigFile(GAMEDATA_FILE);

	if (GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is only compatible with CS:GO.");

	NoOpCommand("noop_movementunlocker");
	NoOpFunction(Config, "WalkMoveMaxSpeed", "WalkMoveMaxSpeedSize");
}

public OnPluginEnd()
{
	RecoverFunction(Config, "WalkMoveMaxSpeed", "WalkMoveMaxSpeedSize");
}