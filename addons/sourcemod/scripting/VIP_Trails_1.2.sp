#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <vip_core>

public Plugin:myinfo =
{
	name = "[VIP] Trails",
	author = "R1KO",
	version = "1.2"
};

static const String:g_sFeature[][] = {"Trails", "Trails_MENU"};

new Handle:g_hKeyValues,
	Handle:g_hTrailsMenu,
	Handle:g_hCookie,
	bool:g_bHide,
	Float:g_fLifeTime,
	g_iStartWidth,
	g_iEndWidth,
	g_iClientTrail[MAXPLAYERS+1],
	g_iClientItem[MAXPLAYERS+1];

public OnPluginStart()
{
	g_hCookie = RegClientCookie("VIP_Trails", "VIP_Trails", CookieAccess_Private);
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerDeath);

	g_hTrailsMenu = CreateMenu(Handler_TrailsMenu, MenuAction_Select|MenuAction_Cancel|MenuAction_Display|MenuAction_DisplayItem|MenuAction_DrawItem);
	SetMenuExitBackButton(g_hTrailsMenu, true);

	LoadTranslations("vip_core.phrases");
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

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature[0], BOOL, _, OnToggleItem);
	VIP_RegisterFeature(g_sFeature[1], _, SELECTABLE, OnSelectItem, _, OnDrawItem);
}

public Action:OnToggleItem(iClient, const String:sFeatureName[], VIP_ToggleState:OldStatus, &VIP_ToggleState:NewStatus)
{
	if(NewStatus == ENABLED)
	{
		if(IsPlayerAlive(iClient))
		{
			UTIL_CreateTrail(iClient);
		}
	}
	else
	{
		UTIL_KillTrail(iClient);
	}

	return Plugin_Continue;
}

public bool:OnSelectItem(iClient, const String:sFeatureName[])
{
	DisplayMenu(g_hTrailsMenu, iClient, MENU_TIME_FOREVER);
	return false;
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

public OnMapStart()
{
	decl String:sBuffer[256];

	if(g_hKeyValues != INVALID_HANDLE)
	{
		CloseHandle(g_hKeyValues);
	}
	
	RemoveAllMenuItems(g_hTrailsMenu);

	g_hKeyValues = CreateKeyValues("Trails");
	BuildPath(Path_SM, sBuffer, 256, "data/vip/modules/trails.ini");

	if (FileToKeyValues(g_hKeyValues, sBuffer) == false)
	{
		SetFailState("Could not open file \"%s\"", sBuffer);
	}

	g_bHide = bool:KvGetNum(g_hKeyValues, "Hide_Opposite_Team");
	g_iStartWidth = KvGetNum(g_hKeyValues, "StartWidth", 10);
	g_iEndWidth = KvGetNum(g_hKeyValues, "EndWidth", 6);
	g_fLifeTime = KvGetFloat(g_hKeyValues, "LifeTime", 1.0);

	KvRewind(g_hKeyValues);
	
	if (KvGotoFirstSubKey(g_hKeyValues))
	{
		do
		{
			KvGetString(g_hKeyValues, "Material", sBuffer, sizeof(sBuffer));
			if(sBuffer[0] && FileExists(sBuffer) && strcmp(sBuffer[strlen(sBuffer)-4], ".vmt") == 0)
			{
				PrecacheModel(sBuffer, true);
				AddFileToDownloadsTable(sBuffer);
				ReplaceString(sBuffer, sizeof(sBuffer), ".vmt", ".vtf", false);
				if(FileExists(sBuffer))
				{
					AddFileToDownloadsTable(sBuffer);
					KvGetSectionName(g_hKeyValues, sBuffer, sizeof(sBuffer));
					AddMenuItem(g_hTrailsMenu, sBuffer, sBuffer);
					continue;
				}
			}

			KvDeleteThis(g_hKeyValues);
		}
		while (KvGotoNextKey(g_hKeyValues));
	}

	if(!GetMenuItemCount(g_hTrailsMenu))
	{
		AddMenuItem(g_hTrailsMenu, "", "No available", ITEMDRAW_DISABLED);
	}
}

public Handler_TrailsMenu(Handle:hMenu, MenuAction:action, iClient, Item)
{
	switch(action)
	{
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack) VIP_SendClientVIPMenu(iClient);
		}
		case MenuAction_Display:
		{
			decl String:sDisplay[64];
			FormatEx(sDisplay, sizeof(sDisplay), "%T:\n ", g_sFeature[0], iClient);
			SetPanelTitle(Handle:Item, sDisplay);
		}
		case MenuAction_Select:
		{
			decl String:sKey[64];
			GetMenuItem(hMenu, Item, sKey, sizeof(sKey));

			VIP_PrintToChatClient(iClient, "\x03You have installed the trail \x04%s", sKey);
			SetClientCookie(iClient, g_hCookie, sKey);
			g_iClientItem[iClient] = Item;
			KvRewind(g_hKeyValues);
			KvJumpToKey(g_hKeyValues, sKey);
			UTIL_LoadTrail(iClient);
			
			if(VIP_IsClientFeatureUse(iClient, g_sFeature[0]) && IsPlayerAlive(iClient))
			{
				UTIL_CreateTrail(iClient);
			}

			DisplayMenuAtItem(g_hTrailsMenu, iClient, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		}
		case MenuAction_DisplayItem:
		{
			if(g_iClientItem[iClient] == Item)
			{
				decl String:sName[64];
				GetMenuItem(hMenu, Item, sName, sizeof(sName));
				
				Format(sName, sizeof(sName), "%s [X]", sName);

				return RedrawMenuItem(sName);
			}
		}
		case MenuAction_DrawItem:
		{
			if(g_iClientItem[iClient] == Item)
			{
				return ITEMDRAW_DISABLED;
			}
		}
	}

	return 0;
}

public OnClientPostAdminCheck(iClient)
{
	g_iClientTrail[iClient] =
	g_iClientItem[iClient] = -1;
}

public VIP_OnVIPClientLoaded(iClient)
{
	if(VIP_GetClientFeatureStatus(iClient, g_sFeature[0]) != NO_ACCESS)
	{
		decl String:sKey[64];
		GetClientCookie(iClient, g_hCookie, sKey, sizeof(sKey));
		if(sKey[0])
		{
			g_iClientItem[iClient] = UTIL_GetItemIndex(sKey);
			if(g_iClientItem[iClient] != -1)
			{
				KvRewind(g_hKeyValues);
				if(KvJumpToKey(g_hKeyValues, sKey))
				{
					UTIL_LoadTrail(iClient);
					return;
				}
			}
		}

		g_iClientItem[iClient] = 0;
		KvRewind(g_hKeyValues);
		KvGotoFirstSubKey(g_hKeyValues);
		UTIL_LoadTrail(iClient);
	}
}

UTIL_GetItemIndex(const String:sItemInfo[])
{
	decl String:sInfo[128], i, iSize;
	iSize = GetMenuItemCount(g_hTrailsMenu);
	for(i = 0; i < iSize; ++i)
	{
		GetMenuItem(g_hTrailsMenu, i, sInfo, sizeof(sInfo));
		if(strcmp(sInfo, sItemInfo) == 0)
		{
			return i;
		}
	}

	return -1;
}

UTIL_LoadTrail(iClient)
{
	decl Handle:hTrie, String:sBuffer[128], Float:fBuffer[3], iBuffer;
	
	hTrie = VIP_GetVIPClientTrie(iClient);

	RemoveFromTrie(hTrie, "Trails->Material");
	RemoveFromTrie(hTrie, "Trails->LifeTime");
	RemoveFromTrie(hTrie, "Trails->StartWidth");
	RemoveFromTrie(hTrie, "Trails->EndWidth");
	RemoveFromTrie(hTrie, "Trails->Color");
	RemoveFromTrie(hTrie, "Trails->Position");

	KvGetString(g_hKeyValues, "Material", sBuffer, sizeof(sBuffer), "materials/sprites/laserbeam.vmt");
	SetTrieString(hTrie, "Trails->Material", sBuffer);

	if((fBuffer[0] = KvGetFloat(g_hKeyValues, "LifeTime")))
	{
		SetTrieValue(hTrie, "Trails->LifeTime", fBuffer[0]);
	}

	if((iBuffer = KvGetNum(g_hKeyValues, "StartWidth")))
	{
		SetTrieValue(hTrie, "Trails->StartWidth", iBuffer);
	}

	if((iBuffer = KvGetNum(g_hKeyValues, "EndWidth")))
	{
		SetTrieValue(hTrie, "Trails->EndWidth", iBuffer);
	}

	KvGetString(g_hKeyValues, "Color", sBuffer, sizeof(sBuffer));

	if(sBuffer[0])
	{
		SetTrieString(hTrie, "Trails->Color", sBuffer);
	}

	KvGetVector(g_hKeyValues, "Position", fBuffer);

	if(fBuffer[0] || fBuffer[1] || fBuffer[2])
	{
		SetTrieArray(hTrie, "Trails->Position", fBuffer, 3);
	}
}

public VIP_OnPlayerSpawn(iClient, iTeam, bool:bIsVIP)
{
	if(bIsVIP && VIP_IsClientFeatureUse(iClient, g_sFeature[0]))
	{
		UTIL_CreateTrail(iClient);
	}
}

public Event_PlayerDeath(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	UTIL_KillTrail(GetClientOfUserId(GetEventInt(hEvent, "userid")));
}

UTIL_KillTrail(iClient)
{
	if(g_iClientTrail[iClient] > 0)
	{
		if(IsValidEdict(g_iClientTrail[iClient]))
		{
			AcceptEntityInput(g_iClientTrail[iClient], "Kill");
			if(g_bHide)
			{
				SDKUnhook(g_iClientTrail[iClient], SDKHook_SetTransmit, Hook_TrailSetTransmit);
			}
		}
		g_iClientTrail[iClient] = -1;
	}
}

UTIL_CreateTrail(iClient)
{
	UTIL_KillTrail(iClient);

	g_iClientTrail[iClient] = CreateEntityByName("env_spritetrail");
	if (g_iClientTrail[iClient] != -1) 
	{
		decl Handle:hTrie, String:sBuffer[PLATFORM_MAX_PATH], Float:fBuffer[3], Float:fOrigin[3], iBuffer;

		hTrie = VIP_GetVIPClientTrie(iClient);
		
		GetTrieString(hTrie, "Trails->Material", sBuffer, sizeof(sBuffer));
		DispatchKeyValue(g_iClientTrail[iClient], "spritename", sBuffer);
	
		IntToString(GetTrieValue(hTrie, "Trails->StartWidth", iBuffer) ? iBuffer:g_iStartWidth, sBuffer, 8);
		DispatchKeyValue(g_iClientTrail[iClient], "startwidth", sBuffer);
		
		IntToString(GetTrieValue(hTrie, "Trails->EndWidth", iBuffer) ? iBuffer:g_iEndWidth, sBuffer, 8);
		DispatchKeyValue(g_iClientTrail[iClient], "endwidth", sBuffer);
	
		DispatchKeyValueFloat(g_iClientTrail[iClient], "lifetime", GetTrieValue(hTrie, "Trails->LifeTime", fBuffer[0]) ? fBuffer[0]:g_fLifeTime);

		DispatchKeyValue(g_iClientTrail[iClient], "renderamt", "255");
		DispatchKeyValue(g_iClientTrail[iClient], "rendercolor", GetTrieString(hTrie, "Trails->Color", sBuffer, sizeof(sBuffer)) ? sBuffer:"255 255 255");

		DispatchKeyValue(g_iClientTrail[iClient], "rendermode", "1");

		FormatEx(sBuffer, sizeof(sBuffer), "vip_trails_%d", g_iClientTrail[iClient]);
		DispatchKeyValue(g_iClientTrail[iClient], "targetname", sBuffer);

		DispatchSpawn(g_iClientTrail[iClient]);

		GetClientAbsOrigin(iClient, fOrigin);

		if(GetTrieArray(hTrie, "Trails->Position", fBuffer, 3))
		{
			decl Float:fAngles[3],
			Float:fForward[3],
			Float:fRight[3],
			Float:fUp[3];

			GetClientAbsAngles(iClient, fAngles);
			
			GetAngleVectors(fAngles, fForward, fRight, fUp);

			fOrigin[0] += fRight[0]*fBuffer[0] + fForward[0]*fBuffer[1] + fUp[0]*fBuffer[2];
			fOrigin[1] += fRight[1]*fBuffer[0] + fForward[1]*fBuffer[1] + fUp[1]*fBuffer[2];
			fOrigin[2] += fRight[2]*fBuffer[0] + fForward[2]*fBuffer[1] + fUp[2]*fBuffer[2];
		}

		TeleportEntity(g_iClientTrail[iClient], fOrigin, NULL_VECTOR, NULL_VECTOR);
		
		SetVariantString("!activator");
		AcceptEntityInput(g_iClientTrail[iClient], "SetParent", iClient); 
		SetEntPropFloat(g_iClientTrail[iClient], Prop_Send, "m_flTextureRes", 0.05);
		SetEntPropEnt(g_iClientTrail[iClient], Prop_Send, "m_hOwnerEntity", iClient);
		
		if (g_bHide)
		{
			SDKHook(g_iClientTrail[iClient], SDKHook_SetTransmit, Hook_TrailSetTransmit);
		}
	}
}

public Action:Hook_TrailSetTransmit(iEntity, iClient)
{
	if (g_iClientTrail[iClient] == iEntity || GetClientTeam(iClient) < 2)
	{
		return Plugin_Continue;
	}

	static iOwner;
	if ((iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity")) != -1 && GetClientTeam(iOwner) != GetClientTeam(iClient))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
