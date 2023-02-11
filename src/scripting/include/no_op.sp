//  Utilities for no-oping blocks of code.

#include <sourcemod>
#define NULLPTR view_as<Address>(0)

//  The original byte content of the patches
StringMap Originals;

#define CLEAN 0
#define INJECTED 1

stock void NoOpInit()
{
	Originals = new StringMap();
}

stock void NoOpAddress(Address start, const char[] key, int size)
{
    any[] originals = new any[size];

	for(int i = 0;i<size;i++)
    {
        any byte = LoadFromAddress(start + Address:i, NumberType_Int8);
        originals[i] = byte;
    
		StoreToAddress(start + Address:i, 0x90, NumberType_Int8);
    }

    //  "false" replace ensures we don't accidentally overwrite valid original with no-ops
    Originals.SetArray(key, originals, size, false);
}

stock void RestoreAddress(Address start, const char[] key, int size)
{
    any[] originals = new any[size];

    if (!Originals.GetArray(key, originals, size))
    {
        LogError("Unable to recover originals for no-op '%s'.", key);
		return;
    }

    for(int i = 0;i<size;i++)
    {
		StoreToAddress(start + Address:i, originals[i] , NumberType_Int8);
    }
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
	NoOpAddress(Func, name, FuncSize);
}

stock void RecoverFunction(GameData gamedata, const char[] name, const char[] sizename)
{
    Address Func = gamedata.GetAddress(name);
		
	if (Func == NULLPTR) {
		LogError("Unable to find address for %s. Fix will not be reverted for that exploit.", name);
		return;
	}
	
	int FuncSize = GetKeyInt(gamedata, sizename);
	RestoreAddress(Func, name, FuncSize);
}