#include <vip_core>

#define VIP_FastPlant "Fastplant"

public void OnPluginStart()
{
	HookEvent("bomb_beginplant", BombBP, EventHookMode_Post);
	
	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public int VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(VIP_FastPlant, BOOL);
}

public void OnPluginEnd()
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_FastPlant") == FeatureStatus_Available)
    {
		VIP_UnregisterFeature(VIP_FastPlant);
	}
}

// by wS
public Action BombBP(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(VIP_IsClientVIP(client) && VIP_IsClientFeatureUse(client, VIP_FastPlant))
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (weapon > 0)
		{
			char class[32];
			if (GetEntityClassname(weapon, class, sizeof(class) && !strcmp(class[7], "c4", false)))
			{
				SetEntPropFloat(weapon, Prop_Send, "m_fArmedTime", GetGameTime());
				//PrintToChatAll(" \x04| VIP | \x07%N \x01 > \x04Использовал(а) фастплнет!", client);
			}
		}
	}
}