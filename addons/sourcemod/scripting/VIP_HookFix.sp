#include <sourcemod>
#include <vip_core>

// #define OBSOLETE_LOG

#pragma newdecls  required
#pragma semicolon 1

public Plugin myinfo = {
  description = "Плагин для частичной поддержки старых модулей новым VIP-ядром R1KO",
  version     = "1.0.1",
  author      = "CrazyHackGUT aka Kruzya",
  name        = "[VIP] Client Spawn Hook Fix",
  url         = "https://kruzya.me"
};

Handle  g_hFwd;

public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] szBuffer, int iBufferLength) {
  CreateNative("VIP_HookClientSpawn",   API_HookClientSpawn);
  CreateNative("VIP_UnhookClientSpawn", API_UnhookClientSpawn);

  g_hFwd = CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

  return APLRes_Success;
}

public int API_HookClientSpawn(Handle hPlugin, int iParams) {
#if defined OBSOLETE_LOG
  OnUseObsoleteApi(hPlugin);
#endif

  return AddToForward(g_hFwd, hPlugin, GetNativeFunction(1));
}

public int API_UnhookClientSpawn(Handle hPlugin, int iParams) {
#if defined OBSOLETE_LOG
  OnUseObsoleteApi(hPlugin);
#endif

  return RemoveFromForward(g_hFwd, hPlugin, GetNativeFunction(1));
}

public void VIP_OnPlayerSpawn(int iClient, int iTeam, bool bVIP) {
  if (GetForwardFunctionCount(g_hFwd) == 0)
    return;

  Call_StartForward(g_hFwd);
  Call_PushCell(iClient);
  Call_PushCell(iTeam);
  Call_PushCell(bVIP);
  Call_Finish();
}

#if defined OBSOLETE_LOG
ArrayList g_hObsoletePlugins;

void OnUseObsoleteApi(Handle hPlugin)
{
  if (g_hObsoletePlugins == null)
  {
    g_hObsoletePlugins = new ArrayList(4);
  }

  if (g_hObsoletePlugins.FindValue(hPlugin) != -1)
  {
    // This plugin already reported.
    return;
  }

  char szPluginPath[PLATFORM_MAX_PATH];
  GetPluginFilename(hPlugin, szPluginPath, sizeof(szPluginPath));

  LogError("[VIP Spawn Hook Fix :: WARNING] Plugin '%s' uses an obsolete API for spawn hooks", szPluginPath);
  g_hObsoletePlugins.Push(hPlugin);
}
#endif