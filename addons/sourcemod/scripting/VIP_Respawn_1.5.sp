#pragma semicolon 1

#include <sourcemod>
#include <vip_core>

#define LIMIT_MODE 			1 	//	Режим работы лимита: 1 - X раз за раунд, 0 - X раз за карту

#define USE_AUTORESPAWN		1	//	Использовать ли Авто Возрождение

#define RESPAWN_CMD 		"sm_respawn"	//	Команда для возрождения

#define MIN_ALIVE_MODE		3 	//	Режим работы sm_vip_respawn_min_alive:
								//		0 - Живых в команде игрока
								//		1 - Живых в команде противника игрока
								//		2 - Живых суммарно в обеих командах 
								//		3 - Живых в каждой команде

#define GAME_CS
// #define GAME_TF2
// #define GAME_L4D
// #define GAME_L4D2
// #define GAME_DODS


#if defined GAME_CS
	#include <cstrike>
	#include <sdktools_gamerules>
	#define PLUGIN_NAME	"[CS:S/CS:GO] [VIP] Respawn"
#elseif defined GAME_TF2
	#include <tf2>
	#include <tf2_stocks>
	#define PLUGIN_NAME	"[TF2] [VIP] Respawn"
#elseif defined GAME_L4D
	#include <sdktools>
	#define PLUGIN_NAME	"[L4D] [VIP] Respawn"
#elseif defined GAME_L4D2
	#include <sdktools>
	#define PLUGIN_NAME	"[L4D2] [VIP] Respawn"
#elseif defined GAME_DODS
	#include <sdktools>
	#define PLUGIN_NAME	"[DOD:S] [VIP] Respawn"
#else
	#error "Invalid define GAME"
#endif

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "R1KO",
	version = "1.3"
};

static const String:g_sFeature[] = "Respawn";
static const String:g_sFeature3[] = "RespawnWaitTime";
#if USE_AUTORESPAWN
static const String:g_sFeature2[] = "AutoRespawn";
new bool:g_bAutoRespawn[MAXPLAYERS+1];
#endif

new g_iClientRespawns[MAXPLAYERS+1];
new Float:g_fDeathTime[MAXPLAYERS+1];

new bool:g_bEnabled;
new g_iMapLimit;
new Float:g_fStartDuration;
new Float:g_fEndDuration;
new g_iMinAlive;

new bool:g_bEnabledRespawn;

new Handle:g_hTimer;
new Handle:g_hAuthTrie;

#if defined GAME_L4D || defined GAME_L4D2
new Handle:g_hRoundRespawn;
new Float:g_fDeathPos[MAXPLAYERS+1][3];
#endif

#if defined GAME_L4D2
new Handle:g_hBecomeGhost;
new Handle:g_hState_Transition;
#elseif defined GAME_DODS
new Handle:g_hPlayerRespawn;
#endif

public OnPluginStart()
{
	#if defined GAME_L4D
	if(GetEngineVersion() != Engine_Left4Dead)
	{
		SetFailState("Эта игра не поддерживается");
	}

	new Handle:hGameConf = LoadGameConfigFile("vip_respawn");

	if (hGameConf != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
		g_hRoundRespawn = EndPrepSDKCall();
		if (g_hRoundRespawn == INVALID_HANDLE) SetFailState("RoundRespawn Signature broken");
	}
	else
	{
		SetFailState("Could not find gamedata file (addons/sourcemod/gamedata/vip_respawn.txt)");
	}

	CloseHandle(hGameConf);
	#elseif defined GAME_L4D2
	if(GetEngineVersion() != Engine_Left4Dead2)
	{
		SetFailState("Эта игра не поддерживается");
	}

	new Handle:hGameConf = LoadGameConfigFile("vip_respawn");

	if (hGameConf != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
		g_hRoundRespawn = EndPrepSDKCall();
		if (g_hRoundRespawn == INVALID_HANDLE) SetFailState("RoundRespawn Signature broken");
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "BecomeGhost");
		PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
		g_hBecomeGhost = EndPrepSDKCall();
		if (g_hBecomeGhost == INVALID_HANDLE)
			SetFailState("BecomeGhost Signature broken");

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "State_Transition");
		PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
		g_hState_Transition = EndPrepSDKCall();
		if (g_hState_Transition == INVALID_HANDLE)
			SetFailState("State_Transition Signature broken");
	}
	else
	{
		SetFailState("Could not find gamedata file (addons/sourcemod/gamedata/vip_respawn.txt)");
	}
	#elseif defined GAME_DODS
	if(GetEngineVersion() != Engine_DODS)
	{
		SetFailState("Эта игра не поддерживается");
	}

	new Handle:hGameConf = LoadGameConfigFile("vip_respawn");

	if (hGameConf != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "DODRespawn");
		g_hPlayerRespawn = EndPrepSDKCall();

		if (g_hPlayerRespawn == INVALID_HANDLE)
		{
			SetFailState("Fatal Error: Unable to find signature for \"CDODPlayer::DODRespawn(void)\"!");
		}
	}
	else
	{
		SetFailState("Could not find gamedata file (addons/sourcemod/gamedata/vip_respawn.txt)");
	}

	CloseHandle(hGameConf);
	#endif

	g_hAuthTrie = CreateTrie();

	new Handle:hCvar = CreateConVar("sm_vip_respawn_enable", "1", "Включен ли плагин (0 - Отключен, 1 - Включен)", 0, true, 0.0, true, 1.0);
	g_bEnabled = GetConVarBool(hCvar);
	HookConVarChange(hCvar, OnEnabledChange);

	hCvar = CreateConVar("sm_vip_respawn_map_limit", "-1", "Ограничение респавнов за раунд/карту для карты (-1 - нет ограничения, 0 - запрещено, 1 и больше)", 0, true, -1.0);
	g_iMapLimit = GetConVarInt(hCvar);
	HookConVarChange(hCvar, OnMapLimitChange);
	
	hCvar = CreateConVar("sm_vip_respawn_start_duration", "20.0", "Через сколько секунд после начала раунда игрок может возрождаться (0.0 - Отключено)", 0, true, 0.0);
	HookConVarChange(hCvar, OnStartDurationChange);
	g_fStartDuration = GetConVarFloat(hCvar);
	
	hCvar = CreateConVar("sm_vip_respawn_end_duration", "120.0", "Сколько секунд после начала раунда игрок может возрождаться (0.0 - Отключено)", 0, true, 0.0);
	HookConVarChange(hCvar, OnEndDurationChange);
	g_fEndDuration = GetConVarFloat(hCvar);
	
	hCvar = CreateConVar("sm_vip_respawn_min_alive", "0", "Сколько минимально должно быть живых игроков в команде чтобы игрок мог возрождаться (0 - Отключено)", 0, true, 0.0);
	HookConVarChange(hCvar, OnMinAliveChange);
	g_iMinAlive = GetConVarInt(hCvar);
	
	AutoExecConfig(true, "VIP_Respawn", "vip");

	RegConsoleCmd(RESPAWN_CMD, Respawn_CMD);
	
	#if defined GAME_TF2
	HookEventEx("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEventEx("teamplay_round_win", Event_RoundEnd, EventHookMode_PostNoCopy);
	#else
	HookEventEx("round_freeze_end", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEventEx("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	#endif

//	HookEventEx("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	#if defined GAME_L4D || defined GAME_L4D2
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	#endif
	HookEvent("player_death", Event_PlayerDeath);

	LoadTranslations("vip_respawn.phrases");
	LoadTranslations("vip_modules.phrases");
	LoadTranslations("vip_core.phrases");

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public OnEnabledChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_bEnabled = GetConVarBool(hCvar);
public OnMapLimitChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iMapLimit = GetConVarInt(hCvar);
public OnStartDurationChange(Handle:hCvar, String:oldValue[], String:newValue[])		g_fStartDuration = GetConVarFloat(hCvar);
public OnEndDurationChange(Handle:hCvar, String:oldValue[], String:newValue[])			g_fEndDuration = GetConVarFloat(hCvar);
public OnMinAliveChange(Handle:hCvar, String:oldValue[], String:newValue[])				g_iMinAlive = GetConVarInt(hCvar);

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, INT, SELECTABLE, OnSelectItem, OnDisplayItem);
	VIP_RegisterFeature(g_sFeature3, INT, HIDE);
	#if USE_AUTORESPAWN
	VIP_RegisterFeature(g_sFeature2, BOOL, TOGGLABLE, OnToggleItem, _, OnDrawItem);
	#endif
}

public OnPluginEnd()
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
		VIP_UnregisterFeature(g_sFeature3);
		#if USE_AUTORESPAWN
		VIP_UnregisterFeature(g_sFeature2);
		#endif
	}
}

#if LIMIT_MODE == 0
public OnMapStart()
{
	ClearTrie(g_hAuthTrie);

	for(new i = 1; i <= MaxClients; ++i) g_iClientRespawns[i] = 0;
}
#endif

public Action:Respawn_CMD(iClient, args)
{
	if(iClient)
	{
		if(!g_bEnabled)
		{
			VIP_PrintToChatClient(iClient, "%t", "RESPAWN_OFF");
		}
		if(VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature))
		{
			RespawnClient(iClient);
		}
		else
		{
			VIP_PrintToChatClient(iClient, "%t", "COMMAND_NO_ACCESS");
		}
	}
	return Plugin_Handled;
}

new g_iRoundStartTime;

public Event_RoundStart(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	#if LIMIT_MODE == 1
	ClearTrie(g_hAuthTrie);

	for(new i = 1; i <= MaxClients; ++i) g_iClientRespawns[i] = 0;
	#endif

	if (g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
/*
	if(g_fStartDuration)
	{
		g_bEnabledRespawn = false;

		g_hTimer = CreateTimer(g_fStartDuration, Timer_EnableRespawn);

		return;
	}
*/
	g_bEnabledRespawn = true;

	if (g_fEndDuration)
	{
		g_hTimer = CreateTimer(g_fEndDuration, Timer_DisableRespawn);
	}
	
	g_iRoundStartTime = GetTime();
}

public Action:Timer_EnableRespawn(Handle:hTimer)
{
	g_bEnabledRespawn = true;

	if(g_fEndDuration && g_fEndDuration > g_fStartDuration)
	{
		g_hTimer = CreateTimer(g_fEndDuration-g_fStartDuration, Timer_DisableRespawn);
		return Plugin_Stop;
	}

	g_hTimer = INVALID_HANDLE;

	return Plugin_Stop;
}

public Action:Timer_DisableRespawn(Handle:hTimer)
{
	g_bEnabledRespawn = false;
	g_hTimer = INVALID_HANDLE;

	return Plugin_Stop;
}

public Event_RoundEnd(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabledRespawn)
	{
		g_bEnabledRespawn = false;
	}

	if (g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
}

public OnClientPutInServer(iClient)
{
	g_iClientRespawns[iClient] = 0;
	
	decl String:sAuth[32];
	GetClientAuthId(iClient, AuthId_Engine, sAuth, sizeof(sAuth));
	GetTrieValue(g_hAuthTrie, sAuth, g_iClientRespawns[iClient]);
}

#if defined GAME_L4D || defined GAME_L4D2
public Action:Event_PlayerDeathPre(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", g_fDeathPos[iClient]);
}

CheatCommand(client, String:command[], String:arguments[])
{
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}
#endif

public Event_PlayerDeath(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	g_fDeathTime[iClient] = GetGameTime();
	
	#if USE_AUTORESPAWN
	if(g_bAutoRespawn[iClient])
	{
		CreateTimer(1.0, Timer_RespawnClient, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
	}
	#endif
}

#if USE_AUTORESPAWN
public Action:Timer_RespawnClient(Handle:hTimer, any:iUserID)
{
	new iClient = GetClientOfUserId(iUserID);
	if(iClient && IsClientInGame(iClient) && CheckRespawn(iClient, false))
	{
		VIP_PrintToChatClient(iClient, "%t", "AUTORESPAWN_NOTIFY");
		RespawnClient(iClient, false);
	}

	return Plugin_Stop;
}
#endif

RespawnClient(iClient, bool:bCheck = true)
{
	if(bCheck && !CheckRespawn(iClient, true))
	{
		return;
	}

	++g_iClientRespawns[iClient];

	decl String:sAuth[32];
	GetClientAuthId(iClient, AuthId_Engine, sAuth, sizeof(sAuth));
	SetTrieValue(g_hAuthTrie, sAuth, g_iClientRespawns[iClient]);

	#if defined GAME_CS
	CS_RespawnPlayer(iClient);
	#elseif defined GAME_TF2
	TF2_RespawnPlayer(iClient);
	#elseif defined GAME_L4D
	if(iTeam == 2)
	{
		SDKCall(g_hRoundRespawn, iClient);

		CheatCommand(iClient, "give", "first_aid_kit");
		CheatCommand(iClient, "give", "smg");
		
		g_fDeathPos[iClient][2] += 40.0;
		TeleportEntity(iClient, g_fDeathPos[iClient], NULL_VECTOR, NULL_VECTOR);
	}
	#elseif defined GAME_L4D2
	switch(iTeam)
	{
		case 2:
		{
			SDKCall(g_hRoundRespawn, iClient);
			
			CheatCommand(iClient, "give", "first_aid_kit");
			CheatCommand(iClient, "give", "smg");
			g_fDeathPos[iClient][2] += 40.0;
			TeleportEntity(iClient, g_fDeathPos[iClient], NULL_VECTOR, NULL_VECTOR);
		}
		case 3:
		{
			SDKCall(g_hState_Transition, iClient, 8);
			SDKCall(g_hBecomeGhost, iClient, 1);
			SDKCall(g_hState_Transition, iClient, 6);
			SDKCall(g_hBecomeGhost, iClient, 1);
			g_fDeathPos[iClient][2] += 40.0;
			TeleportEntity(iClient, g_fDeathPos[iClient], NULL_VECTOR, NULL_VECTOR);
		}
	}
	#elseif defined GAME_DODS
	SDKCall(g_hPlayerRespawn, iClient);
	#endif
}

bool:CheckRespawn(iClient, bool:bNotify)
{
	if(!g_bEnabled)
	{
		VIP_PrintToChatClient(iClient, "%t", "RESPAWN_OFF");
		return false;
	}

	if(g_iMapLimit == 0)
	{
		if(bNotify)
		{
			VIP_PrintToChatClient(iClient, "%t", "RESPAWN_OFF");
		}
		return false;
	}

	if(!g_bEnabledRespawn)
	{
		if(bNotify)
		{
			VIP_PrintToChatClient(iClient, "%t", "RESPAWN_FORBIDDEN");
		}
		return false;
	}

	#if defined GAME_CS
	if(GetEngineVersion() == Engine_CSGO && GameRules_GetProp("m_bWarmupPeriod") == 1) 
    {
		if(bNotify)
		{
			VIP_PrintToChatClient(iClient, "%t", "RESPAWN_FORBIDDEN_ON_WARMUP");
		}
		return false;
	}
	#endif

	if(GetGameTime() < g_fDeathTime[iClient] + 1.0)
	{
		return false;
	}

	new iClientTeam = GetClientTeam(iClient);
	if(iClientTeam < 2)
	{
		if(bNotify)
		{
			VIP_PrintToChatClient(iClient, "%t", "YOU_MUST_BE_ON_TEAM");
		}
		return false;
	}

	if(IsPlayerAlive(iClient))
	{
		if(bNotify)
		{
			VIP_PrintToChatClient(iClient, "%t", "YOU_MUST_BE_DEAD");
		}
		return false;
	}

	new iWaitRespawn = VIP_GetClientFeatureInt(iClient, g_sFeature3);
	if (iWaitRespawn)
	{
		if (GetTime() > g_iRoundStartTime + iWaitRespawn)
		{
			if(bNotify)
			{
				VIP_PrintToChatClient(iClient, "%t", "Респавн больше не доступен !");
			}
			return false;
		}
	}

	new iLimit = VIP_GetClientFeatureInt(iClient, g_sFeature);

	if((g_iMapLimit != -1 && (iLimit == -1 || g_iMapLimit < iLimit) && g_iClientRespawns[iClient] >= g_iMapLimit) ||
	(iLimit != -1 && g_iClientRespawns[iClient] >= iLimit))
	{
		if(bNotify)
		{
			#if LIMIT_MODE == 1
			VIP_PrintToChatClient(iClient, "%t", "REACHED_ROUND_LIMIT");
			#else
			VIP_PrintToChatClient(iClient, "%t", "REACHED_MAP_LIMIT");
			#endif
		}
		return false;
	}

	// PrintToChat(iClient, "g_iMinAlive = %d", g_iMinAlive);
	if(g_iMinAlive)
	{
		decl iPlayers[2], i, iTeam;
		iPlayers[0] = iPlayers[1] = 0;
		for(i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && (iTeam = GetClientTeam(i)) > 1)
			{
				++iPlayers[iTeam-2];
			}
		}
		// PrintToChat(iClient, "MIN_ALIVE_MODE = %d", MIN_ALIVE_MODE);
		// PrintToChat(iClient, "iPlayers[0] = %d", iPlayers[0]);
		// PrintToChat(iClient, "iPlayers[1] = %d", iPlayers[1]);

		#if MIN_ALIVE_MODE == 0			//	Живых в команде игрока
		if(iPlayers[iClientTeam == 2 ? 0:1] < g_iMinAlive)
		#elseif MIN_ALIVE_MODE == 1		//	Живых в команде противника игрока
		if(iPlayers[iClientTeam == 2 ? 1:0] < g_iMinAlive)
		#elseif MIN_ALIVE_MODE == 2		//	Живых суммарно в обеих командах 
		if(iPlayers[0] + iPlayers[1] < g_iMinAlive)
		#elseif MIN_ALIVE_MODE == 3		//	Живых в каждой команде
		if(iPlayers[0] < g_iMinAlive || iPlayers[1] < g_iMinAlive)
		#endif
		{
			if(bNotify)
			{
				VIP_PrintToChatClient(iClient, "%t", "NOT_ENOUGH_ALIVE_PLAYERS");
			}
			return false;
		}
	}

	return true;
}

public bool:OnSelectItem(iClient, const String:sFeatureName[])
{
	if(!g_bEnabled)
	{
		return false;
	}

	if(!CheckRespawn(iClient, false))
	{
		return false;
	}
		
	RespawnClient(iClient);
	return true;
}

public bool:OnDisplayItem(iClient, const String:sFeatureName[], String:sDisplay[], maxlen)
{
	if(VIP_GetClientFeatureStatus(iClient, g_sFeature) == ENABLED)
	{
		new iLimit = VIP_GetClientFeatureInt(iClient, g_sFeature);
		if(iLimit != -1)
		{
			if(g_iMapLimit != -1 && g_iMapLimit < iLimit)
			{
				iLimit = g_iMapLimit - g_iClientRespawns[iClient];
			}
			else
			{
				iLimit -= g_iClientRespawns[iClient];
			}

			FormatEx(sDisplay, maxlen, "%T [%T]", g_sFeature, iClient, "Left", iClient, iLimit);
			return true;
		}
	}

	return false;
}

#if USE_AUTORESPAWN
public Action:OnToggleItem(iClient, const String:sFeatureName[], VIP_ToggleState:OldStatus, &VIP_ToggleState:NewStatus)
{
	g_bAutoRespawn[iClient] = (NewStatus == ENABLED);

	return Plugin_Continue;
}

public OnDrawItem(iClient, const String:sFeatureName[], iStyle)
{
	if(VIP_GetClientFeatureStatus(iClient, g_sFeature) != NO_ACCESS)
	{
		return ITEMDRAW_DEFAULT;
	}

	return ITEMDRAW_RAWLINE;
}

public VIP_OnVIPClientLoaded(iClient)
{
	g_bAutoRespawn[iClient] = VIP_IsClientFeatureUse(iClient, g_sFeature);
}
#endif
