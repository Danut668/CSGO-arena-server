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
#include <sdktools_functions>
#include <vip_core>

public Plugin:myinfo =
{
	name = "[VIP] Kill Bonus",
	author = "R1KO (skype: vova.andrienko1)",
	version = "1.0.0"
};

#define VIP_KILL_BONUS				"KillBonus"

new m_iAccount = -1,
	m_iHealth = -1;

new bool:g_bIsCSGO;

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(VIP_KILL_BONUS, BOOL, HIDE);
}

new g_iCvar_HP,
	g_iCvar_HP_HS,
	g_iCvar_HP_Knife,
	g_iCvar_HP_Gren,
	g_iCvar_Max_HP,
	g_iCvar_Money,
	g_iCvar_Money_HS,
	g_iCvar_Money_Knife,
	g_iCvar_Money_Gren,
	g_iCvar_Max_Money;

public OnPluginStart()
{
	g_bIsCSGO = bool:(GetEngineVersion() == Engine_CSGO);

	decl Handle:hCvar;

	hCvar = CreateConVar("sm_vip_kill_bonus_hp", "20", "Сколько хп будет получать игрок за убийство (0 - Отключено)", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(hCvar, OnBonusHPChange);
	g_iCvar_HP = GetConVarInt(hCvar);
	
	hCvar = CreateConVar("sm_vip_kill_bonus_hp_hs", "30", "Сколько хп будет получать игрок за убийство в голову (0 - Отключено)", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(hCvar, OnBonusHPHSChange);
	g_iCvar_HP_HS = GetConVarInt(hCvar);
	
	hCvar = CreateConVar("sm_vip_kill_bonus_hp_knife", "50", "Сколько хп будет получать игрок за убийство ножом (0 - Отключено)", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(hCvar, OnBonusHPKnifeChange);
	g_iCvar_HP_Knife = GetConVarInt(hCvar);
	
	hCvar = CreateConVar("sm_vip_kill_bonus_hp_gren", "30", "Сколько хп будет получать игрок за убийство гранатой (0 - Отключено)", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(hCvar, OnBonusHPGrenChange);
	g_iCvar_HP_Gren = GetConVarInt(hCvar);
	
	hCvar = CreateConVar("sm_vip_kill_bonus_max_hp", "130", "Сколько максимально хп может получить игрок за убийства", FCVAR_PLUGIN, true, 1.0, true, 500.0);
	HookConVarChange(hCvar, OnBonusMaxHPChange);
	g_iCvar_Max_HP = GetConVarInt(hCvar);
	
	hCvar = CreateConVar("sm_vip_kill_bonus_money", "2000", "Сколько денег будет получать игрок за убийство (0 - Отключено)", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(hCvar, OnBonusMoneyChange);
	g_iCvar_Money = GetConVarInt(hCvar);
	
	hCvar = CreateConVar("sm_vip_kill_bonus_money_hs", "3000", "Сколько денег будет получать игрок за убийство в голову (0 - Отключено)", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(hCvar, OnBonusMoneyHSChange);
	g_iCvar_Money_HS = GetConVarInt(hCvar);
	
	hCvar = CreateConVar("sm_vip_kill_bonus_money_knife", "5000", "Сколько денег будет получать игрок за убийство ножом (0 - Отключено)", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(hCvar, OnBonusMoneyKnifeChange);
	g_iCvar_Money_Knife = GetConVarInt(hCvar);
	
	hCvar = CreateConVar("sm_vip_kill_bonus_money_gren", "5000", "Сколько денег будет получать игрок за убийство гранатой (0 - Отключено)", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(hCvar, OnBonusMoneyGrenChange);
	g_iCvar_Money_Gren = GetConVarInt(hCvar);
	
	hCvar = g_bIsCSGO ? FindConVar("mp_maxmoney"):CreateConVar("sm_vip_kill_bonus_max_money", "16000", "Сколько максимально денег может получить игрок за убийства", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(hCvar, OnBonusMaxMoneyChange);
	g_iCvar_Max_Money = GetConVarInt(hCvar);

	AutoExecConfig(true, "VIP_Kill_Bonus", "vip");

	m_iAccount		= FindSendPropOffs("CCSPlayer", "m_iAccount");
	m_iHealth			= FindSendPropOffs("CCSPlayer", "m_iHealth");
	
	HookEventEx("player_death", Event_PlayerDeath);
}

public OnBonusHPChange(Handle:hCvar, const String:oldValue[], const String:newValue[])			g_iCvar_HP = GetConVarInt(hCvar);
public OnBonusHPHSChange(Handle:hCvar, const String:oldValue[], const String:newValue[])			g_iCvar_HP_HS = GetConVarInt(hCvar);
public OnBonusHPKnifeChange(Handle:hCvar, const String:oldValue[], const String:newValue[])		g_iCvar_HP_Knife = GetConVarInt(hCvar);
public OnBonusHPGrenChange(Handle:hCvar, const String:oldValue[], const String:newValue[])		g_iCvar_HP_Gren = GetConVarInt(hCvar);
public OnBonusMaxHPChange(Handle:hCvar, const String:oldValue[], const String:newValue[])		g_iCvar_Max_HP = GetConVarInt(hCvar);
public OnBonusMoneyChange(Handle:hCvar, const String:oldValue[], const String:newValue[])		g_iCvar_Money = GetConVarInt(hCvar);
public OnBonusMoneyHSChange(Handle:hCvar, const String:oldValue[], const String:newValue[])		g_iCvar_Money_HS = GetConVarInt(hCvar);
public OnBonusMoneyKnifeChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iCvar_Money_Knife = GetConVarInt(hCvar);
public OnBonusMoneyGrenChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iCvar_Money_Gren = GetConVarInt(hCvar);
public OnBonusMaxMoneyChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iCvar_Max_Money = GetConVarInt(hCvar);

public Event_PlayerDeath(Handle:hEvent, const String:sEvName[], bool:bDontBroadcast)
{
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(iAttacker && VIP_IsClientVIP(iAttacker) && VIP_IsClientFeatureUse(iAttacker, VIP_KILL_BONUS))
	{
		new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		if(iAttacker != iClient && GetClientTeam(iClient) != GetClientTeam(iAttacker))
		{
			if(GetEventBool(hEvent, "headshot"))
			{
				iClient = GiveClientData(iAttacker, m_iHealth, g_iCvar_HP_HS, g_iCvar_Max_HP);
				iClient = GiveClientData(iAttacker, m_iAccount, g_iCvar_Money_HS, g_iCvar_Max_Money);
				
				if(iClient)
				{
					return;
				}
			}
			
			decl String:sWeapon[32];
			GetEventString(hEvent, "weapon", sWeapon, sizeof(sWeapon));
			if(strcmp(sWeapon, "knife") == 0)
			{
				iClient = GiveClientData(iAttacker, m_iHealth, g_iCvar_HP_Knife, g_iCvar_Max_HP);
				iClient = GiveClientData(iAttacker, m_iAccount, g_iCvar_Money_Knife, g_iCvar_Max_Money);

				if(iClient)
				{
					return;
				}
			}
			else if(strcmp(sWeapon, "hegreanade") == 0)
			{
				iClient = GiveClientData(iAttacker, m_iHealth, g_iCvar_HP_Gren, g_iCvar_Max_HP);
				iClient = GiveClientData(iAttacker, m_iAccount, g_iCvar_Money_Gren, g_iCvar_Max_Money);

				if(iClient)
				{
					return;
				}
			}
	
			GiveClientData(iAttacker, m_iHealth, g_iCvar_HP, g_iCvar_Max_HP);
			GiveClientData(iAttacker, m_iAccount, g_iCvar_Money, g_iCvar_Max_Money);
		}
	}
}

GiveClientData(iClient, m_Offset, iValue, iMaxValue)
{
	if(iValue > 0)
	{
		iValue += GetEntData(iClient, m_Offset);
		if(iValue > iMaxValue)
		{
			iValue = iMaxValue;
		}

		SetEntData(iClient, m_Offset, iValue);

		return 1;
	}

	return 0;
}