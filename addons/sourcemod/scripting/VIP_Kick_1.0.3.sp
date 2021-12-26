#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <vip_core>
#include <cstrike>

public Plugin myinfo = 
{
	name = "[VIP] Kick",
	author = "R1KO (skype: vova.andrienko1)",
	version = "1.0.3"
};

static const char g_sFeature[] = "Kick";

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL, SELECTABLE, OnSelectItem);
}

Handle g_hReasonsMenu;
int g_iCvar_AdminImmunityMode;
bool g_bCvar_VIPImmunityMode;

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.basecommands");

	g_hReasonsMenu = CreateMenu(Handler_ReasonsMenu, MenuAction_Select|MenuAction_Cancel);
	SetMenuExitBackButton(g_hReasonsMenu, true);
	SetMenuTitle(g_hReasonsMenu, "Причина:\n \n");
	
	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public void OnMapStart()
{
	RemoveAllMenuItems(g_hReasonsMenu);
	
	char sBuffer[256];
	Handle hKeyValues;

	hKeyValues = CreateKeyValues("Kick");
	BuildPath(Path_SM, sBuffer, 256, "data/vip/modules/kick.ini");

	if (FileToKeyValues(hKeyValues, sBuffer) == false)
	{
		SetFailState("Не удалось открыть файл \"%s\"", sBuffer);
	}
	
	KvRewind(hKeyValues);
	
	g_iCvar_AdminImmunityMode = KvGetNum(hKeyValues, "vip_kick_admin_immunity");
	g_bCvar_VIPImmunityMode = view_as<bool>(KvGetNum(hKeyValues, "vip_kick_vip_immunity"));
	
	if (KvJumpToKey(hKeyValues, "Reasons") && KvGotoFirstSubKey(hKeyValues, false))
	{
		char sReason[64];
		do
		{
			KvGetSectionName(hKeyValues, sReason, sizeof(sReason));
			KvGetString(hKeyValues, NULL_STRING, sBuffer, sizeof(sBuffer));
			AddMenuItem(g_hReasonsMenu, sBuffer, sReason);
		}
		while (KvGotoNextKey(hKeyValues, false));
	}
	
	CloseHandle(hKeyValues);
}

public bool OnSelectItem(int iClient, const char[] sFeatureName) {
	DisplayMenu(CreatePlayersMenu(iClient), iClient, MENU_TIME_FOREVER);
	return false;
}

Handle CreatePlayersMenu(int iClient)
{
	char sUserID[16];
	char sName[64];
	Handle hMenu;
	int i;
	AdminId AID;
	hMenu = CreateMenu(PlayersMenu_Handler);
	SetMenuExitBackButton(hMenu, true);
	SetMenuTitle(hMenu, "%T:\n \n", "Kick player", iClient);
	
	sUserID[0] = 0;
	for(i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i))
		{
			if(g_bCvar_VIPImmunityMode && VIP_IsClientVIP(i))
			{
				continue;
			}
			
			AID = GetUserAdmin(i);
			if(g_iCvar_AdminImmunityMode == 0 && AID != INVALID_ADMIN_ID)
			{
				continue;
			}

			if(g_iCvar_AdminImmunityMode > 0 && GetAdminImmunityLevel(AID) >= g_iCvar_AdminImmunityMode)
			{
				continue;
			}
			
			GetClientName(i, sName, sizeof(sName));
			IntToString(GetClientUserId(i), sUserID, sizeof(sUserID));
			AddMenuItem(hMenu, sUserID, sName);
		}
	}

	if(sUserID[0] == 0)
	{
		FormatEx(sName, sizeof(sName), "%T", "No matching clients", iClient);
		AddMenuItem(hMenu, "", sName, ITEMDRAW_DISABLED);
	}

	return hMenu;
}

public int PlayersMenu_Handler(Handle hMenu, MenuAction action, int iClient, int Item)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(hMenu);
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack)
			{
				VIP_SendClientVIPMenu(iClient);
			}
		}
		case MenuAction_Select:
		{
			char sUserID[16];
			int UserID;
			GetMenuItem(hMenu, Item, sUserID, sizeof(sUserID));
			UserID = StringToInt(sUserID);
			if(GetClientOfUserId(UserID) > 0)
			{
				SetTrieValue(VIP_GetVIPClientTrie(iClient), "KickTarget", UserID);
				DisplayMenu(g_hReasonsMenu, iClient, MENU_TIME_FOREVER);
			}
			else
			{
				PrintToChat(iClient, "[SM] %t", "Player no longer available");
			}
		}
	}
}

public int Handler_ReasonsMenu(Handle hMenu, MenuAction action, int iClient, int Item)
{
	switch(action)
	{
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack)
			{
				DisplayMenu(CreatePlayersMenu(iClient), iClient, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Select:
		{
			char sReason[128];
			int iTarget;
			GetMenuItem(hMenu, Item, sReason, sizeof(sReason));
			if(GetTrieValue(VIP_GetVIPClientTrie(iClient), "KickTarget", iTarget))
			{
				iTarget = GetClientOfUserId(iTarget);
				if(iTarget && IsClientInGame(iTarget))
				{
					char sName[MAX_NAME_LENGTH];
					GetClientName(iTarget, sName, sizeof(sName));
					VIP_PrintToChatAll("\x01VIP-игрок \x04%N \x01кикнул игрока \x04%s \x01(Причина: \x04%s\x01)", iClient, sName, sReason);
					VIP_PrintToChatClient(iClient, "\x01%t", "Kicked target reason", "_s", sName, sReason);
					LogAction(iClient, iTarget, "VIP-игрок \"%L\" кикнул игрока \"%L\" (Причина: %s)", iClient, iTarget, sReason);
					KickClient(iTarget, sReason);
				}
				else
				{
					PrintToChat(iTarget, "[SM] %t", "Player no longer available");
				}
			}
		}
	}
}

public void OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}