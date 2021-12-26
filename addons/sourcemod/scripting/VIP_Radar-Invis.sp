#pragma semicolon 1
#include <sdktools>
#include <vip_core>

public Plugin myinfo =
{
	name = "[VIP] Radar Invis",
	author = "Pheonix (˙·٠●Феникс●٠·˙)",
	version = "1.3",
	url = "zizt.ru"
};

static const char g_sRadarInvis[] = "Radar-Invis";

int g_iOffsetCanBeSpotted;

public void OnPluginStart()
{
	g_iOffsetCanBeSpotted = FindSendPropInfo("CBaseEntity", "m_bSpotted") - 4;
	
	if(VIP_IsVIPLoaded()) VIP_OnVIPLoaded();
}

public OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sRadarInvis);
	}
}

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sRadarInvis, BOOL, TOGGLABLE, ToggleItemCallback);
}

public Action ToggleItemCallback(int iClient, const char[] sFeatureName, VIP_ToggleState OldStatus, VIP_ToggleState &Status)
{
	if(Status == ENABLED)
	{
		SetEntProp(iClient, Prop_Send, "m_bSpotted", false);
		SetEntProp(iClient, Prop_Send, "m_bSpottedByMask", 0, 4, 0);
		SetEntProp(iClient, Prop_Send, "m_bSpottedByMask", 0, 4, 1);
		SetEntData(iClient, g_iOffsetCanBeSpotted, 0);
	}
	else SetEntData(iClient, g_iOffsetCanBeSpotted, 9);
}