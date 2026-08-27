-- RareScanner 3.3.5a compatibility backport
-- Modern vignette/map APIs do not exist on WoW 3.3.5a. This build uses the
-- creature-cache scan method used by addons of the Wrath era.

local ADDON = "RareScanner"
local UPDATE_INTERVAL = 0.12
local SCANS_PER_TICK = 12
local ALERT_SOUND = RareScanner335_Asset("Media\\alarmclockwarning2-1.ogg")

RareScannerDB = RareScannerDB or {}
local db
local scanIDs, scanOrder, baselineCached = {}, {}, {}
local scanIndex, elapsedSinceScan = 1, 0
local trackedRareGUIDs = {}
local baselineDone = false
local CLIENT_LOCALE = (GetLocale and GetLocale()) or "enUS"

function RareScanner335_GetNpcName(info)
  if not info then return nil end
  if type(info.names) == "table" then
    return info.names[CLIENT_LOCALE] or info.names.enUS
  end
  -- Backward compatibility for custom/older data structures.
  if type(info.name) == "string" then return info.name end
  return nil
end

local function chat(msg, r, g, b)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd200RareScanner:|r "..tostring(msg), r or 1, g or 0.82, b or 0)
  end
end



local function DumpKilledIDs()
  if not db then return end
  db.killed = db.killed or {}
  local ids = {}
  for npcID in pairs(db.killed) do
    table.insert(ids, tonumber(npcID) or npcID)
  end
  table.sort(ids, function(a,b) return tostring(a) < tostring(b) end)
  if #ids == 0 then
    chat(RareScanner335_L("KILL_CACHE_EMPTY"))
  else
    chat(RareScanner335_L("KILL_CACHE", #ids, table.concat(ids, ", ")))
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

local creatureModel = CreateFrame("PlayerModel", nil, button)
creatureModel:SetWidth(52); creatureModel:SetHeight(52); creatureModel:SetPoint("LEFT", 12, 0)
creatureModel:SetFrameLevel(button:GetFrameLevel() + 2)
creatureModel:Hide()

local portraitCameraPending = false

local function ApplyNpc3DPortraitCamera()
  if creatureModel.SetCamera then
    creatureModel:SetCamera(0)
  end
  if creatureModel.SetRotation then
    creatureModel:SetRotation(0)
  end
end

local function QueueNpc3DPortraitCamera()
  portraitCameraPending = true
end

local function ShowNpcVisual(npcID, unit)
  icon:Hide()
  creatureModel:Show()
  creatureModel:ClearModel()

  if unit and UnitExists(unit) and creatureModel.SetUnit then
    creatureModel:SetUnit(unit)

    -- Apply the portrait camera now and once again on the next frame.
    -- SetUnit can finish loading asynchronously and reset the model camera.
    ApplyNpc3DPortraitCamera()
    QueueNpc3DPortraitCamera()
    return
  end

  if npcID and creatureModel.SetCreature then
    creatureModel:SetCreature(npcID)
    ApplyNpc3DPortraitCamera()
    QueueNpc3DPortraitCamera()
    return
  end

  creatureModel:Hide()
  icon:Show()
  if type(RareScanner335_Asset) == "function" then
    icon:SetTexture(RareScanner335_Asset("Media\\OriginalSkull.blp"))
  else
    icon:SetTexture("Interface\\AddOns\\RareScanner\\Media\\OriginalSkull.blp")
  end
end

local title = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -3)
title:SetText("Rare détecté !")
local mob = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mob:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6); mob:SetWidth(225); mob:SetJustifyH("LEFT")
local hint = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hint:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 10, 3); hint:SetText(RareScanner335_L("CLICK_TARGET"))
button:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self,"ANCHOR_BOTTOM"); GameTooltip:SetText(RareScanner335_L("TOOLTIP_TARGET"),1,1,1); GameTooltip:Show() end)
button:SetScript("OnLeave", function() GameTooltip:Hide() end)

local hideAt
local pendingTargetName
local currentAlertNpcID
local alertPortraitUpdated = false
local currentAlertPortraitUpdated = false
button:SetScript("OnUpdate", function(self)
  if portraitCameraPending then
    portraitCameraPending = false
    ApplyNpc3DPortraitCamera()
  end
  if hideAt and GetTime() >= hideAt and not InCombatLockdown() then self:Hide(); hideAt=nil end
end)

local function Alert(npcID, detectedName, reason, portraitUnit)
  if not db or db.enabled == false then return end
  if npcID and npcID > 0 and db.killed and db.killed[npcID] and db.alertKilledRares ~= true then
    return
  end
  if not npcID or db.seen[npcID] then return end
  local info = scanIDs[npcID]
  local name = RareScanner335_GetNpcName(info) or detectedName or ("NPC "..npcID)
  currentAlertNpcID = npcID
  currentAlertPortraitUpdated = portraitUnit and UnitExists(portraitUnit) and true or false

  -- Model rendering must never prevent the alert.
  pcall(ShowNpcVisual, npcID, portraitUnit)
  mob:SetText(name)
  pendingTargetName = name
  if not InCombatLockdown() then
    button:SetAttribute("macrotext", "/targetexact "..name)
    button:Show()
    pendingTargetName = nil
  end
  db.seen[npcID] = true
  hideAt = GetTime() + (db.alertDuration or 12)
  if db.sound ~= false then PlaySoundFile(ALERT_SOUND) end
  DEFAULT_CHAT_FRAME:AddMessage(RareScanner335_L("RARE_DETECTED", name), 1, 0.35, 0.15)
end

local function RebuildScanList()
  scanIDs = {}
  for id, info in pairs(RareScanner335_NPCs or {}) do
    if not db.disabled[id] then scanIDs[id] = info end
  end
  for id, name in pairs(db.custom or {}) do
    if not db.disabled[id] then scanIDs[id] = {names={ [CLIENT_LOCALE]=name, enUS=name }, custom=true} end
  end
  scanOrder = {}
  for id in pairs(scanIDs) do table.insert(scanOrder, id) end
  table.sort(scanOrder)
  scanIndex = 1
end

local function ParseNpcIDFromGUID(guid)
  if type(guid) ~= "string" then return nil end

  -- WoW 3.3.5a creature GUID:
  -- 0xF130 + 6 hex digits CreatureID + low/spawn GUID.
  -- Example: 0xF1300001D701647E -> 0x0001D7 -> NPC 471.
  local entryHex = guid:match("^0xF130(%x%x%x%x%x%x)")
  if entryHex then
    return tonumber(entryHex, 16)
  end

  -- Alternate unit prefix used by some 3.3.5 servers.
  entryHex = guid:match("^0xF530(%x%x%x%x%x%x)")
  if entryHex then
    return tonumber(entryHex, 16)
  end

  return nil
end

local MarkRareKilled
local CountKilledRares

local function UpdateAlertPortrait(unit)
  if alertPortraitUpdated then return end
  if not currentAlertNpcID or not button:IsShown() then return end
  if UnitExists(unit) and not UnitIsPlayer(unit) then
    local id = ParseNpcIDFromGUID(UnitGUID(unit))
    if id and id == currentAlertNpcID then
      ShowNpcVisual(id, unit)
      alertPortraitUpdated = true
    end
  end
end

local function CheckUnit(unit)
  if not db or db.enabled == false then return end
  if UnitExists(unit) and not UnitIsPlayer(unit) then
    local guid = UnitGUID(unit)
    local id = ParseNpcIDFromGUID(guid)
    if id and scanIDs[id] then
      if guid then
        trackedRareGUIDs[guid] = id
      end
      local isDead = (UnitIsDead and UnitIsDead(unit)) or (UnitHealth and UnitHealth(unit) <= 0)
      if isDead then
        if MarkRareKilled then MarkRareKilled(id) end
      end
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


MarkRareKilled = function(npcID)
  if not db then
    return
  end
  if not npcID then
    return
  end
  if not scanIDs[npcID] then
    return
  end
  db.killed = db.killed or {}
  local existed = db.killed[npcID] and true or false
  db.killed[npcID] = true
end

local function ResetKilledHistory()
  if not db then return end
  db.killed = {}
end

CountKilledRares = function()
  local count = 0
  for _ in pairs((db and db.killed) or {}) do
    count = count + 1
  end
  return count
end

local function CountEncounterHistory()
  local count = 0
  for _ in pairs((db and db.seen) or {}) do
    count = count + 1
  end
  return count
end

local optionsPanel

local function BuildOptionsPanel()
  if optionsPanel then return optionsPanel end

  local panel = CreateFrame("Frame", "RareScanner335OptionsPanel")
  panel.name = RareScanner335_L("ADDON_NAME")

  local titleText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  titleText:SetPoint("TOPLEFT", 16, -16)
  titleText:SetText(RareScanner335_L("ADDON_NAME"))

  local enableCB = CreateFrame("CheckButton", "RareScanner335OptEnabled", panel, "InterfaceOptionsCheckButtonTemplate")
  enableCB:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", -2, -18)
  _G["RareScanner335OptEnabledText"]:SetText(RareScanner335_L("ENABLE_ADDON"))
  enableCB.tooltipText = RareScanner335_L("ENABLE_ADDON_TOOLTIP")

  local soundCB = CreateFrame("CheckButton", "RareScanner335OptSound", panel, "InterfaceOptionsCheckButtonTemplate")
  soundCB:SetPoint("TOPLEFT", enableCB, "BOTTOMLEFT", 0, -6)
  _G["RareScanner335OptSoundText"]:SetText(RareScanner335_L("ENABLE_SOUND"))
  soundCB.tooltipText = RareScanner335_L("ENABLE_SOUND_TOOLTIP")

  local alertKilledCB = CreateFrame("CheckButton", "RareScanner335OptAlertKilledRares", panel, "InterfaceOptionsCheckButtonTemplate")
  alertKilledCB:SetPoint("TOPLEFT", soundCB, "BOTTOMLEFT", 0, -6)
  _G["RareScanner335OptAlertKilledRaresText"]:SetText(RareScanner335_L("ALERT_KILLED_RARES"))
  alertKilledCB.tooltipText = RareScanner335_L("ALERT_KILLED_RARES_TOOLTIP")

  local mapCB = CreateFrame("CheckButton", "RareScanner335OptShowOnMap", panel, "InterfaceOptionsCheckButtonTemplate")
  mapCB:SetPoint("TOPLEFT", alertKilledCB, "BOTTOMLEFT", 0, -6)
  _G["RareScanner335OptShowOnMapText"]:SetText(RareScanner335_L("SHOW_ON_MAP"))
  mapCB.tooltipText = RareScanner335_L("SHOW_ON_MAP_TOOLTIP")

  local killedMapCB = CreateFrame("CheckButton", "RareScanner335OptShowKilledOnMap", panel, "InterfaceOptionsCheckButtonTemplate")
  killedMapCB:SetPoint("TOPLEFT", mapCB, "BOTTOMLEFT", 0, -6)
  _G["RareScanner335OptShowKilledOnMapText"]:SetText(RareScanner335_L("SHOW_KILLED_ON_MAP"))
  killedMapCB.tooltipText = RareScanner335_L("SHOW_KILLED_ON_MAP_TOOLTIP")

  local resetButton, resetKillsButton

  local function RefreshPanel()
    if not db then return end
    enableCB:SetChecked(db.enabled ~= false)
    soundCB:SetChecked(db.sound ~= false)
    alertKilledCB:SetChecked(db.alertKilledRares == true)
    mapCB:SetChecked(db.showOnMap ~= false)
    killedMapCB:SetChecked(db.showKilledOnMap == true)
    if resetButton then
      resetButton:SetText(RareScanner335_L("RESET_ENCOUNTERS", CountEncounterHistory()))
    end
    if resetKillsButton then
      resetKillsButton:SetText(RareScanner335_L("RESET_KILLS", CountKilledRares()))
    end
    if db.enabled ~= false then
      soundCB:Enable()
      alertKilledCB:Enable()
      mapCB:Enable()
      killedMapCB:Enable()
      if resetButton then resetButton:Enable() end
      if resetKillsButton then resetKillsButton:Enable() end
    else
      soundCB:Disable()
      alertKilledCB:Disable()
      mapCB:Disable()
      killedMapCB:Disable()
      if resetButton then resetButton:Disable() end
      if resetKillsButton then resetKillsButton:Disable() end
    end
  end

  enableCB:SetScript("OnClick", function(self)
    db.enabled = self:GetChecked() and true or false
    if not db.enabled then
      button:Hide()
      hideAt = nil
      pendingTargetName = nil
      currentAlertNpcID = nil
    end
    RefreshPanel()
    if type(RareScanner335_UpdateMapPins) == "function" then
      RareScanner335_UpdateMapPins()
    end
    if type(RareScanner335_UpdateMapOptionsButton) == "function" then
      RareScanner335_UpdateMapOptionsButton()
    end
  end)

  soundCB:SetScript("OnClick", function(self)
    db.sound = self:GetChecked() and true or false
  end)

  alertKilledCB:SetScript("OnClick", function(self)
    db.alertKilledRares = self:GetChecked() and true or false
  end)

  mapCB:SetScript("OnClick", function(self)
    db.showOnMap = self:GetChecked() and true or false
    RefreshPanel()
    if type(RareScanner335_UpdateMapPins) == "function" then
      RareScanner335_UpdateMapPins()
    end
  end)

  killedMapCB:SetScript("OnClick", function(self)
    db.showKilledOnMap = self:GetChecked() and true or false
    if type(RareScanner335_UpdateMapPins) == "function" then
      RareScanner335_UpdateMapPins()
    end
  end)

  resetButton = CreateFrame("Button", "RareScanner335OptReset", panel, "UIPanelButtonTemplate")
  resetButton:SetWidth(285)
  resetButton:SetHeight(22)
  resetButton:SetPoint("TOPLEFT", killedMapCB, "BOTTOMLEFT", 2, -18)
  resetButton:SetText(RareScanner335_L("RESET_ENCOUNTERS", CountEncounterHistory()))
  resetButton:SetScript("OnClick", function()
    ResetAlertHistory()
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(RareScanner335_L("RESET_ENCOUNTERS_MESSAGE")) end
    if resetButton then resetButton:SetText(RareScanner335_L("RESET_ENCOUNTERS", CountEncounterHistory())) end
  end)
  resetKillsButton = CreateFrame("Button", "RareScanner335OptResetKills", panel, "UIPanelButtonTemplate")
  resetKillsButton:SetWidth(285)
  resetKillsButton:SetHeight(22)
  resetKillsButton:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -8)
  resetKillsButton:SetText(RareScanner335_L("RESET_KILLS", CountKilledRares()))
  resetKillsButton:SetScript("OnClick", function()
    ResetKilledHistory()
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(RareScanner335_L("RESET_KILLS_MESSAGE")) end
    if resetKillsButton then resetKillsButton:SetText(RareScanner335_L("RESET_KILLS", CountKilledRares())) end
  end)

  panel.refresh = RefreshPanel
  panel:SetScript("OnShow", RefreshPanel)
  panel.okay = function() end
  panel.cancel = function() RefreshPanel() end
  panel.default = function()
    db.enabled = true
    db.sound = true
    db.alertKilledRares = false
    db.showOnMap = true
    db.showKilledOnMap = false
    RefreshPanel()
  end

  InterfaceOptions_AddCategory(panel)
  optionsPanel = panel
  return panel
end

-- Register the Interface > AddOns panel as soon as this file is loaded.
-- The panel refresh function safely handles db == nil until PLAYER_LOGIN.
BuildOptionsPanel()

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("UNIT_HEALTH")
frame:SetScript("OnEvent", function(self,event, ...)
  if event == "PLAYER_LOGIN" then
    RareScannerDB = RareScannerDB or {}
    db = RareScannerDB
    db.disabled = db.disabled or {}
    db.custom = db.custom or {}
    db.seen = db.seen or {}
    db.killed = db.killed or {}
    if db.enabled == nil then db.enabled = true end
    if db.sound == nil then db.sound = true end
    if db.showOnMap == nil then db.showOnMap = true end
    if db.showKilledOnMap == nil then db.showKilledOnMap = false end
    if db.alertKilledRares == nil then db.alertKilledRares = false end
    db.alertDuration = tonumber(db.alertDuration) or 12
    RebuildScanList()
    if optionsPanel and optionsPanel.refresh then optionsPanel.refresh() end
  elseif event == "PLAYER_TARGET_CHANGED" then
    if db then CheckUnit("target") end
  elseif event == "UPDATE_MOUSEOVER_UNIT" then
    if db then CheckUnit("mouseover") end
  elseif event == "PLAYER_FOCUS_CHANGED" then
    if db then CheckUnit("focus") end
  elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
    -- Diagnostic build: support both vararg payloads and legacy argN globals.
    local argc = select("#", ...)
    local subEvent = select(2, ...)
    local sourceGUID = select(3, ...)
    local sourceName = select(4, ...)
    local destGUID = select(6, ...)
    local destName = select(7, ...)

    if not subEvent and arg2 then subEvent = arg2 end
    if not sourceGUID and arg3 then sourceGUID = arg3 end
    if not sourceName and arg4 then sourceName = arg4 end
    if not destGUID and arg6 then destGUID = arg6 end
    if not destName and arg7 then destName = arg7 end

    if subEvent == "UNIT_DIED" or subEvent == "UNIT_DESTROYED" or subEvent == "PARTY_KILL" then
      local trackedID = destGUID and trackedRareGUIDs[destGUID]
      local parsedID = ParseNpcIDFromGUID(destGUID)
      local npcID = trackedID or parsedID
      if npcID and scanIDs[npcID] then
        MarkRareKilled(npcID)
      end
      if destGUID then trackedRareGUIDs[destGUID] = nil end
    end
  elseif event == "UNIT_HEALTH" then
    local unit = ...
    if unit == "target" or unit == "mouseover" or unit == "focus" then
      CheckUnit(unit)
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    CheckUnit("target")
    CheckUnit("mouseover")
    CheckUnit("focus")
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

  -- Direct unit tokens are the most reliable way to identify a rare that is
  -- already present in the client cache. Poll them as well as listening to
  -- events, because some 3.3.5a clients/private servers can miss or delay the
  -- target/mouseover event.
  CheckUnit("target")
  CheckUnit("mouseover")
  CheckUnit("focus")

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
SLASH_RARESCANNER3353 = "/r"
SlashCmdList["RARESCANNER335"] = function(msg)
  msg = msg or ""
  local cmd, rest = msg:match("^%s*(%S*)%s*(.-)%s*$")
  cmd = string.lower(cmd or "")
  if cmd == "" or cmd == "help" then
    chat("Commandes: /rs test | add <ID> <nom> | remove <ID> | enable <ID> | disable <ID> | sound on/off | reset [ID] | resetkills | kills | status")
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
      if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(RareScanner335_L("RESET_ENCOUNTERS_MESSAGE")) end
    end
  elseif cmd == "resetkills" then
    ResetKilledHistory()
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(RareScanner335_L("RESET_KILLS_MESSAGE")) end
  elseif cmd == "kills" then
    DumpKilledIDs()
  elseif cmd == "status" then
    local c=0; for _ in pairs(baselineCached) do c=c+1 end
    local s=0; for _ in pairs(db.seen or {}) do s=s+1 end
    chat("RareScanner: "..(db.enabled ~= false and "on" or "off").."; PNJ suivis: "..#scanOrder.."; cache WDB: "..c.."; historique: "..s.."; rares tués: "..CountKilledRares().."; son: "..(db.sound and "on" or "off"))
  else
    chat("Commande inconnue. /rs help")
  end
end
