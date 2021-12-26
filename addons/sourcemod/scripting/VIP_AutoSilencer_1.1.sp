#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <vip_core>

public Plugin:myinfo = 
{
	name = "[VIP] Auto Silencer [cssv34]",
	author = "R1KO",
	version = "1.1"
};

static const String:g_sFeature[][] = {"AutoSilencer_usp", "AutoSilencer_m4a1"};

public OnPluginStart() 
{
	HookEvent("item_pickup", Event_ItemPickup);

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature[0],	BOOL);
	VIP_RegisterFeature(g_sFeature[1],	BOOL);
}

public OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature[0]);
		VIP_UnregisterFeature(g_sFeature[1]);
	}
}

public Event_ItemPickup(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(iClient && VIP_IsClientVIP(iClient))
	{
		decl String:sWeapon[32];
		GetEventString(hEvent, "item", sWeapon, sizeof(sWeapon));
	//	PrintToChat(iClient, "item: %s", sWeapon);
		if (strcmp(sWeapon, "m4a1") == 0 && VIP_IsClientFeatureUse(iClient, g_sFeature[1]))
		{
			SilencerOn(iClient, 0);
		}
		else if (strcmp(sWeapon, "usp") == 0 && VIP_IsClientFeatureUse(iClient, g_sFeature[0]))
		{
			SilencerOn(iClient, 1);
		}
	}
}

SilencerOn(iClient, iSlot)
{
	new iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
	if (iWeapon != -1)
	{
		SetEntProp(iWeapon, Prop_Send, "m_bSilencerOn", 1);
	//	SetEntProp(iWeapon, Prop_Send, "m_weaponMode", 1);
	}
}