#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <vip_core>

#pragma newdecls required

public Plugin myinfo = 
{
	name	= "[VIP] Teammates Heal",
	author	= "1mpulse & R1KO",
	version = "2.0",
	url = "http://hlmod.ru"
};

#define MENU_INFO 	1 	// Отображать ли информацию в меню

char g_szWeaponBlackList[1024];
ConVar g_hMaxHP;
ConVar g_hMaxShotHP;

static const char g_szFeature[] = "TEAMMATES_HEAL";

int m_hActiveWeapon, m_iHealth;

public void VIP_OnVIPLoaded()
{
	#if MENU_INFO 1
	VIP_RegisterFeature(g_szFeature, INT, _, _, OnItemDisplay);
	#else
	VIP_RegisterFeature(g_szFeature, INT);
	#endif
}

#if MENU_INFO 1
public bool OnItemDisplay(int iClient, const char[] szFeature, char[] szDisplay, int iMaxLen)
{
	if(VIP_IsClientFeatureUse(iClient, g_szFeature))
	{
		FormatEx(szDisplay, iMaxLen, "%T [%d %%]", g_szFeature, iClient, VIP_GetClientFeatureInt(iClient, g_szFeature));

		return true;
	}

	return false;
}
#endif

public void OnPluginStart() 
{
	#if MENU_INFO 1
	LoadTranslations("vip_modules.phrases");
	#endif

	m_hActiveWeapon = FindSendPropInfo("CAI_BaseNPC", "m_hActiveWeapon");
	m_iHealth = FindSendPropInfo("CCSPlayer", "m_iHealth");

	g_hMaxHP = CreateConVar("sm_vip_th_weapon_black_list", "weapon_molotov;weapon_hegrenade;", "Список оружий, которые не должны лечить. Разделитель ;");
	g_hMaxHP.GetString(g_szWeaponBlackList, sizeof(g_szWeaponBlackList));
	g_hMaxHP.AddChangeHook(OnBLChanged);

	g_hMaxHP = CreateConVar("sm_vip_th_max_hp", "100", "До скольки хп максимум можно вылечить игрока", _, true, 1.0);
	g_hMaxShotHP = CreateConVar("sm_vip_th_max_shot_hp", "50", "Скольки максимально можно восстановить хп за 1 раз", _, true, 1.0);
	
	AutoExecConfig(true, "VIP_TeammatesHeal", "vip");

	if (VIP_IsVIPLoaded()) VIP_OnVIPLoaded();

	for (int iClient = 1; iClient <= MaxClients; ++iClient) 
	{
		if(IsClientInGame(iClient)) OnClientPutInServer(iClient);
	}
}

public void OnPluginEnd()
{
	if((CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available) || LibraryExists("vip_core"))
	{
		VIP_UnregisterFeature(g_szFeature);
	}
}

public void OnBLChanged(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	strcopy(g_szWeaponBlackList, sizeof(g_szWeaponBlackList), szNewValue);
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int iVictim, int &iAttacker, int &inflictor, float &damage, int &damagetype, int &iWeapon, float damageForce[3], float damagePosition[3])
{
	if(IsValidPlayer(iVictim) && IsValidPlayer(iAttacker) && iVictim != iAttacker && GetClientTeam(iVictim) == GetClientTeam(iAttacker) && VIP_IsClientVIP(iAttacker) && VIP_IsClientFeatureUse(iAttacker, g_szFeature))
	{
		if(iWeapon == -1)
		{
			if(inflictor > MaxClients)
			{
				iWeapon = inflictor;
			}
			else
			{
				iWeapon = GetEntDataEnt2(iAttacker, m_hActiveWeapon);
			}
		}
	//	PrintToChat(iAttacker, "inflictor = %d, iWeapon = %d, damage = %.2f, damagetype = %d", inflictor, iWeapon, damage, damagetype);

		if (iWeapon > 0)
		{
			char szWeapon[32];
			GetEntityClassname(iWeapon, szWeapon, sizeof(szWeapon));
		//	PrintToChat(iAttacker, "szWeapon = '%s'", szWeapon);
			if(StrContains(g_szWeaponBlackList, szWeapon, true) == -1)
			{
				int iHP = GetEntData(iVictim, m_iHealth);
				int iMaxHP = g_hMaxHP.IntValue;
				if(iHP < iMaxHP)
				{
					int iPercent = VIP_GetClientFeatureInt(iAttacker, g_szFeature);
					int iAddHP = RoundToCeil(damage/100.0*float(iPercent));
					int iMaxShotHP = g_hMaxShotHP.IntValue;
					if(iAddHP > iMaxShotHP)
					{
						iAddHP = iMaxShotHP;
					}
					iHP += iAddHP;
					if(iHP > iMaxHP)
					{
						iHP = iMaxHP;
					}
					SetEntData(iVictim, m_iHealth, iHP);
				}
			}
		}
	}
	return Plugin_Continue;
}

bool IsValidPlayer(int iClient, bool alive = false) 
{
	if(iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient))
	{		
		return !(alive && !IsPlayerAlive(iClient));
	}

	return false;
}