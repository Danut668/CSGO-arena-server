#include <sourcemod>
#include <vip_core>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "[VIP]God",
	author = "DenisPukin",
	version = "1.3",
	url = "hlmod.ru/members/denispukin.85089/"
}

static const char g_sFeature[] = "GOD";

Handle God_Timer[MAXPLAYERS+1];
ConVar g_cvGodTime = null;

public void OnPluginStart()
{
	g_cvGodTime = CreateConVar("vip_godtime", "15", "How many seconds will immortality be?");
	
	AutoExecConfig(true, "VIP_GOD", "vip");
	
	HookEvent("player_spawn", Event_PlayerSpawn);

	if(VIP_IsVIPLoaded())	VIP_OnVIPLoaded();
}

public void VIP_OnVIPLoaded()
{
    VIP_RegisterFeature(g_sFeature, INT);
}

public void Event_PlayerSpawn(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid")); 
	if(VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		SetEntProp(iClient, Prop_Data, "m_takedamage", 0);
		VIP_PrintToChatClient(iClient, "\x03You have immortality on for \x04%i \x03Seconds.", g_cvGodTime.IntValue);
		if(God_Timer[iClient])	KillTimer(God_Timer[iClient]);
		God_Timer[iClient] = CreateTimer(g_cvGodTime.FloatValue, Timer_God, GetClientUserId(iClient));
	}
}

public void OnClientDisconnect(int iClient)
{
    if(God_Timer[iClient])
    {
        KillTimer(God_Timer[iClient]);
        God_Timer[iClient] = null;
    }
}

public Action Timer_God(Handle hTimer, any UserId)
{
	int iClient = GetClientOfUserId(UserId);
	if(iClient)
	{
		SetEntProp(iClient, Prop_Data, "m_takedamage", 2);
		VIP_PrintToChatClient(iClient, "\x03Immortality \x04is \x03over!");
		God_Timer[iClient] = null; 
	}
	return Plugin_Stop;
}

public void OnPluginEnd()
{
    if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
    {
        VIP_UnregisterFeature(g_sFeature);
    }
}