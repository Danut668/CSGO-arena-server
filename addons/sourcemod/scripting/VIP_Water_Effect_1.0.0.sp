#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <vip_core>

public Plugin:myinfo = 
{
	name = "[VIP] Water Effect",
	author = "R1KO",
	version = "1.0.0"
};

#define VIP_WE		"WaterEffect"

public OnPluginStart() 
{
	HookEvent("player_hurt", Event_PlayerHurt);
}

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(VIP_WE, BOOL);
}

public Event_PlayerHurt(Handle:hEvent, const String:sEvName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(iClient && VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, VIP_WE))
	{
		SetVariantString("WaterSurfaceExplosion");
		AcceptEntityInput(GetClientOfUserId(GetEventInt(hEvent, "userid")), "DispatchEffect");
	}
}