
Handle SDKCall_GetPlayerSlot;
Handle SDKCall_GetMsgHandler;

void SdkClients_Setup()
{
    GameData Data = LoadGameConfigFile("sourceforks_sdk_clients");

    StartPrepSDKCall( SDKCall_Raw );
    PrepSDKCall_SetFromConf( Data, SDKConf_Virtual, "CNetChan::GetMsgHandler" );
    PrepSDKCall_SetReturnInfo( SDKType_PlainOldData, SDKPass_Plain );
    SDKCall_GetMsgHandler = EndPrepSDKCall();

    StartPrepSDKCall( SDKCall_Raw );
    PrepSDKCall_SetFromConf( Data, SDKConf_Virtual, "CBaseClient::GetPlayerSlot" );
    PrepSDKCall_SetReturnInfo( SDKType_PlainOldData, SDKPass_Plain );
    SDKCall_GetPlayerSlot = EndPrepSDKCall();

    if (SDKCall_GetMsgHandler == INVALID_HANDLE)
        SetFailState("[SourceForks SDK] Failed to initialize CNetChan::GetMsgHandler");

    if (SDKCall_GetPlayerSlot == INVALID_HANDLE)
        SetFailState("[SourceForks SDK] Failed to initialize CBaseClient::GetPlayerSlot");
}

//  From STAC. Thanks sappho!
//  https://github.com/sapphonie/StAC-tf2/blob/fixup-oversights/scripting/stac/stac_memory.sp#L145-L168
bool SdkClients_GetClientFromNetChan(Address pThis, Address& IClient, int& client)
{
    IClient = Address_Null;
    client  = -1;
    // sanity check
    if (!pThis)
    {
        return false;
    }

    IClient = SDKCall( SDKCall_GetMsgHandler, pThis );
    // Clients will be null when connecting and disconnecting
    if (!IClient)
    {
        return false;
    }

    // Client's ent index is always GetPlayerSlot() + 1
    client = SDKCall(SDKCall_GetPlayerSlot, IClient) + 1;

    return true;
}