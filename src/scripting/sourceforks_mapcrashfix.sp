#include <sourcemod>
#include "asm_patch.sp"
#include "asm_x86.sp"
#include "sourceforks_version.sp"

public Plugin myinfo = {
	name		= "[SourceForks] [CSGO] Generic Map Crash Fixes",
	author		= "EdgeGamers Development",
	description = "Prevents various map issues from crashing the server.",
	version		= PLUGIN_VERSION,
	url			= PLUGIN_WEBSITE
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
	//	CTeleportTrigger::Touch fix
	
	//	Push a imm32 of value 0x0 to the stack.
	any teleport_ent_lookup[] = { PUSH_IMM32, 0, 0, 0, 0 };
	PatchFunction(Config, "TeleportEntLookup", "TeleportEntLookupSize", teleport_ent_lookup, sizeof(teleport_ent_lookup));

}

public OnPluginEnd()
{
	RecoverFunction(Config, "DeactivateNullReference", "DeactivateNullReferenceSize");
	RecoverFunction(Config, "NavmeshUpdateGeneration", "NavmeshUpdateGenerationSize");
	RecoverFunction(Config, "TeleportEntLookup", "TeleportEntLookupSize");
}