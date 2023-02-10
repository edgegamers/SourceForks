//	The original exploit fix was made by backwards.
//	This fork hopes to maintain the gamedata,
//	and merges some of the various plugins scattered around.

//	Original sources:
//	https://forums.alliedmods.net/showthread.php?t=321932
//	https://forums.alliedmods.net/showthread.php?t=332721


#include <sourcemod>

public Plugin:myinfo =
{
	name = "[SourceForks] [CSGO] Server Exploit Fix [5/28/2021 & 3/7/2020]",
	author = "backwards",
	description = "Fixes Several Server Lag Exploits",
	version = SOURCEMOD_VERSION,
	url = "http://www.steamcommunity.com/id/mypassword"
}

#define GAMEDATA_FILE "sourceforks_antilag.games.txt"
#define NULLPTR view_as<Address>(0)

stock void NoOpAddress(Address start, int size)
{
	for(int i = 0;i<size;i++)
		StoreToAddress(start + Address:i, 0x90, NumberType_Int8);
}

stock int GetKeyInt(GameData gamedata, const char[] key)
{
	char buffer[32];

	gamedata.GetKeyValue(key, buffer, sizeof(buffer));

	int asInt = StringToInt(buffer);

	if (asInt == 0)
	{
		LogError("Failed to get keyvalue '%s': Parsing '%s' as int yielded null.", key, buffer);
		SetFailState("Failed to parse gamedata keyvalues");
		return 0;
	}

	return asInt;
}

stock void NoOpFunction(GameData gamedata, const char[] name, const char[] sizename)
{
	Address Func = gamedata.GetAddress(name);
		
	if (Func == NULLPTR) {
		LogError("Unable to find address for %s. Fix will not be applied for that exploit.", name);
		return;
	}
	
	int FuncSize = GetKeyInt(gamedata, sizename);
	NoOpAddress(Func, FuncSize);
}

public OnPluginStart()
{
	GameData config = LoadGameConfigFile(GAMEDATA_FILE);

	if (GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is only compatible with CS:GO.");

	//	Ratelimit spam
	NoOpFunction(config, "Ratelimiter", "RatelimiterSize");

	//	Corrupted packet spam
	NoOpFunction(config, "CorruptedPacket", "CorruptedPacketSize");

	//	Invalid reliable stats spam
	NoOpFunction(config, "InvalidReliableState", "InvalidReliableStateSize");

}