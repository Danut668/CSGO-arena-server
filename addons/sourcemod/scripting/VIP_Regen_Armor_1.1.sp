#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>
#include <vip_core>

public Plugin:myinfo =
{
	name = "[VIP] Regen Armor",
	author = "R1KO",
	version = "1.1",
	url = "http://hlmod.ru"
};

#define MENU_INFO 	1 // Отображать ли информацию в меню


#define VIP_REGEN_ARMOR					0
#define VIP_REGEN_ARMOR_DELAY			1
#define VIP_REGEN_ARMOR_INTERVAL		2
#define VIP_ARMOR							3

static const String:g_sFeature[][] = {"RegenArmor", "DelayRegenArmor", "IntervalRegenArmor", "Armor"};

new g_iClientDelayTicks[MAXPLAYERS+1],
	g_iClientRegenTicks[MAXPLAYERS+1],
	bool:g_bRegen[MAXPLAYERS+1],
	bool:g_bArmorUsed,
	m_ArmorValue = -1;


public OnPluginStart()
{
	HookEvent("player_hurt", Event_OnPlayerHurt);
	
	m_ArmorValue	 = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
	
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
	VIP_RegisterFeature(g_sFeature[VIP_REGEN_ARMOR],				INT, _, OnToggleItem, OnItemDisplay);
	#else
	VIP_RegisterFeature(g_sFeature[VIP_REGEN_ARMOR],				INT, _, OnToggleItem);
	#endif
	VIP_RegisterFeature(g_sFeature[VIP_REGEN_ARMOR_DELAY],		INT, HIDE);
	VIP_RegisterFeature(g_sFeature[VIP_REGEN_ARMOR_INTERVAL],	INT, HIDE);
}

public OnPluginEnd()
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature[VIP_REGEN_ARMOR]);
		VIP_UnregisterFeature(g_sFeature[VIP_REGEN_ARMOR_DELAY]);
		VIP_UnregisterFeature(g_sFeature[VIP_REGEN_ARMOR_INTERVAL]);
	}
}

#if MENU_INFO 1
public bool:OnItemDisplay(iClient, const String:sFeatureName[], String:sDisplay[], iMaxLen)
{
	if(VIP_IsClientFeatureUse(iClient, g_sFeature[VIP_REGEN_ARMOR]))
	{
		FormatEx(sDisplay, iMaxLen, "%T [%i Ед./%i сек]", g_sFeature[VIP_REGEN_ARMOR], iClient, VIP_GetClientFeatureInt(iClient, g_sFeature[VIP_REGEN_ARMOR]), VIP_GetClientFeatureInt(iClient, g_sFeature[VIP_REGEN_ARMOR_INTERVAL]));

		return true;
	}

	return false;
}
#endif

public OnMapStart()
{
	CreateTimer(1.0, Timer_Regen, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(2.0, Timer_OnVIPLoaded, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_OnVIPLoaded(Handle:hTimer)
{
	g_bArmorUsed = VIP_IsValidFeature(g_sFeature[VIP_ARMOR]);

	return Plugin_Stop;
}

public Action:Timer_Regen(Handle:hTimer)
{
	for(new i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(g_bRegen[i] && VIP_IsClientVIP(i) && VIP_IsClientFeatureUse(i, g_sFeature[VIP_REGEN_ARMOR]))
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
				
				if(RegenArmor(i))
				{
					g_iClientRegenTicks[i] = VIP_GetClientFeatureInt(i, g_sFeature[VIP_REGEN_ARMOR_INTERVAL]);
				}
			}
		}
	}
	return Plugin_Continue;
}

bool:RegenArmor(iClient)
{
	static iArmor, iMaxArmor, iNewArmor, String:sArmor[16];
	iArmor = GetEntData(iClient, m_ArmorValue);
	
	if(g_bArmorUsed && VIP_IsClientFeatureUse(iClient, g_sFeature[VIP_ARMOR]))
	{
		VIP_GetClientFeatureString(iClient, g_sFeature[VIP_ARMOR], sArmor, sizeof(sArmor));
		if(sArmor[0] == '+')
		{
			iMaxArmor = StringToInt(sArmor[2])+100;
		}
		else
		{
			iMaxArmor = StringToInt(sArmor);
		}
	}
	else
	{
		iMaxArmor = 100;
	}

	if(iArmor < iMaxArmor)
	{
		iNewArmor = iArmor+VIP_GetClientFeatureInt(iClient, g_sFeature[VIP_REGEN_ARMOR]);
		if(iNewArmor < iMaxArmor)
		{
			SetEntData(iClient, m_ArmorValue, iNewArmor);
			return true;
		}

		SetEntData(iClient, m_ArmorValue, iMaxArmor);
	}

	g_bRegen[iClient] = false;

	return false;
}

public Event_OnPlayerHurt(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (iClient && GetEventInt(hEvent, "dmg_armor") > 0 && VIP_IsClientVIP(iClient) && IsPlayerAlive(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature[VIP_REGEN_ARMOR]))
	{
		g_bRegen[iClient] = true;
		g_iClientDelayTicks[iClient] = VIP_GetClientFeatureInt(iClient, g_sFeature[VIP_REGEN_ARMOR_DELAY]);
	}
}

public VIP_OnClientSpawn(iClient, iTeam, bool:bIsVIP)
{
	if(bIsVIP && VIP_IsClientFeatureUse(iClient, g_sFeature[VIP_REGEN_ARMOR]))
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