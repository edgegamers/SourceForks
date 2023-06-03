#include <sourcemod>
#include <dhooks>
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
#define DEBUG 0

GameData Config;
DynamicDetour Detour_GameUIDeactivate;


public OnPluginStart()
{
	PatchInit();

	Config = LoadGameConfigFile(GAMEDATA_FILE);

	if (GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is only compatible with CS:GO.");

	PatchCommand("noop_mapcrashfix");
	//  CNavMesh::UpdateGeneration fix
	NoOpFunction(Config, "NavmeshUpdateGeneration", "NavmeshUpdateGenerationSize");
	//	CTeleportTrigger::Touch fix
	
	//	Push a imm32 of value 0x0 to the stack.
	any teleport_ent_lookup[] = { PUSH_IMM32, 0, 0, 0, 0 };
	PatchFunction(Config, "TeleportEntLookup", "TeleportEntLookupSize", teleport_ent_lookup, sizeof(teleport_ent_lookup));

	Detour_GameUIDeactivate = DynamicDetour.FromConf(Config, "CGameUI::Deactivate");
	Detour_GameUIDeactivate.Enable(Hook_Pre, GameUIDeactivate)
}

#define GAMEUI_FREEZE 0x20
#define GAMEUI_WEAPON 0x40

#define FLAG_FROZEN 0x80
#define HIDE_HUD_FLAG 0x1

public MRESReturn GameUIDeactivate(int self, DHookParam params)
{
	#if DEBUG
		PrintToServer("CGameUI::Deactivate (%d)", self);
	#endif

	//	Get the player entity
	int player = GetEntPropEnt(self, Prop_Data, "m_player");

	#if DEBUG
		PrintToServer("CGameUI::Deactivate - Player (%d)", player);
	#endif

	//	Is the player still valid/in game?
	//	If so, handle some funky logic
	if (player != -1)
	{
		int spawnflags = GetEntProp(self, Prop_Data, "m_spawnflags");

		#if DEBUG
			PrintToServer("CGameUI::Deactivate - Spawnflags %b - Player %N", spawnflags, player);
		#endif

		if ((spawnflags & GAMEUI_FREEZE) != 0)
		{
			//	GameUI is in freeze mode.
			//	Remove the frozen flag from the player
			int old_flags = GetEntProp(player, Prop_Data, "m_fFlags");

			#if DEBUG
				PrintToServer("CGameUI::Deactivate - Unfreezing");
			#endif

			SetEntProp(player, Prop_Data, "m_fFlags", old_flags & (~FLAG_FROZEN));
		}

		if ((spawnflags & GAMEUI_WEAPON))
		{
			//	GameUI is in hide-hud mode.
			//	Re-enable the hud and give player weapons
			int old_flags = GetEntProp(player, Prop_Send, "m_iHideHUD");
			int old_weapon = GetEntPropEnt(self, Prop_Data, "m_hSaveWeapon");

			SetEntProp(player, Prop_Send, "m_iHideHUD", old_flags & (~HIDE_HUD_FLAG));

			#if DEBUG
				PrintToServer("CGameUI::Deactivate - Re-Weaponing (%d)", old_weapon);
			#endif

			if (old_weapon != -1)
				EquipPlayerWeapon(player, old_weapon);
		}

		//	Fire some outputs to reset everything to 0
		FireEntityOutput(self, "PlayerOff", player, 0.0);

		SetVariantFloat(0.0); 	FireEntityOutput(self, "XAxis", player, 0.0);
		SetVariantFloat(0.0); 	FireEntityOutput(self, "YAxis", player, 0.0);
		SetVariantFloat(0.0); 	FireEntityOutput(self, "AttackAxis", player, 0.0);
		SetVariantFloat(0.0); 	FireEntityOutput(self, "Attack2Axis", player, 0.0);
	}
	else
	{
		//	NOT BASEGAME: Ensure playeroff is always fired
		FireEntityOutput(self, "PlayerOff", self, 0.0);
	}
	//	Reset the game_ui
	SetEntProp(self, Prop_Data, "m_nLastButtonState", 0.0);
	SetEntPropEnt(self, Prop_Data, "m_player", -1);

	#if DEBUG
		PrintToServer("CGameUI::Deactivate - Done", self);
	#endif

	//	Prevent original (crashing) function from being called
	return MRES_Supercede;
}

public OnPluginEnd()
{
	Detour_GameUIDeactivate.Disable(Hook_Pre, GameUIDeactivate);
	RecoverFunction(Config, "NavmeshUpdateGeneration", "NavmeshUpdateGenerationSize");
	RecoverFunction(Config, "TeleportEntLookup", "TeleportEntLookupSize");
}