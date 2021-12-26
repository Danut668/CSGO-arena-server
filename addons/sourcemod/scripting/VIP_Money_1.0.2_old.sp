#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>
#include <vip_core>

public Plugin:myinfo =
{
	name = "[VIP] Money",
	author = "R1KO",
	version = "1.0.2"
};

static const char g_sFeature[] = "Money";

new m_iAccount;
new g_iMaxMoney;

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, STRING);
}

public OnPluginStart()
{
	m_iAccount = FindSendPropInfo("CCSPlayer", "m_iAccount");
	
	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public OnConfigsExecuted()
{
	if((GetEngineVersion() == Engine_CSGO))
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
		decl String:sMoney[16], iMoney;
		VIP_GetClientFeatureString(iClient, g_sFeature, sMoney, sizeof(sMoney));
		if(sMoney[0] == '+')
		{
			iMoney = StringToInt(sMoney[1])+GetEntData(iClient, m_iAccount);

			if(iMoney > g_iMaxMoney)
			{
				iMoney = g_iMaxMoney;
			}
		}
		else
		{
			StringToIntEx(sMoney, iMoney);
		}

		SetEntData(iClient, m_iAccount, iMoney);
	}
}

public OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}