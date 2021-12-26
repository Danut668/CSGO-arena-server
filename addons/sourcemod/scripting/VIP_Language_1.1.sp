#pragma semicolon 1
#include <sourcemod>
#include <clientprefs>
#include <vip_core>

public Plugin:myinfo =
{
	name = "[VIP] Language",
	author = "R1KO",
	version = "1.1"
};

new g_iLangCode[MAXPLAYERS+1];

new Handle:g_hMenu,
	Handle:g_hCookie;

static const String:g_sFeature[] = "Language";

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, VIP_NULL, SELECTABLE, OnItemSelect, OnItemDisplay);
}

public OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}

public OnPluginStart()
{
	g_hCookie = RegClientCookie("Language", "Language", CookieAccess_Private);

	g_hMenu = CreateMenu(LangMenu_Handler, MenuAction_Select|MenuAction_Cancel|MenuAction_Display|MenuAction_DisplayItem|MenuAction_DrawItem);
	SetMenuExitBackButton(g_hMenu, true);

	LoadTranslations("vip_modules.phrases");
}

public OnMapStart()
{
	RemoveAllMenuItems(g_hMenu);

	decl String:sBuffer[256], Handle:hKeyValues;

	hKeyValues = CreateKeyValues("Language");
	BuildPath(Path_SM, sBuffer, 256, "data/vip/modules/Language.ini");

	if (FileToKeyValues(hKeyValues, sBuffer) == false)
	{
		CloseHandle(hKeyValues);
		SetFailState("Не удалось открыть файл \"%s\"", sBuffer);
	}

	KvRewind(hKeyValues);

	sBuffer[0] = 0;
	
	if(KvGotoFirstSubKey(hKeyValues, false))
	{
		decl String:sCode[16], iCode;
		do
		{
			KvGetSectionName(hKeyValues, sBuffer, 8);
			iCode = GetLanguageByCode(sBuffer);
			if(iCode == -1)
			{
				LogError("Не верный код языка: '%s'", sBuffer);
				continue;
			}
			
			IntToString(iCode, sCode, sizeof(sCode));

			KvGetString(hKeyValues, NULL_STRING, sBuffer, 64);
			AddMenuItem(g_hMenu, sCode, sBuffer);
		}
		while (KvGotoNextKey(hKeyValues, false));
	}

	if(sBuffer[0] == 0)
    {
		IntToString(GetLanguageByCode("en"), sBuffer, 4);
		AddMenuItem(g_hMenu, "", "English");  
    }
	
	CloseHandle(hKeyValues);
}

public bool:OnItemSelect(iClient, const String:sFeatureName[])
{
	DisplayMenu(g_hMenu, iClient, MENU_TIME_FOREVER);
	return false;
}

public bool:OnItemDisplay(iClient, const String:sFeatureName[], String:sDisplay[], iMaxLen)
{
	decl String:sLang[32];
	if(g_iLangCode[iClient] == -1)
	{
		g_iLangCode[iClient] = GetClientLanguage(iClient);
	}

	GetLanguageInfo(GetClientLanguage(iClient), _, _, sLang, sizeof(sLang));
	SetGlobalTransTarget(iClient);
	FormatEx(sDisplay, iMaxLen, "%t [%s]", g_sFeature, sLang);

	return true;
}

public LangMenu_Handler(Handle:hMenu, MenuAction:action, iClient, Item)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			decl String:sBuffer[64];
			SetGlobalTransTarget(iClient);
			FormatEx(sBuffer, sizeof(sBuffer), "%t", g_sFeature);
			SetPanelTitle(Handle:Item, sBuffer);
		}
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack) VIP_SendClientVIPMenu(iClient);
		}
		case MenuAction_Select:
		{
			decl String:sCode[16];
			GetMenuItem(hMenu, Item, sCode, sizeof(sCode));
			g_iLangCode[iClient] = StringToInt(sCode);
			SetClientCookie(iClient, g_hCookie, sCode);
			SetClientLanguage(iClient, g_iLangCode[iClient]);
			DisplayMenuAtItem(g_hMenu, iClient, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		}
		case MenuAction_DisplayItem:
		{
			decl String:sCode[16], String:sLang[32];
			GetMenuItem(hMenu, Item, sCode, sizeof(sCode), _, sLang, sizeof(sLang));
			if(g_iLangCode[iClient] == StringToInt(sCode))
			{
				Format(sLang, sizeof(sLang), "%s ☑", sLang);
				return RedrawMenuItem(sLang);
			}
		}
		case MenuAction_DrawItem:
		{
			decl String:sCode[16];
			GetMenuItem(hMenu, Item, sCode, sizeof(sCode));
			if(g_iLangCode[iClient] == StringToInt(sCode))
			{
				return ITEMDRAW_DISABLED;
			}
		}
	}
	
	return 0;
}

public OnClientCookiesCached(iClient)
{
	decl String:sCode[16];
	GetClientCookie(iClient, g_hCookie, sCode, sizeof(sCode));
	if(sCode[0])
	{
		g_iLangCode[iClient] = GetLanguageByCode(sCode);
		if(g_iLangCode[iClient] != -1)
		{
			SetClientLanguage(iClient, g_iLangCode[iClient]);
			return;
		}
	}

	g_iLangCode[iClient] = -1;
}

