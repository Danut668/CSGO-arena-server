//------------------------------------------------------------------------------
// GPL LICENSE (short)
//------------------------------------------------------------------------------
/*
 * Copyright (c) 2020 R1KO, vadrozh

 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <vip_core>

public Plugin myinfo =
{
	name = "[VIP] C4",
	author = "R1KO, vadrozh",
	description = "Gives bomb to VIP-Players",
	version = "1.1.0",
	url = "https://hlmod.ru"
};

static const char g_sFeature[] = "C4";

bool g_bEnabled, g_Cvar_bRemoveC4, g_bHooked = false;
ConVar g_hCvarC4Remove;

public void OnPluginStart()
{
	g_hCvarC4Remove = CreateConVar("sm_vip_c4_remove", "0", "Удалять ли другие бомбы после установки одной.", _, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarC4Remove, OnRemoveC4Change);

	AutoExecConfig(true, "VIP_C4", "vip");

	if (VIP_IsVIPLoaded())
		VIP_OnVIPLoaded();
}

public void OnPluginEnd()
{
	if (CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterMe") == FeatureStatus_Available)
		VIP_UnregisterMe();
}

public void OnMapStart() { g_bEnabled = (FindEntityByClassname(-1, "func_bomb_target") != -1); }

public void OnConfigsExecuted() { OnRemoveC4Change(g_hCvarC4Remove, NULL_STRING, NULL_STRING); }

public void OnRemoveC4Change(Handle hCvar, const char[] sOldValue, const char[] sNewValue)
{
	if (!g_bEnabled)
		return;
	g_Cvar_bRemoveC4 = GetConVarBool(hCvar);
	
	if(g_Cvar_bRemoveC4 && !g_bHooked)
	{
		HookEvent("bomb_planted", Event_BombPlanted);
		g_bHooked = true;
	} else if (g_bHooked) {
		UnhookEvent("bomb_planted", Event_BombPlanted);
		g_bHooked = false;
	}
}

public void VIP_OnVIPLoaded() { VIP_RegisterFeature(g_sFeature, BOOL); }

public void VIP_OnPlayerSpawn(int iClient, int iTeam, bool bIsVIP)
{
	if(g_bEnabled && bIsVIP && iTeam == 2 && VIP_IsClientFeatureUse(iClient, g_sFeature) && GetPlayerWeaponSlot(iClient, 4) == -1)
		GivePlayerItem(iClient, "weapon_c4");
}

public void Event_BombPlanted(Handle hEvent, const char[] sEvName, bool bDontBroadcast) 
{ 
	int iWeapon, iMaxEntities;
	char sWeapon[64];
	for (int i = 1; i <= MaxClients; ++i)
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			iWeapon = GetPlayerWeaponSlot(i, 4);
			if(iWeapon != -1)
			{
				RemovePlayerItem(i, iWeapon);
				AcceptEntityInput(iWeapon, "Kill"); 
			}
		}
	
	iMaxEntities = GetMaxEntities();
	iWeapon = FindSendPropInfo("CBaseCombatWeapon", "m_hOwnerEntity");
	for (int i = MaxClients; i <= iMaxEntities; ++i)
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, sWeapon, sizeof(sWeapon));
			if (strcmp(sWeapon[7], "c4") == 0 && GetEntDataEnt2(i, iWeapon) == -1)
				RemoveEdict(i);
		}
}