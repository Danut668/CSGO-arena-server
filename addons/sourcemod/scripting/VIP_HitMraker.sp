#pragma semicolon 1
#include <sourcemod>
#include <sdktools_stringtables>
#include <vip_core>

char g_sFeature[] = "HitMarker"; 
bool:CSGO;	
	
public Plugin myinfo =
{
	name = "[VIP]Hitmarker",
	description = "",
	author = "iEx (rework by SHKIPPERBEAST)",
	version = "1.0",
	url = ""
};
	
public OnPluginStart()
{
	HookEvent("player_hurt", player_hunt);
	
	CSGO = GetEngineVersion() == Engine_CSGO;
	
	if (VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL);
}

public OnMapStart()
{
	AddFileToDownloadsTable("materials/iex/hit02.vmt");
	AddFileToDownloadsTable("materials/iex/hit02.vtf");

	PrecacheModel("materials/iex/hit02.vmt", true);
}

public player_hunt(Handle:event, const String:name[], bool:silent)
{
	static U, A;
	U = GetEventInt(event, "attacker");
	A = GetClientOfUserId(U);
	if(A && A != GetClientOfUserId(GetEventInt(event, "userid")))
	{
		new client = GetClientOfUserId(GetEventInt(event, "attacker"));

		if (!VIP_IsClientVIP(client) || !VIP_IsClientFeatureUse(client, g_sFeature))
		{
			return;
		}
	
		ClientCommand(client, "r_screenoverlay iex/hit02.vmt");
		CreateTimer(0.2, Timer_RemoveHitMarker, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_RemoveHitMarker(Handle:timer, client)
{
	ClientCommand(client, "r_screenoverlay off");
}

public void OnPluginEnd()
{
    if (CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
    {
        VIP_UnregisterFeature(g_sFeature);
    }
}