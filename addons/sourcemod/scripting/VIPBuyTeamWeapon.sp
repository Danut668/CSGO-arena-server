#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_AUTHOR "Planes"
#define PLUGIN_VERSION "1.2.3"

#include <sourcemod>
#include <sdktools>
#include <vip_core>


int g_Game; // 1 - CS:GO | 2 - CS:S | 3 - Other

static const char g_sFeature[] = "BuyTeamWeapon";

Handle g_hTimer[MAXPLAYERS + 1];

int g_getWeap[MAXPLAYERS + 1]; // Индекс оружия слота 0
int g_GetWeapon[MAXPLAYERS + 1]; // 1 - AK47 | 2 - M4A1-S | 3 - M4A1


public Plugin myinfo = 
{
	name = "[VIP] Покупка оружия команды",
	author = PLUGIN_AUTHOR,
	description = "Позволяет VIP игрокам покупать оружие противоположной команды",
	version = PLUGIN_VERSION,
	url = "hlmod.ru"
};

public void OnPluginStart()
{
	EngineVersion g_Engine = GetEngineVersion();

	switch (g_Engine)
	{
		case Engine_CSGO:
		{
			g_Game = 1;
		}
		case Engine_CSS:
		{
			g_Game = 2;
		}
		
		default:
		{
			g_Game = 3;
		}
	}
	
	LoadTranslations("vip_modules.phrases"); // Файл перевода VIP
	LoadTranslations("vip_buyteamweapon.phrases"); // Файл перевода плагина
}

public void VIP_OnVIPLoaded() // VIP загружено
{
    VIP_RegisterFeature(g_sFeature, INT);
}


public Action CS_OnBuyCommand(int iClient, const char[] weapon) // Игрок купил оружие
{
	if(iClient > 0 && VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		if(StrEqual("ak47", weapon) || StrEqual("m4a1_silencer", weapon) || StrEqual("m4a1", weapon))
		{
			if(g_hTimer[iClient]) 
			{
				KillTimer(g_hTimer[iClient]);
				g_hTimer[iClient] = null;
				return Plugin_Handled;
			} else
			{
				
				g_hTimer[iClient] = CreateTimer(0.5, Timer_Weapon, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
					
				if (StrEqual("ak47", weapon)) 
				{
					g_GetWeapon[iClient] = 1; 
				} else if (StrEqual("m4a1_silencer", weapon))
				{
					g_GetWeapon[iClient] = 2;
				} else
				{
					g_GetWeapon[iClient] = 3;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_Weapon(Handle hTimer, any UserId)
{
	int iClient = GetClientOfUserId(UserId);
	if(iClient > 0 && !IsFakeClient(iClient) && IsClientInGame(iClient))
	{
		g_getWeap[iClient] = GetPlayerWeaponSlot(iClient, 0);
		if (g_getWeap[iClient] != -1 && GetPlayerWeaponSlot(iClient, 0) == g_getWeap[iClient] && GetEntProp(iClient, Prop_Send, "m_bInBuyZone"))
		{
			// 1 - ак, 2 - м4а1 с, 3 - м4а1
			Menu hMenu = new Menu(Menu_Weap, MenuAction_Select);
			char sFormat[128];
			FormatEx(sFormat, sizeof(sFormat), "%t", "BTW_MenuName");
			hMenu.SetTitle(sFormat);

			hMenu.AddItem("ak47", "AK47");
			hMenu.AddItem("m4a1", "M4A1");
			if(g_Game != 1) // Если игра не CS:GO
			hMenu.AddItem("m4a1s", "M4A1 - Silencer", ITEMDRAW_NOTEXT);
			else
			hMenu.AddItem("m4a1s", "M4A1 - Silencer");

			hMenu.Display(iClient, 5); // Время отображения меню в секундах
		}
		g_hTimer[iClient] = null; // Анулируем таймер после его прохождения
	}
	
}

public int Menu_Weap(Menu menu, MenuAction action, int iClient, int iItem)
{
	if(iClient > 0 && !IsFakeClient(iClient) && IsClientInGame(iClient) && GetPlayerWeaponSlot(iClient, 0) == g_getWeap[iClient] && g_getWeap[iClient] != -1)
	{
		if (!GetEntProp(iClient, Prop_Send, "m_bInBuyZone"))return; // Если игрок не в зоне закупки - не выдаем
		int iMoney = GetEntProp(iClient, Prop_Send, "m_iAccount");
		switch (action)
		{
		    case MenuAction_Select:
			{
				switch (iItem)
				{
		   			case 0: // AK47
					{
						if(VIP_GetClientFeatureInt(iClient, g_sFeature) == 2)
						{
							if(g_GetWeapon[iClient] > 1) // Если У игрока мка
							{
								if(g_Game == 1)
								{
									SetEntProp(iClient, Prop_Send, "m_iAccount", iMoney+400);
									RemovePlayerItem(iClient, g_getWeap[iClient]);
						   			GivePlayerItem(iClient, "weapon_ak47");
					   			} else
					   			{
					   				SetEntProp(iClient, Prop_Send, "m_iAccount", iMoney+600);
									RemovePlayerItem(iClient, g_getWeap[iClient]);
						   			GivePlayerItem(iClient, "weapon_ak47");
					   			}
							}
						} else 
						{
							RemovePlayerItem(iClient, g_getWeap[iClient]);
				   			GivePlayerItem(iClient, "weapon_ak47");
						}
					}
					case 1: // m4a1
					{
						if(VIP_GetClientFeatureInt(iClient, g_sFeature) == 2)
						{
				   			if(g_GetWeapon[iClient] == 1) // Если у игрока калаш
				   			{
				   				if(g_Game == 1)
				   				{
					   				if(iMoney >= 400)
					   				{
					   					SetEntProp(iClient, Prop_Send, "m_iAccount", iMoney-400);
					   					RemovePlayerItem(iClient, g_getWeap[iClient]);
					   					GivePlayerItem(iClient, "weapon_m4a1");
					   				} else
					   				{
										PrintLangText(iClient);
					   				}
				   				} else
				   				{
					   				if(iMoney >= 600)
					   				{
					   					SetEntProp(iClient, Prop_Send, "m_iAccount", iMoney-600);
					   					RemovePlayerItem(iClient, g_getWeap[iClient]);
					   					GivePlayerItem(iClient, "weapon_m4a1");
					   				} else
					   				{
										PrintLangText(iClient);
					   				}
				   				}
				   			} else
				   			{
				   				RemovePlayerItem(iClient, g_getWeap[iClient]);
				   				GivePlayerItem(iClient, "weapon_m4a1");
				   			}
						} else
						{
				   			RemovePlayerItem(iClient, g_getWeap[iClient]);
				   			GivePlayerItem(iClient, "weapon_m4a1");
						}
					}
					case 2: // m4a1-s
					{
						if(VIP_GetClientFeatureInt(iClient, g_sFeature) == 2 && g_Game == 1)
						{
							if(g_GetWeapon[iClient] == 1) // Если у игрока калаш
							{
								if(iMoney >= 400)
				   				{
				   					SetEntProp(iClient, Prop_Send, "m_iAccount", iMoney-400); // Отнимаем т.к мка стоит дороже
					   				RemovePlayerItem(iClient, g_getWeap[iClient]);
					   				GivePlayerItem(iClient, "weapon_m4a1_silencer");	
				   				} else
				   				{
									PrintLangText(iClient);
				   				}	
							} else
							{
					   			RemovePlayerItem(iClient, g_getWeap[iClient]);
					   			GivePlayerItem(iClient, "weapon_m4a1_silencer");
							}
						} else
						{
					   		RemovePlayerItem(iClient, g_getWeap[iClient]);
					   		GivePlayerItem(iClient, "weapon_m4a1_silencer");
						}
					}
		  		}
		   	}
		}
		g_hTimer[iClient] = null;
	}
	
}

public void OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}

void PrintLangText(int iClient) // Вывод текста если не хватает денег
{
	
	char sFormat[128];
	FormatEx(sFormat, sizeof(sFormat), "%t", "BTW_NoMoney");
	PrintToChat(iClient, sFormat);
}