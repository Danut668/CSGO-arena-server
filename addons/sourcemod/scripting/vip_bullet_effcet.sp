#pragma semicolon 1
#include <sdktools>
#include <sdkhooks>
#include <vip_core>
#pragma newdecls required

public Plugin myinfo = 
{
	name = "[ViP Core] Bullet Effect",
	author = "Nek.'a 2x2 | ggwp.site ",
	version = "1.0.8",
	url = "https://ggwp.site/"
};
static const char g_sFeature[] = "bullet_effect";

bool bEnable,
	g_bHide;

float
	fRadius,
	fThickMin,
	fThickMax,
	fLifetimeMin,
	fLifetimeMax,
	fIntervalMin,
	fIntervalMax;
	
Handle hColors,
	hColors2, 
	hBeamcCountMin, 
	hBeamcCountMax;

char sColors[18],
	sColors2[18],
	sBeamcCountMin[18],
	sBeamcCountMax[18];
	
int tesla;

public void OnPluginStart()
{
	ConVar cvar;
	cvar = CreateConVar("sm_vip_bullet_effect_enable", "1", "Включить/выключить плагин", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Enable);
	bEnable = cvar.BoolValue;
	cvar = CreateConVar("sm_vip_bullet_effect_hide", "1", "Включения видимости только своей команде", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Hide);
	g_bHide = cvar.BoolValue;
	cvar = CreateConVar("sm_vip_bullet_effect_radius", "15.0", "Радиус", _, true, 0.1);
	cvar.AddChangeHook(CVarChanged_Radius);
	fRadius = cvar.FloatValue;
	cvar = CreateConVar("sm_vip_bullet_effect_thickmin", "3.0", "минимальная тощена молнии", _, true, 0.1);
	cvar.AddChangeHook(CVarChanged_ThickMin);
	fThickMin = cvar.FloatValue;
	cvar = CreateConVar("sm_vip_bullet_effect_thickmax", "5.0", "максимальная тощена молнии", _, true, 0.1);
	cvar.AddChangeHook(CVarChanged_ThickMax);
	fThickMax = cvar.FloatValue;
	cvar = CreateConVar("sm_vip_bullet_effect_lifetimemin", "0.3", "Минимальное время жизни", _, true, 0.1);
	cvar.AddChangeHook(CVarChanged_LifetimeMin);
	fLifetimeMin = cvar.FloatValue;
	cvar = CreateConVar("sm_vip_bullet_effect_lifetimemax", "0.7", "Максимальное время жизни", _, true, 0.1);
	cvar.AddChangeHook(CVarChanged_LifetimeMax);
	fLifetimeMax = cvar.FloatValue;
	cvar = CreateConVar("sm_vip_bullet_effect_intervalmin", "0.1", "Интервал появления молний миниум", _, true, 0.1);
	cvar.AddChangeHook(CVarChanged_IntervalMin);
	fIntervalMin = cvar.FloatValue;
	cvar = CreateConVar("sm_vip_bullet_effect_intervalmax", "0.2", "Интервал появления молний максимум", _, true, 0.1);
	cvar.AddChangeHook(CVarChanged_IntervalMax);
	fIntervalMax = cvar.FloatValue;
	hColors = CreateConVar("sm_vip_bullet_effect_color", "45 211 0", "RGB Террористов");
	GetConVarString(hColors, sColors, sizeof(sColors));
	HookConVarChange(hColors, OnConVarChangesColor);
	hColors2 = CreateConVar("sm_vip_bullet_effect_color2", "0 0 255", "RGB Контр-Террористов");
	GetConVarString(hColors2, sColors2, sizeof(sColors2));
	HookConVarChange(hColors2, OnConVarChangesColor2);
	hBeamcCountMin = CreateConVar("sm_vip_bullet_effect_beamccountmin", "7", "Количество молний минимум");
	GetConVarString(hBeamcCountMin, sBeamcCountMin, sizeof(sBeamcCountMin));
	HookConVarChange(hBeamcCountMin, OnConVarChangesBeamcCountMin);
	hBeamcCountMax = CreateConVar("sm_vip_bullet_effect_beamccountmax", "10", "Количество молний максимум");
	GetConVarString(hBeamcCountMax, sBeamcCountMax, sizeof(sBeamcCountMax));
	HookConVarChange(hBeamcCountMax, OnConVarChangesBeamcCountMax);
	
	HookEvent("bullet_impact", Event_OnBulletImpact);
	
	AutoExecConfig(true, "bullet_effect", "vip");

	if(VIP_IsVIPLoaded()) VIP_OnVIPLoaded();
}
public void CVarChanged_Enable(ConVar cvar, const char[] oldValue, const char[] newValue){bEnable	= cvar.BoolValue;}
public void CVarChanged_Radius(ConVar cvar, const char[] oldValue, const char[] newValue){fRadius = cvar.FloatValue;}
public void CVarChanged_ThickMin(ConVar cvar, const char[] oldValue, const char[] newValue){fThickMin = cvar.FloatValue;}
public void CVarChanged_ThickMax(ConVar cvar, const char[] oldValue, const char[] newValue){fThickMax = cvar.FloatValue;}
public void CVarChanged_LifetimeMin(ConVar cvar, const char[] oldValue, const char[] newValue){fLifetimeMin = cvar.FloatValue;}
public void CVarChanged_LifetimeMax(ConVar cvar, const char[] oldValue, const char[] newValue){fLifetimeMax = cvar.FloatValue;}
public void CVarChanged_IntervalMin(ConVar cvar, const char[] oldValue, const char[] newValue){fIntervalMin = cvar.FloatValue;}
public void CVarChanged_IntervalMax(ConVar cvar, const char[] oldValue, const char[] newValue){fIntervalMax = cvar.FloatValue;}
public void CVarChanged_Hide(ConVar cvar, const char[] oldValue, const char[] newValue){g_bHide	= cvar.BoolValue;}
public void OnConVarChangesColor(ConVar cvar, const char[] oldVal, const char[] newValue){if(hColors) strcopy(sColors, sizeof(sColors), newValue);}
public void OnConVarChangesColor2(ConVar cvar, const char[] oldVal, const char[] newValue){if(hColors2) strcopy(sColors2, sizeof(sColors2), newValue);}
public void OnConVarChangesBeamcCountMin(ConVar cvar, const char[] oldVal, const char[] newValue){if(hBeamcCountMin) strcopy(sBeamcCountMin, sizeof(sBeamcCountMin), newValue);}
public void OnConVarChangesBeamcCountMax(ConVar cvar, const char[] oldVal, const char[] newValue){if(hBeamcCountMax) strcopy(sBeamcCountMax, sizeof(sBeamcCountMax), newValue);}

public void OnPluginEnd()
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
		VIP_UnregisterFeature(g_sFeature);
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL);
}

public void Event_OnBulletImpact(Handle hEvent, const char[] name, bool silent) 
{
	if(!bEnable)
		return;
	
	static bool t;
	static int client, ver;
	
	if(!(client = GetClientOfUserId(GetEventInt(hEvent, "userid"))) || !IsClientInGame(client)
	|| !VIP_IsClientVIP(client) || !VIP_IsClientFeatureUse(client, g_sFeature))
	return;

	t = GetClientTeam(client) == 2;
	ver = GetRandomInt(0, 2);

	float fVec[3] = 0.0;
	fVec[0] = GetEventFloat(hEvent, "x");
	fVec[1] = GetEventFloat(hEvent, "y");
	fVec[2] = GetEventFloat(hEvent, "z");
	
	
	switch(ver)
	{
		case 0:
		{
			if(t)
			{
				tesla = CreateEntityByName("point_tesla", -1);
				DispatchKeyValueFloat(tesla, "m_flRadius", fRadius);	//радиус
				DispatchKeyValue(tesla, "m_SoundName", "DoSpark");	//звук
				DispatchKeyValue(tesla, "beamcount_min", sBeamcCountMin);
				DispatchKeyValue(tesla, "beamcount_max", sBeamcCountMax);
				DispatchKeyValue(tesla, "texture", "sprites/physbeam.vmt");	//вмт
				DispatchKeyValue(tesla, "m_Color", sColors);
				DispatchKeyValueFloat(tesla, "thick_min", fThickMin);	//минимальная тощена молнии
				DispatchKeyValueFloat(tesla, "thick_max", fThickMax);	//максимальная тощена молнии
				DispatchKeyValueFloat(tesla, "lifetime_min", fLifetimeMin);	//Минимальное время жизни 
				DispatchKeyValueFloat(tesla, "lifetime_max", fLifetimeMax);	//Максимальное время жизни 
				DispatchKeyValueFloat(tesla, "interval_min", fIntervalMin);	//интервал миниум
				DispatchKeyValueFloat(tesla, "interval_max", fIntervalMax);	//интервал максимум
				if (!DispatchSpawn(tesla))
				{
					AcceptEntityInput(tesla, "Kill");
					LogError("Couldn't create tesla 'bullet_effect'");
				}
				TeleportEntity(tesla, fVec, NULL_VECTOR, NULL_VECTOR);	//телепорт на позицию(прицела)
				AcceptEntityInput(tesla, "TurnOn", -1, -1, 0);
				AcceptEntityInput(tesla, "DoSpark", -1, -1, 0);
				SetVariantString("OnUser1 !self:kill::2.0:-1");
				AcceptEntityInput(tesla, "AddOutput");
				AcceptEntityInput(tesla, "FireUser1");
				if(g_bHide) SDKHook(tesla, SDKHook_SetTransmit, OnTransmit);
			}
			else
			{
				tesla = CreateEntityByName("point_tesla", -1);
				DispatchKeyValueFloat(tesla, "m_flRadius", fRadius);	//радиус
				DispatchKeyValue(tesla, "m_SoundName", "DoSpark");	//звук
				DispatchKeyValue(tesla, "beamcount_min", sBeamcCountMin);
				DispatchKeyValue(tesla, "beamcount_max", sBeamcCountMax);
				DispatchKeyValue(tesla, "texture", "sprites/physbeam.vmt");	//вмт 	
				DispatchKeyValue(tesla, "m_Color", sColors2);
				DispatchKeyValueFloat(tesla, "thick_min", fThickMin);	//минимальная тощена молнии
				DispatchKeyValueFloat(tesla, "thick_max", fThickMax);	//максимальная тощена молнии
				DispatchKeyValueFloat(tesla, "lifetime_min", fLifetimeMin);	//Минимальное время жизни 
				DispatchKeyValueFloat(tesla, "lifetime_max", fLifetimeMax);	//Максимальное время жизни 
				DispatchKeyValueFloat(tesla, "interval_min", fIntervalMin);	//интервал миниум
				DispatchKeyValueFloat(tesla, "interval_max", fIntervalMax);	//интервал максимум
				if (!DispatchSpawn(tesla))
				{
					AcceptEntityInput(tesla, "Kill");
					LogError("Couldn't create tesla 'bullet_effect'");
				}
				TeleportEntity(tesla, fVec, NULL_VECTOR, NULL_VECTOR);	//телепорт на позицию(прицела)
				AcceptEntityInput(tesla, "TurnOn", -1, -1, 0);
				AcceptEntityInput(tesla, "DoSpark", -1, -1, 0);
				SetVariantString("OnUser1 !self:kill::2.0:-1");
				AcceptEntityInput(tesla, "AddOutput"); 
				AcceptEntityInput(tesla, "FireUser1");
				if(g_bHide) SDKHook(tesla, SDKHook_SetTransmit, OnTransmit);
			}
		}
		case 1:
		{
			if(t)
			{
				tesla = CreateEntityByName("point_tesla", -1);
				DispatchKeyValueFloat(tesla, "m_flRadius", fRadius);	//радиус
				DispatchKeyValue(tesla, "m_SoundName", "DoSpark");	//звук
				DispatchKeyValue(tesla, "beamcount_min", sBeamcCountMin);
				DispatchKeyValue(tesla, "beamcount_max", sBeamcCountMax);
				DispatchKeyValue(tesla, "texture", "sprites/physbeam.vmt");	//вмт 	
				DispatchKeyValue(tesla, "m_Color", sColors);
				DispatchKeyValueFloat(tesla, "thick_min", fThickMin);	//минимальная тощена молнии
				DispatchKeyValueFloat(tesla, "thick_max", fThickMax);	//максимальная тощена молнии
				DispatchKeyValueFloat(tesla, "lifetime_min", fLifetimeMin);	//Минимальное время жизни 
				DispatchKeyValueFloat(tesla, "lifetime_max", fLifetimeMax);	//Максимальное время жизни 
				DispatchKeyValueFloat(tesla, "interval_min", fIntervalMin);	//интервал миниум
				DispatchKeyValueFloat(tesla, "interval_max", fIntervalMax);	//интервал максимум
				if (!DispatchSpawn(tesla))
				{
					AcceptEntityInput(tesla, "Kill");
					LogError("Couldn't create tesla 'bullet_effect'");
					//return -1;
				}
				TeleportEntity(tesla, fVec, NULL_VECTOR, NULL_VECTOR);	//телепорт на позицию(прицела)
				AcceptEntityInput(tesla, "TurnOn", -1, -1, 0);
				AcceptEntityInput(tesla, "DoSpark", -1, -1, 0);
				SetVariantString("OnUser1 !self:kill::2.0:-1");
				AcceptEntityInput(tesla, "AddOutput"); 
				AcceptEntityInput(tesla, "FireUser1");
				if(g_bHide) SDKHook(tesla, SDKHook_SetTransmit, OnTransmit);
			}
			else
			{
				tesla = CreateEntityByName("point_tesla", -1);
				DispatchKeyValueFloat(tesla, "m_flRadius", fRadius);	//радиус
				DispatchKeyValue(tesla, "m_SoundName", "DoSpark");	//звук
				DispatchKeyValue(tesla, "beamcount_min", sBeamcCountMin);
				DispatchKeyValue(tesla, "beamcount_max", sBeamcCountMax);
				DispatchKeyValue(tesla, "texture", "sprites/physbeam.vmt");	//вмт 	
				DispatchKeyValue(tesla, "m_Color", sColors2);
				DispatchKeyValueFloat(tesla, "thick_min", fThickMin);	//минимальная тощена молнии
				DispatchKeyValueFloat(tesla, "thick_max", fThickMax);	//максимальная тощена молнии
				DispatchKeyValueFloat(tesla, "lifetime_min", fLifetimeMin);	//Минимальное время жизни 
				DispatchKeyValueFloat(tesla, "lifetime_max", fLifetimeMax);	//Максимальное время жизни 
				DispatchKeyValueFloat(tesla, "interval_min", fIntervalMin);	//интервал миниум
				DispatchKeyValueFloat(tesla, "interval_max", fIntervalMax);	//интервал максимум
				if (!DispatchSpawn(tesla))
				{
					AcceptEntityInput(tesla, "Kill");
					LogError("Couldn't create tesla 'bullet_effect'");
					//return -1;
				}
				TeleportEntity(tesla, fVec, NULL_VECTOR, NULL_VECTOR);	//телепорт на позицию(прицела)
				AcceptEntityInput(tesla, "TurnOn", -1, -1, 0);
				AcceptEntityInput(tesla, "DoSpark", -1, -1, 0);
				SetVariantString("OnUser1 !self:kill::2.0:-1");
				AcceptEntityInput(tesla, "AddOutput"); 
				AcceptEntityInput(tesla, "FireUser1");
				if(g_bHide) SDKHook(tesla, SDKHook_SetTransmit, OnTransmit);
			}
		}
	}
}

public Action OnTransmit(int iEntity, int iClient)
{
	if (tesla == iEntity)
	{
		return Plugin_Continue;
	}

	static int iOwner, iTeam;

	if ((iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity")) > 0 &&
		(iTeam = GetClientTeam(iClient)) > 1
		&& GetClientTeam(iOwner) != iTeam)
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
