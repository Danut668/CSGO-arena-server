#pragma newdecls required

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <vip_core>

public Plugin myinfo = 
{
	name = "[VIP] Boost Ladder",
	author = "diller110 & KOROVKA",
	version = "3.0.0"
};

#define VIP_MODULE  "BoostLadder"

float g_fScale[MAXPLAYERS+1];
int m_flFallVelocity, m_vecMins, m_vecMaxs;

public void OnPluginStart() 
{
	if(VIP_IsVIPLoaded())
		VIP_OnVIPLoaded();
		
	m_flFallVelocity = FindSendPropInfo("CCSPlayer", "m_flFallVelocity");
	m_vecMins = FindSendPropInfo("CCSPlayer", "m_vecMins");
	m_vecMaxs = FindSendPropInfo("CCSPlayer", "m_vecMaxs");
}

public void OnPluginEnd() 
{
	VIP_UnregisterFeature(VIP_MODULE);
}

public void VIP_OnVIPLoaded() 
{
	VIP_RegisterFeature(VIP_MODULE, FLOAT, TOGGLABLE, OnSelectItem);
	
	for(int i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && VIP_IsClientVIP(i))
			VIP_OnVIPClientLoaded(i);
	}
}

public void VIP_OnVIPClientLoaded(int client) 
{
	if(VIP_GetClientFeatureStatus(client, VIP_MODULE) == ENABLED) 
		g_fScale[client] = VIP_GetClientFeatureFloat(client, VIP_MODULE) * 0.01;
}

public void VIP_OnVIPClientRemoved(int client, const char[] sReason, int admin)
{
	g_fScale[client] = 0.0;
}

public void OnClientDisconnect(int client) 
{
	g_fScale[client] = 0.0;
}

public Action OnSelectItem(int client, const char[] sFeature, VIP_ToggleState oldState, VIP_ToggleState &newState) 
{
	if(newState == ENABLED) g_fScale[client] = VIP_GetClientFeatureFloat(client, VIP_MODULE) * 0.01;
	else g_fScale[client] = 0.0;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2]) 
{
	if(g_fScale[client] == 0.0 || !IsPlayerAlive(client)) return;
	
	if(MOVETYPE_LADDER & GetEntityMoveType(client) &~ MOVETYPE_NOCLIP) 
	{
		if(buttons & IN_SPEED || !(buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVERIGHT || buttons & IN_MOVELEFT))
			return;
		
		static float fFallVel, fOrigin[3];
		
		fFallVel = -GetEntDataFloat(client, m_flFallVelocity);

		if(FloatAbs(fFallVel) < 10.0)
			return;
		
		fFallVel *= g_fScale[client];
		
		GetClientAbsOrigin(client, fOrigin);
		
		if(IsPlayerStuck(client, fOrigin, fFallVel))
			return;
			
		fOrigin[2] += fFallVel;
		
		TeleportEntity(client, fOrigin, NULL_VECTOR, NULL_VECTOR);
	}
}

// Source: https://forums.alliedmods.net/showpost.php?p=2279313&postcount=2
stock bool IsPlayerStuck(int client, const float fOrigin[3], const float fFallVel) 
{
	static float fMins[3], fMaxs[3], fOrigin2[3];
	
	GetEntDataVector(client, m_vecMins, fMins);
	GetEntDataVector(client, m_vecMaxs, fMaxs);
	
	AddVectors(NULL_VECTOR, fOrigin, fOrigin2); fOrigin2[2] += fFallVel;
	
	TR_TraceHullFilter(fOrigin, fOrigin2, fMins, fMaxs, MASK_SOLID, TraceOtherPlayerOnly, client);
	return (TR_DidHit());
}

public bool TraceOtherPlayerOnly(int ent, int mask, any client) 
{
    return (1 <= ent <= MaxClients && ent != client);
} 