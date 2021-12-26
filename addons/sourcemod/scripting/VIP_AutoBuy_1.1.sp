#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <vip_core>
#include <clientprefs>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[VIP] AutoBuy",
	author = "R1KO",
	version = "1.1"
};

#define SZF(%0)		%0, sizeof(%0)

static const char g_szFeature[][] = {"AutoBuy", "AutoBuyMenu"};

bool g_bClientDeath[MAXPLAYERS+1];
KeyValues g_hKeyValues;
StringMap g_hTrieCookies;
ArrayList g_hArrayCookies;
KeyValues g_hKeyValuesWeaponNames;

float g_fDelay;
bool g_bBuyMode;

static const g_iGrenadeOffsets[] = {14, 15, 16, 17, 17, 18, 22};

public void OnPluginStart()
{
	g_hArrayCookies = new ArrayList(ByteCountToCells(64));
	g_hTrieCookies = new StringMap();
	g_hKeyValuesWeaponNames = new KeyValues("WeaponNames");
	
	LoadConfig();

	HookEvent("player_spawn",	Event_PlayerSpawn);

	HookEvent("player_death",	Event_PlayerDeath);
	HookEvent("player_team",	Event_PlayerDeath);
	HookEvent("round_end",		Event_RoundEnd, EventHookMode_PostNoCopy);

	HookEventEx("announce_phase_end",	Event_Restart, EventHookMode_PostNoCopy);
	HookEventEx("cs_match_end_restart",	Event_Restart, EventHookMode_PostNoCopy);

	LoadTranslations("vip_auto_buy.phrases.txt");

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public void OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_szFeature[0]);
		VIP_UnregisterFeature(g_szFeature[1]);
	}
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_szFeature[0], BOOL);
	VIP_RegisterFeature(g_szFeature[1], _, SELECTABLE, OnItemSelect, _, OnItemDraw);
}

public bool OnItemSelect(int iClient, const char[] sFeatureName)
{
	DisplayTeamsMenu(iClient);

	return false;
}

public int OnItemDraw(int iClient, const char[] sFeatureName, int iStyle)
{
	switch(VIP_GetClientFeatureStatus(iClient, g_szFeature[0]))
	{
		case ENABLED: return ITEMDRAW_DEFAULT;
		case DISABLED: return ITEMDRAW_DISABLED;
		case NO_ACCESS: return ITEMDRAW_RAWLINE;
	}

	return iStyle;
}

public void Event_Restart(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	OnRestart();
}

public void Event_RoundEnd(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	char szBuffer[64];
	GetEventString(hEvent, "message", szBuffer, sizeof(szBuffer));
	if(strcmp(szBuffer, "#Game_Commencing") == 0)
	{
		OnRestart();
	}
}

void OnRestart()
{
	for(int i = 1; i <= MaxClients; ++i)
	{
		g_bClientDeath[i] = true;
	}
}

int GetTeamFromString(const char[] szBuffer)
{
	switch(szBuffer[0])
	{
		case 'C', 'c':	return 2;
		case 'T', 't':	return 1;
		default:		return 0;
	}

	return 0;
}

void LoadConfig()
{
	char szBuffer[256];
	Handle hCookie;
	g_hKeyValues = new KeyValues("AutoBuy");

	BuildPath(Path_SM, SZF(szBuffer), "data/vip/modules/auto_buy.ini");
	if (!FileToKeyValues(g_hKeyValues, szBuffer))
	{
		CloseHandle(g_hKeyValues);
		SetFailState("Couldn't parse file '%s'", szBuffer);
		return;
	}

	KvRewind(g_hKeyValues);
	
	g_fDelay = KvGetFloat(g_hKeyValues, "delay", 0.0);
	g_bBuyMode = !!KvGetNum(g_hKeyValues, "buy_mode", 0);

	KvRewind(g_hKeyValues);
	
	if(KvGotoFirstSubKey(g_hKeyValues))
	{
		char sWeapon[64];
		int iStartIndex, iTeam;
		bool bRegCookie;
		do
		{
			bRegCookie = !!KvGetNum(g_hKeyValues, "toggle");
			
			if(!bRegCookie)
			{
				KvGetSectionName(g_hKeyValues, sWeapon, 64);
				RegCookie(hCookie, szBuffer, sizeof(szBuffer), sWeapon, 0);
				RegCookie(hCookie, szBuffer, sizeof(szBuffer), sWeapon, 1);
			}

			if(KvGotoFirstSubKey(g_hKeyValues))
			{
				do
				{
					if(KvGotoFirstSubKey(g_hKeyValues))
					{
						do
						{
							KvGetString(g_hKeyValues, "team", szBuffer, 4);
							iTeam = GetTeamFromString(szBuffer);
							KvSetNum(g_hKeyValues, "team_num", iTeam);

							if(!bRegCookie)
							{
								KvGetSectionName(g_hKeyValues, sWeapon, sizeof(sWeapon));
								KvRewind(g_hKeyValuesWeaponNames);
								KvJumpToKey(g_hKeyValuesWeaponNames, sWeapon, true);
								KvCopySubkeys(g_hKeyValues, g_hKeyValuesWeaponNames);
							}
						} while(KvGotoNextKey(g_hKeyValues));

						KvGoBack(g_hKeyValues);
						continue;
					}

					KvGetString(g_hKeyValues, "team", szBuffer, 4);
					iTeam = GetTeamFromString(szBuffer);
					KvSetNum(g_hKeyValues, "team_num", iTeam);

					KvGetSectionName(g_hKeyValues, sWeapon, sizeof(sWeapon));
					KvRewind(g_hKeyValuesWeaponNames);
					KvJumpToKey(g_hKeyValuesWeaponNames, sWeapon, true);
					KvCopySubkeys(g_hKeyValues, g_hKeyValuesWeaponNames);

					if(bRegCookie)
					{
						iStartIndex = FindCharInString(sWeapon, '_')+1;
						if(iTeam == 0)
						{
							RegCookie(hCookie, szBuffer, sizeof(szBuffer), sWeapon[iStartIndex], 0);
							RegCookie(hCookie, szBuffer, sizeof(szBuffer), sWeapon[iStartIndex], 1);
						}
						else
						{
							RegCookie(hCookie, szBuffer, sizeof(szBuffer), sWeapon[iStartIndex], iTeam-1);
						}
						
						KvSetNum(g_hKeyValuesWeaponNames, "give", 1);
					}
			
				} while(KvGotoNextKey(g_hKeyValues));

				KvGoBack(g_hKeyValues);
			}
		} while(KvGotoNextKey(g_hKeyValues));
	}
}

void RegCookie(Handle &hCookie, char[] szBuffer, int iMaxLen, const char[] sKey, int iTeam)
{
	FormatEx(szBuffer, iMaxLen, "VIP_AutoBuy_%s_%i", sKey, iTeam);
	//	LogMessage("RegCookie: %s", szBuffer);
	hCookie = RegClientCookie(szBuffer, szBuffer, CookieAccess_Protected);
	FormatEx(szBuffer, iMaxLen, "cookie_%s_%i", sKey, iTeam);
	//	LogMessage("SaveCookie: %s", szBuffer);
	SetTrieValue(g_hTrieCookies, szBuffer, hCookie);
	PushArrayString(g_hArrayCookies, szBuffer);
}

void DisplayTeamsMenu(int iClient)
{
	SetGlobalTransTarget(iClient);

	char szBuffer[128];
	Menu hMenu = new Menu(TeamMenu_Handler);
	SetMenuExitBackButton(hMenu, true);
	SetMenuTitle(hMenu, "%t:\n ", "MenuTitle_Settings");

	FormatEx(szBuffer, sizeof(szBuffer), "%t", "Menu_T");
	AddMenuItem(hMenu, "", szBuffer);

	FormatEx(szBuffer, sizeof(szBuffer), "%t", "Menu_CT");
	AddMenuItem(hMenu, "", szBuffer);

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int TeamMenu_Handler(Menu hMenu, MenuAction action, int iClient, int Item)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack) VIP_SendClientVIPMenu(iClient);
		}
		case MenuAction_Select:
		{
			SetTrieValue(VIP_GetVIPClientTrie(iClient), "AutoBuy_team", Item);
			
			DisplayWeaponTypeMenu(iClient);
		}
	}
	return 0;
}

void DisplayWeaponTypeMenu(int iClient)
{
	SetGlobalTransTarget(iClient);

	char szBuffer[128];
	StringMap hTrie = VIP_GetVIPClientTrie(iClient);
	int iTeam;
	GetTrieValue(hTrie, "AutoBuy_team", iTeam);
	Menu hMenu = new Menu(WeaponTypeMenu_Handler);
	SetMenuExitBackButton(hMenu, true);
	SetMenuTitle(hMenu, "%t:\n ", "MenuTitle_Settings");

	char szClientLang[3], szServerLang[3];
	GetLanguageInfo(GetClientLanguage(iClient), szClientLang, sizeof(szClientLang));
	GetLanguageInfo(GetServerLanguage(), szServerLang, sizeof(szServerLang));

	KvRewind(g_hKeyValues);

	if(KvGotoFirstSubKey(g_hKeyValues))
	{
	//	PrintToChat(iClient, "KvGotoFirstSubKey");
		char sItemInfo[64], sDisplay[128];
		Handle hCookie;
		do
		{
			KvGetSectionName(g_hKeyValues, sItemInfo, sizeof(sItemInfo));
		//	PrintToChat(iClient, "sItemInfo: %s", sItemInfo);
		//	PrintToChat(iClient, "g_sClLang: %s", szClientLang);
			KvGetString(g_hKeyValues, szClientLang, sDisplay, sizeof(sDisplay));
			if (!sDisplay[0])
			{
			//	PrintToChat(iClient, "szServerLang: %s", szServerLang);
				KvGetString(g_hKeyValues, szServerLang, sDisplay, sizeof(sDisplay));
				if (!sDisplay[0])
				{
					strcopy(sDisplay, sizeof(sDisplay), sItemInfo);
				}
			}

			if(!KvGetNum(g_hKeyValues, "toggle", 0))
			{
				FormatEx(szBuffer, sizeof(szBuffer), "cookie_%s_%i", sItemInfo, iTeam);

				if(GetTrieValue(g_hTrieCookies, szBuffer, hCookie))
				{
					GetClientCookie(iClient, hCookie, szBuffer, sizeof(szBuffer));
					if(!szBuffer[0] || szBuffer[0] == '0')
					{
						FormatEx(szBuffer, sizeof(szBuffer), "%t", "Menu_Disabled");
					}
					else
					{
						KvRewind(g_hKeyValuesWeaponNames);
						if(KvJumpToKey(g_hKeyValuesWeaponNames, szBuffer))
						{
							KvGetString(g_hKeyValuesWeaponNames, szClientLang, szBuffer, sizeof(szBuffer));
							if (!szBuffer[0])
							{
							//	PrintToChat(iClient, "szServerLang: %s", szServerLang);
								KvGetString(g_hKeyValuesWeaponNames, szServerLang, szBuffer, sizeof(szBuffer));
								if (!szBuffer[0])
								{
									strcopy(szBuffer, sizeof(szBuffer), sItemInfo);
								}
							}
						}
					}
				}

				Format(sDisplay, sizeof(sDisplay), "%s [%s]", sDisplay, szBuffer);
			}

			AddMenuItem(hMenu, sItemInfo, sDisplay);
		} while(KvGotoNextKey(g_hKeyValues));
	}

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int WeaponTypeMenu_Handler(Menu hMenu, MenuAction action, int iClient, int Item)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(hMenu);
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack) DisplayTeamsMenu(iClient);
		}
		case MenuAction_Select:
		{
			char sItemInfo[64];
			GetMenuItem(hMenu, Item, sItemInfo, sizeof(sItemInfo));
		//	PrintToChat(iClient, "sItemInfo: %s", sItemInfo);
			StringMap hTrie = VIP_GetVIPClientTrie(iClient);
			SetTrieString(hTrie, "AutoBuy_type", sItemInfo);

			KvRewind(g_hKeyValues);
	
			if(KvJumpToKey(g_hKeyValues, sItemInfo) && KvGetNum(g_hKeyValues, "have_subkeys"))
			{
				DisplayCategoriesMenu(iClient);
				return 0;
			}

			DisplayWeaponsMenu(iClient);
		}
	}

	return 0;
}

void DisplayCategoriesMenu(int iClient)
{
	SetGlobalTransTarget(iClient);

	char szBuffer[128];
	Menu hMenu = new Menu(CategoriesMenu_Handler);
	SetMenuExitBackButton(hMenu, true);
	SetMenuTitle(hMenu, "%t:\n ", "MenuTitle_Categories");

	char szClientLang[3], szServerLang[3];
	GetLanguageInfo(GetClientLanguage(iClient), szClientLang, sizeof(szClientLang));
	GetLanguageInfo(GetServerLanguage(), szServerLang, sizeof(szServerLang));

	StringMap hTrie = VIP_GetVIPClientTrie(iClient);
	GetTrieString(hTrie, "AutoBuy_type", szBuffer, sizeof(szBuffer));
	
	KvRewind(g_hKeyValues);

	if(KvJumpToKey(g_hKeyValues, szBuffer) && KvGotoFirstSubKey(g_hKeyValues))
	{
		char sDisplay[128]; int iTeam; Handle hCookie;
		GetTrieValue(hTrie, "AutoBuy_team", iTeam);

		FormatEx(sDisplay, sizeof(sDisplay), "cookie_%s_%i", szBuffer, iTeam);

		if(GetTrieValue(g_hTrieCookies, sDisplay, hCookie))
		{
			GetClientCookie(iClient, hCookie, szBuffer, sizeof(szBuffer));

			if(szBuffer[0] || szBuffer[0] == '0')
			{
				FormatEx(szBuffer, sizeof(szBuffer), "%t\n ", "Menu_Disable");
				AddMenuItem(hMenu, "_disable", szBuffer);
			}
		}

		do
		{
			KvGetSectionName(g_hKeyValues, szBuffer, sizeof(szBuffer));
			KvGetString(g_hKeyValues, szClientLang, sDisplay, sizeof(sDisplay));
			if (!sDisplay[0])
			{
				KvGetString(g_hKeyValues, szServerLang, sDisplay, sizeof(sDisplay));
				if (!sDisplay[0])
				{
					strcopy(sDisplay, sizeof(sDisplay), szBuffer);
				}
			}

			AddMenuItem(hMenu, szBuffer, sDisplay);
		} while(KvGotoNextKey(g_hKeyValues));
	}

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int CategoriesMenu_Handler(Menu hMenu, MenuAction action, int iClient, int Item)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(hMenu);
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack) DisplayTeamsMenu(iClient);
		}
		case MenuAction_Select:
		{
			char szBuffer[64];
			
			StringMap hTrie = VIP_GetVIPClientTrie(iClient);
			GetMenuItem(hMenu, Item, szBuffer, sizeof(szBuffer));

			if(strcmp(szBuffer, "_disable") == 0)
			{
				Handle hCookie;
				int iTeam;
				GetTrieValue(hTrie, "AutoBuy_team", iTeam);
				FormatEx(szBuffer, sizeof(szBuffer), "cookie_primary_%i", iTeam);
				if(GetTrieValue(g_hTrieCookies, szBuffer, hCookie))
				{
					SetClientCookie(iClient, hCookie, "0");
					FormatEx(szBuffer, sizeof(szBuffer), "AutoBuy_primary_%i", iTeam);
					RemoveFromTrie(hTrie, szBuffer);
				}
	
				DisplayWeaponTypeMenu(iClient);
				return;
			}

			SetTrieString(hTrie, "AutoBuy_category", szBuffer);

			DisplayWeaponsMenu(iClient);
		}
	}
}

void DisplayWeaponsMenu(int iClient)
{
	SetGlobalTransTarget(iClient);

	char szBuffer[128], sDisplay[64];
	StringMap hTrie = VIP_GetVIPClientTrie(iClient);
	Handle hCookie;
	bool bToggle;
	Menu hMenu = new Menu(WeaponsMenu_Handler);
	SetMenuExitBackButton(hMenu, true);
	SetMenuTitle(hMenu, "%t:\n ", "MenuTitle_Settings");
	
	char szClientLang[3], szServerLang[3];
	GetLanguageInfo(GetClientLanguage(iClient), szClientLang, sizeof(szClientLang));
	GetLanguageInfo(GetServerLanguage(), szServerLang, sizeof(szServerLang));

	int iTeam;
	GetTrieValue(hTrie, "AutoBuy_team", iTeam);
	
	GetTrieString(hTrie, "AutoBuy_type", sDisplay, sizeof(sDisplay));

	KvRewind(g_hKeyValues);
	KvJumpToKey(g_hKeyValues, sDisplay);
	
	bToggle = !!KvGetNum(g_hKeyValues, "toggle", 0);
	if(bToggle)
	{
		FormatEx(szBuffer, sizeof(szBuffer), "%t\n ", "Menu_DisableAll");
		AddMenuItem(hMenu, "_disable_all", szBuffer);
	}
	else
	{
		if(GetTrieString(hTrie, "AutoBuy_category", szBuffer, sizeof(szBuffer)))
		{
			KvJumpToKey(g_hKeyValues, szBuffer);
		}

		FormatEx(szBuffer, sizeof(szBuffer), "cookie_%s_%i", sDisplay, iTeam);

		if(GetTrieValue(g_hTrieCookies, szBuffer, hCookie))
		{
			GetClientCookie(iClient, hCookie, szBuffer, sizeof(szBuffer));

			if(szBuffer[0] || szBuffer[0] == '0')
			{
				FormatEx(sDisplay, sizeof(sDisplay), "%t\n ", "Menu_Disable");
				AddMenuItem(hMenu, "_disable", sDisplay);
			}
		}
		else
		{
			szBuffer[0] = 0;
		}
	}

//	szBuffer[0] = 0;

	if(KvGotoFirstSubKey(g_hKeyValues))
	{
		iTeam++;
		char sWeapon[64];
		int iWeaponTeam;
		do
		{
			iWeaponTeam = KvGetNum(g_hKeyValues, "team_num");
			if(!iWeaponTeam || iTeam == iWeaponTeam)
			{
				KvGetSectionName(g_hKeyValues, sWeapon, sizeof(sWeapon));
				KvGetString(g_hKeyValues, szClientLang, sDisplay, sizeof(sDisplay));
				if (!sDisplay[0])
				{
					KvGetString(g_hKeyValues, szServerLang, sDisplay, sizeof(sDisplay));
					if (!sDisplay[0])
					{
						strcopy(sDisplay, sizeof(sDisplay), sWeapon);
					}
				}

				int iStartIndex = FindCharInString(sWeapon, '_')+1;
				if(bToggle)
				{
					FormatEx(szBuffer, sizeof(szBuffer), "cookie_%s_%i", sWeapon[iStartIndex], iTeam-1);
				//	PrintToChat(iClient, "Cookie: %s", szBuffer);
					if(GetTrieValue(g_hTrieCookies, szBuffer, hCookie))
					{
						GetClientCookie(iClient, hCookie, szBuffer, sizeof(szBuffer));
					//	PrintToChat(iClient, "GetClientCookie: '%s'", szBuffer);

						if(szBuffer[0])
						{
							iWeaponTeam = StringToInt(szBuffer);
						}
						else
						{
							iWeaponTeam = 0;
						}
					//	PrintToChat(iClient, "iWeaponTeam: '%i'", iWeaponTeam);
						
						if(!iWeaponTeam)
						{
							FormatEx(szBuffer, sizeof(szBuffer), " [%t]", "Menu_Disabled");
						}
						else
						{
							if(KvGetNum(g_hKeyValues, "count", 0) == 0)
							{
								FormatEx(szBuffer, sizeof(szBuffer), " [%t]", "Menu_Enabled");
							}
							else
							{
								FormatEx(szBuffer, sizeof(szBuffer), " [x%i]", iWeaponTeam);
							}
						}
						StrCat(sDisplay, sizeof(sDisplay), szBuffer);
					}
				}
				else
				{
				//	PrintToChat(iClient, "sWeapon: %s, szBuffer: %s", sWeapon, szBuffer);
					if(strcmp(sWeapon[iStartIndex], szBuffer[iStartIndex]) == 0)
					{
						StrCat(sDisplay, sizeof(sDisplay), " [X]");
						AddMenuItem(hMenu, sWeapon, sDisplay, ITEMDRAW_DISABLED);
						continue;
					}
				}

				AddMenuItem(hMenu, sWeapon, sDisplay);
			}
		} while(KvGotoNextKey(g_hKeyValues));
	}
	
	if(GetMenuItemCount(hMenu) < 2)
	{
		FormatEx(szBuffer, sizeof(szBuffer), "%t", "Menu_NoWeapons");
		AddMenuItem(hMenu, "", szBuffer, ITEMDRAW_DISABLED);
	}

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int WeaponsMenu_Handler(Menu hMenu, MenuAction action, int iClient, int Item)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(hMenu);
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack) DisplayWeaponTypeMenu(iClient);
		}
		case MenuAction_Select:
		{
			char sWeapon[64], szBuffer[64];
			Handle hCookie;
			int iTeam;
			bool bToggle;

			StringMap hTrie = VIP_GetVIPClientTrie(iClient);
			GetTrieValue(hTrie, "AutoBuy_team", iTeam);
			GetTrieString(hTrie, "AutoBuy_type", szBuffer, sizeof(szBuffer));

			KvRewind(g_hKeyValues);
			KvJumpToKey(g_hKeyValues, szBuffer);
			
			bToggle = !!KvGetNum(g_hKeyValues, "toggle", 0);
			if(bToggle)
			{
				int iStartIndex;
				if(Item == 0)
				{
					for(int i = 1, Items = GetMenuItemCount(hMenu); i <= Items; ++i)
					{
						GetMenuItem(hMenu, i, sWeapon, sizeof(sWeapon));
						iStartIndex = FindCharInString(sWeapon, '_')+1;
						FormatEx(szBuffer, sizeof(szBuffer), "cookie_%s_%i", sWeapon[iStartIndex], iTeam);
						if(GetTrieValue(g_hTrieCookies, szBuffer, hCookie))
						{
							SetClientCookie(iClient, hCookie, "0");
							FormatEx(szBuffer, sizeof(szBuffer), "AutoBuy_%s_%i", sWeapon[iStartIndex], iTeam);
							RemoveFromTrie(hTrie, szBuffer);
						}
					}
				}
				else
				{
					GetMenuItem(hMenu, Item, sWeapon, sizeof(sWeapon));
					iStartIndex = FindCharInString(sWeapon, '_')+1;
					FormatEx(szBuffer, sizeof(szBuffer), "cookie_%s_%i", sWeapon[iStartIndex], iTeam);
					if(GetTrieValue(g_hTrieCookies, szBuffer, hCookie))
					{
						GetClientCookie(iClient, hCookie, szBuffer, sizeof(szBuffer));

						KvJumpToKey(g_hKeyValues, sWeapon);
						int iClientCount;
						if(szBuffer[0])
						{
							iClientCount = StringToInt(szBuffer);

							if(++iClientCount > KvGetNum(g_hKeyValues, "count", 1))
							{
								iClientCount = 0;
							}
						}
						else
						{
							iClientCount = 1;
						}
						
						char sCount[4];
						IntToString(iClientCount, sCount, sizeof(sCount));
						
						SetClientCookie(iClient, hCookie, sCount);
						FormatEx(szBuffer, sizeof(szBuffer), "AutoBuy_%s_%i", sWeapon[iStartIndex], iTeam);
						//	LogMessage("SetTrieString: '%s'", szBuffer);
					//	PrintToChat(iClient, "szBuffer: %s, %i, %s", szBuffer, iClientCount, sCount);
						if(iClientCount)
						{
							SetTrieString(hTrie, szBuffer, sCount);
						}
						else
						{
							RemoveFromTrie(hTrie, szBuffer);
						}
					}
				}

				DisplayWeaponsMenu(iClient);
			}
			else
			{
				FormatEx(sWeapon, sizeof(sWeapon), "cookie_%s_%i", szBuffer, iTeam);

				if(GetTrieValue(g_hTrieCookies, sWeapon, hCookie))
				{
					Format(szBuffer, sizeof(szBuffer), "AutoBuy_%s_%i", szBuffer, iTeam);
					GetMenuItem(hMenu, Item, sWeapon, sizeof(sWeapon));
					if(strcmp(sWeapon, "_disable") == 0)
					{
						SetClientCookie(iClient, hCookie, "0");
						RemoveFromTrie(hTrie, szBuffer);
					}
					else
					{
						SetTrieString(hTrie, szBuffer, sWeapon);
						SetClientCookie(iClient, hCookie, sWeapon);
					}
				}

				DisplayWeaponTypeMenu(iClient);
			}
		}
	}
}

public void OnClientPutInServer(int iClient)
{
	g_bClientDeath[iClient] = true;
}

public void VIP_OnVIPClientLoaded(int iClient)
{
	if(VIP_GetClientFeatureStatus(iClient, g_szFeature[0]) != NO_ACCESS)
	{
		if(AreClientCookiesCached(iClient))
		{
			LoadWeapons(iClient);
		}
		else
		{
			CreateTimer(1.0, Timer_CheckCookies, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action Timer_CheckCookies(Handle hTimer, any UserID)
{
	int iClient = GetClientOfUserId(UserID);
	if(iClient && VIP_IsClientVIP(iClient) && VIP_GetClientFeatureStatus(iClient, g_szFeature[0]) != NO_ACCESS)
	{
		if(AreClientCookiesCached(iClient))
		{
			LoadWeapons(iClient);

			return Plugin_Stop;
		}
		
		CreateTimer(1.0, Timer_CheckCookies, UserID, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Stop;
}

void LoadWeapons(int iClient)
{
	int iSize = GetArraySize(g_hArrayCookies);
	if(iSize)
	{
		char szBuffer[64], sCookie[64], sTrieKey[64];
		Handle hCookie;
		StringMap hTrie = VIP_GetVIPClientTrie(iClient);

		//	LogMessage("LoadWeapons: %i", iClient);
		for(int i = 0; i < iSize; ++i)
		{
			GetArrayString(g_hArrayCookies, i, sCookie, sizeof(sCookie));
			//	LogMessage("sCookie: %s", sCookie);
			if(GetTrieValue(g_hTrieCookies, sCookie, hCookie))
			{
				GetClientCookie(iClient, hCookie, szBuffer, sizeof(szBuffer));
				//	LogMessage("GetClientCookie: '%s'", szBuffer);
				if(szBuffer[0] && szBuffer[0] != '0')
				{
					FormatEx(sTrieKey, sizeof(sTrieKey), "AutoBuy_%s", sCookie[7]);
					//	LogMessage("SetTrieString: sTrieKey: %s, '%s'", sTrieKey, szBuffer);
					SetTrieString(hTrie, sTrieKey, szBuffer);
				}
			}
		}
	}
}

public void Event_PlayerSpawn(Event hEvent, const char[] sEvName, bool dBontBroadcast)
{
	CreateTimer(g_fDelay, Timer_GiveWeapons, GetEventInt(hEvent, "userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_GiveWeapons(Handle hTimer, any iUserID)
{
	int iClient = GetClientOfUserId(iUserID);
	
	if (!iClient || !IsClientInGame(iClient) || !VIP_IsClientVIP(iClient) || !VIP_IsClientFeatureUse(iClient, g_szFeature[0]))
	{
		return Plugin_Stop;
	}
	
	char sWeapon[64], szBuffer[64];
	int i, iCount, iTeam;
	StringMap hTrie = VIP_GetVIPClientTrie(iClient);
	iTeam = GetClientTeam(iClient);
	
	FormatEx(szBuffer, sizeof(szBuffer), "AutoBuy_primary_%i", iTeam-2);
	GivePlayerWeapon(iClient, hTrie, 0, false, szBuffer, sWeapon, sizeof(sWeapon));
	FormatEx(szBuffer, sizeof(szBuffer), "AutoBuy_secondary_%i", iTeam-2);
	GivePlayerWeapon(iClient, hTrie, 1, g_bClientDeath[iClient], szBuffer, sWeapon, sizeof(sWeapon));
	
	g_bClientDeath[iClient] = false;

	KvRewind(g_hKeyValuesWeaponNames);
	if(KvGotoFirstSubKey(g_hKeyValuesWeaponNames))
	{
		char sCount[4];
		do
		{
			KvGetSectionName(g_hKeyValuesWeaponNames, sWeapon, sizeof(sWeapon));
			//	LogMessage("Key: '%s', give: %b", sWeapon, KvGetNum(g_hKeyValuesWeaponNames, "give"));
			if(KvGetNum(g_hKeyValuesWeaponNames, "give"))
			{
				KvGetSectionName(g_hKeyValuesWeaponNames, sWeapon, sizeof(sWeapon));
				i = FindCharInString(sWeapon, '_')+1;
				FormatEx(szBuffer, sizeof(szBuffer), "AutoBuy_%s_%i", sWeapon[i], iTeam-2);
				//	LogMessage("GetTrieString: '%s'", szBuffer);
				if(GetTrieString(hTrie, szBuffer, sCount, sizeof(sCount)))
				{
					iCount = StringToInt(sCount);
					//	LogMessage("sCount: '%s', iCount: '%i'", sCount, iCount);
					if(iCount)
					{
						KvGetString(g_hKeyValuesWeaponNames, "prop", szBuffer, sizeof(szBuffer));
						//	LogMessage("prop: '%s'", szBuffer);
						if(szBuffer[0])
						{
							if(GetEntProp(iClient, Prop_Send, szBuffer) == 0)
							{
								GivePlayerItem(iClient, sWeapon);
							//	SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
							}
							continue;
						}
						
						i = KvGetNum(g_hKeyValuesWeaponNames, "slot");
						// LogMessage("slot: '%i'", i);
						if(i)
						{
							RemoveWeaponBySlot(iClient, i);
							GivePlayerItem(iClient, sWeapon);
							continue;
						}

						i = KvGetNum(g_hKeyValuesWeaponNames, "offset");
						// LogMessage("offset: '%i'", i);
						if(i)
						{
							SetEntProp(iClient, Prop_Send, "m_iAmmo", 0, _, i);
							GivePlayerItem(iClient, sWeapon);
							if(iCount > 1)
							{
								SetEntProp(iClient, Prop_Send, "m_iAmmo", iCount, _, i);
							}
							continue;
						}
						
						while(iCount--)
						{
							GivePlayerItem(iClient, sWeapon);
						}
					}
				}
			}
		} while (KvGotoNextKey(g_hKeyValuesWeaponNames));
	}
	
	return Plugin_Stop;
}


public void Event_PlayerDeath(Event hEvent, const char[] sEvName, bool dBontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	g_bClientDeath[iClient] = true;
}

void GivePlayerWeapon(int iClient, StringMap hTrie, int iSlot, bool bReplace, const char[] sKey, char[] sWeapon,int  iWeaponMaxLen)
{
	if(GetTrieString(hTrie, sKey, sWeapon, iWeaponMaxLen) && sWeapon[0] && sWeapon[0] != '0')
	{
		int iEntity = GetPlayerWeaponSlot(iClient, iSlot);
		if(iEntity != -1 && IsValidEdict(iEntity))
		{
			if(!bReplace || (iSlot == 1 && !IsDefaultWeapon(iClient, iEntity)))
			{
				return;
			}
			RemovePlayerItem(iClient, iEntity);
			AcceptEntityInput(iEntity, "Kill");
		}

		GivePlayerItem(iClient, sWeapon);
	}
}

bool RemoveWeaponBySlot(int iClient, int iSlot)
{
	int iEntity = GetPlayerWeaponSlot(iClient, iSlot);
	if(IsValidEdict(iEntity))
	{
		RemovePlayerItem(iClient, iEntity);
		AcceptEntityInput(iEntity, "Kill");
		return true;
	}

	return false;
}

bool IsDefaultWeapon(int iClient, int iEntity)
{
	char szWeapon[32], szDefWeapon[32];
	GetEdictClassname(iEntity, SZF(szWeapon));
	if (GetClientTeam(iClient) == 2)
	{
		if (!GetConVarValue("mp_t_default_secondary", SZF(szDefWeapon)))
		{
			strcopy(SZF(szDefWeapon), "weapon_glock");
		}
		return !strcmp(szWeapon, szDefWeapon);
	}

	if (!GetConVarValue("mp_ct_default_secondary", SZF(szDefWeapon)))
	{
		strcopy(SZF(szDefWeapon), "weapon_hkp2000");
	}
	return !strcmp(szWeapon, szDefWeapon);
}

bool GetConVarValue(const char[] szName, char[] szBuffer, int iMaxLen)
{
	Handle hCvar = FindConVar(szName);
	if (hCvar)
	{
		GetConVarString(hCvar, szBuffer, iMaxLen);
		return szBuffer[0] > 0;
	}
	
	return false;
}