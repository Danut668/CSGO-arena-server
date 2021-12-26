#pragma semicolon 1
#include <sourcemod>

#include <vip_core>
#include <throwing_knives_core>

public Plugin:myinfo = 
{
	name = "[VIP] Throwing Knives",
	author = "R1KO",
	version = "1.4"
};

new const String:g_sFeature[] = "ThrowingKnives";

public OnPluginStart()
{
	LoadTranslations("vip_modules.phrases");

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public OnPluginEnd()
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, INT, _, OnItemToggle, OnItemDisplay);
}

public bool:OnItemDisplay(iClient, const String:sFeatureName[], String:sDisplay[], iMaxLen)
{
	if(VIP_IsClientFeatureUse(iClient, sFeatureName))
	{
		new iCount = VIP_GetClientFeatureInt(iClient, sFeatureName);
		if(iCount != -1)
		{
			FormatEx(sDisplay, iMaxLen, "%T [+%d]", sFeatureName, iClient, iCount);
			return true;
		}
	}

	return false;
}

public Action:OnItemToggle(iClient, const String:sFeatureName[], VIP_ToggleState:OldStatus, &VIP_ToggleState:NewStatus)
{
	if(NewStatus != ENABLED)
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public VIP_OnPlayerSpawn(iClient, iTeam, bool:bIsVIP)
{
	if(bIsVIP)
	{
		VIP_OnVIPClientLoaded(iClient);
	}
}

public VIP_OnVIPClientLoaded(iClient)
{
	if(VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		new iCount = VIP_GetClientFeatureInt(iClient, g_sFeature);
		new iLimit = TKC_GetClientKnivesLimit(iClient);
		new iKnives = TKC_GetClientKnives(iClient, false);
		if(iCount == -1)
		{
			if(iLimit != iCount)
			{
				TKC_SetClientKnivesLimit(iClient, iCount);
			}
			
			TKC_SetClientKnives(iClient, iCount, false);
			return;
		}

		if(iLimit != -1 && (iLimit < iKnives+iCount))
		{
			TKC_SetClientKnivesLimit(iClient, iKnives+iCount);
		}
		if(iKnives != -1 && (iKnives < iCount))
		{
			TKC_GiveClientKnives(iClient, iCount, false);
		}
	}
}