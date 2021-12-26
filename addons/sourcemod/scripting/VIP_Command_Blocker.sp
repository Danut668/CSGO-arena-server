#pragma semicolon 1
#pragma newdecls required

#define SUPPORT_ENGINE 1

#include <vip_core>
#if SUPPORT_ENGINE == 0
#include <csgo_colors>
#endif

KeyValues 	g_kvConfig;
int			g_iNotifyType;
Panel		g_hPanel;

public Plugin myinfo =
{
	name        = 	"[VIP] Command Blocker",
	author      = 	"FIVE (Discord: FIVE#3136) & Someone",
	version     = 	"1.0",
	url         = 	"Source: http://hlmod.ru | Support: https://discord.gg/ajW69wN"
};

public void OnPluginStart()
{
	LoadTranslations("vip_command_blocker.phrases");
	LoadConfig();
	RegAdminCmd("sm_vip_cb_reload", CMD_RELOAD, ADMFLAG_ROOT);
}

public Action CMD_RELOAD(int iClient, int iArgs)
{
	LoadConfig();
	#if SUPPORT_ENGINE == 1
	CGOPrintToChat(iClient, "%t", "RELOAD_Config");
	#else
	PrintToChat(iClient, "%t", "RELOAD_Config");
	#endif
}

public Action Check(int iClient, const char[] sCommand, int iArgc)
{
	if(iClient != 0 && !CheckCommand(iClient, sCommand))
	{
		PlayerNotify(iClient);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

void LoadConfig()
{
	if(g_kvConfig) delete g_kvConfig;
	g_kvConfig = new KeyValues("VIP_Command_Blocker");
	
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "data/vip/modules/vip_command_blocker.ini");
	if(!g_kvConfig.ImportFromFile(szBuffer)) SetFailState("Файл конфигурации не найден %s", szBuffer);
	g_kvConfig.Rewind();
	
	g_iNotifyType = g_kvConfig.GetNum("notify_type", 0);

	if(g_kvConfig.JumpToKey("commands"))
	{
		if (g_kvConfig.GotoFirstSubKey(false))
		{
			do
			{
				g_kvConfig.GetSectionName(szBuffer, sizeof szBuffer);
				AddCommandListener(Check, szBuffer); 
			} 
			while (g_kvConfig.GotoNextKey(false));
		}
	}

	g_hPanel = new Panel();
	FormatEx(szBuffer, sizeof(szBuffer),"%t\n \n", "MENU_Title");
	g_hPanel.SetTitle(szBuffer);
	FormatEx(szBuffer, sizeof(szBuffer),"%t\n \n\n \n", "MENU_Text");
	g_hPanel.DrawText(szBuffer);
	SetPanelCurrentKey(g_hPanel, 9);
	FormatEx(szBuffer, sizeof(szBuffer),"%t", "MENU_Exit");
	g_hPanel.DrawItem(szBuffer);
}

bool CheckCommand(int iClient, const char[] szCommand)
{
	static char szGroup[32];
	char szBuffer[1024], szSubBuffer[32][32];

	VIP_GetClientVIPGroup(iClient, szGroup, sizeof(szGroup)); 

	g_kvConfig.Rewind();

	g_kvConfig.JumpToKey("commands");

	g_kvConfig.GetString(szCommand, szBuffer, sizeof(szBuffer));
	
	int iSize = ExplodeString(szBuffer, ";", szSubBuffer, sizeof szSubBuffer, sizeof szSubBuffer[]);
		
	for(int i = 0; i < iSize; i++) 
	{
		TrimString(szSubBuffer[i]);
		if(!strcmp(szGroup, szSubBuffer[i])) return true;
	}
	
	return false;
}

void PlayerNotify(int iClient)
{
	switch(g_iNotifyType)
	{
		case 1:
		{
			#if SUPPORT_ENGINE == 1 
			CGOPrintToChat(iClient, "%t", "CHAT_BlockVIP");
			#else
			PrintToChat(iClient, "%t", "CHAT_BlockVIP");
			#endif
		}
		case 2:
		{
			g_hPanel.Send(iClient, view_as<MenuHandler>(OpenEmpty), 0);
		}
		case 3:
		{
			#if SUPPORT_ENGINE == 1 
			CGOPrintToChat(iClient, "%t", "CHAT_BlockVIP");
			#else
			PrintToChat(iClient, "%t", "CHAT_BlockVIP");
			#endif
			g_hPanel.Send(iClient, view_as<MenuHandler>(OpenEmpty), 0);
		}
	}
}

void OpenEmpty() {}

/*
bool CheckCommand(int iClient, const char[] szCommand)
{
    static char szBuffer[256];
    if(g_hTrie.GetString(szCommand, szBuffer, sizeof(szBuffer)))
    {
        static char szGroup[32];
        VIP_GetClientVIPGroup(iClient, szGroup, sizeof(szGroup));
    
        if(StrContains(szBuffer, szGroup) != -1)    return true;
    }
    return false;
}
*/