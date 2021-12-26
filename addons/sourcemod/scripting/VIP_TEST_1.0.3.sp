//------------------------------------------------------------------------------
// GPL LISENCE (short)
//------------------------------------------------------------------------------
/*
 * Copyright (c) 2014 R1KO

 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 * ChangeLog:
		1.0.0 -	Релиз
		1.0.1 -	Исправлена кодировка
				Совместимость с версией ядра 1.1.2 R
				Добавлен лог получения тестового VIP-статуса.
				Добавлен финский перевод.
		1.0.2 -	Исправлена ошибка когда невозможно взять VIP-статус повторно.
		1.0.3 -	При попытке взять VIP-статус повторно будет показано сколько времени осталось.
				Добавлена поддержка MySQL.
				Изменено сообщение в лог.
*/
#pragma semicolon 1

#include <sourcemod>
#include <vip_core>

public Plugin:myinfo =
{
	name = "[VIP] Test",
	author = "R1KO (skype: vova.andrienko1)",
	version = "1.0.3"
};

new Handle:g_hDatabase,
	bool:g_bDBMySQL,
	g_iTestTime,
	g_iTestInterval,
	String:g_sTestGroup[64];

public OnPluginStart()
{
	decl Handle:hCvar;

	hCvar = CreateConVar("sm_vip_test_group", "test_vip", "Группа для тестового VIP-статуса / Test VIP group");
	HookConVarChange(hCvar, OnTestGroupChange);
	GetConVarString(hCvar, g_sTestGroup, sizeof(g_sTestGroup));
	
	hCvar = CreateConVar("sm_vip_test_time", "120", "На сколько времени выдавать тестовый VIP-статус (значение зависит от sm_vip_time_mode) / VIP-Test duration (value depends on sm_vip_time_mode)", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(hCvar, OnTestTimeChange);
	g_iTestTime = GetConVarInt(hCvar);
	
	hCvar = CreateConVar("sm_vip_test_interval", "3600", "Через сколько времени можно повторно брать тестовый VIP-статус (значение зависит от sm_vip_time_mode) (0 - Запретить брать повторно) / How often player can request test VIP status (value depends on sm_vip_time_mode) (0 - deny new requests)");
	HookConVarChange(hCvar, OnTestIntervalChange);
	g_iTestInterval = GetConVarInt(hCvar);

	AutoExecConfig(true, "vip_test", "vip");
	
	RegConsoleCmd("sm_testvip", TestVIP_CMD);
	RegConsoleCmd("sm_viptest", TestVIP_CMD);
	
	RegAdminCmd("sm_clear_viptest", ClearTestVIP_CMD, ADMFLAG_ROOT);
	
	Connect_DB();
	
	LoadTranslations("vip_test.phrases");
	LoadTranslations("vip_core.phrases");
}

public OnTestTimeChange(Handle:hCvar, const String:oldValue[], const String:newValue[])			g_iTestTime = GetConVarInt(hCvar);
public OnTestIntervalChange(Handle:hCvar, const String:oldValue[], const String:newValue[])		g_iTestInterval = GetConVarInt(hCvar);
public OnTestGroupChange(Handle:hCvar, const String:oldValue[], const String:newValue[])			strcopy(g_sTestGroup, sizeof(g_sTestGroup), newValue);

Connect_DB()
{
	if (SQL_CheckConfig("vip_test"))
	{
		SQL_TConnect(DB_OnConnect, "vip_test", 1);
	}
	else
	{
		decl String:sError[256];
		sError[0] = '\0';
		g_hDatabase = SQLite_UseDatabase("vip_test", sError, sizeof(sError));
		DB_OnConnect(g_hDatabase, g_hDatabase, sError, 2);
	}
}

public DB_OnConnect(Handle:owner, Handle:hndl, const String:sError[], any:data)
{
	g_hDatabase = hndl;
	
	if (g_hDatabase == INVALID_HANDLE || sError[0])
	{
		SetFailState("DB Connect %s", sError);
		return;
	}

	decl String:sDriver[16];
	switch (data)
	{
		case 1 :
		{
			SQL_GetDriverIdent(owner, sDriver, sizeof(sDriver));
		}
		default :
		{
			SQL_ReadDriver(owner, sDriver, sizeof(sDriver));
		}
	}

	g_bDBMySQL = (strcmp(sDriver, "mysql", false) == 0);

	if (g_bDBMySQL)
	{
		SQL_TQuery(g_hDatabase, SQL_Callback_ErrorCheck, "SET NAMES 'utf8'");
		SQL_TQuery(g_hDatabase, SQL_Callback_ErrorCheck, "SET CHARSET 'utf8'");
	}
	
	CreateTables();
}

public SQL_Callback_ErrorCheck(Handle:owner, Handle:hndl, const String:sError[], any:data)
{
	if (sError[0])
	{
		LogError("SQL_Callback_ErrorCheck: %s", sError);
	}
}

CreateTables()
{
	SQL_LockDatabase(g_hDatabase);
	if (g_bDBMySQL)
	{
		SQL_TQuery(g_hDatabase, SQL_Callback_ErrorCheck,	"CREATE TABLE IF NOT EXISTS `vip_test` (\
																		`auth` VARCHAR(24) NOT NULL, \
																		`end` INT(10) UNSIGNED NOT NULL, \
																		PRIMARY KEY(`auth`)) \
																		ENGINE=InnoDB DEFAULT CHARSET=utf8;");
	}
	else
	{
		SQL_TQuery(g_hDatabase, SQL_Callback_ErrorCheck,	"CREATE TABLE IF NOT EXISTS `vip_test` (\
																		`auth` VARCHAR(24) NOT NULL PRIMARY KEY, \
																		`end` INTEGER UNSIGNED NOT NULL);");
	}
	SQL_UnlockDatabase(g_hDatabase);
}

public Action:ClearTestVIP_CMD(iClient, args)
{
	if (iClient)
	{
		SQL_TQuery(g_hDatabase, SQL_Callback_DropTable, "DROP TABLE `vip_test`;");
	}
	return Plugin_Handled;
}

public SQL_Callback_DropTable(Handle:hOwner, Handle:hQuery, const String:sError[], any:data)
{
	if (hQuery == INVALID_HANDLE)
	{
		LogError("SQL_Callback_DropTable: %s", sError);
		return;
	}

	CreateTables();
}

public Action:TestVIP_CMD(iClient, args)
{
	if (iClient)
	{
		if(VIP_IsClientVIP(iClient) == false)
		{
			decl String:sQuery[256], String:sAuth[32];
		//	GetClientAuthString(iClient, sAuth, sizeof(sAuth));
			GetClientAuthId(iClient, AuthId_Steam2, sAuth, sizeof(sAuth));
			FormatEx(sQuery, sizeof(sQuery), "SELECT `end` FROM `vip_test` WHERE `auth` = '%s' LIMIT 1;", sAuth);
			SQL_TQuery(g_hDatabase, SQL_Callback_SelectClient, sQuery, GetClientUserId(iClient));
		}
		else
		{
			VIP_PrintToChatClient(iClient, "%t", "VIP_ALREADY");
		}
	}
	return Plugin_Handled;
}

public SQL_Callback_SelectClient(Handle:hOwner, Handle:hQuery, const String:sError[], any:UserID)
{
	new iClient = GetClientOfUserId(UserID);
	if (iClient)
	{
		if (hQuery == INVALID_HANDLE)
		{
			LogError("SQL_Callback_SelectClient: %s", sError);
			return;
		}
		
		if(SQL_FetchRow(hQuery))
		{
			if(g_iTestInterval > 0)
			{
				new iIntervalSeconds = SQL_FetchInt(hQuery, 0)+VIP_TimeToSeconds(g_iTestInterval),
					iTime = GetTime();
				if(iTime > iIntervalSeconds)
				{
					GiveVIPToClient(iClient, true);
				}
				else
				{
					decl String:sTime[64];
					if(VIP_GetTimeFromStamp(sTime, sizeof(sTime), iIntervalSeconds-iTime, iClient))
					{
						VIP_PrintToChatClient(iClient, "%t", "VIP_RENEWAL_IS_NOT_AVAILABLE_YET", sTime);
					}
				}
			}
			else
			{
				VIP_PrintToChatClient(iClient, "%t", "VIP_RENEWAL_IS_DISABLED");
			}
		}
		else
		{
			GiveVIPToClient(iClient);
		}
	}
}

public SQL_Callback_InsertClient(Handle:hOwner, Handle:hQuery, const String:sError[], any:data)
{
	if (hQuery == INVALID_HANDLE)
	{
		LogError("SQL_Callback_InsertClient: %s", sError);
		return;
	}
}

public OnClientPostAdminCheck(iClient)
{
	if(IsFakeClient(iClient) == false)
	{
		decl String:sQuery[256], String:sAuth[32];
		GetClientAuthId(iClient, AuthId_Steam2, sAuth, sizeof(sAuth));
		FormatEx(sQuery, sizeof(sQuery), "SELECT `end` FROM `vip_test` WHERE `auth` = '%s' LIMIT 1;", sAuth);
		SQL_TQuery(g_hDatabase, SQL_Callback_SelectClientAuthorized, sQuery, GetClientUserId(iClient));
	}
}

public SQL_Callback_SelectClientAuthorized(Handle:hOwner, Handle:hQuery, const String:sError[], any:UserID)
{
	new iClient = GetClientOfUserId(UserID);
	if (iClient)
	{
		if (hQuery == INVALID_HANDLE)
		{
			LogError("SQL_Callback_SelectClientAuthorized: %s", sError);
			return;
		}
		
		if(SQL_FetchRow(hQuery))
		{
			decl iEnd, iTime;
			if((iEnd = SQL_FetchInt(hQuery, 0)) > (iTime = GetTime()))
			{
				VIP_SetClientVIP(iClient, iEnd - iTime, _, g_sTestGroup, false);
			}
		}
	}
}

GiveVIPToClient(iClient, bool:bUpdate = false)
{
	decl iSeconds, String:sQuery[256], String:sAuth[32];
	iSeconds = VIP_TimeToSeconds(g_iTestTime);
	VIP_SetClientVIP(iClient, iSeconds, AUTH_STEAM, g_sTestGroup, false);
	VIP_GetTimeFromStamp(sQuery, sizeof(sQuery), iSeconds, LANG_SERVER);

	GetClientAuthId(iClient, AuthId_Steam2, sAuth, sizeof(sAuth));
	
	VIP_LogMessage("Игрок %N (%s) получил тестовый VIP-статус (Группа: %s, Длительность: %s)", iClient, sAuth, g_sTestGroup, sQuery);

	if(bUpdate)
	{
		FormatEx(sQuery, sizeof(sQuery), "UPDATE `vip_test` SET `end` = '%i' WHERE `auth` = '%s';", GetTime()+iSeconds, sAuth);
	}
	else
	{
		FormatEx(sQuery, sizeof(sQuery), "INSERT INTO `vip_test` (`auth`, `end`) VALUES ('%s', '%i');", sAuth, GetTime()+iSeconds);
	}

	SQL_TQuery(g_hDatabase, SQL_Callback_InsertClient, sQuery);
}