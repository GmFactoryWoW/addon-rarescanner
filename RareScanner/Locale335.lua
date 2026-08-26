-- RareScanner 3.3.5a UI localization
RareScanner335_Locales = RareScanner335_Locales or {}

RareScanner335_Locales.enUS = {
  ADDON_NAME = "RareScanner",
  ENABLE_ADDON = "Enable RareScanner",
  ENABLE_ADDON_TOOLTIP = "Enable or disable all RareScanner alerts.",
  ENABLE_SOUND = "Enable alert sound",
  ENABLE_SOUND_TOOLTIP = "Play a sound when a rare NPC is detected.",
  SHOW_ON_MAP = "Show rares on the World Map",
  SHOW_ON_MAP_TOOLTIP = "Show or hide rare spawn locations on the World Map.",
  SHOW_KILLED_ON_MAP = "Show already killed rares on the World Map",
  SHOW_KILLED_ON_MAP_TOOLTIP = "Show or hide rares already recorded as killed.",
  MAP_MENU_SHOW_RARES = "Show rares",
  MAP_MENU_SHOW_KILLED = "Show already killed rares",
  RESET_ENCOUNTERS = "Reset encounter cache (%d)",
  RESET_ENCOUNTERS_MESSAGE = "Encounter cache reset.",
  RESET_KILLS = "Reset killed rares cache (%d)",
  RESET_KILLS_MESSAGE = "Killed rares cache reset.",
  RARE_DETECTED = "Rare detected: %s",
  CLICK_TARGET = "Click to /targetexact",
  TOOLTIP_TARGET = "Click: tries to target the detected NPC.",
  KILL_CACHE_EMPTY = "Killed rares cache: empty",
  KILL_CACHE = "Killed rares cache (%d): %s",
}

RareScanner335_Locales.frFR = {
  ADDON_NAME = "RareScanner",
  ENABLE_ADDON = "Activer RareScanner",
  ENABLE_ADDON_TOOLTIP = "Active ou désactive toutes les alertes de RareScanner.",
  ENABLE_SOUND = "Activer l'alerte sonore",
  ENABLE_SOUND_TOOLTIP = "Joue un son lorsqu'un PNJ rare est détecté.",
  SHOW_ON_MAP = "Afficher les rares sur la carte du monde",
  SHOW_ON_MAP_TOOLTIP = "Affiche ou masque les points d'apparition des rares sur la carte du monde.",
  SHOW_KILLED_ON_MAP = "Afficher les rares déjà tués sur la carte du monde",
  SHOW_KILLED_ON_MAP_TOOLTIP = "Affiche ou masque sur la carte les rares déjà enregistrés comme tués.",
  MAP_MENU_SHOW_RARES = "Afficher les rares",
  MAP_MENU_SHOW_KILLED = "Afficher les rares déjà tués",
  RESET_ENCOUNTERS = "Réinitialiser le cache de rencontres (%d)",
  RESET_ENCOUNTERS_MESSAGE = "Historique des alertes réinitialisé.",
  RESET_KILLS = "Réinitialiser le cache des rares tués (%d)",
  RESET_KILLS_MESSAGE = "Cache des rares tués réinitialisé.",
  RARE_DETECTED = "Rare détecté : %s",
  CLICK_TARGET = "Clique pour /targetexact",
  TOOLTIP_TARGET = "Clic: tente de cibler le PNJ détecté.",
  KILL_CACHE_EMPTY = "Cache rares tués: vide",
  KILL_CACHE = "Cache rares tués (%d): %s",
}

local clientLocale = (GetLocale and GetLocale()) or "enUS"
local activeLocale = RareScanner335_Locales[clientLocale] or RareScanner335_Locales.enUS

function RareScanner335_L(key, ...)
  local value = activeLocale[key] or RareScanner335_Locales.enUS[key] or key
  if select("#", ...) > 0 then
    return string.format(value, ...)
  end
  return value
end
