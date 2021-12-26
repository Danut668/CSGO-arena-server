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
	name = "[VIP] Kill Screen",
	author = "R1KO (skype: vova.andrienko1)",
	version = "1.0.2"
};

new const String:g_sFeature[] = "KillScreen";

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL);
}

public OnPluginEnd()
{
	VIP_UnregisterFeature(g_sFeature);
}

new g_iDuration;
new g_iColor[4];
new bool:g_bHSOnly;

public OnPluginStart()
{
	new Handle:hCvar = CreateConVar("vip_kill_screen_duration", "0.6", "Длительность эффекта (сек.)");
	HookConVarChange(hCvar, OnDurationChange);
	g_iDuration = RoundToCeil(GetConVarFloat(hCvar)*1000.0);
	
	hCvar = CreateConVar("vip_kill_screen_color", "0 0 200 100", "Цвет эффекта");
	HookConVarChange(hCvar, OnColorChange);
	GetConVarColor(hCvar, g_iColor);
	
	hCvar = CreateConVar("vip_kill_screen_hs_only", "0", "Отображать эффект только при убийстве в голову");
	HookConVarChange(hCvar, OnHSOnlyChange);
	g_bHSOnly = GetConVarBool(hCvar);
	
	HookEvent("player_death", Event_PlayerDeath);
	
	AutoExecConfig(true, "VIP_KillScreen", "vip");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("BfWriteByte");
	MarkNativeAsOptional("BfWriteShort");

	MarkNativeAsOptional("PbSetInt");
	MarkNativeAsOptional("PbSetColor");

	return APLRes_Success;
}

public OnDurationChange(Handle:hCvar, const String:sOldVal[], const String:sNewVal[])	g_iDuration = RoundToCeil(GetConVarFloat(hCvar)*1000.0);
public OnColorChange(Handle:hCvar, const String:sOldVal[], const String:sNewVal[])		GetConVarColor(hCvar, g_iColor);
public OnHSOnlyChange(Handle:hCvar, const String:sOldVal[], const String:sNewVal[])	g_bHSOnly = GetConVarBool(hCvar);

GetConVarColor(Handle:hCvar, iColor[4])
{
	decl String:sBuffer[16], String:sParts[4][4], i;
	GetConVarString(hCvar, sBuffer, sizeof(sBuffer));
	ExplodeString(sBuffer, " ", sParts, sizeof(sParts), sizeof(sParts[]));
	for(i = 0; i < 4; ++i)
	{
		StringToIntEx(sParts[i], iColor[i]);
	}
}

public Event_PlayerDeath(Handle:hEvent, const String:sEvName[], bool:bDontBroadcast)  
{
	if(g_bHSOnly && !GetEventBool(hEvent, "headshot"))
	{
		return;
	}

	new iClient = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(iClient && VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		decl iClients[1], Handle:hMessage;
		iClients[0] = iClient;
		hMessage = StartMessage("Fade", iClients, 1); 
		if(GetUserMessageType() == UM_Protobuf) 
		{
			PbSetInt(hMessage, "duration", g_iDuration);
			PbSetInt(hMessage, "hold_time", 0);
			PbSetInt(hMessage, "flags", 0x0001);
			PbSetColor(hMessage, "clr", g_iColor);
		}
		else
		{
			BfWriteShort(hMessage, g_iDuration);
			BfWriteShort(hMessage, 0);
			BfWriteShort(hMessage, (0x0001));
			BfWriteByte(hMessage, g_iColor[0]);
			BfWriteByte(hMessage, g_iColor[1]);
			BfWriteByte(hMessage, g_iColor[2]);
			BfWriteByte(hMessage, g_iColor[3]);
		}
		EndMessage(); 
	}
}