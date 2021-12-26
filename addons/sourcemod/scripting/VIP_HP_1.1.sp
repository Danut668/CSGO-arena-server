#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>
#include <vip_core>

public Plugin:myinfo =
{
	name = "[VIP] HP",
	author = "R1KO (skype: vova.andrienko1)",
	version = "1.1"
};

#define MENU_INFO 	1 // Отображать ли информацию в меню

new const String:g_sFeature[] = "HP";

new m_iHealth;

public VIP_OnVIPLoaded()
{
	#if MENU_INFO 1
	VIP_RegisterFeature(g_sFeature, STRING, _, _, OnItemDisplay);
	#else
	VIP_RegisterFeature(g_sFeature, STRING);
	#endif
}

#if MENU_INFO 1
public bool:OnItemDisplay(iClient, const String:sFeatureName[], String:sDisplay[], iMaxLen)
{
	if(VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		decl String:sHealth[16];
		VIP_GetClientFeatureString(iClient, g_sFeature, sHealth, sizeof(sHealth));
		FormatEx(sDisplay, iMaxLen, "%T [%s]", g_sFeature, iClient, sHealth[(sHealth[0] == '+') ? 1:0]);

		return true;
	}

	return false;
}
#endif

public OnPluginStart()
{
	m_iHealth	 = FindSendPropOffs("CCSPlayer", "m_iHealth");
	
	#if MENU_INFO 1
	LoadTranslations("vip_modules.phrases");
	#endif

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

public VIP_OnPlayerSpawn(iClient, iTeam, bool:bIsVIP)
{
	if(bIsVIP && VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		decl String:sHealth[16], iHealth, iMaxHealth;
		VIP_GetClientFeatureString(iClient, g_sFeature, sHealth, sizeof(sHealth));
		if(sHealth[0] == '+')
		{
			iHealth = StringToInt(sHealth[2])+GetEntData(iClient, m_iHealth);
		}
		else
		{
			StringToIntEx(sHealth, iHealth);
		}

		iMaxHealth = GetEntProp(iClient, Prop_Data, "m_iMaxHealth");
		
		if(iHealth > iMaxHealth)
		{
			SetEntData(iClient, m_iHealth, iHealth);
			SetEntProp(iClient, Prop_Data, "m_iMaxHealth", iHealth);
		}
	}
}