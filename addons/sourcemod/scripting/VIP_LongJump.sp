#pragma semicolon 1
#include <sourcemod>
#include <vip_core>

static const char g_sFeature[] = "LongJump";

int VelocityOffset_0 = -1;
int VelocityOffset_1 = -1;
int BaseVelocityOffset = -1;
	
#pragma newdecls required

public Plugin myinfo =
{
	name = "[VIP] Long Jump",
	author = "vadrozh, R1KO",
	version = "1.3"
};

public void OnPluginStart()
{
	VelocityOffset_0 = GetSendPropOffset("CBasePlayer", "m_vecVelocity[0]");
	VelocityOffset_1 = GetSendPropOffset("CBasePlayer", "m_vecVelocity[1]");
	BaseVelocityOffset = GetSendPropOffset("CBasePlayer", "m_vecBaseVelocity");

	HookEvent("player_jump", Event_PlayerJump);
	
	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, FLOAT);
}

public int GetSendPropOffset(const char[] sNetClass, const char[] sPropertyName)
{
	int iOffset = FindSendPropInfo(sNetClass, sPropertyName);
	if (iOffset == -1) SetFailState("Fatal Error: Unable to find offset: \"%s::%s\"", sNetClass, sPropertyName);

	return iOffset;
}

public void OnPluginEnd()
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}

public Action Event_PlayerJump(Handle event, const char[] name, bool dontBroadcast)
{ 
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if(VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		float fParam = VIP_GetClientFeatureFloat(iClient, g_sFeature);
		
		if (fParam < 1.3)
		{
			char sGroup[64];
			VIP_GetClientVIPGroup(iClient, sGroup, sizeof(sGroup));
			LogError("VIP Group \"%s\" has LongJump parameter < 1.3, jump shorter than normal. Ignoring...", sGroup);
		} else {
			float finalvec[3];
			finalvec[0] = GetEntDataFloat(iClient, VelocityOffset_0) * (1.2/fParam);
			finalvec[1] = GetEntDataFloat(iClient, VelocityOffset_1) * (1.2/fParam);
			finalvec[2] = 0.0;
			SetEntDataVector(iClient, BaseVelocityOffset, finalvec, true);
		}
	}
}