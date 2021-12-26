#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <vip_core>
#include <smartdm>

#define FPATH	"data/vip/modules/paintball.txt"

char g_sFeature[] = "PaintBall"; 

new Handle:g_hArrayMaterials;

public Plugin myinfo =
{
	name = "[VIP] PaintBall",
	author = "FrozDark (HLModders LLC) (rework by SHKIPPERBEAST)",
	description = "paintball",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{	
	g_hArrayMaterials = CreateArray();
	
	HookEvent("bullet_impact", Event_BulletImpact);	
	
	if (VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL);
}

public OnMapStart()
{
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof(szPath), FPATH);
	Handle hFile = OpenFile(szPath, "r");
	
	if (hFile == INVALID_HANDLE)
	{
		ThrowError("%s not parsed... file doesn't exist!", szPath);
	}
	
	ClearArray(g_hArrayMaterials);
		
	while (!IsEndOfFile(hFile))
	{
		if (!ReadFileLine(hFile, szPath, sizeof(szPath)))
			continue;
	
		new pos;
		pos = StrContains((szPath), "//");
		if (pos != -1)
		{
			szPath[pos] = '\0';
		}
	
		pos = StrContains((szPath), "#");
		if (pos != -1)
		{
			szPath[pos] = '\0';
		}
			
		pos = StrContains((szPath), ";");
		if (pos != -1)
		{
			szPath[pos] = '\0';
		}
	
		TrimString(szPath);
		
		if (szPath[0] == '\0')
		{
			continue;
		}
		
		Downloader_AddFileToDownloadsTable(szPath);
		PushArrayCell(g_hArrayMaterials, PrecacheDecal(szPath[10]));
	}
}

public Event_BulletImpact(Handle:event, const String:weaponName[], bool:dontBroadcast)
{	
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
 	if (!VIP_IsClientVIP(client) || !VIP_IsClientFeatureUse(client, g_sFeature))
	{
		return;
	}
	new size = GetArraySize(g_hArrayMaterials);
	if (!size)
	{
		return;
	}
	
	decl Float:bulletDestination[3];//, Float:ang[3];
	bulletDestination[0] = GetEventFloat(event, "x");
	bulletDestination[1] = GetEventFloat(event, "y");
	bulletDestination[2] = GetEventFloat(event, "z");
	
	new index = GetArrayCell(g_hArrayMaterials, Math_GetRandomInt(0, size-1));
	TE_SetupWorldDecal(bulletDestination, index);
	TE_SendToAll();
	
	/*decl Float:fOrigin[3];
	GetClientEyePosition(client, fOrigin);
	
	MakeVectorFromPoints(fOrigin, bulletDestination, ang);
	
	new Handle:trace = TR_TraceRayFilterEx(fOrigin, ang, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(bulletDestination, trace);
		//TE_SetupGlowSprite(bulletDestination, index, 300.0, 0.2, 200);
	}
	
	CloseHandle(trace);*/
}

stock TE_SetupWorldDecal(const Float:vecOrigin[3], index)
{    
    TE_Start("World Decal");
    TE_WriteVector("m_vecOrigin",vecOrigin);
    TE_WriteNum("m_nIndex",index);
}

stock Math_GetRandomInt(min, max)
{
	new random = GetURandomInt();
	
	if (!random)
		random++;
		
	new number = RoundToCeil(float(random) / (float(2147483647) / float(max - min + 1))) + min - 1;
	
	return number;
}

public void OnPluginEnd()
{
    if (CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
    {
        VIP_UnregisterFeature(g_sFeature);
    }
}
