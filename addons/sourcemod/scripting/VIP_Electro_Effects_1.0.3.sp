#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <vip_core>

public Plugin:myinfo = 
{
	name = "[VIP] Electro Effects",
	author = "R1KO",
	version = "1.0.3"
};

static const String:g_sFeature[] = "ElectroEffects";

public OnPluginStart() 
{
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("bullet_impact", Event_OnBulletImpact);

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

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL);
}

public Event_OnBulletImpact(Handle:hEvent, const String:name[], bool:silent) 
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient && VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		decl Float:fPos[3];
		fPos[0] = GetEventFloat(hEvent, "x");
		fPos[1] = GetEventFloat(hEvent, "y");
		fPos[2] = GetEventFloat(hEvent, "z");

		Func_EnergySplash(fPos);
	}
}

public Event_OnPlayerDeath(Handle:hEvent, const String:name[], bool:silent) 
{
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker")),
		iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(iAttacker && iClient && iAttacker != iClient && VIP_IsClientVIP(iAttacker) && VIP_IsClientFeatureUse(iAttacker, g_sFeature))
	{
		decl Float:fPos[3];
		GetClientAbsOrigin(iClient, fPos);
		Func_Tesla(fPos);
	}
}

Func_EnergySplash(Float:fPos[3]) 
{
	decl Float:fEndPos[3];
	fEndPos[0] = fPos[0] + 20.0;
	fEndPos[1] = fPos[1] + 20.0;
	fEndPos[2] = fPos[2] + 20.0;

	TE_SetupEnergySplash(fPos, fEndPos, true);
	TE_SendToAll();
}

Func_Tesla(const Float:fPos[3]) 
{
	new iEntity = CreateEntityByName("point_tesla");
	DispatchKeyValue(iEntity, "beamcount_min", "5"); 
	DispatchKeyValue(iEntity, "beamcount_max", "10");
	DispatchKeyValue(iEntity, "lifetime_min", "0.2");
	DispatchKeyValue(iEntity, "lifetime_max", "0.5");
	DispatchKeyValue(iEntity, "m_flRadius", "100.0");
	DispatchKeyValue(iEntity, "m_SoundName", "DoSpark");
	DispatchKeyValue(iEntity, "texture", "sprites/physbeam.vmt");
	DispatchKeyValue(iEntity, "m_Color", "255 255 255");
	DispatchKeyValue(iEntity, "thick_min", "1.0");  
	DispatchKeyValue(iEntity, "thick_max", "10.0");
	DispatchKeyValue(iEntity, "interval_min", "0.1"); 
	DispatchKeyValue(iEntity, "interval_max", "0.2"); 

	DispatchSpawn(iEntity);
	TeleportEntity(iEntity, fPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iEntity, "TurnOn"); 
	AcceptEntityInput(iEntity, "DoSpark");

	SetVariantString("OnUser1 !self:kill::2.0:-1");
	AcceptEntityInput(iEntity, "AddOutput"); 
	AcceptEntityInput(iEntity, "FireUser1");
}