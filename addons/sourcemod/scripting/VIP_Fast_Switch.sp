#include <sdktools_functions>
#include <vip_core>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = 			"[VIP] Fast Switch",
	author = 		"Someone & KGB1st",
	version = 		"1.0",
	url = 			"http://www.hlmod.ru/"
};

public void OnPluginStart()
{
	HookEvent("weapon_fire", Event_WeaponFire);
	
	LoadTranslations("vip_modules.phrases");
	LoadTranslations("vip_core.phrases");
	
	if(VIP_IsVIPLoaded())
    {
        VIP_OnVIPLoaded();
    }
}

public int VIP_OnVIPLoaded()
{
	VIP_RegisterFeature("FastSwitch", BOOL, TOGGLABLE, _, OnDisplayItem);
}

public void OnPluginEnd()
{
	VIP_UnregisterFeature("FastSwitch");
}

public bool OnDisplayItem(int iClient, const char[] sFeatureName, char[] sDisplay, int iMaxLength)
{
	SetGlobalTransTarget(iClient);
	if(VIP_IsClientFeatureUse(iClient, "FastSwitch"))
	{
		FormatEx(sDisplay, iMaxLength, "%t [%t]", "FastSwitch", "ENABLED");
	}
	else	FormatEx(sDisplay, iMaxLength, "%t [%t]", "FastSwitch", "DISABLED");
	return true;
}

public void Event_WeaponFire(Event hEvent, const char[] sName, bool bDontBroadcast)
{	
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if(VIP_IsClientFeatureUse(iClient, "FastSwitch"))
	{
		int iRifle = GetPlayerWeaponSlot(iClient, 0);
		int iPistol = GetPlayerWeaponSlot(iClient, 1);
		
		int m_hActiveWeapon = GetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon");
		
		if(IsValidEdict(m_hActiveWeapon) && IsValidEdict(iRifle) && IsValidEdict(iPistol))
		{
			if((m_hActiveWeapon == iRifle) && (GetEntProp(iRifle, Prop_Data, "m_iClip1") <= 1) && (GetEntProp(iPistol, Prop_Data, "m_iClip1") > 0 ))
			{
				SetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon", iPistol);
				ChangeEdictState(iClient, FindDataMapInfo(iClient, "m_hActiveWeapon"));
			}
			
			if((m_hActiveWeapon == iPistol) && (GetEntProp(iPistol, Prop_Data, "m_iClip1") <= 1) && (GetEntProp(iRifle, Prop_Data, "m_iClip1") > 0 ))
			{
				SetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon", iRifle);
				ChangeEdictState(iClient, FindDataMapInfo(iClient, "m_hActiveWeapon"));
			}
		}
	}
}