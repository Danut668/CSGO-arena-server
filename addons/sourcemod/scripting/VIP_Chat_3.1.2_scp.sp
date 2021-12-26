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
#include <clientprefs>

#include <vip_core>
#include <scp>

public Plugin:myinfo =
{
	name = "[VIP] CHAT (+scp)",
	author = "R1KO",
	version = "3.1.1"
};

#define GAME_UNDEFINED	0
#define GAME_CSS_34		1
#define GAME_CSS			2
#define GAME_CSGO			3

new Engine_Version = GAME_UNDEFINED;

enum
{
	PREFIX = 0,
	PREFIX_COLOR,
	NAME_COLOR,
	TEXT_COLOR,

	SIZE
};

new const	String:g_sFeature[] = "Chat",
			String:g_sCUSTOM[] = "custom",
			String:g_sLIST[] = "list",
			String:g_sFeatures[SIZE][] =
			{
				"Chat_Prefix",
				"Chat_PrefixColor",
				"Chat_NameColor",
				"Chat_TextColor"
			};

new Handle:g_hCookies[SIZE];
new Handle:g_hKeyValues;
new Handle:g_hIgnoredPhrases;
new Handle:g_hColorsTrie;

new bool:g_bIgnoreTriggers,
	bool:g_bIgnorePhrases;

new bool:g_bWaitChat[MAXPLAYERS+1];

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL, SELECTABLE, OnSelectItem);
	VIP_RegisterFeature(g_sFeatures[PREFIX], STRING, HIDE);
	VIP_RegisterFeature(g_sFeatures[PREFIX_COLOR], STRING, HIDE);
	VIP_RegisterFeature(g_sFeatures[NAME_COLOR], STRING, HIDE);
	VIP_RegisterFeature(g_sFeatures[TEXT_COLOR], STRING, HIDE);
}

public OnPluginEnd()
{
	VIP_UnregisterFeature(g_sFeature);
	VIP_UnregisterFeature(g_sFeatures[PREFIX]);
	VIP_UnregisterFeature(g_sFeatures[PREFIX_COLOR]);
	VIP_UnregisterFeature(g_sFeatures[NAME_COLOR]);
	VIP_UnregisterFeature(g_sFeatures[TEXT_COLOR]);
}

public OnPluginStart() 
{
	Engine_Version = GetGame();
	/*
	if (Engine_Version == GAME_UNDEFINED)
	{
		SetFailState("Game is not supported!");
	}
	*/
	
	g_hColorsTrie = CreateTrie();

	g_hCookies[0]	= RegClientCookie("VIP_Chat_Prefix", "VIP_Chat_Prefix", CookieAccess_Private);
	g_hCookies[1]	= RegClientCookie("VIP_Chat_PrefixColor", "VIP_Chat_PrefixColor", CookieAccess_Private);
	g_hCookies[2]	= RegClientCookie("VIP_Chat_NameColor", "VIP_Chat_NameColor", CookieAccess_Private);
	g_hCookies[3]	= RegClientCookie("VIP_Chat_TextColor", "VIP_Chat_TextColor", CookieAccess_Private);

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	
	LoadTranslations("vip_chat.phrases");
/*
	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
	*/
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("GuessSDKVersion"); 
	MarkNativeAsOptional("GetEngineVersion");
	
	MarkNativeAsOptional("BfWriteByte");
	MarkNativeAsOptional("BfWriteString");
	MarkNativeAsOptional("PbSetInt");
	MarkNativeAsOptional("PbSetBool");
	MarkNativeAsOptional("PbSetString");

	return APLRes_Success;
}

GetGame()
{
	if (GetFeatureStatus(FeatureType_Native, "GetEngineVersion") == FeatureStatus_Available) 
	{ 
		switch (GetEngineVersion()) 
		{ 
			case Engine_SourceSDK2006: return GAME_CSS_34; 
			case Engine_CSS: return GAME_CSS; 
			case Engine_CSGO: return GAME_CSGO; 
		} 
	} 
	else if (GetFeatureStatus(FeatureType_Native, "GuessSDKVersion") == FeatureStatus_Available) 
	{ 
		switch (GuessSDKVersion())
		{ 
			case SOURCE_SDK_EPISODE1: return GAME_CSS_34;
			case SOURCE_SDK_CSS: return GAME_CSS;
			case SOURCE_SDK_CSGO: return GAME_CSGO;
		}
	}
	return GAME_UNDEFINED;
}

public OnMapStart()
{
	decl String:sBuffer[256];

	if(g_hKeyValues != INVALID_HANDLE)
	{
		CloseHandle(g_hKeyValues);
	}

	ClearTrie(g_hColorsTrie);

	g_hKeyValues = CreateKeyValues("Chat");
	BuildPath(Path_SM, sBuffer, 256, "data/vip/modules/chat_config.ini");

	if (FileToKeyValues(g_hKeyValues, sBuffer) == false)
	{
		CloseHandle(g_hKeyValues);
		SetFailState("Не удалось открыть файл \"%s\"", sBuffer);
	}

	KvRewind(g_hKeyValues);
	if(KvJumpToKey(g_hKeyValues, "Settings"))
	{
		g_bIgnoreTriggers = bool:KvGetNum(g_hKeyValues, "ignore_chat_triggers");
		g_bIgnorePhrases = bool:KvGetNum(g_hKeyValues, "ignore_chat_phrases");
	}
	if(g_hIgnoredPhrases != INVALID_HANDLE)
	{
		CloseHandle(g_hIgnoredPhrases);
	}
	
	g_hIgnoredPhrases = CreateArray(ByteCountToCells(64));

	KvRewind(g_hKeyValues);
	if(KvJumpToKey(g_hKeyValues, "Ignore"))
	{
		if(KvGotoFirstSubKey(g_hKeyValues, false))
		{
			do
			{
				KvGetString(g_hKeyValues, NULL_STRING, sBuffer, sizeof(sBuffer));
				PushArrayString(g_hIgnoredPhrases, sBuffer);
			} while (KvGotoNextKey(g_hKeyValues, false));
		}
	}
	
	if(!GetArraySize(g_hIgnoredPhrases))
	{
		CloseHandle(g_hIgnoredPhrases);
		g_hIgnoredPhrases = INVALID_HANDLE;
	}

	LoadColors("NameColor_List");
	LoadColors("TextColor_List");
	LoadColors("PrefixColor_List");
}

LoadColors(const String:sKey[])
{
	KvRewind(g_hKeyValues);
	if(KvJumpToKey(g_hKeyValues, sKey) && KvGotoFirstSubKey(g_hKeyValues, false))
	{
		decl String:sColorCode[16], String:sColorName[32];
		do
		{
			KvGetSectionName(g_hKeyValues, sColorName, sizeof(sColorName));
			KvGetString(g_hKeyValues, NULL_STRING, sColorCode, sizeof(sColorCode));
			SetTrieString(g_hColorsTrie, sColorCode, sColorName);
		} while (KvGotoNextKey(g_hKeyValues, false));
	}
}

public Action:OnChatMessage(&iClient, Handle:hRecipients, String:sName[], String:sMessage[])
{
	if(VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		if(g_bIgnoreTriggers &&
			(sMessage[0] == '!' ||
			sMessage[0] == '/' ||
			sMessage[0] == '@'))
		{
			return Plugin_Continue;
		}

		if(g_bIgnorePhrases && g_hIgnoredPhrases && FindStringInArray(g_hIgnoredPhrases, sMessage) != -1)
		{
			return Plugin_Continue;
		}

		/*
		for(new iSize = GetArraySize(hRecipients), x, i = 0; i < iSize; ++i)
		{
			x = GetArrayCell(hRecipients, i);
			if(IsClientInGame(x) || !IsPlayerAlive(x))
			RemoveFromArray(hRecipients, i);
		}
		*/

		decl String:sBuffer[192];
		if(GetClientChat(iClient, TEXT_COLOR, sBuffer, sizeof(sBuffer)))
		{
			Format(sMessage, MAXLENGTH_MESSAGE, "%s%s", sBuffer, sMessage);
		}

		if(GetClientChat(iClient, NAME_COLOR, sBuffer, sizeof(sBuffer)))
		{
			Format(sName, MAXLENGTH_NAME, "%s%s", sBuffer, sName);
		}
		else
		{
			Format(sName, MAXLENGTH_NAME, "\x03%s", sName);
		}

		if(GetClientChat(iClient, PREFIX, sBuffer, sizeof(sBuffer)))
		{
			Format(sName, MAXLENGTH_NAME, "%s %s", sBuffer, sName);

			if(GetClientChat(iClient, PREFIX_COLOR, sBuffer, sizeof(sBuffer)))
			{
				Format(sName, MAXLENGTH_NAME, "%s%s", sBuffer, sName);
			}
		}
		
		if(Engine_Version == GAME_CSGO)
		{
			Format(sName, MAXLENGTH_NAME, " %s", sName);
		}

		ReplaceStringColors(sName, MAXLENGTH_NAME);
		ReplaceStringColors(sMessage, MAXLENGTH_MESSAGE);
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

bool:GetClientChat(iClient, index, String:sBuffer[], iMaxLen)
{
	if(VIP_IsClientFeatureUse(iClient, g_sFeatures[index]))
	{
		VIP_GetClientFeatureString(iClient, g_sFeatures[index], sBuffer, iMaxLen);
		if(strcmp(sBuffer, g_sCUSTOM) == 0 || strcmp(sBuffer, g_sLIST) == 0)
		{
			GetClientCookie(iClient, g_hCookies[index], sBuffer, iMaxLen);
		}
		else
		{
			decl String:sCookie[4];
			GetClientCookie(iClient, g_hCookies[index], sCookie, sizeof(sCookie));
			if(sCookie[0] == '0')
			{
				return false;
			}
		}

		if(sBuffer[0] == '0')
		{
			return false;
		}

		if(sBuffer[0])
		{
			return true;
		}
	}

	return false;
}

ReplaceStringColors(String:sMessage[], iMaxLen)
{
	ReplaceString(sMessage, iMaxLen, "{DEFAULT}",	"\x01", false);
	ReplaceString(sMessage, iMaxLen, "{TEAM}",		"\x03", false);
	ReplaceString(sMessage, iMaxLen, "{GREEN}",		"\x04", false);

	if(Engine_Version == GAME_CSGO)
	{
		ReplaceString(sMessage, iMaxLen, "{RED}",			"\x02", false);
		ReplaceString(sMessage, iMaxLen, "{LIME}",			"\x05", false);
		ReplaceString(sMessage, iMaxLen, "{LIGHTGREEN}",	"\x06", false);
		ReplaceString(sMessage, iMaxLen, "{LIGHTRED}",		"\x07", false);
		ReplaceString(sMessage, iMaxLen, "{GRAY}",			"\x08", false);
		ReplaceString(sMessage, iMaxLen, "{LIGHTOLIVE}",	"\x09", false);
		ReplaceString(sMessage, iMaxLen, "{OLIVE}",			"\x10", false);
		ReplaceString(sMessage, iMaxLen, "{PURPLE}",		"\x0E", false);
		ReplaceString(sMessage, iMaxLen, "{LIGHTBLUE}",		"\x0B", false);
		ReplaceString(sMessage, iMaxLen, "{BLUE}",			"\x0C", false);
	}
	else if(Engine_Version == GAME_CSS)
	{
		ReplaceString(sMessage, iMaxLen, "#",			"\x07", false);
		ReplaceString(sMessage, iMaxLen, "{DARKGREEN}",	"\x05", false);
	}
}

public bool:OnSelectItem(iClient, const String:sFeatureName[])
{
	DisplayChatMainMenu(iClient);

	return false;
}

DisplayChatMainMenu(iClient)
{
	SetGlobalTransTarget(iClient);

	decl String:sBuffer[128], Handle:hMenu;
	hMenu = CreateMenu(ChatMainMenu_Handler);
	SetMenuExitBackButton(hMenu, true);
	SetMenuTitle(hMenu, "%t:\n ", "MainMenuTitle");

	FormatEx(sBuffer, sizeof(sBuffer), "%t\n ", "DisableAll");
	AddMenuItem(hMenu, "", sBuffer);

	AddMenuFeatureItem(iClient, PREFIX, hMenu, "Prefix");
	AddMenuFeatureItem(iClient, PREFIX_COLOR, hMenu, "PrefixColor");
	AddMenuFeatureItem(iClient, NAME_COLOR, hMenu, "NameColor");
	AddMenuFeatureItem(iClient, TEXT_COLOR, hMenu, "TextColor");

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

AddMenuFeatureItem(iClient, index, &Handle:hMenu, const String:sFeatureName[])
{
	decl String:sBuffer[128];
	if(VIP_IsClientFeatureUse(iClient, g_sFeatures[index]))
	{
		decl String:sItemInfo[128];
		VIP_GetClientFeatureString(iClient, g_sFeatures[index], sBuffer, sizeof(sBuffer));
		GetClientCookie(iClient, g_hCookies[index], sItemInfo, sizeof(sItemInfo));
		
		if(sItemInfo[0] == '0')
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t [%t]", sFeatureName, "Disabled");
		}
		else
		{
			if(strcmp(sBuffer, g_sCUSTOM) == 0 || strcmp(sBuffer, g_sLIST) == 0)
			{
				if(sItemInfo[0])
				{
					GetTrieString(g_hColorsTrie, sItemInfo, sItemInfo, sizeof(sItemInfo));
					FormatEx(sBuffer, sizeof(sBuffer), "%t - %s", sFeatureName, sItemInfo);
				}
				else
				{
					FormatEx(sBuffer, sizeof(sBuffer), "%t [%t]", sFeatureName, "NotChosen");
				}
			}
			else
			{
				Format(sBuffer, sizeof(sBuffer), "%t - %s", sFeatureName, sBuffer);
			}
		}

		FormatEx(sItemInfo, sizeof(sItemInfo), "%i_%s", index, sFeatureName);
		AddMenuItem(hMenu, sItemInfo, sBuffer);
	}
	else
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t (%t)", sFeatureName, "NoAccess");
		AddMenuItem(hMenu, "", sBuffer, ITEMDRAW_DISABLED);
	}
}

public ChatMainMenu_Handler(Handle:hMenu, MenuAction:action, iClient, Item)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(hMenu);
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack) VIP_SendClientVIPMenu(iClient);
		}
		case MenuAction_Select:
		{
			decl String:sBuffer[128], index;
			if(Item == 0)
			{
				for(index = 0; index < 4; ++index)
				{
					if(VIP_IsClientFeatureUse(iClient, g_sFeatures[index]))
					{
						VIP_GetClientFeatureString(iClient, g_sFeatures[index], sBuffer, sizeof(sBuffer));
						if(strcmp(sBuffer, g_sCUSTOM) == 0 || strcmp(sBuffer, g_sLIST) == 0)
						{
							SetClientCookie(iClient, g_hCookies[index], "");
						}
						else
						{
							SetClientCookie(iClient, g_hCookies[index], "0");
						}
					}
				}

				DisplayChatMainMenu(iClient);

				return;
			}
			
			decl String:sItemInfo[128];
			GetMenuItem(hMenu, Item, sItemInfo, sizeof(sItemInfo));
			
			index = sItemInfo[0]-48;

			VIP_GetClientFeatureString(iClient, g_sFeatures[index], sBuffer, sizeof(sBuffer));
			new Handle:hTrie = VIP_GetVIPClientTrie(iClient);

			SetTrieString(hTrie, "Chat_MenuType", sItemInfo[2]);
			SetTrieValue(hTrie, "Chat_CookieIndex", index);
			
			if(strcmp(sBuffer, g_sCUSTOM) == 0)
			{
				GetClientCookie(iClient, g_hCookies[index], sItemInfo, sizeof(sItemInfo));
				if(sItemInfo[0] == '0')
				{
					sItemInfo[0] = 0;
				}

				DisplayWaitChatMenu(iClient, sItemInfo, false, index);
			}
			else if(strcmp(sBuffer, g_sLIST) == 0)
			{
				DisplayChatListMenu(iClient, sItemInfo[2], index);
			}
			else
			{
				RemoveFromTrie(hTrie, "Chat_MenuType");
				RemoveFromTrie(hTrie, "Chat_CookieIndex");

				GetClientCookie(iClient, g_hCookies[index], sItemInfo, sizeof(sItemInfo));
				
				decl bool:bEnable;
				if(sItemInfo[0])
				{
					bEnable = bool:StringToInt(sItemInfo);
				}
				else
				{
					bEnable = true;
				}

				bEnable = !bEnable;
				SetClientCookie(iClient, g_hCookies[index], bEnable ? "":"0");
				
				GetClientCookie(iClient, g_hCookies[index], sItemInfo, sizeof(sItemInfo));

				DisplayChatMainMenu(iClient);
			}
		}
	}
}

DisplayChatListMenu(iClient, const String:sKey[], index)
{
	SetGlobalTransTarget(iClient);

	decl String:sBuffer[128], Handle:hMenu, String:sClientColor[64];
	hMenu = CreateMenu(ChatListMenu_Handler);
	SetMenuExitBackButton(hMenu, true);

	SetMenuTitle(hMenu, "%t:\n ", sKey);
	GetClientCookie(iClient, g_hCookies[index], sClientColor, sizeof(sClientColor));

	if(sClientColor[0] && sClientColor[0] != '0')
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t\n ", "Disable");
		AddMenuItem(hMenu, "_disable", sBuffer);
	}

	KvRewind(g_hKeyValues);
	FormatEx(sBuffer, sizeof(sBuffer), "%s_List", sKey);
	if(KvJumpToKey(g_hKeyValues, sBuffer) && KvGotoFirstSubKey(g_hKeyValues, false))
	{
		sBuffer[0] = 0;
		decl String:sColor[64];
		do
		{
			KvGetString(g_hKeyValues, NULL_STRING, sColor, sizeof(sColor));
			KvGetSectionName(g_hKeyValues, sBuffer, sizeof(sBuffer));
			if(strcmp(sClientColor, sColor) == 0)
			{
				Format(sBuffer, sizeof(sBuffer), "%s (%t)", sBuffer, "Selected");
				AddMenuItem(hMenu, sColor, sBuffer, ITEMDRAW_DISABLED);
				continue;
			}

			AddMenuItem(hMenu, sColor, sBuffer);
		}
		while (KvGotoNextKey(g_hKeyValues, false));

		if(sBuffer[0] == 0)
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t", "NoItems");
			AddMenuItem(hMenu, "", sBuffer, ITEMDRAW_DISABLED);
		}
	}
	else
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "NoItems");
		AddMenuItem(hMenu, "", sBuffer, ITEMDRAW_DISABLED);
	}

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public ChatListMenu_Handler(Handle:hMenu, MenuAction:action, iClient, Item)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(hMenu);
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack) DisplayChatMainMenu(iClient);
		}
		case MenuAction_Select:
		{
			decl String:sColor[64], String:sColorName[128], Handle:hTrie, index;
			GetMenuItem(hMenu, Item, sColor, sizeof(sColor), _, sColorName, sizeof(sColorName));

			hTrie = VIP_GetVIPClientTrie(iClient);
			GetTrieValue(hTrie, "Chat_CookieIndex", index);
			
			if(strcmp(sColor, "_disable") == 0)
			{
				SetClientCookie(iClient, g_hCookies[index], "0");
				RemoveFromTrie(hTrie, "Chat_MenuType");
				RemoveFromTrie(hTrie, "Chat_CookieIndex");
				DisplayChatMainMenu(iClient);
				return;
			}
			
			decl String:sBuffer[64];

			SetClientCookie(iClient, g_hCookies[index], sColor);

			GetTrieString(hTrie, "Chat_MenuType", sBuffer, sizeof(sBuffer));

			if(index == PREFIX)
			{
				VIP_PrintToChatClient(iClient, "\x03%t %t: \x04%s", "Set", sBuffer, sColorName);
			}
			else
			{
				VIP_PrintToChatClient(iClient, "\x03%t -> %s%t", "Set", sColor, sBuffer);
			}

			DisplayChatListMenu(iClient, sBuffer, index);
		}
	}
}

DisplayWaitChatMenu(iClient, const String:sValue[] = "", const bool:bIsValid = false, const index)
{
	if(!bIsValid)
	{
		g_bWaitChat[iClient] = true;
	}

	new Handle:hMenu = CreateMenu(WaitChatMenu_Handler);

	SetGlobalTransTarget(iClient);

	if(sValue[0])
	{
		SetMenuTitle(hMenu, "%t \"%t\"\n%t: %s\n ", "EnterValueInChat", "Confirm", "Value", sValue);
	}
	else
	{
		SetMenuTitle(hMenu, "%t \"%t\"\n ", "EnterValueInChat", "Confirm");
	}
	
	decl String:sBuffer[128];

	FormatEx(sBuffer, sizeof(sBuffer), "%t", "Confirm");
	AddMenuItem(hMenu, sValue, sBuffer, bIsValid ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);

	FormatEx(sBuffer, sizeof(sBuffer), "%t\n ", "Cancel");
	AddMenuItem(hMenu, "", sBuffer);
	
	GetClientCookie(iClient, g_hCookies[index], sBuffer, sizeof(sBuffer));

	if(sBuffer[0] && sBuffer[0] != '0')
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t\n ", "Disable");
		AddMenuItem(hMenu, "_disable", sBuffer);
	}

	KvRewind(g_hKeyValues);
	if(KvJumpToKey(g_hKeyValues, "Help"))
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t\n ", "Help");
		AddMenuItem(hMenu, "_help", sBuffer);
	}
	else
	{
		AddMenuItem(hMenu, "", "", ITEMDRAW_NOTEXT);
	}

	AddMenuItem(hMenu, "", "", ITEMDRAW_NOTEXT);
	AddMenuItem(hMenu, "", "", ITEMDRAW_NOTEXT);

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public WaitChatMenu_Handler(Handle:hMenu, MenuAction:action, iClient, Item)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(hMenu);
		case MenuAction_Cancel:
		{
			g_bWaitChat[iClient] = false;
			if(Item == MenuCancel_ExitBack)
			{
				DisplayChatMainMenu(iClient);
			}
		}
		case MenuAction_Select:
		{
			decl Handle:hTrie, index;
			hTrie = VIP_GetVIPClientTrie(iClient);
			GetTrieValue(hTrie, "Chat_CookieIndex", index);

			if(Item == 0)
			{
				decl String:sBuffer[64], String:sColor[64];
				GetMenuItem(hMenu, Item, sColor, sizeof(sColor));

				SetClientCookie(iClient, g_hCookies[index], sColor);

				GetTrieString(hTrie, "Chat_MenuType", sBuffer, sizeof(sBuffer));

				if(index == PREFIX)
				{
					VIP_PrintToChatClient(iClient, "\x03%t %t: \x04%s", "Set", sBuffer, sColor);
				}
				else
				{
					VIP_PrintToChatClient(iClient, "\x03%t -> %s%t", "Set", sColor, sBuffer);
				}
			}
			else
			{
				decl String:sBuffer[64];
				GetMenuItem(hMenu, Item, sBuffer, sizeof(sBuffer));
				if(strcmp(sBuffer, "_disable") == 0)
				{
					SetClientCookie(iClient, g_hCookies[index], "0");
				}
				else if(strcmp(sBuffer, "_help") == 0)
				{
					DisplayHelpMenu(iClient);
					return;
				}
			}
			
			RemoveFromTrie(hTrie, "Chat_MenuType");
			RemoveFromTrie(hTrie, "Chat_CookieIndex");
			g_bWaitChat[iClient] = false;
			DisplayChatMainMenu(iClient);
		}
	}
}

public Action:Command_Say(iClient, const String:sCommand[], iArgs)
{
	if(iClient && iClient <= MaxClients && iArgs)
	{
		if(g_bWaitChat[iClient])
		{
			decl String:sText[64];
			GetCmdArgString(sText, sizeof(sText));
			TrimString(sText);
			StripQuotes(sText);
			
			if(sText[0])
			{
				decl index;
				GetTrieValue(VIP_GetVIPClientTrie(iClient), "Chat_CookieIndex", index);
				DisplayWaitChatMenu(iClient, sText, true, index);
			}

			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

DisplayHelpMenu(iClient)
{
	SetGlobalTransTarget(iClient);

	decl String:sBuffer[128], Handle:hPanel;
	
	hPanel = CreatePanel();
	FormatEx(sBuffer, sizeof(sBuffer), "%t:\n ", "Help");
	SetPanelTitle(hPanel, sBuffer);

	KvRewind(g_hKeyValues);
	if(KvJumpToKey(g_hKeyValues, "Help"))
	{
		if(KvGotoFirstSubKey(g_hKeyValues, false))
		{
			do
			{
				KvGetString(g_hKeyValues, NULL_STRING, sBuffer, sizeof(sBuffer));
				DrawPanelText(hPanel, sBuffer);
			} while (KvGotoNextKey(g_hKeyValues, false));
		}
	}

	DrawPanelItem(hPanel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);

	DrawPanelItem(hPanel, "<-");

	SendPanelToClient(hPanel, iClient, ChatInfoMenu_Handler, MENU_TIME_FOREVER); 
	CloseHandle(hPanel); 
}

public ChatInfoMenu_Handler(Handle:hMenu, MenuAction:action, iClient, Item)
{
	if(action == MenuAction_Select)
	{
		decl index, String:sBuffer[64];
		GetTrieValue(VIP_GetVIPClientTrie(iClient), "Chat_CookieIndex", index);
		GetClientCookie(iClient, g_hCookies[index], sBuffer, sizeof(sBuffer));
		if(sBuffer[0] == '0')
		{
			sBuffer[0] = 0;
		}

		DisplayWaitChatMenu(iClient, sBuffer, false, index);
	}
}