#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <vip_core>

public Plugin:myinfo = 
{
	name = "[VIP] Fire Damage",
	author = "R1KO",
	version = "1.0.1"
};

new const String:g_sFeature[] = "FireDamage";

new bool:g_bCvar_bKnife,
	bool:g_bCvar_bHE,
	Float:g_fCvar_FireDuration;
	
public OnPluginStart() 
{
	HookEvent("player_hurt", Event_PlayerHurt);
	
	decl Handle:hCvar;
	HookConVarChange((hCvar = CreateConVar("vip_fire_damage_knife", "0", "Поджигать ли при ударе ножом (0 - Отключено)", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnKnifeChange);
	g_bCvar_bKnife = GetConVarBool(hCvar);

	HookConVarChange((hCvar = CreateConVar("vip_fire_damage_he", "0", "Поджигать ли при повреждении гранатой (0 - Отключено)", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnHEChange);
	g_bCvar_bHE = GetConVarBool(hCvar);

	HookConVarChange((hCvar = CreateConVar("vip_fire_damage_fire_duration", "2.0", "Длительность горения", FCVAR_PLUGIN, true, 0.1, true, 1.0)), OnFireDurationChange);
	g_fCvar_FireDuration = GetConVarFloat(hCvar);

	AutoExecConfig(true, "VIP_FireDamage", "vip");

	CloseHandle(hCvar);
	
	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public OnKnifeChange(Handle:hCvar, const String:oldValue[], const String:newValue[])			g_bCvar_bKnife = GetConVarBool(hCvar);
public OnHEChange(Handle:hCvar, const String:oldValue[], const String:newValue[])				g_bCvar_bHE = GetConVarBool(hCvar);
public OnFireDurationChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_fCvar_FireDuration = GetConVarFloat(hCvar);

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL);
}

public Event_PlayerHurt(Handle:hEvent, const String:sEvName[], bool:bSilent) 
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(iClient && VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		if(g_bCvar_bKnife == false || g_bCvar_bHE == false)
		{
			decl String:sWeapon[32];
			GetEventString(hEvent, "weapon", sWeapon, sizeof(sWeapon));
			if(g_bCvar_bKnife == false && strcmp(sWeapon, "knife") == 0)
			{
				return;
			}
			if(g_bCvar_bHE == false && strcmp(sWeapon, "hegrenade") == 0)
			{
				return;
			}
		}
		
		IgniteEntity(GetClientOfUserId(GetEventInt(hEvent, "userid")), g_fCvar_FireDuration);
	}
}

public OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}