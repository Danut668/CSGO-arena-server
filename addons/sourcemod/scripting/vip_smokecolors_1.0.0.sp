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
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <vip_core>
#include <clientprefs>

public Plugin:myinfo =
{
	name = "[VIP] SmokeColors",
	author = "R1KO",
	version = "1.0.0"
}

#define VIP_SC		"SmokeColors"
#define VIP_SC_M		"SmokeColors_MENU"

new g_iClientItem[MAXPLAYERS+1];

new Handle:g_hColorsMenu,
	Handle:g_hCookie;

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(VIP_SC, BOOL);
	VIP_RegisterFeature(VIP_SC_M, _, SELECTABLE, OnSelectItem, _, OnDrawItem);
}
public OnPluginStart()
{
	HookEvent("smokegrenade_detonate", Event_SmokeGrenadeDetonate);

	g_hCookie = RegClientCookie("VIP_SmokeColors", "VIP_SmokeColors", CookieAccess_Public);

	g_hColorsMenu = CreateMenu(Handler_ColorsMenu, MenuAction_Select|MenuAction_Cancel|MenuAction_DisplayItem);
	SetMenuExitBackButton(g_hColorsMenu, true);
	SetMenuTitle(g_hColorsMenu, "Smoke color: \n \n");
}

public OnDrawItem(iClient, const String:sFeatureName[], iStyle)
{
	switch(VIP_GetClientFeatureStatus(iClient, VIP_SC))
	{
		case ENABLED: return ITEMDRAW_DEFAULT;
		case DISABLED: return ITEMDRAW_DISABLED;
		case NO_ACCESS: return ITEMDRAW_RAWLINE;
	}

	return iStyle;
}

public bool:OnSelectItem(iClient, const String:sFeatureName[])
{
	DisplayMenu(g_hColorsMenu, iClient, MENU_TIME_FOREVER);
	return false;
}

public OnMapStart()
{
	RemoveAllMenuItems(g_hColorsMenu);

	decl String:sBuffer[256], Handle:hKeyValues;

	hKeyValues = CreateKeyValues("SmokeColors");
	BuildPath(Path_SM, sBuffer, 256, "data/vip/modules/SmokeColors.ini");

	if (FileToKeyValues(hKeyValues, sBuffer) == false)
	{
		CloseHandle(hKeyValues);
		SetFailState("Could not open file\"%s\"", sBuffer);
	}

	KvRewind(hKeyValues);

	sBuffer[0] = 0;
	
	if(KvGotoFirstSubKey(hKeyValues, false))
	{
		decl String:sColor[64];
		do
		{
			KvGetSectionName(hKeyValues, sBuffer, sizeof(sBuffer));
			KvGetString(hKeyValues, NULL_STRING, sColor, sizeof(sColor));
			AddMenuItem(g_hColorsMenu, sColor, sBuffer);
		}
		while (KvGotoNextKey(hKeyValues, false));
	}

	if(sBuffer[0] == 0)
    {  
		//  FormatEx(sName, sizeof(sName), "%T", "NO_COLORS_AVAILABLE", iClient);  
		AddMenuItem(g_hColorsMenu, "", "No Colors", ITEMDRAW_DISABLED);  
    }
	
	CloseHandle(hKeyValues);
}

public Handler_ColorsMenu(Handle:hMenu, MenuAction:action, iClient, Item)
{
	switch(action)
	{
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack) VIP_SendClientVIPMenu(iClient);
		}
		case MenuAction_Select:
		{
			decl String:sInfo[64], String:sColorName[128];
			GetMenuItem(hMenu, Item, sInfo, sizeof(sInfo), _, sColorName, sizeof(sColorName));
			
			SetClientCookie(iClient, g_hCookie, sInfo);
			g_iClientItem[iClient] = Item;

			VIP_PrintToChatClient(iClient, "\x03You changed Smoke Color to \x04%s", sColorName);
			
			DisplayMenuAtItem(g_hColorsMenu, iClient, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		}
		case MenuAction_DisplayItem:
		{
			if(g_iClientItem[iClient] == Item)
			{
				decl String:sColorName[128];
				GetMenuItem(hMenu, Item, "", 0, _, sColorName, sizeof(sColorName));
				
				Format(sColorName, sizeof(sColorName), "%s [✓]", sColorName);

				return RedrawMenuItem(sColorName);
			}
		}
	}

	return 0;
}

public VIP_OnVIPClientLoaded(iClient)
{
	g_iClientItem[iClient] = 0;

	if(VIP_GetClientFeatureStatus(iClient, VIP_SC) != NO_ACCESS)
	{
		decl String:sInfo[64];
		GetClientCookie(iClient, g_hCookie, sInfo, sizeof(sInfo));
		if(sInfo[0])
		{
			g_iClientItem[iClient] = UTIL_GetItemIndex(sInfo);
		}
	}
}

UTIL_GetItemIndex(const String:sItemInfo[])
{
	decl String:sInfo[64], i, iSize;
	iSize = GetMenuItemCount(g_hColorsMenu);
	for(i = 0; i < iSize; ++i)
	{
		GetMenuItem(g_hColorsMenu, i, sInfo, sizeof(sInfo));
		if(strcmp(sInfo, sItemInfo) == 0)
		{
			return i;
		}
	}

	return 0;
}

public Event_SmokeGrenadeDetonate(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(iClient && VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, VIP_SC))
	{
		new iEntity = CreateEntityByName("light_dynamic");
		
		if (iEntity != -1)
		{
			decl String:sBuffer[64];
			GetMenuItem(g_hColorsMenu, g_iClientItem[iClient], sBuffer, sizeof(sBuffer));
			if(strcmp(sBuffer, "teamcolor") == 0)
			{
				switch (GetClientTeam(iClient))
				{
					case 2 :
					{
						FormatEx(sBuffer, sizeof(sBuffer), "200 25 25 255");
					}
					case 3 :
					{
						FormatEx(sBuffer, sizeof(sBuffer), "25 25 200 255");
					}
				}
			}
			else if(strcmp(sBuffer, "random") == 0)
			{
				FormatEx(sBuffer, sizeof(sBuffer), "%i %i %i 255", GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255));
			}

			DispatchKeyValue(iEntity, "_light", sBuffer);

			FormatEx(sBuffer, sizeof(sBuffer), "smokelight_%d", iEntity);
			DispatchKeyValue(iEntity, "targetname", sBuffer);
			FormatEx(sBuffer, sizeof(sBuffer), "%f %f %f", GetEventFloat(hEvent, "x"), GetEventFloat(hEvent, "y"), GetEventFloat(hEvent, "z"));
			DispatchKeyValue(iEntity, "origin", sBuffer);
			DispatchKeyValue(iEntity, "angles", "-90 0 0");
			DispatchKeyValue(iEntity, "pitch", "-90");
			DispatchKeyValue(iEntity, "distance", "256");
			DispatchKeyValue(iEntity, "spotlight_radius", "96");
			DispatchKeyValue(iEntity, "brightness", "3");
			DispatchKeyValue(iEntity, "style", "6");
			DispatchKeyValue(iEntity, "spawnflags", "1");
			DispatchSpawn(iEntity);
			AcceptEntityInput(iEntity, "DisableShadow");
			
			AcceptEntityInput(iEntity, "TurnOn");
			
			CreateTimer(20.0, _Timer_RemoveLight, EntIndexToEntRef(iEntity), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:_Timer_RemoveLight(Handle:hTimer, any:iRef)
{
	new iEntity = EntRefToEntIndex(iRef);
	
	if (iEntity != INVALID_ENT_REFERENCE && IsValidEdict(iEntity))
	{
		AcceptEntityInput(iEntity, "TurnOff");
		AcceptEntityInput(iEntity, "kill");
		RemoveEdict(iEntity);
	}
}