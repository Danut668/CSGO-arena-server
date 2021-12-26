#pragma semicolon 1
#pragma tabsize 0

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <vip_core>

public Plugin myinfo =
{
	name = "[VIP] Unlimited Ammo",
	author = "SN(Kaneki)",
	version = "1.2.5.5b"
};

Handle trie_armas;

static const char g_sFeature[] = "UnlimitedAmmo";

bool g_bEnable[MAXPLAYERS+1];

public void OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}

public void OnPluginStart() 
{
	HookEvent("weapon_fire", Event_WeaponFire);
	
	trie_armas = CreateTrie();

	if(VIP_IsVIPLoaded()) VIP_OnVIPLoaded();
	
	for(int i = 1; i <= MaxClients; i++)
	    if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, INT, _, OnToggleItem);
}

public Action OnToggleItem(int iClient, const char[] sFeatureName, VIP_ToggleState OldStatus, VIP_ToggleState &NewStatus)
{
	g_bEnable[iClient] = (NewStatus == ENABLED);

	return Plugin_Continue;
}

public void VIP_OnVIPClientLoaded(int iClient)
{
	g_bEnable[iClient] = VIP_IsClientFeatureUse(iClient, g_sFeature);
}

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	
    if (iClient && g_bEnable[iClient] && IsPlayerAlive(iClient) && VIP_GetClientFeatureInt(iClient, g_sFeature) == 2)
	{
        FunctionFirst(iClient);
	}
	else if(iClient && g_bEnable[iClient] && IsPlayerAlive(iClient) && VIP_GetClientFeatureInt(iClient, g_sFeature) == 1)
	{
		FunctionTwo(iClient);
	}
}

void FunctionFirst(int iClient)
{
	int WeaponIndex = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if (WeaponIndex == -1)
		return;
	int ClipAmmo = GetEntProp(WeaponIndex, Prop_Send, "m_iClip1");
	if (!ClipAmmo) 
		return;
	SetEntProp(WeaponIndex, Prop_Send, "m_iClip1", 100);
}

void FunctionTwo(int iClient)
{
	int weapon = GetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon");
	if(weapon > 0 && (weapon == GetPlayerWeaponSlot(iClient, CS_SLOT_PRIMARY) || weapon == GetPlayerWeaponSlot(iClient, CS_SLOT_SECONDARY)))
	{
		int warray;
		char classname[4];

		Format(classname, 4, "%i", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
			
		if(GetTrieValue(trie_armas, classname, warray))
		{
			if(GetReserveAmmo(weapon) != warray) SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", warray);
		}
	}
}

stock GetReserveAmmo(int weapon)
{
    return GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
}

public Action EventItemPickup2(int iClient, int weapon)
{
	if(weapon == GetPlayerWeaponSlot(iClient, CS_SLOT_PRIMARY) || weapon == GetPlayerWeaponSlot(iClient, CS_SLOT_SECONDARY))
	{
		int warray;
		char classname[4];

		Format(classname, 4, "%i", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
	
		if(!GetTrieValue(trie_armas, classname, warray))
		{
			warray = GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
		
			SetTrieValue(trie_armas, classname, warray);
		}
	}
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_WeaponEquipPost, EventItemPickup2);
	g_bEnable[iClient] = false;
}

public void OnClientDisconnect(int iClient)
{
	g_bEnable[iClient] = false;
}