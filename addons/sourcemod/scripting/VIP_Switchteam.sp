#include <cstrike>
#include <vip_core>


#pragma semicolon 1

#define VIP_Switchteam "Switchteam"

public Plugin:myinfo = 
{
	name = "[VIP] Switchteam",
	author = "Dreizehnt",
	version = "1.0"
};
public void OnPluginStart()
{
	AddCommandListener(Command_CheckJoin, "jointeam");
	
	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(VIP_Switchteam, BOOL);
}

public Action Command_CheckJoin(int client, const char[] command, int args)
{
	if(client && VIP_IsClientVIP(client) && VIP_IsClientFeatureUse(client, VIP_Switchteam) && IsPlayerAlive(client))
	{
		char team[4];
		GetCmdArg(1, team, sizeof(team));		
		CS_SwitchTeam(client, StringToInt(team));		
	}
}

public void OnPluginEnd()
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_Switchteam") == FeatureStatus_Available)
    {
		VIP_UnregisterFeature(VIP_Switchteam);
	}
}