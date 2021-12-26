#pragma semicolon 1

#include <sdktools>
#include <vip_core>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[VIP] Anti Flash",
	author = "R1KO, babka68",
	version = "1.2"
};

#define ANTI_FLASH_FULL		2
#define ANTI_FLASH_TEAM		1

static const char g_sFeature[] = "AntiFlash";

int 
		m_flFlashDuration = -1,
    	m_flFlashMaxAlpha = -1,
		g_iOwner = -1;

bool 
		g_bSelfBlind;

public void OnPluginStart() 
{
	HookEvent("player_blind", 		Event_PlayerBlind);
	HookEvent("flashbang_detonate", 	Event_FlashbangDetonate);
	
	m_flFlashDuration = UTIL_FindSendPropInfo("CCSPlayer", "m_flFlashDuration");
	m_flFlashMaxAlpha = UTIL_FindSendPropInfo("CCSPlayer", "m_flFlashMaxAlpha");
	
	Handle g_hSelfBlind = CreateConVar("vip_af_selfblind", "0", "Режим работы (1 - Слепить самого себя/0 - Не слепить)", _, true, 0.0, true, 1.0);
	g_bSelfBlind = GetConVarBool(g_hSelfBlind);
	HookConVarChange(g_hSelfBlind, OnConVarChange);
	
	AutoExecConfig(true, "VIP_AntiFlash", "vip");

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public void OnPluginEnd()
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}

int UTIL_FindSendPropInfo(const char[] sNetClass, const char[] sPropertyName)
{
	int iOffset = FindSendPropInfo(sNetClass, sPropertyName);
	if (iOffset == -1) SetFailState("Fatal Error: Unable to find offset: \"%s::%s\"", sNetClass, sPropertyName);
	return iOffset;
}

public void OnConVarChange(Handle hCvar, const char[] oldValue, const char[] newValue)
{
	g_bSelfBlind = GetConVarBool(hCvar);
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, INT);
}

public void Event_FlashbangDetonate(Handle hEvent, const char[] name, bool dontBroadcast)
{
	g_iOwner = GetClientOfUserId(GetEventInt(hEvent, "userid"));
}

public void Event_PlayerBlind(Handle hEvent, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		CreateTimer(0.01, Timer_PlayerBlind, iClient);
	}
}

public Action Timer_PlayerBlind(Handle hTimer, any iClient)
{
	if(g_iOwner > 0 && IsClientInGame(g_iOwner) && IsClientInGame(iClient))
	{
		if(iClient == g_iOwner && g_bSelfBlind)
		{
			return Plugin_Stop;
		}

		if((VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature)) && (VIP_GetClientFeatureInt(iClient, g_sFeature) == 2 || GetClientTeam(g_iOwner) == GetClientTeam(iClient)))
		{
			SetEntDataFloat(iClient, m_flFlashDuration, 0.0);
			SetEntDataFloat(iClient, m_flFlashMaxAlpha, 0.0);
			ClientCommand(iClient, "dsp_player 0.0");
		}
	}

	return Plugin_Stop;
}