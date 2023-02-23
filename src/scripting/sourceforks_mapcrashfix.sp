#include <sourcemod>
#include "asm_patch.sp"
#include "sourceforks_version.sp"

public Plugin myinfo = {
	name		= "[SourceForks] [CSGO] Generic Map Crash Fixes",
	author		= "EdgeGamers Development",
	description = "Prevents various map issues from crashing the server.",
	version		= PLUGIN_VERSION,
	url			= "https://edgegamers.com"
}

#define GAMEDATA_FILE "sourceforks_mapcrashfix"

GameData Config;

public OnPluginStart()
{
	PatchInit();

	Config = LoadGameConfigFile(GAMEDATA_FILE);

	if (GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is only compatible with CS:GO.");

	PatchCommand("noop_mapcrashfix");
    //  GameUI::Deactivate fix
	NoOpFunction(Config, "DeactivateNullReference", "DeactivateNullReferenceSize");
    //  CNavMesh::UpdateGeneration fix
    NoOpFunction(Config, "NavmeshUpdateGeneration", "NavmeshUpdateGenerationSize");

}

public OnPluginEnd()
{
	RecoverFunction(Config, "DeactivateNullReference", "DeactivateNullReferenceSize");
    RecoverFunction(Config, "NavmeshUpdateGeneration", "NavmeshUpdateGenerationSize");
}