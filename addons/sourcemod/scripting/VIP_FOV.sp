#pragma semicolon 1

#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <vip_core>
#include <clientprefs>

public Plugin myinfo = 
{
	name = "[VIP] FOV",
	author = "R1KO",
	version = "1.0.4"
};

static const char g_szFeature[] = "FOV";

int g_iClientFOV[MAXPLAYERS+1];

Handle g_hCookie;

public void OnPluginStart() 
{
	HookEvent("player_spawn", Event_PlayerSpawn);

	g_hCookie = RegClientCookie("VIP_FOV", "VIP_FOV", CookieAccess_Private);

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
	
	RegConsoleCmd("sm_fov", FovMenu);
	
	LoadTranslations("vip_modules.phrases");
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_szFeature, STRING, SELECTABLE, OnSelectItem, OnDisplayItem);
}

public void OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_szFeature);
	}
}

public void OnClientPutInServer(int iClient)
{
	g_iClientFOV[iClient] = 0;
}

public Action FovMenu(int client, int args) 
{
	if(!args) DisplayFOVMenu(client);
	else
	{
		char sBuff[16];
		GetCmdArg(1, sBuff, sizeof(sBuff));
		TrimString(sBuff);
		
		int fov = StringToInt(sBuff);
	
		if(fov != g_iClientFOV[client])
		{
			int iMin, iMax, iStep;
			GetClientFeatureValues(client, iMin, iMax, iStep);
			
			if(!fov || fov >= iMin && fov <= iMax)
			{
				SetClientCookie(client, g_hCookie, sBuff);
				g_iClientFOV[client] = fov;
				SetClientFOV(client, !fov ? 90 : g_iClientFOV[client]);
				if(fov) VIP_PrintToChatClient(client, "Угол обзора был успешно изменен на %i!", fov);
				else VIP_PrintToChatClient(client, "Функция изменения угла обзора была успешно отключена!");
			}
			else VIP_PrintToChatClient(client, "Вы не можете установить значение меньше %i или больше %i!", iMin, iMax);
		}
	}
	
	return Plugin_Handled;
}

public bool OnDisplayItem(int iClient, const char[] szFeatureName, char[] szDisplay, int iMaxLength)
{
	if (g_iClientFOV[iClient])
	{
		FormatEx(szDisplay, iMaxLength, "%T [%d]", szFeatureName, iClient, g_iClientFOV[iClient]);
		return true;
	}

	return false;
}

public bool OnSelectItem(int iClient, const char[] szFeatureName)
{
	DisplayFOVMenu(iClient);
	return false;
}

void DisplayFOVMenu(int iClient)
{
	Menu hMenu = new Menu(Handler_FOVMenu);
	SetMenuExitBackButton(hMenu, true);
	SetMenuTitle(hMenu, "%T:\n ", g_szFeature, iClient);

	char szDisplay[32], szValue[4];
	int iMin, iMax, iStep;
	GetClientFeatureValues(iClient, iMin, iMax, iStep);

	FormatEx(szDisplay, sizeof(szDisplay), "%T%s\n ", "Disable", iClient, g_iClientFOV[iClient] == 0 ? " [X]":"");
	AddMenuItem(hMenu, NULL_STRING, szDisplay, g_iClientFOV[iClient] == 0 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);

	for (int i = iMin; i <= iMax; i += iStep)
	{
		FormatEx(szDisplay, sizeof(szDisplay), "%d%s", i, g_iClientFOV[iClient] == i ? " [X]":"");
		IntToString(i, szValue, sizeof(szValue));
		AddMenuItem(hMenu, szValue, szDisplay, g_iClientFOV[iClient] == i ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	}

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

void GetClientFeatureValues(int iClient, int &iMin, int &iMax, int &iStep)
{
	char szValue[16], szLimits[3][4];
	VIP_GetClientFeatureString(iClient, g_szFeature, szValue, sizeof(szValue));
	int iCountParts = ExplodeString(szValue, ":", szLimits, sizeof(szLimits), sizeof(szLimits[]));

	if (iCountParts == 3)
	{
		iMin = StringToInt(szLimits[0]);
		iStep = StringToInt(szLimits[1]);
		iMax = StringToInt(szLimits[2]);
		return;
	}
	if (iCountParts == 2)
	{
		iMin = StringToInt(szLimits[0]);
		iMax = StringToInt(szLimits[1]);
		iStep = 10;
		return;
	}
	
	iMin = iMax = StringToInt(szLimits[0]);
	iStep = 1;
}

public int Handler_FOVMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack) VIP_SendClientVIPMenu(iClient);
		}
		case MenuAction_Select:
		{
			char szValue[4];
			GetMenuItem(hMenu, iItem, szValue, sizeof(szValue));

			SetClientCookie(iClient, g_hCookie, szValue);
			g_iClientFOV[iClient] = iItem == 0 ? 0 : StringToInt(szValue);
			SetClientFOV(iClient, iItem == 0 ? 90 : g_iClientFOV[iClient]);

			DisplayFOVMenu(iClient);
		}
	}
	
	return 0;
}

public void VIP_OnVIPClientLoaded(int iClient)
{
	char szValue[4];
	GetClientCookie(iClient, g_hCookie, szValue, sizeof(szValue));
	if(szValue[0])
	{
		g_iClientFOV[iClient] = StringToInt(szValue);
	}
}

public void Event_PlayerSpawn(Event hEvent, const char[] weaponName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));

	if(iClient && IsPlayerAlive(iClient) && g_iClientFOV[iClient])
	{
		ApplyClientFOV(iClient);
	}
}

public void VIP_OnVIPClientRemoved(int client, const char[] sReason, int admin)
{
	if(!g_iClientFOV[client])
		SetClientFOV(client, 90);
}

void SetClientFOV(int iClient, int iFOV)
{
	SetEntProp(iClient, Prop_Send, "m_iFOV", iFOV);
	SetEntProp(iClient, Prop_Send, "m_iDefaultFOV", iFOV);
}

void ApplyClientFOV(int iClient)
{
	if (g_iClientFOV[iClient])
	{
		SetClientFOV(iClient, g_iClientFOV[iClient]);
	}
}