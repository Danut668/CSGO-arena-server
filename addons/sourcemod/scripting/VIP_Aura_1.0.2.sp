#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <vip_core>
#include <clientprefs>

public Plugin:myinfo =
{
	name = "[VIP] AURA",
	author = "R1KO & Pheonix (˙·٠●Феникс●٠·˙)",
	version = "1.0.2",
	url = "zizt.ru"
};

#define VIP_AURA_M			"AURA_M"
#define VIP_AURA				"AURA"

new g_iClientColor[MAXPLAYERS+1][4],
	g_iClientItem[MAXPLAYERS+1];

new bool:g_bHasAura[MAXPLAYERS+1];
new Handle:g_hKeyValues, Handle:g_hTimer[MAXPLAYERS+1], Handle:g_hColorsMenu, Handle:g_hCookie;
new g_BeamSprite, g_HaloSprite;

new bool:g_bHide;

public OnPluginStart()
{
	g_hCookie = RegClientCookie("VIP_AURA", "VIP_AURA", CookieAccess_Public);
	
	g_hColorsMenu = CreateMenu(Handler_ColorsMenu, MenuAction_Select|MenuAction_Display|MenuAction_Cancel|MenuAction_DisplayItem);
	SetMenuExitBackButton(g_hColorsMenu, true);

	LoadTranslations("vip_modules.phrases");
}

public OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/blueflare1.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/glow08.vmt");
	
	if (g_hKeyValues != INVALID_HANDLE) CloseHandle(g_hKeyValues);

	g_hKeyValues = CreateKeyValues("Aura_Colors");

	if (FileToKeyValues(g_hKeyValues, "addons/sourcemod/data/vip/modules/aura_colors.ini") == false)
	{
		CloseHandle(g_hKeyValues);
		g_hKeyValues = INVALID_HANDLE;
		SetFailState("Couldn't parse file 'addons/sourcemod/data/vip/modules/aura_colors.ini'");
	}
	
	g_bHide = bool:KvGetNum(g_hKeyValues, "Hide_Opposite_Team");

	RemoveAllMenuItems(g_hColorsMenu);

	KvRewind(g_hKeyValues);
	if (KvGotoFirstSubKey(g_hKeyValues))
	{
		decl String:sBuffer[256];
		do
		{
			KvGetSectionName(g_hKeyValues, sBuffer, sizeof(sBuffer));
			AddMenuItem(g_hColorsMenu, sBuffer, sBuffer);
		}
		while (KvGotoNextKey(g_hKeyValues));
	}
}

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(VIP_AURA, BOOL, _, OnToggleItem);
	VIP_RegisterFeature(VIP_AURA_M, _, SELECTABLE, OnSelectItem, _, OnDrawItem);

	VIP_HookClientSpawn(OnPlayerSpawn);
}

public VIP_OnVIPClientLoaded(iClient)
{
	if(VIP_GetClientFeatureStatus(iClient, VIP_AURA) != NO_ACCESS)
	{
		g_bHasAura[iClient] = VIP_IsClientFeatureUse(iClient, VIP_AURA);
		decl String:sColor[64];
		GetClientCookie(iClient, g_hCookie, sColor, 64);
		if(sColor[0] == 0 || LoadClientColor(iClient, sColor) == false)
		{
			g_iClientItem[iClient] = 0;
			GetMenuItem(g_hColorsMenu, g_iClientItem[iClient], sColor, 64);
			SetClientCookie(iClient, g_hCookie, sColor);
			LoadClientColor(iClient, sColor);
		}
		else
		{
			g_iClientItem[iClient] = UTIL_GetItemIndex(sColor);
		}
	}
}

bool:LoadClientColor(iClient, const String:sColor[])
{
	KvRewind(g_hKeyValues);
	if (KvJumpToKey(g_hKeyValues, sColor, false))
	{
		KvGetColor(g_hKeyValues, "color", g_iClientColor[iClient][0],  g_iClientColor[iClient][1],  g_iClientColor[iClient][2],  g_iClientColor[iClient][3]);
		KvRewind(g_hKeyValues);
		return true;
	}
	
	return false;
}

UTIL_GetItemIndex(const String:sItemInfo[])
{
	decl String:sColor[64], i, iSize;
	iSize = GetMenuItemCount(g_hColorsMenu);
	for(i = 0; i < iSize; ++i)
	{
		GetMenuItem(g_hColorsMenu, i, sColor, sizeof(sColor));
		if(strcmp(sColor, sItemInfo) == 0)
		{
			return i;
		}
	}

	return -1;
}

public bool:OnSelectItem(iClient, const String:sFeatureName[])
{
	DisplayMenu(g_hColorsMenu, iClient, MENU_TIME_FOREVER);
	return false;
}

public Handler_ColorsMenu(Handle:hMenu, MenuAction:action, iClient, Item)
{
	switch(action)
	{
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack) VIP_SendClientVIPMenu(iClient);
		}
		case MenuAction_Display:
		{
	 		decl String:sBuffer[255];
			FormatEx(sBuffer, sizeof(sBuffer), "%T", "AURA_M", iClient);
 
			SetPanelTitle(Handle:Item, sBuffer);
		}
		case MenuAction_Select:
		{
			decl String:sColor[64];
			GetMenuItem(hMenu, Item, sColor, sizeof(sColor));
			
			g_iClientItem[iClient] = Item;
			if(LoadClientColor(iClient, sColor))
			{
				VIP_PrintToChatClient(iClient, "\x03You changed your Aura Color to \x04%s", sColor);
				SetClientCookie(iClient, g_hCookie, sColor);
			}

			DisplayMenu(g_hColorsMenu, iClient, MENU_TIME_FOREVER);
		}
		case MenuAction_DisplayItem:
		{
			if(g_iClientItem[iClient] == Item)
			{
				decl String:sColorName[64];
				GetMenuItem(hMenu, Item, sColorName, sizeof(sColorName));
				
				Format(sColorName, sizeof(sColorName), "%s [X]", sColorName);

				return RedrawMenuItem(sColorName);
			}
		}
	}

	return 0;
}

public OnDrawItem(iClient, const String:sFeatureName[], iStyle)
{
	if(VIP_GetClientFeatureStatus(iClient, VIP_AURA) != ENABLED)
	{
		return ITEMDRAW_DISABLED;
	}

	return iStyle;
}

public Action:OnToggleItem(iClient, const String:sFeatureName[], VIP_ToggleState:OldStatus, &VIP_ToggleState:NewStatus)
{
	g_bHasAura[iClient] = bool:(NewStatus == ENABLED);
	if(g_bHasAura[iClient])
	{
		SetClientAura(iClient);
	}

	return Plugin_Continue;
}

public OnClientDisconnect(iClient)
{
	g_bHasAura[iClient] = false;
	g_hTimer[iClient] = INVALID_HANDLE;

	for(new i=0; i < 4; ++i)
	{
		g_iClientColor[iClient][i] = 255;
	}

	g_iClientItem[iClient] = 0;
}


public OnPlayerSpawn(iClient, iTeam, bool:bIsVIP)
{
	if(bIsVIP && g_bHasAura[iClient])
	{
		SetClientAura(iClient);
	}
}

SetClientAura(iClient)
{
	if(g_hTimer[iClient] == INVALID_HANDLE) g_hTimer[iClient] = CreateTimer(0.1, Timer_Beacon, iClient, TIMER_REPEAT);
}

public Action:Timer_Beacon(Handle:hTimer, any:iClient)
{
	if(IsClientInGame(iClient) && IsPlayerAlive(iClient) && g_bHasAura[iClient])
	{
		static Float:fVec[3], iClients, i;
		decl iClientsArray[MaxClients];
		GetClientAbsOrigin(iClient, fVec);
		fVec[2] += 10;
		TE_SetupBeamRingPoint(fVec, 50.0, 60.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.1, 10.0, 0.0, g_iClientColor[iClient], 10, 0);
		i = 1;
		iClients = 0;
		
		if(g_bHide) 
		{
			decl iTeam;
			iTeam = GetClientTeam(iClient);
			while(i <= MaxClients)
			{ 
				if(IsClientInGame(i) && IsFakeClient(i) == false && GetClientTeam(i) == iTeam)
				{
					iClientsArray[iClients++] = i;
				}
				++i;
			}
		}
		else while(i <= MaxClients)
		{ 
			if(IsClientInGame(i) && IsFakeClient(i) == false)
			{
				iClientsArray[iClients++] = i;
			}
			++i;
		}
		TE_Send(iClientsArray, iClients);
		return Plugin_Continue;
	} 
	else
	{
		g_hTimer[iClient] = INVALID_HANDLE;
	}
	return Plugin_Stop;
}