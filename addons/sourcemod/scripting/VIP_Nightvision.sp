
#include <vip_core>

#pragma semicolon 1
#pragma newdecls required

static char g_sFeature[] = "nightvision";

public Plugin myinfo = 
{
    name	= "[VIP] Nightvision",
    author	= "asdf",
    version = "1.0"
}

public void OnPluginStart()
{
    if (VIP_IsVIPLoaded())
        VIP_OnVIPLoaded();
}

public void VIP_OnVIPLoaded()
{
    VIP_RegisterFeature(g_sFeature,BOOL, _, OnClientEnable);
}

public Action OnClientEnable(int client, const char[] szFeatureName, VIP_ToggleState EOldStatus, VIP_ToggleState &ENewStatus)
{
    bool enabled = ENewStatus == ENABLED;
    ClientCommand(client,"play items/nvg_o%s.wav",enabled ? "n":"ff");
    SetEntProp(client, Prop_Send, "m_bNightVisionOn",enabled);
}

public void VIP_OnPlayerSpawn(int client,int iTeam, bool bIsVIP)
{
    if(!bIsVIP || !VIP_IsClientFeatureUse(client, g_sFeature)) return;
    ClientCommand(client,"play items/nvg_on.wav");
    SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
}

public void OnPluginEnd()
{
    if (CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
        VIP_UnregisterFeature(g_sFeature);
}