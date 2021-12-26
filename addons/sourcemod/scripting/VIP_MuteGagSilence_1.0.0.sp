#pragma semicolon 1

#include <sourcemod>
#include <vip_core>
#include <clientprefs>
#include <basecomm>

public Plugin:myinfo =
{
	name = "[VIP] MuteGagSilence",
	author = "R1KO",
	version = "1.0.0"
};

static const String:g_sFeature[] = "MuteGagSilence";

#define NONE		0
#define GAG		(1 << 0)
#define MUTE		(1 << 1)

#define TIME		3600

new Handle:g_hTypeMenu,
	Handle:g_hCookie,
	Handle:g_hCookieTime,
	g_iCvar_AdminImmunityMode,
	bool:g_bCvar_VIPImmunityMode;

public OnPluginStart()
{
	g_hCookie = CreateConVar("sm_vip_admin_immunity_mode", "0", "Mode of immunity for admins (-1 - Allow admin kicks, 0 - Immunity for all admins, 1-99 - the required amount of immunity to protect against kicks)", FCVAR_PLUGIN, true, -1.0, true, 100.0);
	HookConVarChange(g_hCookie, OnAdminImmunityModeChange);
	g_iCvar_AdminImmunityMode = GetConVarInt(g_hCookie);
	
	g_hCookie = CreateConVar("sm_vip_vip_immunity_mode", "0", "Immunity mode for VIP players (0 - Allow other VIP players to kick, 1 - Deny other VIP players to kick)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCookie, OnVIPImmunityModeChange);
	g_bCvar_VIPImmunityMode = GetConVarBool(g_hCookie);

	AutoExecConfig(true, "vip_MuteGagSilence", "vip");
	
	g_hCookie = RegClientCookie("VIP_MuteGagSilence", "VIP_MuteGagSilence", CookieAccess_Private);
	g_hCookieTime = RegClientCookie("VIP_MuteGagSilenceTime", "VIP_MuteGagSilenceTime", CookieAccess_Private);

	g_hTypeMenu = CreateMenu(Handler_TypeMenu);
	SetMenuExitBackButton(g_hTypeMenu, true);
	SetMenuTitle(g_hTypeMenu, "Тype :\n \n");
	AddMenuItem(g_hTypeMenu, "1", "Gag");
	AddMenuItem(g_hTypeMenu, "2", "Mute");
	AddMenuItem(g_hTypeMenu, "3", "Gag and Mute");

	LoadTranslations("common.phrases");

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}

public OnAdminImmunityModeChange(Handle:hCvar, const String:sOldValue[], const String:sNewValue[])	g_iCvar_AdminImmunityMode = GetConVarInt(hCvar);
public OnVIPImmunityModeChange(Handle:hCvar, const String:sOldValue[], const String:sNewValue[])		g_bCvar_VIPImmunityMode = GetConVarBool(hCvar);

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL, SELECTABLE, OnSelectItem, _, OnDrawItem);
}

public OnDrawItem(iClient, const String:sFeatureName[], iStyle)
{
	if(VIP_GetClientFeatureStatus(iClient, g_sFeature) == NO_ACCESS)
	{
		return ITEMDRAW_RAWLINE;
	}

	return iStyle;
}

public bool:OnSelectItem(iClient, const String:sFeatureName[])
{
	DisplayMenu(g_hTypeMenu, iClient, MENU_TIME_FOREVER);
	return false;
}

public Handler_TypeMenu(Handle:hMenu, MenuAction:action, iClient, Item)
{
	switch(action)
	{
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack)
			{
				VIP_SendClientVIPMenu(iClient);
			}
		}
		case MenuAction_Select:
		{
			SetTrieValue(VIP_GetVIPClientTrie(iClient), "MGS_Type", Item+1);
			DisplayMenu(CreatePlayersMenu(iClient), iClient, MENU_TIME_FOREVER);
		}
	}
}

Handle:CreatePlayersMenu(iClient)
{
	decl String:sUserID[16], String:sName[64], Handle:hMenu, i, AdminId:AID;
	hMenu = CreateMenu(PlayersMenu_Handler);
	SetMenuExitBackButton(hMenu, true);
	SetMenuTitle(hMenu, "Player :\n \n");
	
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
			
			
			GetClientCookie(i, g_hCookie, sUserID, sizeof(sUserID));
			if(sUserID[0])
			{
				switch(StringToInt(sUserID))
				{
					case 0:
					{
						GetClientName(i, sName, sizeof(sName));
					}
					case 1:
					{
						FormatEx(sName, sizeof(sName), "%N [Gag]", i);
					}
					case 2:
					{
						FormatEx(sName, sizeof(sName), "%N [Mute]", i);
					}
					case 3:
					{
						FormatEx(sName, sizeof(sName), "%N [Gag and Мute]", i);
					}
				}
			}
			else
			{
				GetClientName(i, sName, sizeof(sName));
			}
			
			IntToString(GetClientUserId(i), sUserID, sizeof(sUserID));
			LogMessage("sUserID: %s", sUserID);
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

public PlayersMenu_Handler(Handle:hMenu, MenuAction:action, iClient, Item)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(hMenu);
		case MenuAction_Cancel:
		{
			if(Item == MenuCancel_ExitBack)
			{
				DisplayMenu(g_hTypeMenu, iClient, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Select:
		{
			decl String:sUserID[16], iTarget;
			GetMenuItem(hMenu, Item, sUserID, sizeof(sUserID));
			LogMessage("sUserID: %s", sUserID);
			iTarget = GetClientOfUserId(StringToInt(sUserID));
			LogMessage("iTarget: %i", iTarget);
			if(iTarget && IsClientInGame(iTarget))
			{
				decl iType, iClientType;
				GetTrieValue(VIP_GetVIPClientTrie(iClient), "MGS_Type", iType);
				
				GetClientCookie(iTarget, g_hCookie, sUserID, sizeof(sUserID));
				iClientType = StringToInt(sUserID);
				switch(iType)
				{
					case 1:
					{
						if(iClientType & iType)
						{
							VIP_PrintToChatClient(iClient,  "\x03The Player \x04%N,\x03 is Now \x04UnGagged \x03by VIP Player", iTarget);
							VIP_PrintToChatClient(iTarget, "\x03You are Now \x04UnGagged \x03by VIP Player");
							LogAction(iClient, iTarget, "VIP-Player \"%L\" has UnGagged the player \"%L\"", iClient, iTarget);
							BaseComm_SetClientGag(iTarget, false);
							iClientType &= ~GAG;
						}
						else
						{
							VIP_PrintToChatClient(iClient, "\x03The Player \x04%N,\x03 is Now \x04Gagged \x03by VIP Player", iTarget);
							VIP_PrintToChatClient(iTarget, "\x03Your are Now \x04Gagged \x03by VIP Player");
							LogAction(iClient, iTarget, "VIP-Player \"%L\" has Gagged the Player \"%L\"", iClient, iTarget);
							BaseComm_SetClientGag(iTarget, true);
							iClientType |= GAG;
						}
					}
					case 2:
					{
						if(iClientType & iType)
						{
							VIP_PrintToChatClient(iClient, "\x03The Player \x04%N,\x03 is Now \x04UnMuted \x03by VIP Player", iTarget);
							VIP_PrintToChatClient(iTarget, "\x03You are now \x04UnMuted \x03by VIP Player");
							LogAction(iClient, iTarget, "VIP-Player \"%L\" has UnMuted the Player \"%L\"", iClient, iTarget);
							BaseComm_SetClientMute(iTarget, false);
							iClientType &= ~MUTE;
						}
						else
						{
							VIP_PrintToChatClient(iClient, "\x03The Player \x04%N,\x03 is Now \x04Muted \x03by VIP Player", iTarget);
							VIP_PrintToChatClient(iTarget, "\x03You are now \x04Muted \x03by VIP Player");
							LogAction(iClient, iTarget, "VIP-Player \"%L\" has Muted the Player \"%L\"", iClient, iTarget);
							BaseComm_SetClientMute(iTarget, true);
							iClientType |= MUTE;
						}
					}
					case 3:
					{
						if(iClientType & GAG && iClientType & MUTE)
						{
							VIP_PrintToChatClient(iClient, "\x03Player \x04%N,\x03 is Now \x04UnGagged \x03and \x04UnMuted \x03by VIP Player", iTarget);
							VIP_PrintToChatClient(iTarget, "\x03You are Now \x04UnGagged \x03and \x04UnMuted \x03by VIP Player");
							LogAction(iClient, iTarget, "VIP-Player \"%L\" has UnGagged and UnMuted the Player \"%L\"", iClient, iTarget);
							BaseComm_SetClientGag(iTarget, false);
							BaseComm_SetClientMute(iTarget, false);
							iClientType = 0;
						}
						else
						{
							VIP_PrintToChatClient(iClient, "\x03The Player \x04%N,\x03 is Now \x04Gagged \x03and \x04Muted \x03by VIP Player", iTarget);
							VIP_PrintToChatClient(iTarget, "\x03You are Now \x04Gagged \x03and \x04Muted \x03by VIP Player");
							LogAction(iClient, iTarget, "VIP-Player \"%L\" has Gagged and Muted the Player \"%L\"", iClient, iTarget);
							BaseComm_SetClientGag(iTarget, true);
							BaseComm_SetClientMute(iTarget, true);
							iClientType = GAG|MUTE;
						}
					}
				}
				
				IntToString(iClientType, sUserID, sizeof(sUserID));
				SetClientCookie(iTarget, g_hCookie, sUserID);
				
				IntToString(GetTime()+TIME, sUserID, sizeof(sUserID));
				SetClientCookie(iTarget, g_hCookieTime, sUserID);
			}
			else
			{
				PrintToChat(iClient, "[SM] %t", "Player no longer available");
			}
		}
	}
}

public OnClientCookiesCached(iClient)
{
	if(IsClientInGame(iClient) && IsClientConnected(iClient))
	{
		decl String:sBuffer[32], iType;
		GetClientCookie(iClient, g_hCookie, sBuffer, sizeof(sBuffer));
		iType = StringToInt(sBuffer);
		if(iType)
		{
			decl iTime;
			GetClientCookie(iClient, g_hCookieTime, sBuffer, sizeof(sBuffer));
			iTime = StringToInt(sBuffer);
			if(GetTime() > iTime)
			{
				switch(iType)
				{
					case 1:
					{
						VIP_PrintToChatClient(iClient, "\x03Your are \x04Gagged!");
						BaseComm_SetClientGag(iClient, true);
					}
					case 2:
					{
						VIP_PrintToChatClient(iClient, "\x03Your are \x04Muted!");
						BaseComm_SetClientMute(iClient, true);
					}
					case 3:
					{
						VIP_PrintToChatClient(iClient, "\x03Your are \x04Gagged \x03and \x04Muted!");
						BaseComm_SetClientGag(iClient, true);
						BaseComm_SetClientMute(iClient, true);
					}
				}
			}
			else
			{
				SetClientCookie(iClient, g_hCookie, "0");
				SetClientCookie(iClient, g_hCookieTime, "0");
			}
		}
	}
}

public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[])
{
	if (client && BaseComm_IsClientGagged(client))
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}