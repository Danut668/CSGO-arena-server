#include <sourcemod>
// #include <materialadmin>
#include <AS_Colors>

#pragma newdecls required;
#pragma semicolon 1;

int g_iCountL[MAXPLAYERS+1], g_iCountD[MAXPLAYERS+1], g_iAdminId[MAXPLAYERS+1];
bool g_IsAvaliable[MAXPLAYERS+1][5];
char g_sAuthID[MAXPLAYERS+1][32];
char g_sContact[MAXPLAYERS+1][32];
Database g_hDatabase = null;

ConVar g_cvFlag, g_cvImmunity, g_cvGroup, g_cvContactLen, g_cvMessageLen;

#define LikeAccess(%0)	g_IsAvaliable[%0][0]
#define DisAccess(%0)	g_IsAvaliable[%0][1]
#define HasDb(%0)		g_IsAvaliable[%0][2]
#define IsChange(%0)	g_IsAvaliable[%0][3]
#define IsMessage(%0)	g_IsAvaliable[%0][4]

public Plugin myinfo =
{
	name = "Simple Admins List",
	author = "SN(Kaneki)",
	version = "9/11/2019"
};

public void OnPluginStart()
{
	g_cvFlag 		= CreateConVar("sm_admins_flag", "a", "The flag allowing the admin is in the menu");
	g_cvImmunity 	= CreateConVar("sm_admins_immunity", "1", "Show immunity? 1/0");
	g_cvGroup 		= CreateConVar("sm_admins_group", "1", "Show groups? 1/0");
	g_cvContactLen	= CreateConVar("sm_admins_contactlen", "20", "The length of contact string.");
	g_cvMessageLen	= CreateConVar("sm_admins_messagelen", "50", "The length of message string.");

	Database.Connect(Database_Callback, "admins");
	RegConsoleCmd("sm_admins", Command_Admins);

	AutoExecConfig(true, "plugin.admins");
	LoadTranslations("plugin.admins.phrases");
}

public void Database_Callback(Database hDB, const char[] sError, any data)
{
	if(SQL_CheckConfig("admins"))
	{
		if(!hDB){
			LogError("[Admins] - Could not connect to the database MySQL(%s)", sError);
			return;
		}
	}

	else
	{
		char sSQLError[215];
		hDB = SQLite_UseDatabase("admins_info", sSQLError, sizeof(sSQLError));
		if(!hDB)
		{
			LogError("[Admins] - Could not connect to the database SQLite (%s)", sSQLError);
			return;
		}
	}
	
	char sIdent[16];
	
	g_hDatabase = hDB;
	g_hDatabase.SetCharset("utf8");
	
	DBDriver hDatabaseDriver = g_hDatabase.Driver;
	hDatabaseDriver.GetIdentifier(sIdent, sizeof(sIdent));
	
	if(sIdent[0] == 's')
	{
		g_hDatabase.Query(DB_GlobalCallback, "CREATE TABLE IF NOT EXISTS `admins` (\
											   `id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,\
											   `auth` VARCHAR(32) NOT NULL,\
											   `contact` VARCHAR(32) NOT NULL,\
											   `likes` INTEGER NOT NULL default '0',\
											   `dislikes` INTEGER NOT NULL default '0');");
											   
		g_hDatabase.Query(DB_GlobalCallback, "CREATE TABLE IF NOT EXISTS `users` (\
											   `id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,\
											   `user` VARCHAR(32) NOT NULL,\
											   `admin` VARCHAR(32) NOT NULL default '0',\
											   `isput` INTEGER NOT NULL);");	// if 0 - dislike, if 1 - like
	}
	else if(sIdent[0] == 'm')
	{		
		g_hDatabase.Query(DB_GlobalCallback, "CREATE TABLE IF NOT EXISTS `admins` (" ...
											   "`id` INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT," ...
											   "`auth` VARCHAR(32) NOT NULL," ...
											   "`contact` VARCHAR(32)," ...
											   "`likes` INTEGER NOT NULL default '0'," ...
											   "`dislikes` INTEGER NOT NULL default '0') ENGINE=InnoDB CHARSET=utf8 COLLATE utf8_general_ci;");
											   
		g_hDatabase.Query(DB_GlobalCallback, "CREATE TABLE IF NOT EXISTS `users` (" ...
											   "`id` INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT," ...
											   "`user` VARCHAR(32) NOT NULL," ...
											   "`admin` VARCHAR(32) NOT NULL default '0'," ...
											   "`isput` INTEGER NOT NULL) ENGINE=InnoDB CHARSET=utf8 COLLATE utf8_general_ci;");
	}
}

stock bool IsValidClient(int iClient, bool bAllowBots = false, bool bAllowDead = true)
{
    if (!(1 <= iClient <= MaxClients) || !IsClientInGame(iClient) || (IsFakeClient(iClient) && !bAllowBots) || IsClientSourceTV(iClient) || IsClientReplay(iClient) || (!bAllowDead && !IsPlayerAlive(iClient)))
    {
        return false;
    }
    return true;
} 

stock bool CheckAdminFlags(int iClient, int iFlag)
{
	int iUserFlags = GetUserFlagBits(iClient);
	return (iUserFlags & ADMFLAG_ROOT || (iUserFlags & iFlag) == iFlag);
}

public void OnClientPostAdminCheck(int iClient)
{
	if(!IsFakeClient(iClient))
	{
		char sBuffer[8];
		g_cvFlag.GetString(sBuffer, sizeof(sBuffer));
		GetClientAuthId(iClient, AuthId_Engine, g_sAuthID[iClient], sizeof(g_sAuthID));
		if(CheckAdminFlags(iClient, ReadFlagString(sBuffer)))
		{
			char szQuery[128];
			g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT `id` FROM `admins` WHERE `auth` = '%s';", g_sAuthID[iClient]);
			g_hDatabase.Query(DB_GetAuthCallback, szQuery, GetClientUserId(iClient));
		}
	}
}

public Action OnClientSayCommand(int iClient, const char[] szCommand, const char[] sArgs)
{
	SetGlobalTransTarget(iClient);
	
	if(IsChange(iClient))
	{
		if(StrEqual(sArgs, "cancel"))
		{
			IsChange(iClient) = false;
			A_PrintToChat(iClient, "%t", "ChatCancel");
			return Plugin_Handled;
		}
		else
		{
			if(strlen(sArgs) < GetConVarInt(g_cvContactLen))
			{
				char szQuery[256];
				g_hDatabase.Format(szQuery, sizeof(szQuery), "UPDATE `admins` SET `contact` = '%s' WHERE `auth` = '%s';", sArgs, g_sAuthID[iClient]);
				g_hDatabase.Query(SetContactCallBack, szQuery, GetClientUserId(iClient));
				IsChange(iClient) = false;
				return Plugin_Handled;
			}
			else
			{
				A_PrintToChat(iClient, "%t", "ChatLongText");
				return Plugin_Handled;
			}
		}
	}

	else if(IsMessage(iClient))
	{
		if(StrEqual(sArgs, "cancel"))
		{
			IsMessage(iClient) = false;
			A_PrintToChat(iClient, "%t", "ChatCancel");
			return Plugin_Handled;
		}
		else{
			if(strlen(sArgs) >= GetConVarInt(g_cvMessageLen)){
				A_PrintToChat(iClient, "%t", "ChatLongText");
				return Plugin_Handled;
			}
			else{
				if(IsValidClient(g_iAdminId[iClient])){
					ClientCommand(g_iAdminId[iClient], "playgamesound buttons/blip2.wav");
					A_PrintToChat(g_iAdminId[iClient], "%t", "ChatSendMessage", iClient, sArgs);
					A_PrintToChat(iClient, "%t", "ChatGotMessage", g_iAdminId[iClient]);
					IsMessage(iClient) = false;
					return Plugin_Handled;
				}
				else{
					A_PrintToChat(iClient, "%t", "ChatPlayerIsNotInGame");
					IsMessage(iClient) = false;
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}

void GetContact(int iClient)
{
	char sQuery[128];
	g_hDatabase.Format(sQuery, sizeof(sQuery), "SELECT `contact` FROM `admins` WHERE `auth` = '%s';", g_sAuthID[iClient]);
	g_hDatabase.Query(DB_GetContactCallBack, sQuery, GetClientUserId(iClient), DBPrio_High);
}

void GetAccess(int iUser, int iAdmin)
{	
	char sQuery[128];
	g_hDatabase.Format(sQuery, sizeof(sQuery), "SELECT `isput` FROM `users` WHERE `admin` = '%s' and `user` = '%s';", g_sAuthID[iAdmin], g_sAuthID[iUser]);
	g_hDatabase.Query(DB_GetAccessCallBack, sQuery, GetClientUserId(iUser), DBPrio_High);
}

void SetReputation(int iUser, int iAdmin, int iType)
{
	if(HasDb(iUser))
	{
		DataPack hPack = new DataPack();
		hPack.WriteCell(iType);
		hPack.WriteCell(GetClientUserId(iUser));
		if(iType)
		{
			Transaction hTransaction = new Transaction();

			char sQuery_First[128], sQuery_Second[128];
			if(g_iCountD[iAdmin]) g_hDatabase.Format(sQuery_First, sizeof(sQuery_First), "UPDATE `admins` SET `likes` = `likes` + 1, `dislikes` = `dislikes` - 1 WHERE `auth` = '%s';", g_sAuthID[iAdmin]);
			else g_hDatabase.Format(sQuery_First, sizeof(sQuery_First), "UPDATE `admins` SET `likes` = `likes` + 1 WHERE `auth` = '%s';", g_sAuthID[iAdmin]);
			g_hDatabase.Format(sQuery_Second, sizeof(sQuery_Second), "UPDATE `users` SET `isput` = 1 WHERE `user` = '%s' and `admin` = '%s';", g_sAuthID[iUser], g_sAuthID[iAdmin]);
			hTransaction.AddQuery(sQuery_First);
			hTransaction.AddQuery(sQuery_Second);
			g_hDatabase.Execute(hTransaction, TransactionSuccess_Callback, TransactionError_Callback, hPack);
		}
		else
		{
			Transaction hTransaction = new Transaction();
			
			char sQuery_First[128], sQuery_Second[128];
			if(g_iCountL[iAdmin]) g_hDatabase.Format(sQuery_First, sizeof(sQuery_First), "UPDATE `admins` SET `likes` = `likes` - 1, `dislikes` = `dislikes` + 1 WHERE `auth` = '%s';", g_sAuthID[iAdmin]);
			else g_hDatabase.Format(sQuery_First, sizeof(sQuery_First), "UPDATE `admins` SET `dislikes` = `dislikes` + 1 WHERE `auth` = '%s';", g_sAuthID[iAdmin]);
			g_hDatabase.Format(sQuery_Second, sizeof(sQuery_Second), "UPDATE `users` SET `isput` = 0 WHERE `user` = '%s' and `admin` = '%s';", g_sAuthID[iUser], g_sAuthID[iAdmin]);
			hTransaction.AddQuery(sQuery_First);
			hTransaction.AddQuery(sQuery_Second);
			g_hDatabase.Execute(hTransaction, TransactionSuccess_Callback, TransactionError_Callback, hPack);
		}
	}
	else
	{
		if(iType)
		{
			char sQuery[128];
			g_hDatabase.Format(sQuery, sizeof(sQuery), "INSERT INTO `users` (`user`, `admin`, `isput`) VALUES ('%s', '%s', 1);", g_sAuthID[iUser], g_sAuthID[iAdmin]);
			g_hDatabase.Query(DB_GlobalCallback, sQuery);
			HasDb(iUser) = true;
			SetReputation(iUser, iAdmin, 1);
		}
		else
		{
			char sQuery[128];
			g_hDatabase.Format(sQuery, sizeof(sQuery), "INSERT INTO `users` (`user`, `admin`, `isput`) VALUES ('%s', '%s', 0);", g_sAuthID[iUser], g_sAuthID[iAdmin]);
			g_hDatabase.Query(DB_GlobalCallback, sQuery);
			HasDb(iUser) = true;
			SetReputation(iUser, iAdmin, 0);
		}
	}
}

void GetCountVotes(int iAdmin)
{
	char sQuery[128];
	g_hDatabase.Format(sQuery, sizeof(sQuery), "SELECT `likes`, `dislikes` FROM `admins` WHERE `auth` = '%s';", g_sAuthID[iAdmin]);
	g_hDatabase.Query(DB_GetCountVotesCallback, sQuery, GetClientUserId(iAdmin), DBPrio_High);
}

public void DB_GetAccessCallBack(Database hDatabase, DBResultSet hResults, const char[] szError, int iClient)
{
	if(szError[0])
	{
		LogError("[Admins] DB_GetAccessCallBack: %s", szError);
		return;
	}

	iClient = GetClientOfUserId(iClient);

	if(hResults.FetchRow())
	{
		int iType = hResults.FetchInt(0);
		HasDb(iClient) = true;
		if(iType == 0){
			LikeAccess(iClient) = true;
			DisAccess(iClient) = false;
		}
		else if(iType == 1){
			DisAccess(iClient) = true;
			LikeAccess(iClient) = false;
		}
	}
	else
	{
		DisAccess(iClient) = true;
		LikeAccess(iClient) = true;
		HasDb(iClient) = false;
	}
}

public void DB_GetContactCallBack(Database hDatabase, DBResultSet hResults, const char[] szError, int iClient)
{
	if(szError[0])
	{
		LogError("[Admins] DB_GetContactCallBack: %s", szError);
		return;
	}

	iClient = GetClientOfUserId(iClient);

	if(hResults.FetchRow())	hResults.FetchString(0, g_sContact[iClient], sizeof(g_sContact));
}

public void SetContactCallBack(Database hDatabase, DBResultSet hResults, const char[] szError, int iClient)
{
	iClient = GetClientOfUserId(iClient);
	if(!iClient) return;

	if(szError[0])
	{
		LogError("[Admins] DB_SetContactCallBack: %s", szError);
		A_PrintToChat(iClient, "%t", "ContactChangeFailure");
		return;
	} 
	SetGlobalTransTarget(iClient);
	A_PrintToChat(iClient, "%t", "ContactHasChanged");
}

public void DB_GetCountVotesCallback(Database hDatabase, DBResultSet hResults, const char[] szError, any data)
{
	if(szError[0])
	{
		LogError("[Admins] DB_GetCountVotesCallback: %s", szError);
		return;
	}

	int iClient = GetClientOfUserId(data);
	if(!iClient) return;

	if(hResults.FetchRow())
	{
		g_iCountL[iClient] = hResults.FetchInt(0); 
		g_iCountD[iClient] = hResults.FetchInt(1);
	}
	else
	{
		LogError("[Admins] Error! I cant get results from GetVotes callback! Check your db..");
	}
}

public void DB_GlobalCallback(Database hDatabase, DBResultSet hResults, const char[] szError, any data)
{
	if(szError[0])
	{
		LogError("[Admins] DB_GlobalCallback: %s", szError);
		return;
	}
}

public void TransactionError_Callback(Database hDatabase, DataPack hPack, int numQueries, const char[] szError, int failIndex, any[] queryData)
{
	if(szError[0])
	{
		LogError("[Admins] Transaction Error: %s", szError);
		return;
	}
	delete hPack;
}

public void TransactionSuccess_Callback(Database hDatabase, DataPack hPack, int numQueries, Handle[] results, any[] queryData)
{
	hPack.Reset();
	int iType = hPack.ReadCell();
	int iClient = GetClientOfUserId(hPack.ReadCell());
	if(!iClient) return;

	SetGlobalTransTarget(iClient);

	if(iType) A_PrintToChat(iClient, "%t", "ChatVoteLike");
	else A_PrintToChat(iClient, "%t", "ChatVoteDis");
	delete hPack;
}

public void DB_GetAuthCallback(Database hDatabase, DBResultSet hResults, const char[] szError, any data)
{
	if(szError[0])
	{
		LogError("[Admins] DB_GetAuthCallback: %s", szError);
		return;
	}

	int iClient = GetClientOfUserId(data);

	if(!iClient) return;

	if(!hResults.FetchRow())
	{
		char sQuery[128];
		g_hDatabase.Format(sQuery, sizeof(sQuery), "INSERT INTO `admins` (`auth`, `contact`, `likes`, `dislikes`) VALUES ('%s', NULL, 0, 0);", g_sAuthID[iClient]);
		g_hDatabase.Query(DB_GlobalCallback, sQuery);
	}
}

public Action Command_Admins(int iClient, int iArgs)
{
	SetGlobalTransTarget(iClient);
	Menu hMenu = new Menu(CMD_MenuHandler);
	
	hMenu.SetTitle("%t", "MainMenu_Title");
	int iCount = 0;
	char sName[32], iUser[16], sBuffer[32];
	g_cvFlag.GetString(sBuffer, sizeof(sBuffer));

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && CheckAdminFlags(i, ReadFlagString(sBuffer)))
		{
			IntToString(GetClientUserId(i), iUser, sizeof(iUser));
			GetClientName(i, sName, sizeof(sName));
			hMenu.AddItem(iUser, sName);		
			iCount++;

			GetCountVotes(i);
			GetContact(i);
		}
	}
	if(iCount) DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
	else{
		delete hMenu;
		A_PrintToChat(iClient, "%t", "ChatListIsEmpty");
	}

	return Plugin_Handled;
}

public int CMD_MenuHandler(Menu hMenu, MenuAction action, int iClient, int iItem)
{    
	switch(action)
	{
		case MenuAction_Select:
		{
			SetGlobalTransTarget(iClient);
			char sID[16];
			hMenu.GetItem(iItem, sID, sizeof(sID));
			int iAdmin = GetClientOfUserId(StringToInt(sID));
			
			if(IsValidClient(iAdmin)) Description(iClient, iAdmin);
			else A_PrintToChat(iClient, "%t", "ChatPlayerIsNotInGame");
		}
		case MenuAction_End:    
		{
			delete hMenu;
		}
	}
}

void Reputation(int iClient)
{
	SetGlobalTransTarget(iClient);
	Menu hMenu = new Menu(Reputation_Handler);
	hMenu.SetTitle("%t", "Reputation_Menu", g_iAdminId[iClient], g_iCountL[g_iAdminId[iClient]], g_iCountD[g_iAdminId[iClient]]);

	if(iClient != g_iAdminId[iClient]){
		LikeAccess(iClient) ? hMenu.AddItem("0", "[-]Поставить лайк", ITEMDRAW_DEFAULT) : hMenu.AddItem("0", "[+]Поставить лайк", ITEMDRAW_DISABLED);
		DisAccess(iClient) ? hMenu.AddItem("1", "[-]Поставить дизлайк", ITEMDRAW_DEFAULT) : hMenu.AddItem("1", "[+]Поставить дизлайк", ITEMDRAW_DISABLED);
	}
	else{
		hMenu.AddItem("2", "-------------------", ITEMDRAW_DISABLED);
	}
	hMenu.ExitBackButton = true;
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

void SetContact(int iClient)
{
	Menu hMenu = new Menu(SetContact_Handler);

	hMenu.SetTitle((g_sContact[iClient][0]) ? ("Ваш контакт %s\nСменить?\n \n") : ("У вас не указан контакт\nУказать?\n \n"), g_sContact[iClient]);
	hMenu.AddItem("0", "Да");
	hMenu.AddItem("1", "Нет");
	hMenu.ExitBackButton = true;
	hMenu.ExitButton = false;
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

void Description(int iClient, int iTarget)
{ 
	SetGlobalTransTarget(iClient);
	g_iAdminId[iClient] = iTarget;
	GetAccess(iClient, iTarget);
	Menu hMenu = new Menu(Description_Handler);
	
	char sGroup[64], sBuffer[256];
	
	AdminId	aid = GetUserAdmin(iTarget);
	int iGcount = GetAdminGroupCount(aid);
	// int iTime = MAGetAdminExpire(aid);
	int iImmunity = GetAdminImmunityLevel(aid);
	// if (iTime == 0){
	// 	strcopy(sTime, sizeof(sTime), "Никогда");
	// }
	// else{
	// 	GetConVarString(g_cvTimeType, scvBuffer, sizeof(scvBuffer));
	// 	FormatTime(sTime, sizeof(sTime), scvBuffer, iTime);
	// }

	if(GetConVarInt(g_cvImmunity)) hMenu.SetTitle("%t", "DescriptionMenu_Imm", iTarget, iImmunity);
	else hMenu.SetTitle("%t", "DescriptionMenu", iTarget);

	if(GetConVarInt(g_cvGroup))
	{     
		for (int i = 0; i < iGcount; i++)
		{
			GroupId gid = GetAdminGroup(aid, i, sGroup, sizeof(sGroup));
			FormatEx(sBuffer, sizeof(sBuffer), "%t", "DescriptionMenu_Group", sGroup, gid);
			hMenu.AddItem("0", sBuffer, ITEMDRAW_DISABLED);
		}
	}

	if (!g_sContact[iTarget][0] && iClient != iTarget)
		strcopy(sBuffer, sizeof(sBuffer), "Контакт не указан");
	else
		FormatEx(sBuffer, sizeof(sBuffer), "Указать/Сменить контакт\nТекущий контакт: %s", g_sContact[iTarget][0] ? g_sContact[iTarget] : "Не указан");

	hMenu.AddItem("2", sBuffer, iClient == iTarget ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	if(iClient != iTarget){ 
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "DescriptionMenu_SendMessage");
		hMenu.AddItem("3", sBuffer);
	}

	FormatEx(sBuffer, sizeof(sBuffer), "%t", "DescriptionMenu_Reputation");
	hMenu.AddItem("1", sBuffer);
	
	hMenu.ExitBackButton = true;
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int Description_Handler(Menu hMenu, MenuAction action, int iClient, int iItem)
{       
	switch(action)
	{
		case MenuAction_End:    
		{
			delete hMenu;
		}

		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack)
			{
				Command_Admins(iClient, 0);
			}
		}

		case MenuAction_Select:
		{
			SetGlobalTransTarget(iClient);

			char szInfo[3];
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo));
			switch(szInfo[0]){
				case'1':{
					if(IsValidClient(g_iAdminId[iClient])) Reputation(iClient);
					else A_PrintToChat(iClient, "%t", "ChatPlayerIsNotInGame");
				}
				case'2':{
					SetContact(iClient);
				}
				case'3':{
					IsMessage(iClient) = true;
					A_PrintToChat(iClient, "Введите сообщение для отправки:\ncancel - отменить действие\n \n");
				}
			}
		}
	}
}

public int Reputation_Handler(Menu hMenu, MenuAction action, int iClient, int iItem)
{       
	switch(action)
	{
		case MenuAction_End:    
		{
			delete hMenu;
		}

		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack)
			{
				Description(iClient, g_iAdminId[iClient]);
			}
		}

		case MenuAction_Select:
		{
			char szInfo[3];
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo));
			if(szInfo[0] == '0') SetReputation(iClient, g_iAdminId[iClient], 1);
			else SetReputation(iClient, g_iAdminId[iClient], 0);
		}
	}
}

public int SetContact_Handler(Menu hMenu, MenuAction action, int iClient, int iItem)
{       
	switch(action)
	{
		case MenuAction_End:    
		{
			delete hMenu;
		}

		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack)
			{
				Description(iClient, iClient);
			}
		}

		case MenuAction_Select:
		{
			char szInfo[2];
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo));
			if(szInfo[0] == '0'){
				IsChange(iClient) = true;
				A_PrintToChat(iClient, "Введите в чат контакт, который нужно установить:\ncancel - отменить действие\n \n");
			}
			else IsChange(iClient) = false;
		}
	}
}