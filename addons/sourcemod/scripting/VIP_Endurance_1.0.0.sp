//------------------------------------------------------------------------------
// GPL LISENCE (short)
//------------------------------------------------------------------------------
/*
* Copyright (c) 2016 R1KO

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
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <vip_core>

public Plugin:myinfo =
{
	name = "[VIP] Endurance",
	author = "R1KO (skype: vova.andrienko1)",
	version = "1.0.0"
};

new const String:g_sFeature[] = "Endurance";

new bool:g_bEndurance[MAXPLAYERS+1];
new m_flVelocityModifier;

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL, _, OnToggleItem);
}

public Action:OnToggleItem(iClient, const String:sFeatureName[], VIP_ToggleState:OldStatus, &VIP_ToggleState:NewStatus)
{
	g_bEndurance[iClient] = (NewStatus == ENABLED);

	return Plugin_Continue;
}

public VIP_OnVIPClientLoaded(iClient)
{
	g_bEndurance[iClient] = (VIP_GetClientFeatureStatus(iClient, g_sFeature) == ENABLED);
}

public OnPluginStart()
{
	m_flVelocityModifier = FindSendPropOffs("CCSPlayer", "m_flVelocityModifier");
}

public Action:OnPlayerRunCmd(iClient, &buttons, &impulse, Float:vel[3], Float:angles[3])
{
	if (IsPlayerAlive(iClient) && g_bEndurance[iClient] && GetEntDataFloat(iClient, m_flVelocityModifier) < 1.0)
	{
		SetEntDataFloat(iClient, m_flVelocityModifier, 1.0, true);
	}
	return Plugin_Continue;
}

