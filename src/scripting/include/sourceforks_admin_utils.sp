//  Utilities to assist with printing messages to admins

#include <multicolors>
#include <sourcemod>

#define BUFFER_SIZE 512

stock void PrintToAdmins(const char[] format, AdminFlag flags, ...)
{
	char buffer[BUFFER_SIZE];
	VFormat(buffer, sizeof(buffer), format, 3);

    PrintToServer("[SourceForks Server]: %s", buffer);

	for (int admin = 1; admin < MAXPLAYERS; admin++)
	{
		if (!CheckCommandAccess(admin, "", int:flags, true))
			continue;

		PrintToChat(admin, "[SourceForks]: %s", buffer);
	}
}

stock void CPrintToAdmins(const char[] in_format, AdminFlag flags, ...)
{
	char buffer[BUFFER_SIZE];
    char format[BUFFER_SIZE];

    strcopy(format, sizeof(format), in_format);
    //  Consume buffer early to print to server
    {
        CRemoveTags(format, sizeof(format));
        VFormat(buffer, sizeof(buffer), format, 3);
        PrintToServer("[SourceForks Server]: %s", buffer);
    }
    strcopy(format, sizeof(format), in_format);

    //  Now do color formatting
    {
        CFormatColor(format, sizeof(format), -1);
        VFormat(buffer, sizeof(buffer), format, 3);
    }
	for (int admin = 1; admin < MAXPLAYERS; admin++)
	{
		if (!CheckCommandAccess(admin, "", int:flags, true))
			continue;

		PrintToChat(admin, "[SourceForks]: %s", buffer);
	}
}

stock void CPrintToAdminsNoServer(const char[] in_format, AdminFlag flags, ...)
{
	char buffer[BUFFER_SIZE];
    char format[BUFFER_SIZE];

    strcopy(format, sizeof(format), in_format);

    //  Now do color formatting
    {
        CFormatColor(format, sizeof(format), -1);
        VFormat(buffer, sizeof(buffer), format, 3);
    }
	for (int admin = 1; admin < MAXPLAYERS; admin++)
	{
		if (!CheckCommandAccess(admin, "", int:flags, true))
			continue;

		PrintToChat(admin, "[SourceForks]: %s", buffer);
	}
}