#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <vip_core>

public Plugin:myinfo = 
{
	name = "[VIP] Grenades",
	author = "R1KO",
	version = "1.1"
};

new const String:g_sFeature[] = "Grenades";

new const String:g_sGrens[][] =
{
	"weapon_hegrenade",			// Осколочная
	"weapon_flashbang",			// Световая
	"weapon_smokegrenade",		// Дымовая
	// CS:GO only
	"weapon_molotov",			// Молотов
	"weapon_decoy",				// Ложная
	"weapon_incgrenade"			// Зажигательная
};

public OnPluginStart() 
{
	HookEvent("hegrenade_detonate",			Event_GrenDetonate);
	HookEvent("flashbang_detonate",			Event_GrenDetonate);
	HookEvent("smokegrenade_detonate",		Event_GrenDetonate);
	HookEventEx("molotov_detonate",			Event_GrenDetonate);
	HookEventEx("decoy_detonate",			Event_GrenDetonate);

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public OnPluginEnd()
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, STRING);
}
/*
public VIP_OnVIPClientLoaded(iClient)
{
	if(VIP_IsClientFeatureStatus(iClient, g_sFeature) != NO_ACCESS)
	{
		LoadClientGrens(iClient);
	}
}

LoadClientGrens(iClient)
{
	decl String:sBuffer[64], String:sParts[sizeof(g_sGrens)][3], iParts;
	VIP_GetClientFeatureString(iClient, g_sFeature, sBuffer, sizeof(sBuffer));
	if((iParts = ExplodeString(sBuffer, ";", sParts, sizeof(sParts), sizeof(sParts[]))) <= sizeof(g_sGrens))
	{
		decl i, Handle:hTrie;
		hTrie = VIP_GetVIPClientTrie(iClient);
		for(i = 0; i < iParts; ++i)
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%s->%s", g_sFeature, g_sGrens[i][7]);
			SetTrieValue(hTrie, sBuffer, StringToInt(sParts[i]));
		}
	}
}

public VIP_OnPlayerSpawn(iClient, iTeam, bool:bIsVIP)
{
	if(bIsVIP && VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
	//	//	LogMessage("OnPlayerSpawn: %N (%i)", iClient, iClient);
		decl String:sBuffer[64], Handle:hTrie, iCount, i;
		hTrie = VIP_GetVIPClientTrie(iClient);
		for(i = 0; i < sizeof(g_sGrens)-1; ++i)
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%s->%s", g_sFeature, g_sGrens[i][7]);
			if(GetTrieValue(hTrie, sBuffer, iCount) && iCount > 0)
			{
			//	//	LogMessage("g_sGrens[i]: %s -> %i", g_sGrens[i], iCount);
				SetTrieValue(hTrie, g_sGrens[i][7], iCount-1);
				
				if(GetEntProp(iClient, Prop_Send, "m_iAmmo", i+14) < 1)
				{
					GivePlayerItem(iClient, g_sGrens[i]);
				}
			}
		}
	}
}
*/

public VIP_OnPlayerSpawn(iClient, iTeam, bool:bIsVIP)
{
	if(bIsVIP && VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		decl String:sBuffer[64], String:sParts[sizeof(g_sGrens)-1][3], iParts;
		VIP_GetClientFeatureString(iClient, g_sFeature, sBuffer, sizeof(sBuffer));
		if((iParts = ExplodeString(sBuffer, ";", sParts, sizeof(sParts), sizeof(sParts[]))) <= sizeof(g_sGrens)-1)
		{
			//	LogMessage("VIP_OnPlayerSpawn %N (%d)", iClient, iClient);
			decl i, iCount;
			for(i = 0; i < iParts; ++i)
			{
				iCount = StringToInt(sParts[i]);
				if(iCount)
				{
					if(GetEntProp(iClient, Prop_Send, "m_iAmmo", i+14) < 1)
					{
						GivePlayerItem(iClient, (i == 3 && iTeam == 3) ? g_sGrens[5]:g_sGrens[i]);
					}

					sBuffer[i*2] = iCount+47;
				}
			}

			//	LogMessage("SetTrieString -> '%s'", sBuffer);
			SetTrieString(VIP_GetVIPClientTrie(iClient), "Grenades->Count", sBuffer);
		}
	}
}

public Event_GrenDetonate(Handle:hEvent, const String:sEvName[], bool:bSilent)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (iClient && IsPlayerAlive(iClient) && VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		//	LogMessage("%s %N (%d)", sEvName, iClient, iClient);
		decl i;
		switch(sEvName[0])
		{
			case 'h': i = 0;
			case 'f': i = 1;
			case 's': i = 2;
			case 'm': i = 3;
			case 'd': i = 4;
			default:
			{
				return;
			}
		}
		
		decl String:sBuffer[64], Handle:hTrie;
		hTrie = VIP_GetVIPClientTrie(iClient);
		if(GetTrieString(hTrie, "Grenades->Count", sBuffer, sizeof(sBuffer)))
		{
			//	LogMessage("GetTrieString -> '%s'", sBuffer);
			new iCount = sBuffer[i*2]-48;
			if(iCount)
			{
				GivePlayerItem(iClient, (i == 3 && GetClientTeam(iClient) == 3) ? g_sGrens[5]:g_sGrens[i]);
				sBuffer[i*2] = iCount+47;
			}

			//	LogMessage("SetTrieString -> '%s'", sBuffer);
			SetTrieString(hTrie, "Grenades->Count", sBuffer);
		}
	}
}
