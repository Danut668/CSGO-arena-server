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
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <vip_core>

public Plugin:myinfo =
{
	name = "[VIP] No Self Damage",
	author = "R1KO (skype: vova.andrienko1)",
	version = "1.0.0"
};

public OnPluginStart()
{
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (IsValidEntity(i) && IsClientInGame(i)) OnClientPutInServer(i);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(iClient, &iAttacker, &inflictor, &Float:fDamage, &damagetype)
{
	if(0 < iAttacker <= MaxClients && VIP_IsClientVIP(iClient) && iClient == iAttacker)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}