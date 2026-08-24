-- RareScanner 3.3.5a world-map spawn pins
-- Coordinate projection follows the Astrolabe-based approach used by WDM.

local ICON_TEXTURE = "Interface\\AddOns\\RareScanner\\Media\\OriginalSkull.blp"

-- AzerothCore map IDs -> WoW 3.3.5 continent indexes.
local MAP_TO_CONTINENT = {
  [0] = 2,   -- Eastern Kingdoms
  [1] = 1,   -- Kalimdor
  [530] = 3, -- Outland
  [571] = 4, -- Northrend
}

-- World-coordinate bounds used by WDM before handing positions to Astrolabe.
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



local function RareScanner335_FadePin(region, targetAlpha)
  if not region then return end

  local fromAlpha = region:GetAlpha() or 1
  if math.abs(fromAlpha - targetAlpha) < 0.01 then
    region:SetAlpha(targetAlpha)
    return
  end

  -- Texture regions are not reliably handled by UIFrameFade on WoW 3.3.5a,
  -- so animate alpha ourselves with a lightweight per-region OnUpdate driver.
  region._rsFadeFrom = fromAlpha
  region._rsFadeTo = targetAlpha
  region._rsFadeElapsed = 0
  region._rsFadeDuration = 0.5

  if not region._rsFadeDriver then
    local driver = CreateFrame("Frame")
    region._rsFadeDriver = driver
    driver:SetScript("OnUpdate", function(self, elapsed)
      local target = self._rsTarget
      if not target or not target._rsFadeTo then
        self:Hide()
        return
      end

      target._rsFadeElapsed = target._rsFadeElapsed + elapsed
      local p = target._rsFadeElapsed / target._rsFadeDuration
      if p >= 1 then
        target:SetAlpha(target._rsFadeTo)
        target._rsFadeFrom = nil
        target._rsFadeTo = nil
        target._rsFadeElapsed = nil
        self:Hide()
      else
        target:SetAlpha(target._rsFadeFrom + (target._rsFadeTo - target._rsFadeFrom) * p)
      end
    end)
  end

  region._rsFadeDriver._rsTarget = region
  region._rsFadeDriver:Show()
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


local function SetRegionFocus(npcID)
  if not RareScanner335_IsRegionMap() then return end
  for i = 1, activePins do
    local pin = pins[i]
    if pin and pin:IsShown() and pin.texture then
      if npcID and pin.npcID ~= npcID then
        RareScanner335_FadePin(pin.texture, 0.40)
      else
        RareScanner335_FadePin(pin.texture, 1.0)
      end
    end
  end
end

local function WorldToContinent(continent, worldX, worldY)
  local bounds = CONTINENT_COORDS[continent]
  if not bounds then return end

  -- WDM/Astrolabe uses the normalized Y axis as the first map coordinate
  -- and the normalized X axis as the second one for WoW world coordinates.
  local normalizedY = math.abs(worldY - bounds[1]) / math.abs(bounds[2] - bounds[1])
  local normalizedX = math.abs(worldX - bounds[3]) / math.abs(bounds[4] - bounds[3])
  return normalizedY, normalizedX
end

local function HidePins()
  for i = 1, #pins do
    pins[i]:Hide()
  end
  activePins = 0
end

local function GetPin(index)
  local pin = pins[index]
  if pin then return pin end

  -- Match the native/WDM WorldMap POI implementation as closely as possible.
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

  -- Blizzard's native WorldMap POI handlers are the same mechanism used by WDM.
  -- They read self.name/self.description and manage GameTooltip themselves.
  if type(WorldMapPOI_OnEnter) == "function" then
    pin:SetScript("OnEnter", function(self)
        if RareScanner335_IsRegionMap() then
          SetRegionFocus(self.npcID)
          WorldMapPOI_OnEnter(self)
        end
      end)
  else
    pin:SetScript("OnEnter", function(self)
      if not self.name then return end
      if RareScanner335_IsRegionMap() then SetRegionFocus(self.npcID) end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(self.name, 1, 1, 1)
      GameTooltip:Show()
    end)
  end

  if type(WorldMapPOI_OnLeave) == "function" then
    pin:SetScript("OnLeave", function(self)
        if RareScanner335_IsRegionMap() then
          SetRegionFocus(nil)
          WorldMapPOI_OnLeave(self)
        elseif GameTooltip then
          GameTooltip:Hide()
        end
      end)
  else
    pin:SetScript("OnLeave", function()
      if RareScanner335_IsRegionMap() then SetRegionFocus(nil) end
      GameTooltip:Hide()
    end)
  end

  pins[index] = pin
  return pin
end

local function AddPin(x, y, npcID, name, size)
  activePins = activePins + 1
  local pin = GetPin(activePins)

  pin:ClearAllPoints()
  -- WDM keeps the actual Button hit area equal to the visible POI size.
  pin:SetWidth(size)
  pin:SetHeight(size)
  pin.texture:SetWidth(size)
  pin.texture:SetHeight(size)
  pin:SetPoint(
    "CENTER",
    WorldMapButton,
    "TOPLEFT",
    x * WorldMapButton:GetWidth(),
    -y * WorldMapButton:GetHeight()
  )
  -- Native WorldMapPOI_OnEnter expects these exact fields.
  pin.npcID = npcID
  pin.name = name
  pin.description = nil
  pin.texture:SetAlpha(1.0)

  if pin.highlight then
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
                  AddPin(x, y, npcID, info.name or ("NPC "..npcID), size)

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

-- WDM refreshes its POIs from WorldMapFrame_Update; do the same here.
if type(WorldMapFrame_Update) == "function" then
  hooksecurefunc("WorldMapFrame_Update", RareScanner335_UpdateMapPins)
end

if WorldMapButton then
  WorldMapButton:HookScript("OnShow", RareScanner335_UpdateMapPins)
  WorldMapButton:HookScript("OnHide", HidePins)
end