#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <vip_core>

enum GameMode(+=1)
{
	Game_CSS = 0,
	Game_DoDS,
	Game_TF2,
	Game_CSGO
};

new GameMode:gM_Game;

public Plugin myinfo =
{
    name = "[VIP] Reset Score/Death",
    description = "Allows only VIP player to reset kills or deaths.",
    author = "FIVE",
    version = "1.3.2",
    url = "https://hlmod.ru/"
};

#define VIP_ResetSD				"Reset_SD"
ConVar g_hCvar;
int g_iEnable;

public void OnPluginStart()
{
    LoadTranslations("vip_resetsd.phrases");

    g_hCvar = CreateConVar("sm_vip_resetsd_mode","3","0 - disabled, 1 - only reset deaths, 2 - only reset counts, 3 - all.", _, true, 0.0, true, 3.0);
    HookConVarChange(g_hCvar, Update_CV);

    SwitchCvar(g_hCvar);

    RegConsoleCmd("sm_rd", Command_RD, "Resets deaths to a VIP player");
    RegConsoleCmd("sm_reset", Command_RS, "Resets the VIP account to the player");


    if(VIP_IsVIPLoaded())
    {
        VIP_OnVIPLoaded();
    }
    
    decl String:Mod[16];
    GetGameFolderName(Mod, 16);
    
	if(StrContains(Mod, "cstrike", false) != -1)
	{
		gM_Game = Game_CSS;
	}
	else if(StrContains(Mod, "dod", false) != -1)
	{
		gM_Game = Game_DoDS;
	}
	else if(StrEqual(Mod, "csgo", false))
	{
		gM_Game = Game_CSGO;
	}
	else if(StrEqual(Mod, "tf", false))
	{
		gM_Game = Game_TF2;
	}
	
	AutoExecConfig(true, "VIP_ResetSD" ,"vip");
}

public void Update_CV(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
    SwitchCvar(hCvar);
}

public void SwitchCvar(ConVar hCvar)
{
    g_iEnable = hCvar.IntValue;
}

public void VIP_OnVIPLoaded()
{
    VIP_RegisterFeature(VIP_ResetSD, INT, HIDE);
}

public void OnPluginEnd()
{
    if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
    {
        VIP_UnregisterFeature(VIP_ResetSD);
    }
}

public Action:Command_RD(int iClient, args)
{
    if(g_iEnable == 0 || g_iEnable == 2)
	{
		return Plugin_Handled;
	}    

    if(!VIP_IsClientVIP(iClient))
    {
        PrintToChat(iClient, "\x04%t\x03", "Access_VIP");
        return Plugin_Handled;
    }

    if(VIP_IsClientFeatureUse(iClient, VIP_ResetSD))
    {
        int iSet = VIP_GetClientFeatureInt(iClient, VIP_ResetSD);

        if(iSet != 1 && iSet != 3)
        {
            PrintToChat(iClient, "\x04%t\x03", "Access_Function");
            return Plugin_Handled;
        }
    }
    else
    {
        PrintToChat(iClient, "\x04%t\x03", "Access_Function");
        return Plugin_Handled;
    }
            
    if(GetClientDeaths(iClient) == 0)
    {
        PrintToChat(iClient, "\x04%t\x03", "Zero_Death");
        return Plugin_Handled;
    }
    switch(gM_Game)
	{
		case Game_CSS, Game_DoDS:
		{
			SetEntProp(iClient, Prop_Data, "m_iDeaths", 0);
		}
		
		case Game_CSGO:
		{
			SetEntProp(iClient, Prop_Data, "m_iDeaths", 0);
		}
		
		case Game_TF2:
		{
			SetEntProp(iClient, Prop_Send, "m_iDeaths", 0);
		}
	}

    ReplyToCommand(iClient, "\x04%t\x03", "Success_Death");
    return Plugin_Handled;
}

public Action:Command_RS(int iClient, args)
{
    if(g_iEnable == 0 || g_iEnable == 1)
	{
		return Plugin_Handled;
	}

    if(!VIP_IsClientVIP(iClient))
    {
        PrintToChat(iClient, "\x04%t\x03", "Access_VIP");
        return Plugin_Handled;
    }

    if(VIP_IsClientFeatureUse(iClient, VIP_ResetSD))
    {
        int iSet = VIP_GetClientFeatureInt(iClient, VIP_ResetSD);
        if(iSet < 2)
        {
            PrintToChat(iClient, "\x04%t\x03", "Access_Function");
            return Plugin_Handled;
        }
    }
    else
    {
        PrintToChat(iClient, "\x04%t\x03", "Access_Function");
        return Plugin_Handled;
    }

    if(GetClientDeaths(iClient) == 0 && GetClientFrags(iClient) == 0)
    {
        PrintToChat(iClient, "\x04%t\x03", "Zero_Score");
        return Plugin_Handled;
    }
    else
    {
	switch(gM_Game)
	{
		case Game_CSS, Game_DoDS:
		{
			SetEntProp(iClient, Prop_Data, "m_iFrags", 0);
			SetEntProp(iClient, Prop_Data, "m_iDeaths", 0);
		}
		
		case Game_CSGO:
		{
			CS_SetClientContributionScore(iClient, 0);
			CS_SetClientAssists(iClient, 0);
			SetEntProp(iClient, Prop_Data, "m_iFrags", 0);
			SetEntProp(iClient, Prop_Data, "m_iDeaths", 0);
			CS_SetMVPCount(iClient, 0);
		}
		
		case Game_TF2:
		{
			SetEntProp(iClient, Prop_Data, "m_iAssists", 0);
			SetEntProp(iClient, Prop_Send, "m_iFrags", 0);
			SetEntProp(iClient, Prop_Send, "m_iDeaths", 0);
		}
	}
	}


    ReplyToCommand(iClient, "\x04%t\x03", "Success_Score");
    
    return Plugin_Handled;
}
stock bool:IsValidClient(client, bool:alive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)));
}