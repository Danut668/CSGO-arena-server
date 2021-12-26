#pragma semicolon 1
#include <sourcemod>
#include <vip_core>

public Plugin:myinfo =
{
	name = "[VIP] Show Damage Extended (CSS)",
	author = "R1KO",
	version = "1.0.0"
};

new const String:g_sFeature[] = "ShowDamageExtended";

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL);
}

public OnPluginEnd() 
{
	VIP_UnregisterFeature(g_sFeature);
}

public OnPluginStart()
{
	HookEventEx("player_hurt", Event_PlayerHurt);

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public Event_PlayerHurt(Handle:hEvent, const String:sEvName[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(iClient && iClient != GetClientOfUserId(GetEventInt(hEvent, "userid")) && VIP_IsClientVIP(iClient)&& VIP_IsClientFeatureUse(iClient, g_sFeature))
	{	
		decl String:sBuffer[32];
		FormatEx(sBuffer, sizeof(sBuffer), "- %i", GetEventInt(hEvent, "dmg_health"));

		SendHudMsg(iClient, 1, sBuffer, 0.5, 0.5, 1.5, {255,0,0,255}, {0,0,255,255}, 0.0, 0, 0.0, 0.0);
	}
}

SendHudMsg(iClient, iChannel, const String:sMessage[], Float:pos1, Float:pos2, Float:time = 2.0, const color1[4] = {255,0,0,255}, const color2[4]={0,0,255,255}, Float:fxtime=1.0, effect = 0, Float:fadein=1.0, Float:fadeout=1.0)
{
	decl iClients[1], Handle:hBuffer;
	iClients[0] = iClient;
	hBuffer = StartMessage("HudMsg", iClients, 1);
	if (hBuffer)
	{
		BfWriteByte(hBuffer, iChannel); // channel
		BfWriteFloat(hBuffer, pos1); // x
		BfWriteFloat(hBuffer, pos2); // y
		
		BfWriteByte(hBuffer, color1[0]); // r
		BfWriteByte(hBuffer, color1[1]); // g
		BfWriteByte(hBuffer, color1[2]); // b
		BfWriteByte(hBuffer, color1[3]); // a
		
		BfWriteByte(hBuffer, color2[0]); // r
		BfWriteByte(hBuffer, color2[1]); // g
		BfWriteByte(hBuffer, color2[2]); // b
		BfWriteByte(hBuffer, color2[3]); // a
		
		BfWriteByte(hBuffer, effect); // effect
		BfWriteFloat(hBuffer, fadein); // fade in
		BfWriteFloat(hBuffer, fadeout); // fade out
		BfWriteFloat(hBuffer, time); // holdtime
		BfWriteFloat(hBuffer, fxtime); // fxtime
		
		BfWriteString(hBuffer, sMessage); // message
		
		EndMessage();
	}
}