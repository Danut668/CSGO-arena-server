#include <sourcemod>
#include <sdktools>
#include <vip_core>

#define coordx 0.2 
#define coordy 0.8 

#pragma newdecls required

public Plugin myinfo =
{
	name = "[VIP]Quiz",
	author = "DeeperSpy (rework by SHKIPPERBEAST)",
	version = "1.3"
};

int g_iAnswer;
int g_VIPTime;
	
bool g_bVar;
	
float kTime2;

char szPrefix[256];
char szVIPGroup[64];

Handle g_hTimer;

public void OnPluginStart()
{	
	RegAdminCmd("sm_answer", Answer, ADMFLAG_ROOT)
	RegAdminCmd("sm_createprimer", CreatePrimer, ADMFLAG_ROOT)
}

public Action Answer(int client, int args)
{
	PrintToChat(client, "\x04%s\x03Answer: \x04%d", szPrefix, g_iAnswer);
}

public Action CreatePrimer(int client, int args)
{
	g_bVar = true;
       
	g_hTimer = null;
	CreateTimer(0.1, Timer_Message, _, TIMER_FLAG_NO_MAPCHANGE);
	
	PrintToChat(client, "\x04%s\x03Example Created!", szPrefix);
}

public void OnMapStart()
{    
	CreateTimer(0.1, Timer_Message, _, TIMER_FLAG_NO_MAPCHANGE);
	
	AddFileToDownloadsTable("sound/quiz/quiz.mp3");
	
	AddToStringTable(FindStringTable("soundprecache"), "*quiz/quiz.mp3");
	PrecacheSound("quiz/quiz.mp3", true);
}

public void OnConfigsExecuted()
{
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "data/vip/modules/quiz.cfg");
    KeyValues kv = new KeyValues("Quiz");
    
    if(!kv.ImportFromFile(sPath) || !kv.GotoFirstSubKey()) SetFailState("[Quiz] file is not found (%s)", sPath);
    
    kv.Rewind();
    
    if(kv.JumpToKey("Settings"))
    {
        CreateTimer(kv.GetFloat("Time", 180.0), Timer_Message,_ , TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE) 
        kTime2 = kv.GetFloat("Time2", 60.0);
        kv.GetString("Prefix", szPrefix, sizeof(szPrefix));
        g_VIPTime =  kv.GetNum("VIPTime", 1800);
        kv.GetString("VIPGroup", szVIPGroup, sizeof(szVIPGroup));
    }
    else
    {
        SetFailState("[Quiz] section Settings is not found (%s)", sPath);
    }
        
    delete kv;
}

public Action Timer_Message(Handle hTimer)
{	
	int i, iCount;
	for(i = 1; i <= MaxClients; ++i)
    {
        if(IsClientInGame(i) && !IsFakeClient(i))
        {
			++iCount;
        }
    }
 
	if(iCount == 0)
    {
        return Plugin_Stop;
    }
    
	int primer 	= GetRandomInt(1, 18),
		j 		= GetRandomInt(500, 1000),
		k 		= GetRandomInt(1, 100),
		k2 		= GetRandomInt(1, 500),
		l 		= GetRandomInt(1, 50),
		b 		= GetRandomInt(1, 20),
		c 		= GetRandomInt(1, 5);
		
	g_bVar = true;
	
	switch(primer)
	{
		case 1:
		{
			PrintToChatAll("\x04%s\x03Example =  \x04%d+%d+%d-%d = ", szPrefix, j, k, k2, b);
			g_iAnswer=j+k+k2-b
		}
		case 2:
		{
			PrintToChatAll("\x04%s\x03Example =  \x04%d-%d+%d-%d = ", szPrefix, j, k, k2, l);
			g_iAnswer=j-k+k2-l
		}
		case 3:
		{
			PrintToChatAll("\x04%s\x03Example =  \x04%d-%d-%d+%d-%d = ", szPrefix, j, k, k2, l , b);
			g_iAnswer=j-k-k2+l-b
		}
		case 4:
		{
			PrintToChatAll("\x04%s\x03Example =  \x04%d+%d-%d-%d = ", szPrefix, j, k, k2, l);
			g_iAnswer=j+k-k2-l
		}
		case 5:
		{
			PrintToChatAll("\x04%s\x03Example =  \x04%d-%d*%d+%d = ", szPrefix, c, k, b, l);
			g_iAnswer=c-k*b+l
		}
		case 6:
		{
			PrintToChatAll("\x04%s\x03Example =  \x04%d+%d*%d = ", szPrefix, j, l, c);
			g_iAnswer=j+l*c
		}
		case 7:
		{
			PrintToChatAll("\x04%s\x03Example =  \x04%d+%d-%d+%d = ", szPrefix, j, k, c, l);
			g_iAnswer=j+k-c+l
		}
		case 8:
		{
			PrintToChatAll("\x04%s\x03Example =  \x04(%d+%d)/%d-%d = ", szPrefix, j, k2, b, l);
			g_iAnswer=(j+k2)/b-l
		}
		case 9:
		{
			PrintToChatAll("\x04%s\x03Example =  \x04(%d-%d)-%d+%d = ", szPrefix, j, k2, k, k2);
			g_iAnswer=(j-k2)-k+k2
		}
		case 10:
		{
			PrintToChatAll("\x04%s\x03Example =  \x04%d-%d+(%d*%d) = ", szPrefix, j, k2, b, c);
			g_iAnswer=j-k2+(b*c)
		}
		case 11:
		{
			PrintToChatAll("\x04%s\x03Example =  \x04%d+%d/%d-%d = ", szPrefix, j, b, c, l);
			g_iAnswer=j+b/c-l
		}
		case 12:
		{
			PrintToChatAll("\x04%s\x03Example =  \x04%d-%d-%d+%d = ", szPrefix, k, j, b, k2);
			g_iAnswer=k-j-b+k2
		}
		case 13:
		{
			PrintToChatAll("\x04%s\x03Example =  \x04%d-%d+%d-%d/%d = ", szPrefix, j, k, k2, l, c);
			g_iAnswer=j-k+k2-l/c
		}
		case 14:
		{
			PrintToChatAll("\x04%s\x03Example =  \x04%d+%d-%d-%d+%d = ", szPrefix, j, k2, b, l, k);
			g_iAnswer=j+k2-b-l+k
		}
		case 15:
		{
			PrintToChatAll("\x04%s\x03Example =  \x04%d-%d+%d-%d+%d = ", szPrefix, k2, j, k, j, b);
			g_iAnswer=k2-j+k-j+b
		}
		case 16:
		{
			PrintToChatAll("\x04%s\x03Example =  \x04(%d-%d)*%d/%d = ", szPrefix, j, k2, c, b);
			g_iAnswer=(j-k2)*c/b
		}
		case 17:
		{
			PrintToChatAll("\x04%s\x03Example =  \x04%d+%d-%d-%d/%d = ", szPrefix, j, j, k2, k, b);
			g_iAnswer=j+j+k2-k/b
		}
		case 18:
		{
			PrintToChatAll("\x04%s\x03Example =  \x04%d*%d-%d+%d/2 = ", szPrefix, k, c, k2, k);
			g_iAnswer=k*c-k2+k/2
		}
	}
	
	g_hTimer = CreateTimer(kTime2, Timer_Message2,_, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action Timer_Message2(Handle hTimer)
{
	PrintToChatAll("\x04%s\x03Time is up, Correct Answer = \x04 %d", szPrefix, g_iAnswer);
	g_bVar = false;
	g_hTimer = null;
}

public void OnClientSayCommand_Post(int iClient, const char[] szCommand, const char[] szMessage)
{	
	if(g_bVar == false)
	{
		return;
	}
	int iValue = StringToInt(szMessage);
	if(iValue == g_iAnswer)
	{
		if(VIP_IsClientVIP(iClient) == false)
		{
			PrintToChatAll("\x04%s%N, \x03Answered correctly, Correct answer = \x04 %d", szPrefix, iClient, g_iAnswer);
		
			int iSeconds;
			char sQuery[256];
			iSeconds = VIP_TimeToSeconds(g_VIPTime);
			VIP_GiveClientVIP(0, iClient, iSeconds, szVIPGroup, true);
			VIP_GetTimeFromStamp(sQuery, sizeof(sQuery), iSeconds, LANG_SERVER);
		
			PrintToChat(iClient, "\x04%s%N, \x03You answered the Question Correctly and you get \x04VIP \x03for \x04%s", szPrefix, iClient, sQuery); 
		
			ClientCommand(iClient, "play quiz/quiz.mp3");
		
			g_bVar = false;
		
			if(g_hTimer)  
			{
				KillTimer(g_hTimer);
				g_hTimer = null;     
			}
		}		
		else if(VIP_IsClientVIP(iClient) == true)
		{
			PrintToChat(iClient, "\x04%s \x03You already have a \x04VIP.", szPrefix)
		}
	}
	return;
}