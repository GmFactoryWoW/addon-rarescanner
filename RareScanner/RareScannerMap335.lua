-- RareScanner 3.3.5a world-map spawn pins

local ICON_TEXTURE = RareScanner335_Asset("Media\\OriginalSkull.blp")
local KILLED_ICON_TEXTURE = RareScanner335_Asset("Media\\BlueSkullLight.blp")

-- AzerothCore map IDs -> WoW 3.3.5 continent indexes.
local MAP_TO_CONTINENT = {
  [0] = 2,   -- Eastern Kingdoms
  [1] = 1,   -- Kalimdor
  [530] = 3, -- Outland
  [571] = 4, -- Northrend
}

-- { worldY1, worldY2, worldX1, worldX2 }
local CONTINENT_COORDS = {
  [1] = { 17066.5996094, -19733.2109375, 12799.9003906, -11733.2998047 }, -- Kalimdor
  [2] = { 18171.9707031, -22569.2109375, 11176.34375,   -15973.34375   }, -- Eastern Kingdoms
  [3] = { 12996.0390625, -4468.0390625,   5821.359375,  -5821.359375   }, -- Outland
  [4] = { 9217.15234375, -8534.24609375,  10593.375,    -1240.89001465 }, -- Northrend
}

local Astrolabe = DongleStub and DongleStub("Astrolabe-0.4")
local pins = {}
local activePins = 0



local FADE_DURATION = 0.5
local fadingTextures = {}
local fadeDriver = CreateFrame("Frame")
fadeDriver:Hide()

fadeDriver:SetScript("OnUpdate", function(self, elapsed)
  local active = false
  for texture, fade in pairs(fadingTextures) do
    fade.elapsed = fade.elapsed + elapsed
    local progress = fade.elapsed / FADE_DURATION
    if progress >= 1 then
      texture:SetAlpha(fade.to)
      fadingTextures[texture] = nil
    else
      texture:SetAlpha(fade.from + (fade.to - fade.from) * progress)
      active = true
    end
  end

  if not active then
    for _ in pairs(fadingTextures) do
      active = true
      break
    end
  end

  if not active then
    self:Hide()
  end
end)

local function RareScanner335_FadePin(texture, targetAlpha)
  if not texture then return end

  local currentAlpha = texture:GetAlpha() or 1
  if math.abs(currentAlpha - targetAlpha) < 0.001 then
    texture:SetAlpha(targetAlpha)
    fadingTextures[texture] = nil
    return
  end

  -- Restart from the actual current alpha every time the mouse changes pin.
  fadingTextures[texture] = {
    from = currentAlpha,
    to = targetAlpha,
    elapsed = 0,
  }
  fadeDriver:Show()
end


local function RareScanner335_GetLevelColorCode(minlevel, maxlevel)
  if not minlevel or not maxlevel then return "" end

  local playerLevel = UnitLevel("player") or 0
  local lowThreshold
  if playerLevel < 60 then
    lowThreshold = minlevel - 2
  else
    lowThreshold = minlevel - 1
  end

  if minlevel <= 0 then
    return GRAY_FONT_COLOR_CODE or "|cff808080"
  elseif playerLevel < lowThreshold then
    return RED_FONT_COLOR_CODE or "|cffff2020"
  elseif playerLevel > maxlevel + 3 then
    return GRAY_FONT_COLOR_CODE or "|cff808080"
  elseif playerLevel >= maxlevel and playerLevel <= maxlevel + 3 then
    return GREEN_FONT_COLOR_CODE or "|cff20ff20"
  elseif playerLevel > minlevel and playerLevel < maxlevel then
    return YELLOW_FONT_COLOR_CODE or "|cffffff00"
  elseif playerLevel >= lowThreshold and playerLevel <= minlevel then
    return ORANGE_FONT_COLOR_CODE or "|cffff8040"
  end

  return NORMAL_FONT_COLOR_CODE or "|cffffffff"
end

local function RareScanner335_IsRegionMap()
  -- On WoW 3.3.5a: GetCurrentMapContinent() > 0 and GetCurrentMapZone() > 0
  -- means a specific region/zone map is being viewed.
  local continent = GetCurrentMapContinent and GetCurrentMapContinent() or 0
  local zone = GetCurrentMapZone and GetCurrentMapZone() or 0
  return continent and continent > 0 and zone and zone > 0
end

local function RareScanner335_IsContinentMap()
  local continent = GetCurrentMapContinent and GetCurrentMapContinent() or 0
  local zone = GetCurrentMapZone and GetCurrentMapZone() or 0
  return continent and continent > 0 and (not zone or zone == 0)
end


local focusedNpcID
local leaveResetPending = false

local function SetRegionFocus(npcID)
  if not RareScanner335_IsRegionMap() then return end
  focusedNpcID = npcID

  for i = 1, activePins do
    local pin = pins[i]
    if pin and pin:IsShown() and pin.texture then
      local targetAlpha = 1.0
      if npcID and pin.npcID ~= npcID then
        targetAlpha = 0.40
      end
      RareScanner335_FadePin(pin.texture, targetAlpha)
    end
  end
end

local function WorldToContinent(continent, worldX, worldY)
  local bounds = CONTINENT_COORDS[continent]
  if not bounds then return end

  -- and the normalized X axis as the second one for WoW world coordinates.
  local normalizedY = math.abs(worldY - bounds[1]) / math.abs(bounds[2] - bounds[1])
  local normalizedX = math.abs(worldX - bounds[3]) / math.abs(bounds[4] - bounds[3])
  return normalizedY, normalizedX
end


local mapOptionsButton
local mapOptionsMenuFrame

local function MapMenuText(key, fallback)
  if type(RareScanner335_L) == "function" then
    return RareScanner335_L(key)
  end
  return fallback
end

local function UpdateMapOptionsButtonVisibility()
  if not mapOptionsButton then return end

  if RareScannerDB and RareScannerDB.enabled == false then
    mapOptionsButton:Hide()
  elseif WorldMapButton and WorldMapButton:IsShown() then
    mapOptionsButton:Show()
  end
end

function RareScanner335_UpdateMapOptionsButton()
  UpdateMapOptionsButtonVisibility()
end

local function CreateMapOptionsButton()
  if mapOptionsButton or not WorldMapButton then return end

  mapOptionsButton = CreateFrame("Button", "RareScanner335MapOptionsButton", WorldMapButton)
  mapOptionsButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  mapOptionsButton:ClearAllPoints()
  mapOptionsButton:SetFrameStrata("TOOLTIP")
  mapOptionsButton:SetFrameLevel(WorldMapButton:GetFrameLevel() + 2)
  mapOptionsButton:SetWidth(32)
  mapOptionsButton:SetHeight(32)
  mapOptionsButton:RegisterForClicks("LeftButtonUp")
  local function UpdateMapOptionsButtonPosition()
    if not mapOptionsButton or not WorldMapButton then return end

    mapOptionsButton:ClearAllPoints()

    -- Compatibility positioning for Questie and WDM.
    -- Questie exposes its current World Map control through Questie.WorldMap.Button
    -- and already moves itself around other direct TOPRIGHT controls. Anchoring
    -- RareScanner to Questie instead of WorldMapButton prevents both addons from
    -- repeatedly pushing each other farther left. WDM uses a stable named button,
    -- so it is the fallback external anchor when Questie is absent or hidden.
    local questieButton = _G.Questie and _G.Questie.WorldMap and _G.Questie.WorldMap.Button
    local wdmButton = _G.WDM_WorldMapButton

    if questieButton and questieButton ~= mapOptionsButton and questieButton.IsShown and questieButton:IsShown() then
      mapOptionsButton:SetPoint("RIGHT", questieButton, "LEFT", -2, 0)
    elseif wdmButton and wdmButton ~= mapOptionsButton and wdmButton.IsShown and wdmButton:IsShown() then
      mapOptionsButton:SetPoint("RIGHT", wdmButton, "LEFT", -2, 0)
    else
      mapOptionsButton:SetPoint("TOPRIGHT", WorldMapButton, "TOPRIGHT", -4, -4)
    end
  end


  local function UpdateMapOptionsButtonScale()
    if not mapOptionsButton or not mapOptionsButton.GetParent then return end
    local parent = mapOptionsButton:GetParent()
    if not parent then return end

    local parentScale = parent.GetEffectiveScale and parent:GetEffectiveScale() or parent:GetScale() or 1
    local frameScale = WorldMapFrame and WorldMapFrame.GetEffectiveScale and WorldMapFrame:GetEffectiveScale() or 1
    if parentScale == 0 then parentScale = 1 end

    mapOptionsButton:SetScale(frameScale / parentScale)
    UpdateMapOptionsButtonPosition()
    UpdateMapOptionsButtonVisibility()
  end

  local background = mapOptionsButton:CreateTexture(nil, "BACKGROUND")
  background:SetWidth(25)
  background:SetHeight(25)
  background:SetPoint("TOPLEFT", 2, -4)
  background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

  local icon = mapOptionsButton:CreateTexture(nil, "ARTWORK")
  icon:SetWidth(20)
  icon:SetHeight(20)
  icon:SetPoint("TOPLEFT", 6, -5)
  icon:SetTexture(ICON_TEXTURE)

  local border = mapOptionsButton:CreateTexture(nil, "OVERLAY")
  border:SetWidth(54)
  border:SetHeight(54)
  border:SetPoint("TOPLEFT")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

  local menu = {
    { text = MapMenuText("ADDON_NAME", "RareScanner"), isTitle = true },
    {
      text = MapMenuText("MAP_MENU_SHOW_RARES", "Afficher les rares"),
      keepShownOnClick = 1,
      checked = function()
        return not (RareScannerDB and RareScannerDB.showOnMap == false)
      end,
      func = function()
        RareScannerDB = RareScannerDB or {}
        RareScannerDB.showOnMap = not (RareScannerDB.showOnMap ~= false)
        RareScanner335_UpdateMapPins()
      end,
    },
    {
      text = MapMenuText("MAP_MENU_SHOW_KILLED", "Afficher les rares déjà tués"),
      keepShownOnClick = 1,
      checked = function()
        return RareScannerDB and RareScannerDB.showKilledOnMap == true
      end,
      func = function()
        RareScannerDB = RareScannerDB or {}
        RareScannerDB.showKilledOnMap = not (RareScannerDB.showKilledOnMap == true)
        RareScanner335_UpdateMapPins()
      end,
    },
  }

  mapOptionsButton:SetScript("OnClick", function(self, button)
    if button ~= "LeftButton" then return end
    if not mapOptionsMenuFrame then
      mapOptionsMenuFrame = CreateFrame("Frame", "RareScanner335MapOptionsMenu", UIParent, "UIDropDownMenuTemplate")
    end
    EasyMenu(menu, mapOptionsMenuFrame, self, 0, 0, "MENU", 0)
  end)

  UpdateMapOptionsButtonScale()

  if not mapOptionsButton.rsScaleHooked then
    mapOptionsButton.rsScaleHooked = true
    WorldMapButton:HookScript("OnShow", UpdateMapOptionsButtonScale)
    WorldMapButton:HookScript("OnSizeChanged", UpdateMapOptionsButtonScale)

    if WorldMapFrame then
      WorldMapFrame:HookScript("OnShow", UpdateMapOptionsButtonScale)
      WorldMapFrame:HookScript("OnSizeChanged", UpdateMapOptionsButtonScale)
    end

    if type(WorldMapFrame_Update) == "function" then
      hooksecurefunc("WorldMapFrame_Update", UpdateMapOptionsButtonScale)
    end
  end
end

local function HidePins()
  for i = 1, #pins do
    pins[i]:Hide()
  end
  activePins = 0
end

local leaveResetFrame = CreateFrame("Frame")
leaveResetFrame:Hide()
leaveResetFrame:SetScript("OnUpdate", function(self)
  self:Hide()
  if leaveResetPending then
    leaveResetPending = false
    if not focusedNpcID then
      SetRegionFocus(nil)
    end
  end
end)

local function QueueRegionFocusReset()
  focusedNpcID = nil
  leaveResetPending = true
  leaveResetFrame:Show()
end

local function GetPin(index)
  local pin = pins[index]
  if pin then return pin end

  pin = CreateFrame("Button", "RareScanner335MapPin"..index, WorldMapButton)
  pin:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  pin:EnableMouse(true)

  local texture = pin:CreateTexture(pin:GetName().."Texture", "BACKGROUND")
  texture:SetPoint("CENTER", 0, 0)
  texture:SetTexture(ICON_TEXTURE)
  texture:SetTexCoord(0, 1, 0, 1)
  pin.texture = texture

  -- Create the hover highlight once per pin. Recreating HIGHLIGHT textures on
  -- every map refresh leaves old layers attached to the button.
  local highlight = pin:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints(pin)
  highlight:SetTexture(ICON_TEXTURE)
  highlight:SetBlendMode("ADD")
  highlight:SetAlpha(0.65)
  highlight:Hide()
  pin.highlight = highlight

  -- They read self.name/self.description and manage GameTooltip themselves.
  if type(WorldMapPOI_OnEnter) == "function" then
    pin:SetScript("OnEnter", function(self)
        if RareScanner335_IsRegionMap() then
          leaveResetPending = false
          SetRegionFocus(self.npcID)
          WorldMapPOI_OnEnter(self)
        end
      end)
  else
    pin:SetScript("OnEnter", function(self)
      if not self.name then return end
      if RareScanner335_IsRegionMap() then leaveResetPending = false; SetRegionFocus(self.npcID) end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(self.name, 1, 1, 1)
      GameTooltip:Show()
    end)
  end

  if type(WorldMapPOI_OnLeave) == "function" then
    pin:SetScript("OnLeave", function(self)
        if RareScanner335_IsRegionMap() then
          QueueRegionFocusReset()
          WorldMapPOI_OnLeave(self)
        elseif GameTooltip then
          GameTooltip:Hide()
        end
      end)
  else
    pin:SetScript("OnLeave", function()
      if RareScanner335_IsRegionMap() then QueueRegionFocusReset() end
      GameTooltip:Hide()
    end)
  end

  pins[index] = pin
  return pin
end

local function AddPin(x, y, npcID, name, size, texturePath)
  activePins = activePins + 1
  local pin = GetPin(activePins)

  pin:ClearAllPoints()
  pin:SetWidth(size)
  pin:SetHeight(size)
  pin.texture:SetWidth(size)
  pin.texture:SetHeight(size)
  pin.texture:SetTexture(texturePath or ICON_TEXTURE)
  pin:SetPoint(
    "CENTER",
    WorldMapButton,
    "TOPLEFT",
    x * WorldMapButton:GetWidth(),
    -y * WorldMapButton:GetHeight()
  )

  pin.npcID = npcID
  pin.name = name
  pin.description = nil
  pin.texture:SetAlpha(1.0)

  if pin.highlight then
    pin.highlight:SetTexture(texturePath or ICON_TEXTURE)
    if RareScanner335_IsRegionMap() then
      pin.highlight:SetAlpha(0.65)
      pin.highlight:Show()
    else
      pin.highlight:Hide()
    end
  end

  pin:Show()
end

function RareScanner335_UpdateMapPins()
  HidePins()

  if not WorldMapButton or not WorldMapButton:IsShown() then return end
  if not Astrolabe or not RareScanner335_NPCs then return end
  if RareScannerDB and RareScannerDB.enabled == false then return end
  if RareScannerDB and RareScannerDB.showOnMap == false then return end

  local currentContinent = GetCurrentMapContinent()
  local currentZone = GetCurrentMapZone()

  if currentContinent == nil or currentContinent < 0 then return end

  local size
  if currentContinent == 0 then
    size = 12
  elseif currentZone == 0 then
    size = 15
  else
    size = 20
  end

  for npcID, info in pairs(RareScanner335_NPCs) do
    if not (RareScannerDB and RareScannerDB.disabled and RareScannerDB.disabled[npcID]) then
      local isKilled = RareScannerDB and RareScannerDB.killed and RareScannerDB.killed[npcID]
      if not isKilled or (RareScannerDB and RareScannerDB.showKilledOnMap == true) then
      local spawns = info.spawns
      if spawns then
        for _, spawn in ipairs(spawns) do
          local sourceContinent = MAP_TO_CONTINENT[spawn.map]

          -- Instance maps and other unsupported map IDs are intentionally skipped.
          if sourceContinent then
            local canProject = false

            if currentContinent == 0 then
              -- Azeroth world map can display Kalimdor, Eastern Kingdoms and Northrend.
              canProject = sourceContinent ~= 3
            else
              canProject = sourceContinent == currentContinent
            end

            if canProject then
              local x, y = WorldToContinent(sourceContinent, spawn.x, spawn.y)
              if x and y then
                if currentContinent == 0 then
                  x, y = Astrolabe:TranslateWorldMapPosition(
                    sourceContinent, 0, x, y,
                    0, 0
                  )
                else
                  x, y = Astrolabe:TranslateWorldMapPosition(
                    sourceContinent, 0, x, y,
                    currentContinent, currentZone
                  )
                end

                if x and y and x > 0 and x < 1 and y > 0 and y < 1 then
                  local pinName = (RareScanner335_GetNpcName and RareScanner335_GetNpcName(info)) or ("NPC "..npcID)
                  if info.minlevel and info.maxlevel then
                    local levelColor = RareScanner335_GetLevelColorCode(info.minlevel, info.maxlevel)
                    if info.minlevel == info.maxlevel then
                      pinName = pinName.." "..levelColor.."("..info.minlevel..")|r"
                    else
                      pinName = pinName.." "..levelColor.."("..info.minlevel.."-"..info.maxlevel..")|r"
                    end
                  end
                  AddPin(x, y, npcID, pinName, size, isKilled and KILLED_ICON_TEXTURE or ICON_TEXTURE)

                  -- On the world map and continent maps, only show one spawn
                  -- per NPC ID. Region maps keep every known spawn point.
                  if currentContinent == 0 or currentZone == 0 then
                    break
                  end
                end
              end
            end
          end
        end
      end
      end
    end
  end
end

if type(WorldMapFrame_Update) == "function" then
  hooksecurefunc("WorldMapFrame_Update", RareScanner335_UpdateMapPins)
end

if WorldMapButton then
  WorldMapButton:HookScript("OnShow", RareScanner335_UpdateMapPins)
  WorldMapButton:HookScript("OnHide", HidePins)
end
CreateMapOptionsButton()
