#include <sourcemod>
#include <chat-processor>
#include <clientprefs>
#include <multicolors>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "HexTags Lite",
    author      = "moongetsu",
    description = "HexTags but it's lite, optimized and more simple",
    version     = "1.5",
    url         = "https://github.com/moongetsu"
};

enum struct ClientTags
{
    char ScoreTag[64];
    char ChatTag[64];
    char ChatColor[32];
    char NameColor[32];
    char ChatNamePrefix[128];
    bool ForceTag;
}

ClientTags g_Tags[MAXPLAYERS + 1];
KeyValues  g_kvTags;
Cookie     g_hCookieHide;
bool       g_HideTags[MAXPLAYERS + 1];
bool       g_bClanTags;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    MarkNativeAsOptional("CS_SetClientClanTag");
    MarkNativeAsOptional("CS_GetClientClanTag");
    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations("hextags_lite.phrases");

    RegAdminCmd("sm_reloadtags", Cmd_ReloadTags, ADMFLAG_GENERIC, "Reload HexTags Lite config.");
    RegConsoleCmd("sm_hidetags", Cmd_HideTags, "Toggle your tag visibility.");

    g_hCookieHide = new Cookie("hextags_hidetags", "Hide or show your tags", CookieAccess_Private);
    g_bClanTags   = (GetFeatureStatus(FeatureType_Native, "CS_SetClientClanTag") == FeatureStatus_Available);

    LoadConfig();

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            if (AreClientCookiesCached(i)) OnClientCookiesCached(i);
            ApplyTags(i);
        }
    }

    if (g_bClanTags)
        CreateTimer(5.0, Timer_ForceTag, _, TIMER_REPEAT);
}

void SetClanTag(int client, const char[] tag)
{
    if (g_bClanTags)
        CS_SetClientClanTag(client, tag);
}

public void OnMapStart()
{
    LoadConfig();
}

public Action Cmd_ReloadTags(int client, int args)
{
    LoadConfig();
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i)) ApplyTags(i);
    }
    CReplyToCommand(client, "%t", "Tags Reloaded");
    return Plugin_Handled;
}

public Action Cmd_HideTags(int client, int args)
{
    if (!client) return Plugin_Handled;

    g_HideTags[client] = !g_HideTags[client];
    g_hCookieHide.Set(client, g_HideTags[client] ? "1" : "0");

    ApplyTags(client);

    CReplyToCommand(client, "%t", g_HideTags[client] ? "Tags Hidden" : "Tags Visible");
    return Plugin_Handled;
}

void LoadConfig()
{
    delete g_kvTags;
    g_kvTags = new KeyValues("HexTags");

    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "configs/hextags_lite.cfg");

    if (!g_kvTags.ImportFromFile(sPath))
    {
        LogError("Could not load config: %s", sPath);
    }
}

public void OnClientPostAdminCheck(int client)
{
    ApplyTags(client);
}

public void OnClientCookiesCached(int client)
{
    char sValue[4];
    g_hCookieHide.Get(client, sValue, sizeof(sValue));
    g_HideTags[client] = view_as<bool>(StringToInt(sValue));
    ApplyTags(client);
}

public void OnClientDisconnect(int client)
{
    ResetClientData(client);
}

void ResetClientData(int client)
{
    g_Tags[client].ScoreTag       = "";
    g_Tags[client].ChatTag        = "";
    g_Tags[client].ChatColor      = "";
    g_Tags[client].NameColor      = "{teamcolor}";
    g_Tags[client].ChatNamePrefix = "";
    g_Tags[client].ForceTag       = false;
    g_HideTags[client]            = false;
}

bool ClientInAnyGroup(AdminId admin, const char[] section)
{
    if (admin == INVALID_ADMIN_ID)
        return false;

    char groups[8][32];
    int  n = ExplodeString(section, ",", groups, sizeof(groups), sizeof(groups[]));

    char sAdminGroup[64];
    int  count = admin.GroupCount;

    for (int p = 0; p < n; p++)
    {
        TrimString(groups[p]);
        if (groups[p][0] != '@' || groups[p][1] == '\0')
            continue;

        for (int i = 0; i < count; i++)
        {
            admin.GetGroup(i, sAdminGroup, sizeof(sAdminGroup));
            if (StrEqual(sAdminGroup, groups[p][1], false))
                return true;
        }
    }

    return false;
}

void ApplyTags(int client)
{
    if (!IsClientInGame(client) || IsFakeClient(client) || !g_kvTags) return;

    g_Tags[client].ScoreTag       = "";
    g_Tags[client].ChatTag        = "";
    g_Tags[client].ChatColor      = "";
    g_Tags[client].NameColor      = "{teamcolor}";
    g_Tags[client].ChatNamePrefix = "";
    g_Tags[client].ForceTag       = true;

    if (g_HideTags[client])
    {
        SetClanTag(client, "");
        return;
    }

    g_kvTags.Rewind();
    if (!g_kvTags.GotoFirstSubKey()) return;

    char sSection[128], sSteam[32], sSteamAlt[32];
    GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));

    strcopy(sSteamAlt, sizeof(sSteamAlt), sSteam);
    if (sSteam[6] == '0') sSteamAlt[6] = '1';
    else if (sSteam[6] == '1') sSteamAlt[6] = '0';

    AdminId admin           = GetUserAdmin(client);
    int     currentPriority = 0;

    do
    {
        g_kvTags.GetSectionName(sSection, sizeof(sSection));
        int priority = 0;

        if (StrEqual(sSection, "default", false))
        {
            priority = 1;
        }
        else if (StrEqual(sSteam, sSection, false) || StrEqual(sSteamAlt, sSection, false)) {
            priority = 4;
        }
        else if (sSection[0] == '@') {
            if (ClientInAnyGroup(admin, sSection))
                priority = 3;
        }
        else if (strlen(sSection) == 1) {
            AdminFlag flag;
            if (FindFlagByChar(sSection[0], flag))
            {
                if (admin != INVALID_ADMIN_ID && admin.HasFlag(flag))
                    priority = 2;
            }
        }

        if (priority > currentPriority)
        {
            currentPriority = priority;
            g_kvTags.GetString("ScoreTag", g_Tags[client].ScoreTag, 64);
            g_kvTags.GetString("ChatTag", g_Tags[client].ChatTag, 64);
            g_kvTags.GetString("ChatColor", g_Tags[client].ChatColor, 32);
            g_kvTags.GetString("NameColor", g_Tags[client].NameColor, 32, "{teamcolor}");
            g_Tags[client].ForceTag = (g_kvTags.GetNum("ForceTag", 1) == 1);

            if (currentPriority == 4) break;
        }
    }
    while (g_kvTags.GotoNextKey());

    Format(g_Tags[client].ChatNamePrefix, sizeof(ClientTags::ChatNamePrefix), "%s%s", g_Tags[client].ChatTag, g_Tags[client].NameColor);

    if (g_Tags[client].ScoreTag[0] != '\0')
        SetClanTag(client, g_Tags[client].ScoreTag);
}

public Action Timer_ForceTag(Handle timer)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && g_Tags[i].ForceTag && g_Tags[i].ScoreTag[0] != '\0')
        {
            char sCurrentTag[64];
            CS_GetClientClanTag(i, sCurrentTag, sizeof(sCurrentTag));
            if (!StrEqual(sCurrentTag, g_Tags[i].ScoreTag))
                SetClanTag(i, g_Tags[i].ScoreTag);
        }
    }
    return Plugin_Continue;
}

public Action CP_OnChatMessage(int &author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool &processcolors, bool &removecolors)
{
    if (g_HideTags[author]) return Plugin_Continue;

    bool changed = false;
    if (g_Tags[author].ChatNamePrefix[0] != '\0')
    {
        char sNewName[MAXLENGTH_NAME];
        Format(sNewName, sizeof(sNewName), "%s%s", g_Tags[author].ChatNamePrefix, name);
        strcopy(name, MAXLENGTH_NAME, sNewName);
        changed = true;
    }

    if (g_Tags[author].ChatColor[0] != '\0')
    {
        char sNewMessage[MAXLENGTH_MESSAGE];
        Format(sNewMessage, sizeof(sNewMessage), "%s%s", g_Tags[author].ChatColor, message);
        strcopy(message, MAXLENGTH_MESSAGE, sNewMessage);
        changed = true;
    }

    if (changed)
    {
        processcolors = true;
        return Plugin_Changed;
    }

    return Plugin_Continue;
}
