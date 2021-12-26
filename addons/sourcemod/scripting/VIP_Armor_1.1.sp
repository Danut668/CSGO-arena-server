#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>
#include <vip_core>

public Plugin:myinfo =
{
	name = "[VIP] Armor",
	author = "R1KO (skype: vova.andrienko1)",
	version = "1.1"
};

#define MENU_INFO 		1 // Отображать ли информацию в меню

#define GIVE_HELMET 		1 // Выдавать ли шлем

new const String:g_sFeature[] = "Armor";

new m_ArmorValue;
#if GIVE_HELMET 1
new m_bHasHelmet;
#endif

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
		decl String:sArmor[16];
		VIP_GetClientFeatureString(iClient, g_sFeature, sArmor, sizeof(sArmor));
		FormatEx(sDisplay, iMaxLen, "%T [%s]", g_sFeature, iClient, sArmor[(sArmor[0] == '+') ? 1:0]);

		return true;
	}

	return false;
}
#endif

public OnPluginStart()
{
	m_ArmorValue	 = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
	#if GIVE_HELMET 1
	m_bHasHelmet = FindSendPropOffs("CCSPlayer", "m_bHasHelmet");
	#endif
	
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
		decl String:sArmor[16], iArmor;
		VIP_GetClientFeatureString(iClient, g_sFeature, sArmor, sizeof(sArmor));
		if(sArmor[0] == '+')
		{
			iArmor = StringToInt(sArmor[2])+GetEntData(iClient, m_ArmorValue);
		}
		else
		{
			StringToIntEx(sArmor, iArmor);
		}
		
		SetEntData(iClient, m_ArmorValue, iArmor);
		#if GIVE_HELMET 1
		SetEntData(iClient, m_bHasHelmet, 1);
		#endif
	}
}