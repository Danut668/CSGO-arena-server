#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <vip_core>

#pragma newdecls required

public Plugin myinfo =
{
	name = "[VIP] Quick Defuse",
	author = "R1KO",
	version = "1.2"
};

#define MENU_INFO 	1 	// Отображать ли информацию в меню

static const char g_sFeature[] = "QuickDefuse";

int m_flDefuseCountDown;
int m_iProgressBarDuration;

public void OnPluginStart()
{
	#if MENU_INFO 1
	LoadTranslations("vip_modules.phrases");
	#endif

	m_flDefuseCountDown = FindSendPropInfo("CPlantedC4", "m_flDefuseCountDown");
	m_iProgressBarDuration = FindSendPropInfo("CCSPlayer", "m_iProgressBarDuration");

	HookEvent("bomb_begindefuse", Event_BeginDefuse);

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public void VIP_OnVIPLoaded()
{
	#if MENU_INFO 1
	VIP_RegisterFeature(g_sFeature, INT, _, _, OnItemDisplay);
	#else
	VIP_RegisterFeature(g_sFeature, INT);
	#endif
}

public void OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}

public void Event_BeginDefuse(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));

	if (VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		RequestFrame(OnRequestFrame, iClient);
	}
}

public void OnRequestFrame(any iClient)
{
	if(IsClientInGame(iClient))
	{
		int iBombEntity = FindEntityByClassname(-1, "planted_c4");
		if (iBombEntity > 0) 
		{
			int iValue = VIP_GetClientFeatureInt(iClient, g_sFeature);
			float fGameTime = GetGameTime();
			float fCountDown = GetEntDataFloat(iBombEntity, m_flDefuseCountDown) - fGameTime;
			fCountDown -= fCountDown/100.0*float(iValue);
			SetEntDataFloat(iBombEntity, m_flDefuseCountDown, fGameTime+fCountDown, true);
			SetEntData(iClient, m_iProgressBarDuration, RoundToCeil(fCountDown)); 
		}
	}
}

#if MENU_INFO 1
public bool OnItemDisplay(int iClient, const char[] sFeatureName, char[] sDisplay, int iMaxLen)
{
	if(VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		FormatEx(sDisplay, iMaxLen, "%T [+%d %%]", g_sFeature, iClient, VIP_GetClientFeatureInt(iClient, g_sFeature));

		return true;
	}

	return false;
}
#endif
