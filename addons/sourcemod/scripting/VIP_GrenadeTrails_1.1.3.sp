#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <vip_core>
#include <clientprefs>

public Plugin:myinfo = 
{
	name = "[VIP] GrenadeTrails",
	author = "R1KO, Add random trails colors by SLAYER",
	version = "1.1.3"
};

static const String:g_sFeature[][] = {"GrenadeTrails", "GrenadeTrails_MENU"};

new g_iClientColor[MAXPLAYERS+1][4],
	g_iClientItem[MAXPLAYERS+1];

new m_hThrower,
	g_iBeamSprite,
	Float:g_fLife,
	Float:g_fStartWidth,
	Float:g_fEndWidth,
	g_iFadeLength,
	bool:g_bHide;

new Handle:g_hColorsMenu,
	Handle:g_hCookie;

public OnPluginStart() 
{
	m_hThrower = FindSendPropOffs("CBaseGrenade", "m_hThrower");

	HookEvent("player_team", Event_PlayerTeam);
	
	g_hCookie = RegClientCookie("VIP_GrenadeTrails", "VIP_GrenadeTrails", CookieAccess_Public);
	
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

public OnClientPutInServer(iClient)
{
	for(new i=0; i < 4; ++i)
	{
		g_iClientColor[iClient][i] = 0;
	}

	g_iClientItem[iClient] = -1;
	
//	LogToFile("addons/sourcemod/logs/VIP_GrenadeTrails.log", "OnClientPutInServer -> Reset");
}

public OnDrawItem(iClient, const String:sSubMenuName[], style)
{
	return VIP_GetClientFeatureStatus(iClient, g_sFeature[0]) == ENABLED ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED;
}

public bool:OnSelectItem(iClient, const String:sFeatureName[])
{
	DisplayMenu(g_hColorsMenu, iClient, MENU_TIME_FOREVER);
	return false;
}

public OnMapStart()
{
	decl String:sBuffer[256], Handle:hKeyValues ;

	hKeyValues = CreateKeyValues("GrenadeTrails");
	BuildPath(Path_SM, sBuffer, 256, "data/vip/modules/grenade_trails.ini");
	if (FileToKeyValues(hKeyValues, sBuffer) == false) SetFailState("Couldn't parse file %s", sBuffer);

	g_hColorsMenu = CreateMenu(Handler_ColorsMenu, MenuAction_Select|MenuAction_Cancel|MenuAction_DisplayItem);
	SetMenuExitBackButton(g_hColorsMenu, true);
	SetMenuTitle(g_hColorsMenu, "Grenade Trail color:\n \n");

	g_bHide			= bool:KvGetNum(hKeyValues, "Hide_Opposite_Team");
	g_fLife			= KvGetFloat(hKeyValues, "Life", 0.2);
	g_fStartWidth	= KvGetFloat(hKeyValues, "StartWidth", 2.0);
	g_fEndWidth		= KvGetFloat(hKeyValues, "EndWidth", 2.0);
	g_iFadeLength	= KvGetNum(hKeyValues, "FadeLength", 5);

	KvGetString(hKeyValues, "Material", sBuffer, sizeof(sBuffer), "materials/sprites/laserbeam.vmt");
	g_iBeamSprite = PrecacheModel(sBuffer);
//	LogMessage("PrecacheModel: %i", g_iBeamSprite);

	KvRewind(hKeyValues);
	sBuffer[0] = 0;
	if(KvJumpToKey(hKeyValues, "Colors", true))
	{
		if (KvGotoFirstSubKey(hKeyValues, false))
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
			
	//		LogToFile("addons/sourcemod/logs/VIP_GrenadeTrails.log", "Select -> %s, %s (%i)", sInfo, sColorName, Item);
			
			UTIL_LoadColor(iClient, sInfo);
			SetClientCookie(iClient, g_hCookie, sInfo);
			g_iClientItem[iClient] = Item;

			VIP_PrintToChatClient(iClient, "\x03You changed the color of the Grenade Trails to \x04%s", sColorName);
			
			DisplayMenu(g_hColorsMenu, iClient, MENU_TIME_FOREVER);
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
	decl String:sInfo[64];
	GetClientCookie(iClient, g_hCookie, sInfo, sizeof(sInfo));
//	LogToFile("addons/sourcemod/logs/VIP_GrenadeTrails.log", "VIP_OnVIPClientLoaded -> %s", sInfo);
	if(sInfo[0])
	{
		g_iClientItem[iClient] = UTIL_GetItemIndex(sInfo);
	}
	else
	{
		g_iClientItem[iClient] = 0;
		GetMenuItem(g_hColorsMenu, g_iClientItem[iClient], sInfo, sizeof(sInfo));
	}

	UTIL_LoadColor(iClient, sInfo);
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
	
//	LogToFile("addons/sourcemod/logs/VIP_GrenadeTrails.log", "LoadColor -> %s -> %i %i %i %i", sInfo, g_iClientColor[iClient][0], g_iClientColor[iClient][1], g_iClientColor[iClient][2], g_iClientColor[iClient][3]);
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

UTIL_GetItemIndex(const String:sInfo[])
{
//	LogToFile("addons/sourcemod/logs/VIP_GrenadeTrails.log", "GetItemIndex -> %s", sInfo);
	decl String:sItemInfo[64], i, iSize;
	iSize = GetMenuItemCount(g_hColorsMenu);
	for(i = 0; i < iSize; ++i)
	{
		GetMenuItem(g_hColorsMenu, i, sItemInfo, sizeof(sItemInfo));
		if(strcmp(sInfo, sItemInfo) == 0)
		{
			return i;
		}
	}

	return -1;
}


public Event_PlayerTeam(Handle:hEvent, const String:weaponName[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(iClient && g_iClientColor[iClient][3] == -1)
	{
		GetClientTeamColor(iClient, GetEventInt(hEvent, "team"));
	}
}

GetClientTeamColor(iClient, iTeam)
{
	if(iTeam > 1)
	{
		g_iClientColor[iClient][1] = 25;
		g_iClientColor[iClient][3] = 150;

		switch (iTeam)
		{
			case 2 :
			{
				g_iClientColor[iClient][0] = 200;
				g_iClientColor[iClient][2] = 25;
			}
			case 3 :
			{
				g_iClientColor[iClient][0] = 25;
				g_iClientColor[iClient][2] = 200;
			}
		}
	}
	
	g_iClientColor[iClient][3] = -1;
}

public OnEntityCreated(iEntity, const String:sClassName[])
{
	if (StrContains(sClassName, "_projectile") != -1)
	{
	//	LogMessage("OnEntityCreated: %s (%i)", sClassName, iEntity);
		CreateTimer(0.0, Timer_OnSpawnProjectile, EntIndexToEntRef(iEntity), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_OnSpawnProjectile(Handle:hTimer, any:iEntRef)
{
	new iEntity = EntRefToEntIndex(iEntRef);
	if (iEntity != INVALID_ENT_REFERENCE && IsValidEntity(iEntity))
	{
		new iClient = GetEntDataEnt2(iEntity, m_hThrower);
	//	LogMessage("Timer_OnSpawnProjectile-> Entity: %i, iClient: %i", iEntity, iClient);
		if(0 < iClient <= MaxClients && VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature[0]))
		{
			decl clients[MaxClients], i, totalClients, iTeam, iColor[4];
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
			
			
			TE_SetupBeamFollow(iEntity, g_iBeamSprite, 0, g_fLife, g_fStartWidth, g_fEndWidth, g_iFadeLength, iColor);
			i = 1;
			totalClients = 0;
			if(g_bHide) 
			{
				while(i <= MaxClients)
				{ 
					if(IsClientInGame(i) && IsFakeClient(i) == false && GetClientTeam(i) == iTeam)
					{
						clients[totalClients++] = i;
					}
					++i;
				}
			}
			else while(i <= MaxClients)
			{ 
				if(IsClientInGame(i) && IsFakeClient(i) == false)
				{
					clients[totalClients++] = i;
				}
				++i;
			}

			TE_Send(clients, totalClients);
		}
	}

	return Plugin_Stop;
}

public OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature[0]);
		VIP_UnregisterFeature(g_sFeature[1]);
	}
}