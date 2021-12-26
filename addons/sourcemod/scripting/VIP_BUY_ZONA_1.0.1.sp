#pragma newdecls required

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <vip_core>

public Plugin myinfo =
{
	name = "[VIP] Buy Zona",
	author = "KOROVKA",
	version = "1.0.1"
};

ConVar g_hCvarBZRadius, g_hCvarBZEnemyTeam, g_hCvarBZForPlayer, g_hCvarBZOnlyVIP;

int g_BZRadius;
bool g_bBZEnemyTeam;
bool g_bBZForPlayer;
bool g_bBZOnlyVIP;

#define VIP_BZ		"BuyZona"

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(VIP_BZ, BOOL);  
}

public void OnPluginStart()
{
	g_hCvarBZRadius = CreateConVar("sm_vip_bz_radius", "100", "Радиус зоны закупки возле вип игроков");
	HookConVarChange(g_hCvarBZRadius, OnSettingChanged);
	
	g_hCvarBZEnemyTeam = CreateConVar("sm_vip_bz_enemy_team", "0", "Смогут ли игроки из вражеской команды закупится возле вип игрока? (1 - Да, 0 - Нет)");
	HookConVarChange(g_hCvarBZEnemyTeam, OnSettingChanged);
	
	g_hCvarBZForPlayer = CreateConVar("sm_vip_bz_for_player", "1", "Сможет ли вип игрок закупится у себя? (1 - Да, 0 - Нет)");
	HookConVarChange(g_hCvarBZForPlayer, OnSettingChanged);
	
	g_hCvarBZOnlyVIP = CreateConVar("sm_vip_bz_only_vip", "1", "Только вип игроки смогут закупится? (1 - Да, 0 - Нет)");
	HookConVarChange(g_hCvarBZOnlyVIP, OnSettingChanged);
	
	AutoExecConfig(true, "BuyZona", "vip");

	if(VIP_IsVIPLoaded())
		VIP_OnVIPLoaded();
		
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			OnClientPutInServer(i);
	}
}

public void OnPluginEnd() 
{
	VIP_UnregisterFeature(VIP_BZ);
}

public void OnConfigsExecuted()
{
	g_BZRadius = GetConVarInt(g_hCvarBZRadius);
	g_bBZEnemyTeam = GetConVarBool(g_hCvarBZEnemyTeam);
	g_bBZForPlayer = GetConVarBool(g_hCvarBZForPlayer);
	g_bBZOnlyVIP = GetConVarBool(g_hCvarBZOnlyVIP);
}

public void OnSettingChanged(ConVar convar, char[] oldValue, char[] newValue)
{
	if(g_hCvarBZRadius == convar) g_BZRadius = StringToInt(newValue);
	else if(g_hCvarBZEnemyTeam == convar) g_bBZEnemyTeam = view_as<bool>(StringToInt(newValue));
	else if(g_hCvarBZForPlayer == convar) g_bBZForPlayer = view_as<bool>(StringToInt(newValue));
	else if(g_hCvarBZOnlyVIP == convar) g_bBZOnlyVIP = view_as<bool>(StringToInt(newValue));
}

public void OnClientPutInServer(int client) 
{
	if(!IsFakeClient(client)) 
		SDKHook(client, SDKHook_SetTransmit, SetTransmit);
}

public Action SetTransmit(int client, int target)
{
	if(IsFakeClient(target)
	|| !IsPlayerAlive(client) || !IsPlayerAlive(target) 
	|| !VIP_IsClientFeatureUse(client, VIP_BZ) || g_bBZOnlyVIP && !VIP_IsClientFeatureUse(target, VIP_BZ) 
	|| !g_bBZForPlayer && client == target 
	|| !g_bBZEnemyTeam && GetClientTeam(client) != GetClientTeam(target)) return;
	
	float fPos[3], fPosTarget[3];
		
	GetClientAbsOrigin(client, fPos);
	GetClientAbsOrigin(target, fPosTarget);

	if(GetVectorDistance(fPos, fPosTarget) <= g_BZRadius) 
		SetEntProp(target, Prop_Send, "m_bInBuyZone", 1);
}