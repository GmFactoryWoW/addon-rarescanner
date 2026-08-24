-- RareScanner 3.3.5a compatibility backport
-- Modern vignette/map APIs do not exist on WoW 3.3.5a. This build uses the
-- creature-cache scan method used by addons of the Wrath era.

local ADDON = "RareScanner"
local UPDATE_INTERVAL = 0.12
local SCANS_PER_TICK = 12
local ALERT_SOUND = "Interface\\AddOns\\RareScanner\\Media\\alarmclockwarning2-1.ogg"

RareScannerDB = RareScannerDB or {}
local db
local scanIDs, scanOrder, baselineCached = {}, {}, {}
local scanIndex, elapsedSinceScan = 1, 0
local baselineDone = false

local function chat(msg, r, g, b)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd200RareScanner:|r "..tostring(msg), r or 1, g or 0.82, b or 0)
  end
end

local scanTooltip = CreateFrame("GameTooltip", "RareScanner335ScanTooltip")
local scanText = scanTooltip:CreateFontString()
scanTooltip:AddFontStrings(scanText, scanTooltip:CreateFontString())

local function TestID(npcID)
  scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
  scanTooltip:SetHyperlink(("unit:0xF5300%05X000000"):format(npcID))
  if scanTooltip:IsShown() then
    local name = scanText:GetText()
    scanTooltip:Hide()
    return name
  end
  scanTooltip:Hide()
end

local button = CreateFrame("Button", "RareScanner335AlertButton", UIParent, "SecureActionButtonTemplate")
button:SetWidth(310); button:SetHeight(74)
button:SetPoint("TOP", UIParent, "TOP", 0, -135)
button:SetFrameStrata("DIALOG")
button:SetMovable(true); button:EnableMouse(true); button:RegisterForDrag("LeftButton")
button:SetScript("OnDragStart", function(self) if not InCombatLockdown() then self:StartMoving() end end)
button:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
button:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileSize=32, edgeSize=24, insets={left=6,right=6,top=6,bottom=6}})
button:SetBackdropColor(0.08,0.08,0.08,0.96)
button:RegisterForClicks("AnyUp")
button:SetAttribute("type", "macro")
button:Hide()

local icon = button:CreateTexture(nil, "ARTWORK")
icon:SetWidth(52); icon:SetHeight(52); icon:SetPoint("LEFT", 12, 0)
icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

-- WoW 3.3.5a cannot build a 2D portrait from an NPC ID alone. However,
-- PlayerModel:SetCreature(entryID) exists in Wrath and can render the cached
-- creature model even when no target/mouseover unit token is available.
local creatureModel = CreateFrame("PlayerModel", nil, button)
creatureModel:SetWidth(52); creatureModel:SetHeight(52); creatureModel:SetPoint("LEFT", 12, 0)
creatureModel:SetFrameLevel(button:GetFrameLevel() + 2)
creatureModel:Hide()

local function ShowNpcVisual(npcID, unit)
  if unit and UnitExists(unit) then
    creatureModel:Hide()
    icon:Show()
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    SetPortraitTexture(icon, unit)
    return
  end

  -- Cache-only detection: render the creature itself instead of a question mark.
  -- SetCreature uses the creature entry ID and works once that creature is cached.
  icon:Hide()
  creatureModel:Show()
  creatureModel:ClearModel()
  creatureModel:SetCreature(npcID)
  if creatureModel.SetCamera then creatureModel:SetCamera(0) end
end
local title = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -3)
title:SetText("Rare détecté !")
local mob = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mob:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6); mob:SetWidth(225); mob:SetJustifyH("LEFT")
local hint = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hint:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 10, 3); hint:SetText("Clique pour /targetexact")
button:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self,"ANCHOR_BOTTOM"); GameTooltip:SetText("Clic: tente de cibler le PNJ détecté.",1,1,1); GameTooltip:Show() end)
button:SetScript("OnLeave", function() GameTooltip:Hide() end)

local hideAt
local pendingTargetName
local currentAlertNpcID
button:SetScript("OnUpdate", function(self)
  if hideAt and GetTime() >= hideAt and not InCombatLockdown() then self:Hide(); hideAt=nil end
end)

local function Alert(npcID, detectedName, reason, portraitUnit)
  if not db or db.enabled == false then return end
  if not npcID or db.seen[npcID] then return end
  db.seen[npcID] = true
  local info = scanIDs[npcID]
  local name = detectedName or (info and info.name) or ("NPC "..npcID)
  currentAlertNpcID = npcID
  ShowNpcVisual(npcID, portraitUnit)
  mob:SetText(name)
  pendingTargetName = name
  if not InCombatLockdown() then
    button:SetAttribute("macrotext", "/targetexact "..name)
    button:Show()
    pendingTargetName = nil
  end
  hideAt = GetTime() + (db.alertDuration or 12)
  if db.sound ~= false then PlaySoundFile(ALERT_SOUND) end
  DEFAULT_CHAT_FRAME:AddMessage("Rare détecté : "..name, 1, 0.35, 0.15)
end

local function RebuildScanList()
  scanIDs = {}
  for id, info in pairs(RareScanner335_NPCs or {}) do
    if not db.disabled[id] then scanIDs[id] = info end
  end
  for id, name in pairs(db.custom or {}) do
    if not db.disabled[id] then scanIDs[id] = {name=name, zoneID=0, custom=true} end
  end
  scanOrder = {}
  for id in pairs(scanIDs) do table.insert(scanOrder, id) end
  table.sort(scanOrder)
  scanIndex = 1
end

local function ParseNpcIDFromGUID(guid)
  if not guid or type(guid) ~= "string" then return end
  -- Patch 3.3.x GUID example: 0xF130890300002235
  -- NPC entry is hexadecimal characters 7-10 (8903 in this example).
  if guid:match("^0xF[0-9A-Fa-f][0-9A-Fa-f]30") or guid:match("^0xF[0-9A-Fa-f]30") then
    return tonumber(guid:sub(7,10), 16)
  end
  -- Generic Wrath creature/pet/vehicle-style hexadecimal GUID fallback.
  if guid:match("^0xF") and #guid >= 10 then
    return tonumber(guid:sub(7,10), 16)
  end
end

local function UpdateAlertPortrait(unit)
  if not currentAlertNpcID or not button:IsShown() then return end
  if UnitExists(unit) and not UnitIsPlayer(unit) then
    local id = ParseNpcIDFromGUID(UnitGUID(unit))
    if id and id == currentAlertNpcID then ShowNpcVisual(id, unit) end
  end
end

local function CheckUnit(unit)
  if not db or db.enabled == false then return end
  if UnitExists(unit) and not UnitIsPlayer(unit) then
    local id = ParseNpcIDFromGUID(UnitGUID(unit))
    if id and scanIDs[id] then
      UpdateAlertPortrait(unit)
      Alert(id, UnitName(unit), unit, unit)
    end
  end
end

local function ResetAlertHistory(id)
  if id then
    -- Rearm only this NPC in RareScanner's own alert history.
    -- The WDB baseline is deliberately left untouched.
    db.seen[id] = nil
  else
    -- Global reset only clears RareScanner's own persistent alert history.
    -- Never clear the WDB baseline here: doing so would make every creature
    -- already cached by the client look newly discovered and cause false alerts.
    db.seen = {}
  end

  -- If the rare is actually in front of the player, allow it to alert again
  -- immediately through a real unit token.
  CheckUnit("target")
  CheckUnit("mouseover")
end

local optionsPanel

local function BuildOptionsPanel()
  if optionsPanel then return optionsPanel end

  local panel = CreateFrame("Frame", "RareScanner335OptionsPanel")
  panel.name = "RareScanner"

  local titleText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  titleText:SetPoint("TOPLEFT", 16, -16)
  titleText:SetText("RareScanner")

  local enableCB = CreateFrame("CheckButton", "RareScanner335OptEnabled", panel, "InterfaceOptionsCheckButtonTemplate")
  enableCB:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", -2, -18)
  _G["RareScanner335OptEnabledText"]:SetText("Activer RareScanner")
  enableCB.tooltipText = "Active ou désactive toutes les alertes de RareScanner."

  local soundCB = CreateFrame("CheckButton", "RareScanner335OptSound", panel, "InterfaceOptionsCheckButtonTemplate")
  soundCB:SetPoint("TOPLEFT", enableCB, "BOTTOMLEFT", 0, -6)
  _G["RareScanner335OptSoundText"]:SetText("Activer l'alerte sonore")
  soundCB.tooltipText = "Joue un son lorsqu'un PNJ rare est détecté."

  local mapCB = CreateFrame("CheckButton", "RareScanner335OptShowOnMap", panel, "InterfaceOptionsCheckButtonTemplate")
  mapCB:SetPoint("TOPLEFT", soundCB, "BOTTOMLEFT", 0, -6)
  _G["RareScanner335OptShowOnMapText"]:SetText("Afficher les rares sur la carte du monde")
  mapCB.tooltipText = "Affiche ou masque les points d'apparition des rares sur la carte du monde."

  local function RefreshPanel()
    if not db then return end
    enableCB:SetChecked(db.enabled ~= false)
    soundCB:SetChecked(db.sound ~= false)
    mapCB:SetChecked(db.showOnMap ~= false)
    if db.enabled ~= false then
      soundCB:Enable()
    else
      soundCB:Disable()
    end
  end

  enableCB:SetScript("OnClick", function(self)
    db.enabled = self:GetChecked() and true or false
    if db.enabled then
      soundCB:Enable()
    else
      soundCB:Disable()
      button:Hide()
      hideAt = nil
      pendingTargetName = nil
      currentAlertNpcID = nil
    end
  end)

  soundCB:SetScript("OnClick", function(self)
    db.sound = self:GetChecked() and true or false
  end)

  mapCB:SetScript("OnClick", function(self)
    db.showOnMap = self:GetChecked() and true or false
    if type(RareScanner335_UpdateMapPins) == "function" then
      RareScanner335_UpdateMapPins()
    end
  end)

  local resetButton = CreateFrame("Button", "RareScanner335OptReset", panel, "UIPanelButtonTemplate")
  resetButton:SetWidth(110)
  resetButton:SetHeight(22)
  resetButton:SetPoint("TOPLEFT", mapCB, "BOTTOMLEFT", 2, -18)
  resetButton:SetText("Réinitialiser")
  resetButton:SetScript("OnClick", function()
    ResetAlertHistory()
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Historique des alertes réinitialisé.") end
  end)

  panel.refresh = RefreshPanel
  panel:SetScript("OnShow", RefreshPanel)
  panel.okay = function() end
  panel.cancel = function() RefreshPanel() end
  panel.default = function()
    db.enabled = true
    db.sound = true
    db.showOnMap = true
    RefreshPanel()
  end

  InterfaceOptions_AddCategory(panel)
  optionsPanel = panel
  return panel
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:SetScript("OnEvent", function(self,event)
  if event == "PLAYER_LOGIN" then
    RareScannerDB = RareScannerDB or {}
    db = RareScannerDB
    db.disabled = db.disabled or {}
    db.custom = db.custom or {}
    db.seen = db.seen or {}
    if db.enabled == nil then db.enabled = true end
    if db.sound == nil then db.sound = true end
    if db.showOnMap == nil then db.showOnMap = true end
    db.alertDuration = tonumber(db.alertDuration) or 12
    RebuildScanList()
    BuildOptionsPanel()
  elseif event == "PLAYER_TARGET_CHANGED" then
    if db then CheckUnit("target") end
  elseif event == "UPDATE_MOUSEOVER_UNIT" then
    if db then CheckUnit("mouseover") end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if pendingTargetName then
      button:SetAttribute("macrotext", "/targetexact "..pendingTargetName)
      pendingTargetName = nil
    end
    if db and db.enabled ~= false and hideAt and GetTime() < hideAt then button:Show() elseif hideAt then button:Hide(); hideAt=nil end
  end
end)

frame:SetScript("OnUpdate", function(self, elapsed)
  if not db or db.enabled == false or #scanOrder == 0 then return end
  elapsedSinceScan = elapsedSinceScan + elapsed
  if elapsedSinceScan < UPDATE_INTERVAL then return end
  elapsedSinceScan = 0
  for n=1,SCANS_PER_TICK do
    if scanIndex > #scanOrder then
      scanIndex = 1
      if not baselineDone then
        baselineDone = true

      end
    end
    local id = scanOrder[scanIndex]
    scanIndex = scanIndex + 1
    local name = TestID(id)
    if not baselineDone then
      if name then baselineCached[id] = name end
    elseif name and not baselineCached[id] then
      Alert(id, name, "cache")
      baselineCached[id] = name
    end
  end
end)

SLASH_RARESCANNER3351 = "/rarescanner"
SLASH_RARESCANNER3352 = "/rs"
SlashCmdList["RARESCANNER335"] = function(msg)
  msg = msg or ""
  local cmd, rest = msg:match("^%s*(%S*)%s*(.-)%s*$")
  cmd = string.lower(cmd or "")
  if cmd == "" or cmd == "help" then
    chat("Commandes: /rs test | add <ID> <nom> | remove <ID> | enable <ID> | disable <ID> | sound on/off | reset [ID] | status")
  elseif cmd == "test" then
    db.seen[-1]=nil; Alert(-1, "Test RareScanner", "test")
  elseif cmd == "add" then
    local id, name = rest:match("^(%d+)%s+(.+)$")
    id=tonumber(id)
    if id and name then db.custom[id]=name; db.disabled[id]=nil; RebuildScanList(); chat("PNJ ajouté: "..name.." ["..id.."]") else chat("Usage: /rs add <ID> <nom>") end
  elseif cmd == "remove" then
    local id=tonumber(rest); if id and db.custom[id] then db.custom[id]=nil; RebuildScanList(); chat("PNJ personnalisé supprimé: "..id) else chat("ID personnalisé introuvable.") end
  elseif cmd == "disable" then
    local id=tonumber(rest); if id then db.disabled[id]=true; RebuildScanList(); chat("Scan désactivé pour ID "..id) end
  elseif cmd == "enable" then
    local id=tonumber(rest); if id then db.disabled[id]=nil; RebuildScanList(); chat("Scan activé pour ID "..id) end
  elseif cmd == "sound" then
    if rest == "off" then db.sound=false; chat("Son désactivé.") elseif rest == "on" then db.sound=true; chat("Son activé.") else chat("Usage: /rs sound on|off") end
  elseif cmd == "reset" then
    local id = tonumber(rest)
    if id then
      ResetAlertHistory(id)
      chat("Alerte réarmée pour ID "..id..".")
    else
      ResetAlertHistory()
      if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Historique des alertes réinitialisé.") end
    end
  elseif cmd == "status" then
    local c=0; for _ in pairs(baselineCached) do c=c+1 end
    local s=0; for _ in pairs(db.seen or {}) do s=s+1 end
    chat("RareScanner: "..(db.enabled ~= false and "on" or "off").."; PNJ suivis: "..#scanOrder.."; cache WDB: "..c.."; historique: "..s.."; son: "..(db.sound and "on" or "off"))
  else
    chat("Commande inconnue. /rs help")
  end
end