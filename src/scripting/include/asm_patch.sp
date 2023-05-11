//  Utilities for no-oping blocks of code.

#include <sourcemod>
#define NULLPTR view_as<Address>(0)
#define BUFFER_SIZE 128

//  The original byte content of the patches
StringMap Originals;

stock void PatchInit()
{
	Originals = new StringMap();
}

//	=============================================================
//	PATCH STOCKS
//	=============================================================

stock bool ByteOverflowCheck(const any[] list, int listsize)
{
	for(int i = 0; i < listsize; i++)
	{
		if (list[i] >= 256)
			return false;
	}
	return true;
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

//	Designed to patch the beginning of an instruction
//	(Replaces bytes before (size - replacementSize) with no-op's)
//	Assumes that the replacement is smaller than the original.
stock void PatchAddressInstBegin(Address start, const char[] key, int size, const any[] replacement, int replacementSize)
{
	//	Verify replacement does not overflow
	if (!ByteOverflowCheck(replacement, replacementSize))
	{
		LogError("[SourceForks Patch] Unable to patch: Cannot coerce 'any' value to byte without loss of precision. (%s)", key)
		return;
	}
	any[] originals = new any[size];

	//	First, no-op some bytes
	int noopSize = size - replacementSize;

	for(int i = 0; i<noopSize; i++)
	{
		any byte = LoadFromAddress(start + Address:i, NumberType_Int8);
		originals[i] = byte;
	
		StoreToAddress(start + Address:i, 0x90, NumberType_Int8);
	}

	//	Then, patch some bytes!
	//	These are very helpful comments, I know.
	int patchBegin = noopSize;

	for (int i = 0; i<replacementSize; i++)
	{
		any byte = LoadFromAddress(start + Address:i + Address:patchBegin, NumberType_Int8);
		originals[i + patchBegin] = byte;
	
		StoreToAddress(start + Address:i + Address:patchBegin, replacement[i], NumberType_Int8);
	}

	//  "false" replace ensures we don't accidentally overwrite valid original with no-ops
	Originals.SetArray(key, originals, size, false);
}

//	=============================================================
//	RESTORE STOCKS
//	=============================================================

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

//	=============================================================
//	UTILITIES
//	=============================================================

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

//	=============================================================
//	PUBLIC INTERFACE
//	=============================================================

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

stock void PatchFunction(GameData gamedata, const char[] name, const char[] sizename, const any[] replacement, int replacementSize)
{
	Address Func = gamedata.GetAddress(name);
		
	if (Func == NULLPTR) {
		LogError("Unable to find address for %s. Fix will not be applied for that exploit.", name);
		return;
	}
	
	int FuncSize = GetKeyInt(gamedata, sizename);
	PatchAddressInstBegin(Func, name, FuncSize, replacement, replacementSize);
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

stock void PatchCommand(const char[] name)
{
	RegAdminCmd(name, Command_PatchStatus, ADMFLAG_RCON, "Displays patch status and information", "no_op");
}

//	=============================================================
//	COMMANDS
//	=============================================================

public Action Command_PatchStatus(int client, int argc)
{
	ReplyToCommand(client, "[SourceForks Patches] Hello!");

	StringMapSnapshot snapshot = Originals.Snapshot();
	int length = snapshot.Length;

	ReplyToCommand(client, "[SourceForks Patches] Found %i patches.", length);

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
			ReplyToCommand(client, "[SourceForks Patches] '%s': Couldn't find original for patch", key);
			continue;
		}

		char[] original_hex = new char[original_length * 8];
		for (int j = 0; j < original_length; j++)
		{
			Format(original_hex, original_length * 8, "%s %02X", original_hex, originals[j]);
		}

		ReplyToCommand(client, "[SourceForks Patches] '%s': Original [%i] <%s >", key, original_length, original_hex);

	}

	ReplyToCommand(client, "[SourceForks Patches] Goodbye!");
	return Plugin_Handled;
}

#undef BUFFER_SIZE
#undef NULLPTR