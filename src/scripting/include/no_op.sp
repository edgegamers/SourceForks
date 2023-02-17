//  Utilities for no-oping blocks of code.

#include <sourcemod>
#define NULLPTR view_as<Address>(0)
#define BUFFER_SIZE 128

//  The original byte content of the patches
StringMap Originals;

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

public Action Command_NoOpStatus(int client, int argc)
{
	ReplyToCommand(client, "[NoOp] Hello!");

	StringMapSnapshot snapshot = Originals.Snapshot();
	int length = snapshot.Length;

	ReplyToCommand(client, "[NoOp] Found %i patches.", length);

	for (int i = 0; i < length; i++)
	{
		//	Recover key
		char key[BUFFER_SIZE];
		snapshot.GetKey(i, key, sizeof(key));

		//	Recover originals
		any[] originals = new any[BUFFER_SIZE];
		int original_length = 0;
		if (!Originals.GetArray(key, originals, BUFFER_SIZE, original_length))
		{
			LogError("Unable to recover originals for no-op '%s'.", key);
			ReplyToCommand(client, "[NoOp] '%s': Couldn't find original for patch", key);
			continue;
		}

		char[] original_hex = new char[original_length * 8];
		for (int j = 0; j < original_length; j++)
		{

			Format(original_hex, original_length * 8, "%s %X", original_hex, originals[j]);
		}

		ReplyToCommand(client, "[NoOp] '%s': Original [%i] <%s >", key, original_length, original_hex);

	}

	ReplyToCommand(client, "[NoOp] Goodbye!");
	return Plugin_Handled;
}

stock void NoOpCommand(const char[] name)
{
	RegAdminCmd(name, Command_NoOpStatus, ADMFLAG_RCON, "Displays patch status and information", "no_op");
}