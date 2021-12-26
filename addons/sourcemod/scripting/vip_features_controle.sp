
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <vip_core>
#include <topmenus>
#include <adminmenu>

public Plugin myinfo =
{
	name		= "[VIP] Features Controle",
	author	  	= "ღ λŌK0ЌЭŦ ღ ™",
	description = "",
	version	 	= "1.0.2",
	url			= "iLoco#7631"
};

char gPath[256];
KeyValues kv;
ArrayList arFeatures;
TopMenu gTopMenu;

StringMap iDefFeaturesToggles[MAXPLAYERS+1];
StringMap iDefFeaturesValues[MAXPLAYERS+1];

#include "vip_feature_controle\adminmenu.sp"
#include "vip_feature_controle\menu.sp"
// #include "vip_feature_controle\menu_toggle_players.sp"
// #include "vip_feature_controle\menu_maps.sp"

public void OnPluginStart()
{
	BuildPath(Path_SM, gPath, sizeof(gPath), "data/vip/modules/features_controle.ini");
	LoadCfg();
	RegAdminCmd("sm_vip_features_controle", CMD_Menu, ADMFLAG_RCON);

	LoadTranslations("vip_modules.phrases");

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();

		for(int i = 1; i <= MaxClients; i++) if(IsClientAuthorized(i) && IsClientInGame(i) && !IsFakeClient(i) && VIP_IsClientVIP(i))
			VIP_OnVIPClientLoaded(i);
	}

	HookEvent("player_disconnect", Event_OnClientDisconnect);
}

public Action Event_OnClientDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(iDefFeaturesToggles[client])
		delete iDefFeaturesToggles[client];
	if(iKv[client])
		delete iKv[client];
}

public void VIP_OnVIPLoaded()
{
	TopMenu topmenu;
	if(LibraryExists("adminmenu") &&((topmenu = GetAdminTopMenu()) != null))
		OnAdminMenuReady(topmenu);

	if(arFeatures)
		delete arFeatures;
	arFeatures = new ArrayList(64);

	VIP_FillArrayByFeatures(arFeatures);
}
	

public Action CMD_Menu(int client, int args)
{
	if(client && arFeatures)
		Menu_Main(client).Display(client, 0);
		
	return Plugin_Continue;
}

public void VIP_OnFeatureRegistered(const char[] szFeature)
{
	if(arFeatures)
		delete arFeatures;
	arFeatures = new ArrayList(64);

	VIP_FillArrayByFeatures(arFeatures);
}

public void VIP_OnVIPClientRemoved(int client, const char[] szReason, int iAdmin)
{
	if(JumpToClient(client) && kv.GetNum("delete on left"))
		kv.DeleteThis();

	if(iDefFeaturesToggles[client])
		delete iDefFeaturesToggles[client];
}

public void VIP_OnVIPClientLoaded(int client)
{
	if(iDefFeaturesToggles[client])
		delete iDefFeaturesToggles[client];
	iDefFeaturesToggles[client] = new StringMap();

	char feature[64];
	for(int p; p < arFeatures.Length; p++)
	{
		arFeatures.GetString(p, feature, sizeof(feature));

		iDefFeaturesToggles[client].SetValue(feature, VIP_GetClientFeatureStatus(client, feature))
	}

	if(JumpToClient(client) && kv.GotoFirstSubKey(false))
	{
		do
		{
			kv.GetSectionName(feature, sizeof(feature))

			if(!VIP_IsValidFeature(feature) || kv.GetNum(NULL_STRING))
				continue;
			
			VIP_SetClientFeatureStatus(client, feature, NO_ACCESS);
		}
		while(kv.GotoNextKey(false));
	}
}

public void VIP_OnVIPClientAdded(int client, int iAdmin)
{
	VIP_OnVIPClientLoaded(client);
}

stock void LoadCfg()
{
	if(kv)
		delete kv;
	
	kv = new KeyValues("Features Controle");
	kv.ImportFromFile(gPath);
}

stock bool GetDeleteDataOnVipLeft(int target, char[] key = "")
{
	if(JumpToClient(target, false, key) && kv.GetNum("delete on left", 1))
		return false;

	return true;
}

stock bool JumpToClient(int client, bool create = false, char[] key = "")
{
	kv.Rewind();
	char buff[64];
	GetClientAuthId(client, AuthId_Steam2, buff, sizeof(buff));
	if(kv.JumpToKey(buff, create) && (!key[0] || key[0] && kv.JumpToKey(key, true)))
		return true;

	return false
}

stock bool IsValidClient(int client)
{
	if(IsClientAuthorized(client) && IsClientInGame(client) && !IsFakeClient(client) && VIP_IsClientVIP(client))
		return true;

	return false;
}

stock void SaveThisFile()
{
	kv.Rewind();
	kv.ExportToFile(gPath);
}