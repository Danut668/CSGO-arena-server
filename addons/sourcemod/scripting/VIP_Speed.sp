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
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools_functions>
#include <vip_core>

#define VIP_SPEED	"Speed"

public Plugin myinfo =
{
	name = "[VIP] Speed",
	author = "R1KO, vadrozh",
	description = "Увеличение скорости VIP игроков",
	version = "1.2.0",
	url = "https://hlmod.ru"
};

int m_flLaggedMovementValue;

public void OnPluginStart()
{
	m_flLaggedMovementValue = FindSendPropInfo("CCSPlayer", "m_flLaggedMovementValue");
	
	if (!m_flLaggedMovementValue)
		SetFailState("Unable to get m_flLaggedMovementValue offset");
	
	if(VIP_IsVIPLoaded())
		VIP_OnVIPLoaded();
}

public void OnPluginEnd()
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterMe") == FeatureStatus_Available)
		VIP_UnregisterMe();
}

public void VIP_OnVIPLoaded() { VIP_RegisterFeature(VIP_SPEED, STRING, _, VIP_OnFeatureToggle); }

public void VIP_OnPlayerSpawn(int iClient, int iTeam, bool bIsVIP)
{
	if(bIsVIP && VIP_IsClientFeatureUse(iClient, VIP_SPEED))
		GiveSpeed(iClient);
}

public Action VIP_OnFeatureToggle(int iClient, const char[] szFeature, VIP_ToggleState eOldStatus, VIP_ToggleState &eNewStatus)
{
	if (eNewStatus == ENABLED)
		GiveSpeed(iClient);
	else
		SetEntDataFloat(iClient, m_flLaggedMovementValue, 1.0, true);

	return Plugin_Continue;
}

void GiveSpeed(int iClient)
{
	char sSpeed[16];
	float fSpeed;
	VIP_GetClientFeatureString(iClient, VIP_SPEED, sSpeed, sizeof(sSpeed));
	if(sSpeed[0] == '+')
		fSpeed = StringToFloat(sSpeed[2]) + GetEntDataFloat(iClient, m_flLaggedMovementValue);
	else
		StringToFloatEx(sSpeed, fSpeed);
	SetEntDataFloat(iClient, m_flLaggedMovementValue, fSpeed, true);
}