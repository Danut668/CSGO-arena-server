#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <vip_core>

new g_iSteamSprite,
 	g_iLightningSprite,
	g_iExplosionSprite;

#define VIP_SpawnEffects "Spawn_Effects"

public Plugin:myinfo = {
	name 		= "[VIP] Spawn Effects",
	author 		= "Mr.ToNik",
	description = "Effects when players spawn VIP",
	version 	= "1.2",
};

public OnPluginStart() {
	LoadTranslations("vip_modules.phrases");
}

public VIP_OnVIPLoaded() {
	VIP_RegisterFeature(VIP_SpawnEffects, BOOL);
}

public OnMapStart() {
	g_iLightningSprite = PrecacheModel("sprites/lgtning.vmt");
	g_iExplosionSprite = PrecacheModel("materials/sprites/sprite_fire01.vmt");
	g_iSteamSprite = PrecacheModel("sprites/steam1.vmt"); 
}

public VIP_OnPlayerSpawn(iClient, iTeam, bool:bIsVIP) {
	if (bIsVIP && VIP_IsClientFeatureUse(iClient, VIP_SpawnEffects)) {
		switch(GetRandomInt(1, 5)) {
			case 1: {
				decl Float:pos[3];
				GetClientAbsOrigin(iClient, pos);
				new randomx = GetRandomInt(-500, 500);
				new randomy = GetRandomInt(-500, 500);
				new Float:startpos[3]; 
				startpos[0] = pos[0] + randomx; 
				startpos[1] = pos[1] + randomy; 
				startpos[2] = pos[2] + 800;
				new color[4] = {0, 0, 255, 255};
				new Float:dir[3] = {0.0, 0.0, 0.0}; 
				TE_SetupBeamPoints(startpos, pos, g_iLightningSprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 2.0, color, 3);
				TE_SendToAll();
				TE_SetupBeamPoints(startpos, pos, g_iLightningSprite, 0, 0, 0, 0.2, 10.0, 5.0, 0, 1.0, {255, 255, 255, 255}, 3);
				TE_SendToAll();
				TE_SetupSparks(pos, dir, 5000, 1000);
				TE_SendToAll();
				TE_SetupEnergySplash(pos, dir, false);
				TE_SendToAll();
				TE_SetupSmoke(pos, g_iSteamSprite, 5.0, 10);
				TE_SendToAll();
			}
			case 2: {
				decl Float:pos[3];
				GetClientAbsOrigin(iClient, pos);
				TE_SetupExplosion(pos, g_iExplosionSprite, 10.0, 1, 0, 100, 5000);
				TE_SendToAll();
			}
			case 3: {
				Lightning_EnergySplash(iClient);
			}
			case 4: {
				decl Float:pos[3];
				GetClientAbsOrigin(iClient, pos);
				new iEntity = CreateEntityByName("info_particle_system", -1);
				DispatchKeyValue(iEntity, "effect_name", "env_fire_large");
				DispatchKeyValueVector(iEntity, "origin", pos);
				DispatchSpawn(iEntity);
				SetVariantString("!activator");
				AcceptEntityInput(iEntity, "SetParent", iClient);
				ActivateEntity(iEntity);
				AcceptEntityInput(iEntity, "Start");
				SetVariantString("OnUser1 !self:kill::1.5:1");
				AcceptEntityInput(iEntity, "AddOutput");
				AcceptEntityInput(iEntity, "FireUser1");
				return;
			}
			case 5: {
				SmokeEnt(iClient);
			}
		}
	}
}

SmokeEnt(iClient) {
	new Float:center[3];
	GetClientAbsOrigin(iClient, center);
	new iSmoke = CreateEntityByName("env_smokestack");
	DispatchKeyValue(iSmoke, "SmokeMaterial", "particle/smokestack.vmt"); 
	DispatchKeyValue(iSmoke, "BaseSpread", "30"); 
	DispatchKeyValue(iSmoke, "Speed", "100"); 
	DispatchKeyValue(iSmoke, "StartSize", "10"); 
	DispatchKeyValue(iSmoke, "Rate", "100"); 
	DispatchKeyValue(iSmoke, "JetLength", "150"); 
	DispatchKeyValue(iSmoke, "Twist", "70"); 
	DispatchKeyValue(iSmoke, "rendercolor", "255 255 255"); 
	DispatchKeyValue(iSmoke, "RenderAmt", "255"); 
	DispatchKeyValue(iSmoke, "Angles", "0"); 
	AcceptEntityInput(iSmoke, "TurnOn");
	DispatchSpawn(iSmoke);
	TeleportEntity(iSmoke, center, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("OnUser1 !self:TurnOff::2.5:-1");
	SetVariantString("OnUser1 !self:kill::3.0:-1"); 
	AcceptEntityInput(iSmoke, "AddOutput");
	AcceptEntityInput(iSmoke, "FireUser1");
}

Lightning_EnergySplash(iClient) {
	new Float:center[3];
	GetClientAbsOrigin(iClient, center);
	new iTesla = CreateEntityByName("point_tesla");
	DispatchKeyValue(iTesla, "beamcount_min", "100");
	DispatchKeyValue(iTesla, "beamcount_max", "120");
	DispatchKeyValue(iTesla, "lifetime_min", "0.5");
	DispatchKeyValue(iTesla, "lifetime_max", "0.7");
	DispatchKeyValue(iTesla, "m_flRadius", "225.0");
	DispatchKeyValue(iTesla, "m_SoundName", "DoSpark");
	DispatchKeyValue(iTesla, "texture", "sprites/physbeam.vmt");
	DispatchKeyValue(iTesla, "m_Color", "255 255 255");
	DispatchKeyValue(iTesla, "thick_min", "1.0");  
	DispatchKeyValue(iTesla, "thick_max", "10.0");
	DispatchKeyValue(iTesla, "interval_min", "0.1"); 
	DispatchKeyValue(iTesla, "interval_max", "0.2"); 
	DispatchSpawn(iTesla);
	TeleportEntity(iTesla, center, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iTesla, "TurnOn"); 
	AcceptEntityInput(iTesla, "DoSpark");
	SetVariantString("OnUser1 !self:kill::0.1:1"); 
	AcceptEntityInput(iTesla, "AddOutput"); 
	AcceptEntityInput(iTesla, "FireUser1");
}