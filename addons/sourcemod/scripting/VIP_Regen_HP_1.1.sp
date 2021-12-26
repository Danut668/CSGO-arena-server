#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>
#include <vip_core>

public Plugin:myinfo =
{
	name = "[VIP] Regen HP",
	author = "R1KO",
	version = "1.1",
	url = "http://hlmod.ru"
};

#define MENU_INFO 	1 // Отображать ли информацию в меню


#define VIP_REGEN_HP					0
#define VIP_REGEN_HP_DELAY			1
#define VIP_REGEN_HP_INTERVAL		2

static const String:g_sFeature[][] = {"RegenHP", "DelayRegenHP", "IntervalRegenHP"};

new g_iClientDelayTicks[MAXPLAYERS+1],
	g_iClientRegenTicks[MAXPLAYERS+1],
	bool:g_bRegen[MAXPLAYERS+1],
	m_iHealth = -1;

public OnPluginStart()
{
	HookEvent("player_hurt", Event_OnPlayerHurt);

	m_iHealth	 = FindSendPropOffs("CCSPlayer", "m_iHealth");
	
	#if MENU_INFO 1
	LoadTranslations("vip_modules.phrases");
	#endif

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public VIP_OnVIPLoaded()
{
	#if MENU_INFO 1
	VIP_RegisterFeature(g_sFeature[VIP_REGEN_HP],				INT, _, OnToggleItem, OnItemDisplay);
	#else
	VIP_RegisterFeature(g_sFeature[VIP_REGEN_HP],				INT, _, OnToggleItem);
	#endif
	VIP_RegisterFeature(g_sFeature[VIP_REGEN_HP_DELAY],		INT, HIDE);
	VIP_RegisterFeature(g_sFeature[VIP_REGEN_HP_INTERVAL],	INT, HIDE);
}

public OnPluginEnd()
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature[VIP_REGEN_HP]);
		VIP_UnregisterFeature(g_sFeature[VIP_REGEN_HP_DELAY]);
		VIP_UnregisterFeature(g_sFeature[VIP_REGEN_HP_INTERVAL]);
	}
}

#if MENU_INFO 1
public bool:OnItemDisplay(iClient, const String:sFeatureName[], String:sDisplay[], iMaxLen)
{
	if(VIP_IsClientFeatureUse(iClient, g_sFeature[VIP_REGEN_HP]))
	{
		FormatEx(sDisplay, iMaxLen, "%T [%i HP/%i сек]", g_sFeature[VIP_REGEN_HP], iClient, VIP_GetClientFeatureInt(iClient, g_sFeature[VIP_REGEN_HP]), VIP_GetClientFeatureInt(iClient, g_sFeature[VIP_REGEN_HP_INTERVAL]));

		return true;
	}

	return false;
}
#endif

public OnMapStart()
{
	CreateTimer(1.0, Timer_Regen, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_Regen(Handle:hTimer)
{
	for(new i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(g_bRegen[i] && VIP_IsClientVIP(i) && VIP_IsClientFeatureUse(i, g_sFeature[VIP_REGEN_HP]))
			{
				if(g_iClientDelayTicks[i] > 0)
				{
					g_iClientDelayTicks[i]--;
					continue;
				}
				
				if(g_iClientRegenTicks[i] > 0)
				{
					g_iClientRegenTicks[i]--;
					continue;
				}
				
				if(RegenHP(i))
				{
					g_iClientRegenTicks[i] = VIP_GetClientFeatureInt(i, g_sFeature[VIP_REGEN_HP_INTERVAL]);
				}
			}
		}
	}
	return Plugin_Continue;
}

bool:RegenHP(iClient)
{
	static iHP, iMaxHP;
	iHP = GetEntData(iClient, m_iHealth);
	
	iMaxHP = GetEntProp(iClient, Prop_Data, "m_iMaxHealth");

	if(iHP < iMaxHP)
	{
		iHP += VIP_GetClientFeatureInt(iClient, g_sFeature[VIP_REGEN_HP]);
		if(iHP < iMaxHP)
		{
			SetEntData(iClient, m_iHealth, iHP);
			return true;
		}

		SetEntData(iClient, m_iHealth, iMaxHP);
	}

	g_bRegen[iClient] = false;

	return false;
}

public Event_OnPlayerHurt(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (iClient && GetEventInt(hEvent, "dmg_health") && GetEventInt(hEvent, "health") && IsPlayerAlive(iClient) && VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature[VIP_REGEN_HP]))
	{
		g_bRegen[iClient] = true;
		g_iClientDelayTicks[iClient] = VIP_GetClientFeatureInt(iClient, g_sFeature[VIP_REGEN_HP_DELAY]);
	}
}

public VIP_OnClientSpawn(iClient, iTeam, bool:bIsVIP)
{
	if(bIsVIP && VIP_IsClientFeatureUse(iClient, g_sFeature[VIP_REGEN_HP]))
	{
		g_bRegen[iClient] = false;
	}
}

public Action:OnToggleItem(iClient, const String:sFeatureName[], VIP_ToggleState:OldStatus, &VIP_ToggleState:NewStatus)
{
	g_bRegen[iClient] = bool:(NewStatus == ENABLED);

	return Plugin_Continue;
}

public OnClientPutInServer(iClient)
{
	g_bRegen[iClient] = false;
}