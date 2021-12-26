#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <vip_core>
#include <clientprefs>

public Plugin:myinfo = 
{
	name = "[VIP] Tracers",
	author = "R1KO",
	version = "1.1"
};

static const String:g_sFeature[][] = {"Tracers", "Tracers_MENU"};

new g_iClientColor[MAXPLAYERS+1][4],
	g_iClientItem[MAXPLAYERS+1];

new g_iBeamSprite,
	Float:g_fLife,
	Float:g_fStartWidth,
	Float:g_fEndWidth,
	Float:g_fAmplitude,
	bool:g_bHide;

new Handle:g_hColorsMenu,
	Handle:g_hCookie;

public OnPluginStart() 
{
	HookEvent("bullet_impact",	Event_BulletImpact);

	g_hCookie = RegClientCookie("VIP_Tracers", "VIP_Tracers", CookieAccess_Public);

	g_hColorsMenu = CreateMenu(Handler_ColorsMenu, MenuAction_Select|MenuAction_Cancel|MenuAction_DisplayItem);
	SetMenuExitBackButton(g_hColorsMenu, true);
	SetMenuTitle(g_hColorsMenu, "Tracer color:\n \n");

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature[0], BOOL);
	VIP_RegisterFeature(g_sFeature[1], _, SELECTABLE, OnSelectItem, _, OnDrawItem);
}

public OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature[0]);
		VIP_UnregisterFeature(g_sFeature[1]);
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

public bool:OnSelectItem(iClient, const String:sFeatureName[])
{
	DisplayMenu(g_hColorsMenu, iClient, MENU_TIME_FOREVER);
	return false;
}

public OnMapStart()
{
	RemoveAllMenuItems(g_hColorsMenu);

	decl String:sBuffer[256], Handle:hKeyValues;

	hKeyValues = CreateKeyValues("Tracers");
	BuildPath(Path_SM, sBuffer, 256, "data/vip/modules/tracers.ini");

	if (FileToKeyValues(hKeyValues, sBuffer) == false)
	{
		CloseHandle(hKeyValues);
		SetFailState("Could not open file \"%s\"", sBuffer);
	}

	g_bHide			= bool:KvGetNum(hKeyValues, "Hide_Opposite_Team");
	g_fLife			= KvGetFloat(hKeyValues, "Life", 0.2);
	g_fStartWidth	= KvGetFloat(hKeyValues, "StartWidth", 2.0);
	g_fEndWidth		= KvGetFloat(hKeyValues, "EndWidth", 2.0);
	g_fAmplitude		= KvGetFloat(hKeyValues, "Amplitude", 0.0);

	KvGetString(hKeyValues, "Material", sBuffer, sizeof(sBuffer), "materials/sprites/laserbeam.vmt");
	g_iBeamSprite = PrecacheModel(sBuffer);

	KvRewind(hKeyValues);

	sBuffer[0] = 0;
	
	if(KvJumpToKey(hKeyValues, "Colors", true) && KvGotoFirstSubKey(hKeyValues, false))
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
			
			UTIL_LoadColor(iClient, sInfo);
			SetClientCookie(iClient, g_hCookie, sInfo);
			g_iClientItem[iClient] = Item;

			VIP_PrintToChatClient(iClient, "\x03You changed the color of the tracers to \x04%s", sColorName);
			
			DisplayMenuAtItem(g_hColorsMenu, iClient, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		}
		case MenuAction_DisplayItem:
		{
			if(g_iClientItem[iClient] == Item)
			{
				decl String:sColorName[128];
				GetMenuItem(hMenu, Item, "", 0, _, sColorName, sizeof(sColorName));
				
				Format(sColorName, sizeof(sColorName), "%s [✔]", sColorName);

				return RedrawMenuItem(sColorName);
			}
		}
	}

	return 0;
}

public VIP_OnVIPClientLoaded(iClient)
{
	if(VIP_GetClientFeatureStatus(iClient, g_sFeature[0]) != NO_ACCESS)
	{
		decl String:sInfo[64];
		GetClientCookie(iClient, g_hCookie, sInfo, sizeof(sInfo));
		if(sInfo[0] == '\0' || (g_iClientItem[iClient] = UTIL_GetItemIndex(sInfo)) == -1)
		{
			g_iClientItem[iClient] = 0;
			GetMenuItem(g_hColorsMenu, g_iClientItem[iClient], sInfo, sizeof(sInfo));
			SetClientCookie(iClient, g_hCookie, sInfo);
		}

		UTIL_LoadColor(iClient, sInfo);
	}
}

UTIL_LoadColor(iClient, const String:sInfo[])
{
	if(StrEqual(sInfo, "randomcolor"))
	{
		g_iClientColor[iClient][3] = -2;
	}
	else if(StrEqual(sInfo, "teamcolor"))
	{
		g_iClientColor[iClient][3] = -1;
	}
	else
	{
		UTIL_GetRGBAFromString(sInfo, g_iClientColor[iClient]);
	}
}

UTIL_GetRGBAFromString(const String:sBuffer[], iColor[4])
{
	decl String:sBuffers[4][4], i;
	ExplodeString(sBuffer, " ", sBuffers, sizeof(sBuffers), sizeof(sBuffers[]));
	for(i=0; i < 4; ++i)
	{
		StringToIntEx(sBuffers[i], iColor[i]);
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

	return -1;
}

public Event_BulletImpact(Handle:hEvent, const String:sEvName[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(iClient && VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature[0]))
	{
		decl iClients[MaxClients], Float:fClientOrigin[3], Float:fEndPos[3], Float:fStartPos[3], Float:fPercentage, i, iTeam, iTotalClients, iColor[4]; 
		GetClientEyePosition(iClient, fClientOrigin);
		
		fEndPos[0] = GetEventFloat(hEvent, "x");
		fEndPos[1] = GetEventFloat(hEvent, "y");
		fEndPos[2] = GetEventFloat(hEvent, "z");
		
		fPercentage = 0.4/(GetVectorDistance(fClientOrigin, fEndPos)/100.0);

		fStartPos[0] = fClientOrigin[0] + ((fEndPos[0]-fClientOrigin[0]) * fPercentage); 
		fStartPos[1] = fClientOrigin[1] + ((fEndPos[1]-fClientOrigin[1]) * fPercentage)-0.08; 
		fStartPos[2] = fClientOrigin[2] + ((fEndPos[2]-fClientOrigin[2]) * fPercentage);
		
		iTeam = GetClientTeam(iClient);
		if(g_iClientColor[iClient][3] == -2)
		{
			for(i = 0; i < 3; ++i)
			{
				iColor[i] = GetRandomInt(0, 255);
			}

			iColor[3] = GetRandomInt(120, 200);
		}
		else if(g_iClientColor[iClient][3] == -1)
		{
			iColor[1] = 25;
			iColor[3] = 150;

			switch (iTeam)
			{
				case 2 :
				{
					iColor[0] = 200;
					iColor[2] = 25;
				}
				case 3 :
				{
					iColor[0] = 25;
					iColor[2] = 200;
				}
			}
		}
		else
		{
			for(i = 0; i < 4; ++i)
			{
				iColor[i] = g_iClientColor[iClient][i];
			}
		}

		TE_SetupBeamPoints(fStartPos, fEndPos, g_iBeamSprite, 0, 0, 0, g_fLife, g_fStartWidth, g_fEndWidth, 1, g_fAmplitude, iColor, 0);
		i = 1;
		iTotalClients = 0;
		
		if(g_bHide) 
		{
			while(i <= MaxClients)
			{ 
				if(IsClientInGame(i) && IsFakeClient(i) == false && GetClientTeam(i) == iTeam)
				{
					iClients[iTotalClients++] = i;
				}
				++i;
			}
		}
		else while(i <= MaxClients)
		{ 
			if(IsClientInGame(i) && IsFakeClient(i) == false)
			{
				iClients[iTotalClients++] = i;
			}
			++i;
		}

		TE_Send(iClients, iTotalClients);
	}
}