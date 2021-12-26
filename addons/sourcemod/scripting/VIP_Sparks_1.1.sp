#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <vip_core>

public Plugin:myinfo = 
{
	name = "[VIP] Sparks",
	author = "R1KO",
	version = "1.0.0"
};

static const String:g_sFeature[] = "Sparks";


/*
Режим отображения искр:
0 - Только игроку
1 - Всей команде
2 - Всем игрокам
*/
#define SHOW_MODE	2

new g_iSize, g_iLength;
public OnPluginStart() 
{
	decl Handle:hCvar;
	
	HookConVarChange((hCvar = CreateConVar("sm_vip_sparks_size", "5000", "Размер.")), OnSizeChange);
	g_iSize = GetConVarInt(hCvar);
	
	HookConVarChange((hCvar = CreateConVar("sm_vip_sparks_length", "1000", "Длина следа искр.")), OnLengthChange);
	g_iLength = GetConVarInt(hCvar);

	AutoExecConfig(true, "VIP_Sparks", "vip");

	HookEvent("bullet_impact", Event_OnBulletImpact);

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public OnSizeChange(Handle:hCvar, const String:oldValue[], const String:newValue[])		g_iSize = GetConVarInt(hCvar);
public OnLengthChange(Handle:hCvar, const String:oldValue[], const String:newValue[])		g_iLength = GetConVarInt(hCvar);

public OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL);
}

public Event_OnBulletImpact(Handle:hEvent, const String:name[], bool:silent) 
{
	static iClient;
	iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient && VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		static Float:fPos[3];
		fPos[0] = GetEventFloat(hEvent, "x");
		fPos[1] = GetEventFloat(hEvent, "y");
		fPos[2] = GetEventFloat(hEvent, "z");

		TE_SetupSparks(fPos, Float:{0.0, 0.0, 0.0}, g_iSize, g_iLength);
		
		#if SHOW_MODE == 0
			static iClients[1], iCount = 1;
			iClients[0] = iClient;
		#else
			static iClients[MAXPLAYERS], iCount, i;
			iCount = 0;
			#if SHOW_MODE == 1
			new iTeam = GetClientTeam(iClient);
			#endif
			for(i = 1; i <= MaxClients; ++i)
			{
				if(IsClientInGame(i) && !IsFakeClient(i))
				{
					#if SHOW_MODE == 1
					if(GetClientTeam(i) != iTeam)
					{
						continue;
					}
					#endif
					
					iClients[iCount++] = i;
				}
			}
		#endif
		TE_Send(iClients, iCount);
	}
}
