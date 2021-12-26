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
		1.0.1 -	Кнопка "Назад" изменена из 1 на 8
				Исправлено закрытие меню при нажатии "Назад"
*/
#pragma semicolon 1

#include <sourcemod>
#include <vip_core>

public Plugin:myinfo =
{
	name = "[VIP] Vips Online",
	author = "R1KO (skype: vova.andrienko1)",
	version = "1.0.1",
	url = "hlmod.ru"
};

new bool:g_bShowGroup,
	bool:g_bShowExpired;

public OnPluginStart()
{
	decl Handle:hCvar;

	hCvar = CreateConVar("vip_vo_show_group", "1", "Показывать ли VIP-группу при нажатии на игрока (0 - Отключено)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(hCvar, OnShowGroupChange);
	g_bShowGroup = GetConVarBool(hCvar);

	hCvar = CreateConVar("vip_vo_show_expired", "1", "Показывать ли время окончания VIP-статуса при нажатии на игрока (0 - Отключено)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(hCvar, OnShowExpiredChange);
	g_bShowExpired = GetConVarBool(hCvar);

	AutoExecConfig(true, "vips_online", "vip");

	CloseHandle(hCvar);
	
	RegConsoleCmd("sm_viplist", VIPList_CMD);
	RegConsoleCmd("sm_vips", VIPList_CMD);
	RegConsoleCmd("sm_випс", VIPList_CMD);

	LoadTranslations("vips_online.phrases");
	LoadTranslations("vip_core.phrases");
}

public OnShowGroupChange(Handle:hCvar, const String:oldValue[], const String:newValue[])			g_bShowGroup = GetConVarBool(hCvar);
public OnShowExpiredChange(Handle:hCvar, const String:oldValue[], const String:newValue[])		g_bShowExpired = GetConVarBool(hCvar);

public Action:VIPList_CMD(iClient, args)
{
	if(iClient)
	{
		decl Handle:hMenu, String:sName[64], String:sBuffer[16], i;
		hMenu = CreateMenu(Handler_VIPListMenu);
		SetMenuTitle(hMenu, "%T:\n \n", "VIP_PLAYERS_ONLINE", iClient);

		sBuffer[0] = '\0';
		for (i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i) && VIP_IsClientVIP(i) && GetClientName(i, sName, sizeof(sName)))
			{
				IntToString(GetClientUserId(i), sBuffer, sizeof(sBuffer));
				AddMenuItem(hMenu, sBuffer, sName);
			}
		}
		
		if(sBuffer[0] == '\0')
		{
			FormatEx(sName, sizeof(sName), "%T", "NO_VIP_PLAYERS_ONLINE", iClient);
			AddMenuItem(hMenu, "", sName, ITEMDRAW_DISABLED);
		}

		DisplayMenu(hMenu, iClient, 30);
	}

	return Plugin_Handled;
}

public Handler_VIPListMenu(Handle:hMenu, MenuAction:action, iClient, iOption)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(hMenu);
		}
		case MenuAction_Select:
		{
			if(g_bShowGroup || g_bShowExpired)
			{
				decl Handle:hPanel, String:sBuffer[64], iTarget;
				GetMenuItem(hMenu, iOption, sBuffer, sizeof(sBuffer));
				hPanel = CreatePanel();
				SetGlobalTransTarget(iClient);
				iTarget = GetClientOfUserId(StringToInt(sBuffer));
				if(iTarget)
				{
					FormatEx(sBuffer, sizeof(sBuffer), "%t\n \n", "INFO");
					SetPanelTitle(hPanel, sBuffer);
					if(g_bShowGroup)
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t:", "GROUP");
						DrawPanelText(hPanel, sBuffer);
						if(VIP_GetClientVIPGroup(iTarget, sBuffer, sizeof(sBuffer)))
						{
							DrawPanelText(hPanel, sBuffer);
						}

						DrawPanelText(hPanel, " \n");
					}
					
					if(g_bShowExpired)
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t:", "EXPIRES");
						DrawPanelText(hPanel, sBuffer);
						new iExpire = VIP_GetClientAccessTime(iTarget);
						if(iExpire == -1)
						{
							FormatEx(sBuffer, sizeof(sBuffer), "%t", "TEMP");
							DrawPanelText(hPanel, sBuffer);
						}
						else if(iExpire == 0)
						{
							FormatEx(sBuffer, sizeof(sBuffer), "%t", "NEVER");
							DrawPanelText(hPanel, sBuffer);
						}
						else
						{
							decl String:sTimeEnd[128];
							if(VIP_GetTimeFromStamp(sTimeEnd, sizeof(sTimeEnd), iExpire-GetTime(), iClient))
							{
								Format(sTimeEnd, sizeof(sTimeEnd), "%t %s", "EXPIRE", sTimeEnd);
							}
							else
							{
								FormatEx(sTimeEnd, sizeof(sTimeEnd), "%t", "ERROR");
							}
							DrawPanelText(hPanel, sTimeEnd);
						}
						
						DrawPanelText(hPanel, " \n");
					}
				}
				else
				{
					FormatEx(sBuffer, sizeof(sBuffer), "%t", "ERROR");
					SetPanelTitle(hPanel, sBuffer);

					FormatEx(sBuffer, sizeof(sBuffer), "%t", "PLAYER_NO_LONGER_AVAILABLE");
					DrawPanelText(hPanel, sBuffer);
					
					DrawPanelText(hPanel, " \n");
				}

				DrawPanelText(hPanel, " \n");

				FormatEx(sBuffer, sizeof(sBuffer), "%t", "Back");
				SetPanelCurrentKey(hPanel, 8);
				DrawPanelItem(hPanel, sBuffer, ITEMDRAW_CONTROL);

				DrawPanelItem(hPanel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
				
				FormatEx(sBuffer, sizeof(sBuffer), "%t", "Exit");
				SetPanelCurrentKey(hPanel, 10);
				DrawPanelItem(hPanel, sBuffer, ITEMDRAW_CONTROL);
				
				SendPanelToClient(hPanel, iClient, Handler_InfoMenu, 30);
				CloseHandle(hPanel);
			}
			else
			{
				VIPList_CMD(iClient, 0);
			}
		}
	}
}

public Handler_InfoMenu(Handle:hMenu, MenuAction:action, iClient, iOption)
{
	if(action == MenuAction_Select && iOption == 8)
	{
		VIPList_CMD(iClient, 0);
	}
}