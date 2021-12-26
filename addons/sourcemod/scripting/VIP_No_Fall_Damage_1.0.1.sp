//------------------------------------------------------------------------------
// GPL LISENCE (short)
//------------------------------------------------------------------------------
/*
 * Copyright (c) 2014 R1KO

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
 
 * ChangeLog:
		1.0.0 -	Релиз
		1.0.1 -	Поддержка версии ядра 3.0
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <vip_core>



public Plugin:myinfo =
{
	name = "[VIP] No Fall Damage",
	author = "R1KO (skype: vova.andrienko1)",
	version = "1.0.1"
};

static const char g_sFeature[] = "NoFallDamage";

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL);
}

public OnPluginStart()
{
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i)) OnClientPutInServer(i);
	}
	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(iClient, &iAttacker, &inflictor, &Float:fDamage, &damagetype)
{
	if(damagetype & DMG_FALL && VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}