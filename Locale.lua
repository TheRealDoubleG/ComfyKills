ComfyKills=ComfyKills or {}
local A=ComfyKills
local de=GetLocale and GetLocale()=="deDE"
local EN={
 TAB_GENERAL="Kills",TAB_INFO="Info",ADDON_ENABLED="Enable ComfyKills",
 INFO_VERSION="Version",INFO_BUILD_DATE="Build date",INFO_STATUS="Status",INFO_CLIENT="Current client",
 INFO_TESTED_TARGET="Tested target",INFO_COMPAT_STATUS="Compatibility",INFO_AUTHOR="Author",INFO_DISCORD="Discord",
 INFO_GITHUB="GitHub",INFO_COMMANDS="Slash commands",COMPAT_MATCH="Compatible",COMPAT_UPDATE_REQUIRED="Interface differs from the tested target",
 INFO_NOTICE="ComfyKills records personal mob-kill history in ComfyData. It does not automate combat or targeting.",
 INFO_THANKS="Thanks for using ComfyKills! Feedback and bug reports are welcome via Discord.",
 SHOW_TOOLTIP="Show kill data in unit tooltips",TRACK_DEATHS="Track player deaths",COUNT_PET="Count kills credited to your pet",
 MILESTONES="Show kill milestones",OPEN_DATABASE="Open kill database",DATABASE="Database",
 SUMMARY_FORMAT="%d total kills · %d unique mobs · %d deaths on this character",
 ALL_KILLS="All kills",SESSION="Session",SEARCH="Search",MOB="Mob",KILLS="Kills",LAST_KILL="Last kill",TYPE="Type",
 TOOLTIP_CHARACTER="This character",TOOLTIP_ACCOUNT="Account",TOOLTIP_SESSION="This session",TOOLTIP_AVG_XP="Average XP",
 FOREVER_NOTE="0.1 records PARTY_KILL events credited to you or your pet. Group-wide attribution can be added after Forever runtime testing.",
}
local DE={
 TAB_GENERAL="Kills",TAB_INFO="Info",ADDON_ENABLED="ComfyKills aktivieren",
 INFO_VERSION="Version",INFO_BUILD_DATE="Build-Datum",INFO_STATUS="Status",INFO_CLIENT="Aktueller Client",
 INFO_TESTED_TARGET="Getestetes Ziel",INFO_COMPAT_STATUS="Kompatibilität",INFO_AUTHOR="Autor",INFO_DISCORD="Discord",
 INFO_GITHUB="GitHub",INFO_COMMANDS="Slash-Befehle",COMPAT_MATCH="Kompatibel",COMPAT_UPDATE_REQUIRED="Interface weicht vom getesteten Ziel ab",
 INFO_NOTICE="ComfyKills speichert deine persönliche Mob-Kill-Historie in ComfyData. Kampf und Zielwahl werden nicht automatisiert.",
 INFO_THANKS="Danke, dass du ComfyKills nutzt! Feedback und Fehlermeldungen sind über Discord willkommen.",
 SHOW_TOOLTIP="Kill-Daten im Einheiten-Tooltip anzeigen",TRACK_DEATHS="Eigene Tode tracken",COUNT_PET="Kills deines Begleiters mitzählen",
 MILESTONES="Kill-Meilensteine anzeigen",OPEN_DATABASE="Kill-Datenbank öffnen",DATABASE="Datenbank",
 SUMMARY_FORMAT="%d Kills gesamt · %d verschiedene Mobs · %d Tode mit diesem Charakter",
 ALL_KILLS="Alle Kills",SESSION="Sitzung",SEARCH="Suche",MOB="Mob",KILLS="Kills",LAST_KILL="Letzter Kill",TYPE="Typ",
 TOOLTIP_CHARACTER="Dieser Charakter",TOOLTIP_ACCOUNT="Account",TOOLTIP_SESSION="Diese Sitzung",TOOLTIP_AVG_XP="Ø XP",
 FOREVER_NOTE="0.1 speichert PARTY_KILL-Ereignisse, die dir oder deinem Begleiter zugerechnet werden. Gruppenweite Zuordnung folgt nach Forever-Laufzeittests.",
}
local S=de and DE or EN
function A:T(k) return S[k] or EN[k] or k end
