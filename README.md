<h1 align="center">
  <img src="https://images.gamebanana.com/img/ico/sprays/naruto.gif" width="64" alt="HexTags Lite"/>
  <br />
  HexTags Lite
</h1>
<p align="center">
  <b>Ultra-optimized and minimalist <span style="color:#F5E260;">Tags & Colors</span> manager for SourceMod servers.</b><br>
</p>

<hr>

## 🛡️ About

**HexTags Lite** is a modernized and high-performance rewrite of the classic HexTags plugin. It removes unnecessary bloat and dependencies (like RankMe, Warden, or complex APIs) to provide a streamlined experience centered around player aesthetics and server performance.

---

## ✨ Features

- **Hierarchy Priority System:** Automatically applies the most specific tag based on a predefined order:
	- **SteamID** (Priority 4)
	- **Admin Group** (Priority 3)
	- **Admin Flag** (Priority 2)
	- **Default** (Priority 1)
- **High Performance:** Tags are cached upon joining (`ApplyTags`) and pre-formatted (`ChatNamePrefix`) to minimize overhead during chat messages.
- **Scoreboard & Chat:** Supports both ClanTags (Scoreboard) and Chat Prefixes/Colors.
- **Smart SteamID Handling:** Handles `STEAM_0` and `STEAM_1` interchangeably.
- **Persistent Preferences:** Players can use `sm_hidetags` to toggle their own tags, with settings saved across sessions via client cookies.
- **Multilingual Support:** Fully translatable messages with integrated **MultiColors** support.

---

## 🛠️ Requirements

- **[SourceMod 1.11+](https://www.sourcemod.net/downloads.php)**
- **[Chat-Processor](https://github.com/Drixevel/Chat-Processor)**
- **[MultiColors](https://github.com/Bara/Multi-Colors)** (Include for compilation)

---

## 📦 Installation

1. Download the latest `hextags_lite.zip` from [Releases](https://github.com/maxijabase/HexTags-Lite/releases).
2. Extract it into your game directory so the files land under `addons/sourcemod/`.
3. Load the plugin: `sm plugins load hextags_lite`.

Manual layout (if compiling yourself):

- `addons/sourcemod/plugins/hextags_lite.smx`
- `addons/sourcemod/scripting/hextags_lite.sp`
- `addons/sourcemod/translations/hextags_lite.phrases.txt`
- `addons/sourcemod/configs/hextags_lite.cfg`

---

## 🎮 Commands

| Command | Alias | Description | Flag |
|---------|-------|-------------|------|
| `sm_reloadtags` | - | Reloads the configuration file. | Generic |
| `sm_hidetags` | `!hidetags` | Toggles your tag visibility (Saved in cookies). | None |

---

## ⚙️ Configuration Guide

Located in `addons/sourcemod/configs/hextags_lite.cfg`. The plugin uses a **Hierarchy Priority System**, meaning it will only apply the settings from the **highest priority** match found for a player.

### Priority Hierarchy
| Level | Selector | Example | Description |
|---|---|---|---|
| **4** | **SteamID** | `STEAM_0:1:12345` | Hits specific players. (Highest) |
| **3** | **Admin Group** | `@Owner` or `@Admin, @Root` | Matches any listed group name (comma-separated, OR). |
| **2** | **Admin Flag** | `z` | Matches a single Admin Flag. |
| **1** | **Default** | `default` | Applies if no other match is found. |

---

### Available Settings
| Key | Description |
|---|---|
| `ScoreTag` | The text shown on the TAB scoreboard (ClanTag). *CS:S/CS:GO only. Ignored on other games.* |
| `ChatTag` | The prefix shown before the player's name in chat. *Supports colors.* |
| `ChatColor` | The color of the message text sent by the player. |
| `NameColor` | The color of the player's name in chat. (Default: `{teamcolor}`) |
| `ForceTag` | `1` to force the ScoreTag every 5s, `0` to set it only once. |

### 🎨 Available Colors
You can use the following color tags in your configuration:

<p>
  <img src="https://raw.githubusercontent.com/PremyslTalich/ColorVariables/refs/heads/master/csgo%20colors.png" alt="CSGO Colors" />
</p>

---

### Full Example (`hextags_lite.cfg`)

```keyvalues
"HexTags"
{
    // Example: SteamID Match (Highest Priority)
    "STEAM_0:1:396607694"
    {
        "ScoreTag"  "[Moongetsu]"
        "ChatTag"   "{darkred}[Moongetsu] {default}"
        "ChatColor" "{darkred}"
        "NameColor" "{grey}"
    }

	  // Example: Admin Group Match (Priority 3)
	  // Must match a Group Name defined in admin_groups.cfg
	  // Multiple groups in one section: comma-separated, OR match
    "@Admin, @Root"
    {
        "ScoreTag"  "[ADMIN]"
        "ChatTag"   "{darkblue}[ADMIN] {default}"
        "ChatColor" "{grey}"
        "NameColor" "{darkblue}"
    }

	  // Example: Admin Flag Match (Priority 2)
	  // Use a single flag character (e.g., 'z' for Root, 'b' for Generic Admin)
    "z"
    {
        "ScoreTag"  "[ROOT]"
        "ChatTag"   "{orchid}[ROOT] {default}"
        "ChatColor" "{grey}"
        "NameColor" "{orchid}"
    }

    // Example: Default (Lowest Priority) - Applies to everyone not matched above
    "default"
    {
        "ScoreTag"  ""
        "ChatTag"   "{teamcolor}[PLAYER] {default}"
        "ChatColor" "{grey}"
        "NameColor" "{teamcolor}"
    }
}
```

---

<p align="center">
  <img src="https://badgen.net/badge/Optimized%20for/CS:GO/green?icon=sourceengine" alt="Engine Optimized" />
  <img src="https://badgen.net/badge/Version/v1.5/blue" alt="Version" />
  <img src="https://badgen.net/badge/Language/SourcePawn/orange" alt="SourcePawn" />
</p>
