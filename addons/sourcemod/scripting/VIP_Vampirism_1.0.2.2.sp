#include <sourcemod>
#include <vip_core>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "[VIP] Vampirism",
	author = "R1KO",
	version = "1.0.2.2"
};

static const char g_sFeature[] = "Vampirism";

int m_iHealth,
	g_Cvar_iMaxHP;

public void OnPluginStart()
{
	ConVar hCvar = CreateConVar("sm_vip_vampirism_max_hp", "100", "Сколько максимально хп может получить игрок (0 - Без ограничений)", _, true, 0.0);
	g_Cvar_iMaxHP = hCvar.IntValue;
	hCvar.AddChangeHook(OnMaxHPChange);

	HookEvent("player_hurt", Event_OnPlayerHurt);

	m_iHealth = FindSendPropInfo("CCSPlayer", "m_iHealth");
	
	LoadTranslations("vip_modules.phrases");
	
	AutoExecConfig(true, "VIP_Vampirism", "vip");

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public void OnMaxHPChange(ConVar hCvar, const char[] oldValue, const char[] newValue)	
{
	g_Cvar_iMaxHP = hCvar.IntValue;
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, FLOAT, _, _, OnDisplayItem);
}

public bool OnDisplayItem (int iClient, const char[] szFeature, char[] sDisplay, int iMaxLength)
{
	if(VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		FormatEx(sDisplay, iMaxLength, "%T [%.0f %%]", g_sFeature, iClient, VIP_GetClientFeatureFloat(iClient, g_sFeature) );
		return true;
	}

	return false;
}

public void Event_OnPlayerHurt(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId( hEvent.GetInt("attacker") );
	if (iClient && IsPlayerAlive(iClient) && VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		int iHealth = GetEntData(iClient, m_iHealth) + RoundFloat( ( float( hEvent.GetInt("dmg_health") ) * VIP_GetClientFeatureFloat(iClient, g_sFeature) ) /100.0);
		
		if(g_Cvar_iMaxHP && iHealth > g_Cvar_iMaxHP)
		{
			iHealth = g_Cvar_iMaxHP;
		}

		SetEntData(iClient, m_iHealth, iHealth);
	}
}