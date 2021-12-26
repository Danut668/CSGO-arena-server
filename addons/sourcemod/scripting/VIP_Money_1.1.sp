#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>
#include <vip_core>

public Plugin:myinfo =
{
	name = "[VIP] Money",
	author = "R1KO (skype: vova.andrienko1)",
	version = "1.1"
};

#define MENU_INFO 	1 	// Отображать ли информацию в меню

new const String:g_sFeature[] = "Money";

new m_iAccount;
new g_iMaxMoney;

public OnPluginStart()
{
	m_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");

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
		decl String:sMoney[16];
		VIP_GetClientFeatureString(iClient, g_sFeature, sMoney, sizeof(sMoney));
		FormatEx(sDisplay, iMaxLen, "%T [%s]", g_sFeature, iClient, sMoney[(sMoney[0] == '+') ? 1:0]);

		return true;
	}

	return false;
}
#endif

public OnConfigsExecuted()
{
	if(GetEngineVersion() == Engine_CSGO)
	{
		new Handle:hCvar = FindConVar("mp_maxmoney");
		g_iMaxMoney = GetConVarInt(hCvar);
		HookConVarChange(hCvar, OnMaxMoneyChange);
	}
	else
	{
		g_iMaxMoney = 16000;
	}
}

public OnMaxMoneyChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iMaxMoney = GetConVarInt(hCvar);

public VIP_OnPlayerSpawn(iClient, iTeam, bool:bIsVIP)
{
	if(bIsVIP && VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		decl String:sMoney[16], iMoney, iClientMoney;
		VIP_GetClientFeatureString(iClient, g_sFeature, sMoney, sizeof(sMoney));
		iClientMoney = GetEntData(iClient, m_iAccount);
		if(sMoney[0] == '+')
		{
			iMoney = StringToInt(sMoney[1])+iClientMoney;

			if(iMoney > g_iMaxMoney)
			{
				iMoney = g_iMaxMoney;
			}
		}
		else
		{
			StringToIntEx(sMoney, iMoney);
		}

		if(iMoney > iClientMoney)
		{
			SetEntData(iClient, m_iAccount, iMoney);
		}
	}
}
