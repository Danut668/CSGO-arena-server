#pragma semicolon 1

#include <sourcemod>
#include <vip_core>

public Plugin:myinfo =
{
	name = "[VIP] Medkit",
	author = "R1KO",
	version = "1.0"
};

static const String:g_sFeature[] = "Medkit";

new g_iUsed[MAXPLAYERS+1];

new g_iMinHP, g_iHP;

new m_iHealth;

public OnPluginStart()
{
	m_iHealth	 = FindSendPropOffs("CCSPlayer", "m_iHealth");

	HookEventEx("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

	RegConsoleCmd("med", Medkit_CMD);

	new Handle:hCvar = CreateConVar("sm_vip_medkit_min_health", "30", "Сколько у игрока должно быть хп чтобы он мог использовать аптечку", 0, true, 1.0);
	g_iMinHP = GetConVarInt(hCvar);
	HookConVarChange(hCvar, OnMinHPChange);
	
	hCvar = CreateConVar("sm_vip_medkit_health", "100", "До скольки хп должна восстанавливать аптечка", 0, true, 1.0);
	g_iHP = GetConVarInt(hCvar);
	HookConVarChange(hCvar, OnHPChange);
	
	AutoExecConfig(true, "vip_medkit", "vip");

	LoadTranslations("vip_modules.phrases");
	LoadTranslations("vip_core.phrases");

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public OnMinHPChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iMinHP = GetConVarInt(hCvar);
public OnHPChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iHP = GetConVarInt(hCvar);

public OnPluginEnd()
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, INT, SELECTABLE, OnSelectItem, OnDisplayItem, OnDrawItem);
}

public bool:OnSelectItem(iClient, const String:sFeatureName[])
{
	MedkitClient(iClient);
	return true;
}

public bool:OnDisplayItem(iClient, const String:sFeatureName[], String:sDisplay[], maxlen)
{
	if(VIP_GetClientFeatureStatus(iClient, sFeatureName) == ENABLED)
	{
		FormatEx(sDisplay, maxlen, "%T [%T]", sFeatureName, iClient, "Left", iClient, (VIP_GetClientFeatureInt(iClient, g_sFeature)-g_iUsed[iClient]));
		return true;
	}

	return false;
}

public OnDrawItem(iClient, const String:sFeatureName[], iStyle)
{
	if(VIP_GetClientFeatureStatus(iClient, sFeatureName) != NO_ACCESS )
	{
		if(g_iUsed[iClient] >= VIP_GetClientFeatureInt(iClient, g_sFeature))
		{
			return ITEMDRAW_DISABLED;
		}
	}

	return iStyle;
}

public Action:Medkit_CMD(iClient, args)
{
	if(iClient)
	{
		if(VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature))
		{
			MedkitClient(iClient);
		}
		else
		{
			VIP_PrintToChatClient(iClient, "%t", "COMMAND_NO_ACCESS");
		}
	}
	return Plugin_Handled;
}

public Event_RoundStart(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++) g_iUsed[i] = 0;
}

public OnClientPutInServer(iClient)
{
	g_iUsed[iClient] = 0;
}

MedkitClient(iClient)
{
	if(!IsPlayerAlive(iClient))
	{
		VIP_PrintToChatClient(iClient, "You must be alive!");
		return;
	}

	if(GetClientTeam(iClient) < 2)
	{
		VIP_PrintToChatClient(iClient, "You must be on the team!");
		return;
	}

	if(g_iUsed[iClient] >= VIP_GetClientFeatureInt(iClient, g_sFeature))
	{
		PrintToChat(iClient, "%tRound Usage Limit Reached!", "VIP_CHAT_PREFIX");
		return;
	}

	if(GetEntData(iClient, m_iHealth) > g_iMinHP)
	{
		VIP_PrintToChatClient(iClient, "You have too much HP!");
		return;
	}

	++g_iUsed[iClient];

	SetEntData(iClient, m_iHealth, g_iHP);
}
