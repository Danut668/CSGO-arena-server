#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <vip_core>
#include <clientprefs>

public Plugin:myinfo =
{
	name = "[VIP] NEON (CSS/CSGO)",
	author = "R1KO & Pheonix (˙·٠●Феникс●٠·˙)",
	version = "1.2"
};

static const String:g_sFeature[][] = {"NEON", "NEON_MENU"};

new g_iClientColor[MAXPLAYERS+1][4],
	g_iNeon[MAXPLAYERS+1],
	g_iClientItem[MAXPLAYERS+1];

new bool:g_bHide;
new Handle:g_hKeyValues, Handle:g_hColorsMenu, Handle:g_hCookie;

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature[0], BOOL, _, OnToggleItem);
	VIP_RegisterFeature(g_sFeature[1], _, SELECTABLE, OnSelectItem, _, OnDrawItem);
}

public OnPluginStart()
{
	g_hCookie = RegClientCookie("VIP_Neon", "VIP_Neon", CookieAccess_Public);
	
	g_hColorsMenu = CreateMenu(Handler_ColorsMenu, MenuAction_Select|MenuAction_Display|MenuAction_Cancel|MenuAction_DisplayItem);
	SetMenuExitBackButton(g_hColorsMenu, true);

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerDeath);

	LoadTranslations("vip_modules.phrases");

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature[0]);
		VIP_UnregisterFeature(g_sFeature[1]);
	}
}

public OnMapStart()
{
	RemoveAllMenuItems(g_hColorsMenu);

	if(g_hKeyValues != INVALID_HANDLE)
	{
		CloseHandle(g_hKeyValues);
	}
	g_hKeyValues = CreateKeyValues("Neon_Colors");
	if (FileToKeyValues(g_hKeyValues, "addons/sourcemod/data/vip/modules/neon_colors.ini") == false)
	{
		CloseHandle(g_hKeyValues);
		g_hKeyValues = INVALID_HANDLE;
		SetFailState("Couldn't parse file \"addons/sourcemod/data/vip/modules/neon_colors.ini\"");
	}

	g_bHide = bool:KvGetNum(g_hKeyValues, "Hide_Opposite_Team");

	KvRewind(g_hKeyValues);
	if(KvJumpToKey(g_hKeyValues, "Colors") && KvGotoFirstSubKey(g_hKeyValues, false))
	{
		decl String:sColor[64];
		do
		{
			if (KvGetSectionName(g_hKeyValues, sColor, sizeof(sColor)))
			{
				AddMenuItem(g_hColorsMenu, sColor, sColor);
			}
		}
		while (KvGotoNextKey(g_hKeyValues, false));
	}
	KvRewind(g_hKeyValues);
}

public VIP_OnVIPClientLoaded(iClient)
{
	if(VIP_GetClientFeatureStatus(iClient, g_sFeature[0]) != NO_ACCESS)
	{
		decl String:sColor[64];
		GetClientCookie(iClient, g_hCookie, sColor, sizeof(sColor));
		if(sColor[0] == 0 || LoadClientColor(iClient, sColor) == false)
		{
			g_iClientItem[iClient] = 0;
			GetMenuItem(g_hColorsMenu, g_iClientItem[iClient], sColor, sizeof(sColor));
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
	if (KvJumpToKey(g_hKeyValues, "Colors"))
	{
		decl String:sBuffer[64];
		KvGetString(g_hKeyValues, sColor, sBuffer, sizeof(sBuffer));
		if(StrEqual(sBuffer, "randomcolor"))
		{
			g_iClientColor[iClient][2] = -1;
		}
		else if(StrEqual(sBuffer, "teamcolor"))
		{
			g_iClientColor[iClient][2] = -2;
		}
		else
		{
			KvGetColor(g_hKeyValues, sColor, g_iClientColor[iClient][0], g_iClientColor[iClient][1], g_iClientColor[iClient][2], g_iClientColor[iClient][3]);
		}

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
			FormatEx(sBuffer, sizeof(sBuffer), "%T", g_sFeature[1], iClient);
 
			SetPanelTitle(Handle:Item, sBuffer);
		}
		case MenuAction_Select:
		{
			decl String:sColor[64];
			GetMenuItem(hMenu, Item, sColor, sizeof(sColor));
			g_iClientItem[iClient] = Item;
			if(LoadClientColor(iClient, sColor))
			{
				VIP_PrintToChatClient(iClient, " \x03You changed the Neon Color to \x04%s", sColor);
				SetClientCookie(iClient, g_hCookie, sColor);
				if(IsPlayerAlive(iClient))
				{
					SetClientNeon(iClient);
				}
			}
			else
			{
				VIP_PrintToChatClient(iClient, "Usage error \"%s\"!.", sColor);
			}

			DisplayMenu(g_hColorsMenu, iClient, MENU_TIME_FOREVER);
		}
	}
}

public OnDrawItem(iClient, const String:sFeatureName[], iStyle)
{
	switch(VIP_GetClientFeatureStatus(iClient, g_sFeature[0]))
	{
		case ENABLED: return ITEMDRAW_DEFAULT;
		case DISABLED: return ITEMDRAW_DISABLED;
		case NO_ACCESS: return ITEMDRAW_RAWLINE;
	}

	return iStyle;
}

public Action:OnToggleItem(iClient, const String:sFeatureName[], VIP_ToggleState:OldStatus, &VIP_ToggleState:NewStatus)
{
	RemoveNeon(iClient);

	if(NewStatus == ENABLED && IsPlayerAlive(iClient) && GetClientTeam(iClient) > 1)
	{
		SetClientNeon(iClient);
	}

	return Plugin_Continue;
}

public OnClientDisconnect(iClient)
{
	g_iNeon[iClient] = 0;
}

public VIP_OnPlayerSpawn(iClient, iTeam, bool:bIsVIP)
{
	if(bIsVIP && VIP_IsClientFeatureUse(iClient, g_sFeature[0]))
	{
		SetClientNeon(iClient);
	}
}

public Event_PlayerDeath(Handle:hEvent, const String:sEvName[], bool:dBontBroadcast)
{
	RemoveNeon(GetClientOfUserId(GetEventInt(hEvent, "userid")));
}

RemoveNeon(iClient)
{
	if(g_iNeon[iClient] && IsValidEdict(g_iNeon[iClient]))
	{
		AcceptEntityInput(g_iNeon[iClient], "TurnOff"); 
		AcceptEntityInput(g_iNeon[iClient], "Kill");
	}

	g_iNeon[iClient] = 0;
}

SetClientNeon(iClient)
{
	RemoveNeon(iClient);

	g_iNeon[iClient] = CreateEntityByName("light_dynamic");
	DispatchKeyValue(g_iNeon[iClient], "brightness", "5");
	decl Float:fOrigin[3],  String:sBuffer[16];
	GetClientAbsOrigin(iClient, fOrigin);
	switch(g_iClientColor[iClient][2])
	{
		case -1:
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%d %d %d %d", GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(120, 200));
		}
		case -2:
		{
			switch(GetClientTeam(iClient))
			{
				case 2:
				{
					strcopy(sBuffer, sizeof(sBuffer), "200 25 25 150");
				}
				case 3:
				{
					strcopy(sBuffer, sizeof(sBuffer), "25 25 200 150");
				}
			}
		}
		default:
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%d %d %d %d", g_iClientColor[iClient][0],  g_iClientColor[iClient][1],  g_iClientColor[iClient][2],  g_iClientColor[iClient][3]);
		}
	}
	
	DispatchKeyValue(g_iNeon[iClient], "_light", sBuffer);
	DispatchKeyValue(g_iNeon[iClient], "spotlight_radius", "50");
	DispatchKeyValue(g_iNeon[iClient], "distance", "150");
	DispatchKeyValue(g_iNeon[iClient], "style", "0");
	SetEntPropEnt(g_iNeon[iClient], Prop_Send, "m_hOwnerEntity", iClient);
	if(DispatchSpawn(g_iNeon[iClient]))
	{
		AcceptEntityInput(g_iNeon[iClient], "TurnOn");
		TeleportEntity(g_iNeon[iClient], fOrigin, NULL_VECTOR, NULL_VECTOR);
		SetVariantString("!activator");
		AcceptEntityInput(g_iNeon[iClient], "SetParent", iClient, g_iNeon[iClient], 0);
		if(g_bHide)
		{
			SDKHook(g_iNeon[iClient], SDKHook_SetTransmit, OnTransmit);
		}
		
		return;
	}

	g_iNeon[iClient] = 0;
}

public Action:OnTransmit(iEntity, iClient)
{
	if (g_iNeon[iClient] == iEntity)
	{
		return Plugin_Continue;
	}

	static iOwner, iTeam;

	if ((iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity")) > 0 &&
		(iTeam = GetClientTeam(iClient)) > 1
		&& GetClientTeam(iOwner) != iTeam)
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}