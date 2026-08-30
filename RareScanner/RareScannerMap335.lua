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


local INSTANCE_MAPS = {
  [686] = {
    name = "ZulFarrak",
    mapID = 209,
    floors = {
      { 1383.33322143555, 922.916625976562, -1624.99987792969, 2052.08325195312, -241.666656494141, 1129.16662597656 },
    },
  },
  [691] = {
    name = "Gnomeregan",
    mapID = 90,
    floors = {
      { 769.667999267578, 513.111999511719, 277.772003173828, -694.0, -491.89599609375, -180.888000488281 },
      { 769.667999267578, 513.111999511719, 77.7720031738281, -714.0, -691.89599609375, -200.888000488281 },
      { 869.667999267578, 579.778015136719, 127.772003173828, -967.3330078125, -741.89599609375, -387.554992675781 },
      { 869.669708251953, 579.779998779297, -72.9992980957031, -937.333984375, -942.669006347656, -357.553985595703 },
    },
  },
  [699] = {
    name = "DireMaul",
    mapID = 429,
    floors = {
      { 1275.0, 850.0, 387.5, 200.0, -887.5, 1050.0 },
      { 525.0, 350.0, -125.0, -150.0, -650.0, 200.0 },
      { 487.5, 325.0, -231.25, -150.0, -718.75, 175.0 },
      { 750.0, 500.0, -325.0, -250.0, -1075.0, 250.0 },
      { 800.000801086426, 533.333999633789, 900.0, -281.6669921875, 99.9991989135742, 251.667007446289 },
      { 975.0, 650.0, 862.5, -200.0, -112.5, 450.0 },
    },
  },
  [704] = {
    name = "BlackrockDepths",
    mapID = 230,
    floors = {
      { 1407.06097412109, 938.040756225586, 884.723999023438, 248.639663696289, -522.336975097656, 1186.68041992188 },
      { 1507.06097412109, 1004.70742797852, 934.723999023438, 495.302825927734, -572.336975097656, 1500.01025390625 },
    },
  },
  [721] = {
    name = "BlackrockSpire",
    mapID = 229,
    floors = {
      { 886.839014053345, 591.226013183594, 876.252014160156, -286.828002929688, -10.5869998931885, 304.398010253906 },
      { 886.839014053345, 591.226013183594, 876.252014160156, -286.828002929688, -10.5869998931885, 304.398010253906 },
      { 886.839014053345, 591.226013183594, 876.252014160156, -286.828002929688, -10.5869998931885, 304.398010253906 },
      { 886.839014053345, 591.226013183594, 876.252014160156, -286.828002929688, -10.5869998931885, 304.398010253906 },
      { 886.839014053345, 591.226013183594, 876.252014160156, -286.828002929688, -10.5869998931885, 304.398010253906 },
      { 886.839014053345, 591.226013183594, 876.252014160156, -286.828002929688, -10.5869998931885, 304.398010253906 },
      { 886.839014053345, 591.226013183594, 876.252014160156, -286.828002929688, -10.5869998931885, 304.398010253906 },
    },
  },
  [749] = {
    name = "WailingCaverns",
    mapID = 43,
    floors = {
      { 936.475006103516, 624.315994262695, 375.946014404297, -410.14599609375, -560.528991699219, 214.169998168945 },
    },
  },
  [750] = {
    name = "Maraudon",
    mapID = 349,
    floors = {
      { 975.0, 650.0, 827.5, 550.0, -147.5, 1200.0 },
      { 1637.5, 1091.66600036621, 1158.75, -208.332992553711, -478.75, 883.3330078125 },
    },
  },
  [756] = {
    name = "TheDeadmines",
    mapID = 36,
    floors = {
      { 559.264007568359, 372.842502593994, 796.622009277344, -337.509002685547, 237.358001708984, 35.3334999084473 },
      { 499.263000488281, 332.842300415039, 1016.61999511719, -267.509002685547, 517.356994628906, 65.3332977294922 },
    },
  },
  [761] = {
    name = "RazorfenKraul",
    mapID = 47,
    floors = {
      { 736.449951171875, 490.959838867188, -1322.46997070312, 1858.68005371094, -2058.919921875, 2349.63989257812 },
    },
  },
  [762] = {
    name = "ScarletMonastery",
    mapID = 189,
    floors = {
      { 619.983947753906, 413.32275390625, -947.986022949219, 1616.85864257812, -1567.96997070312, 2030.18139648438 },
      { 320.190994262695, 213.460494995117, 482.463989257812, 93.9055023193359, 162.272994995117, 307.365997314453 },
      { 612.69660949707, 408.4599609375, 562.424011230469, 1600.64001464844, -50.2725982666016, 2009.09997558594 },
      { 703.300048828125, 468.86669921875, -1040.68994140625, 812.423706054688, -1743.98999023438, 1281.29040527344 },
    },
  },
  [764] = {
    name = "ShadowfangKeep",
    mapID = 33,
    floors = {
      { 352.429931640625, 234.953392028809, -2003.77001953125, -319.882995605469, -2356.19995117188, -84.9296035766602 },
      { 212.419921875, 141.61799621582, -2147.56005859375, -303.214996337891, -2359.97998046875, -161.59700012207 },
      { 152.429931640625, 101.619903564453, -2103.77001953125, -193.216003417969, -2256.19995117188, -91.5960998535156 },
      { 152.429931640625, 101.624694824219, -2103.77001953125, -193.214996337891, -2256.19995117188, -91.5903015136719 },
      { 152.429931640625, 101.624694824219, -2103.77001953125, -193.214996337891, -2256.19995117188, -91.5903015136719 },
      { 198.429931640625, 132.286605834961, -2080.77001953125, -182.546005249023, -2279.19995117188, -50.2593994140625 },
      { 272.429931640625, 181.619903564453, -2023.77001953125, -278.216003417969, -2296.19995117188, -96.5960998535156 },
    },
  },
  [765] = {
    name = "Stratholme",
    mapID = 329,
    floors = {
      { 705.719970703125, 470.47998046875, 3617.67993164062, 3338.96997070312, 2911.9599609375, 3809.44995117188 },
      { 1005.72045898438, 670.480224609375, 3967.68017578125, 3498.96997070312, 2961.95971679688, 4169.4501953125 },
    },
  },
}

local function NormalizeInstanceMapName(mapName)
  if not mapName then return nil end
  return string.match(mapName, "^(.-)%d*_$") or mapName
end

local function GetDisplayedInstanceMap()
  local areaID
  if type(GetCurrentMapAreaID) == "function" then
    areaID = GetCurrentMapAreaID()
  end

  local instance = areaID and INSTANCE_MAPS[areaID]

  if not instance and type(GetMapInfo) == "function" then
    local mapName = NormalizeInstanceMapName(GetMapInfo())
    if mapName then
      for _, candidate in pairs(INSTANCE_MAPS) do
        if candidate.name == mapName then
          instance = candidate
          break
        end
      end
    end
  end

  if not instance then return nil end

  local floor = 1
  if type(GetCurrentMapDungeonLevel) == "function" then
    local currentFloor = GetCurrentMapDungeonLevel()
    if currentFloor and currentFloor > 0 then
      floor = currentFloor
    end
  end

  if floor > #instance.floors then
    floor = #instance.floors
  end

  return instance, instance.floors[floor], floor
end

local function InstanceWorldToMap(floorData, spawnX, spawnY)
  if not floorData then return nil end

  local width = floorData[1]
  local height = floorData[2]
  local lowerRightX = floorData[5]
  local lowerRightY = floorData[6]
  if not width or not height or width == 0 or height == 0 then return nil end

  local left = -lowerRightX
  local top = lowerRightY
  local mapX = (left - spawnY) / width
  local mapY = (top - spawnX) / height

  if mapX < 0 or mapX > 1 or mapY < 0 or mapY > 1 then
    return nil
  end

  return mapX, mapY
end


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
  local instance = GetDisplayedInstanceMap()
  if instance then return true end

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


-- Map 530 also contains several Burning Crusade zones that are displayed on
-- Kalimdor or Eastern Kingdoms rather than on the Outland continent map.
-- Values are { width, height, left, top, right, bottom } in world coordinates.
local MAP530_SPECIAL_ZONES = {
  -- City maps must be tested before their surrounding outdoor zones because
  -- their world-coordinate rectangles overlap those parent zones.
  { mapFile = "SilvermoonCity", parentContinent = 2, bounds = { 1211.459296502504, 806.7736903384404, 6400.75091570836, 10153.7121932813, 7612.21021221086, 9346.93850294286 } },
  { mapFile = "TheExodar", parentContinent = 1, bounds = { 1056.782908333002, 704.6827795715492, 11066.3726778873, -3609.67094368333, 12123.1555862203, -4314.35372325488 } },
  { mapFile = "EversongWoods", parentContinent = 2, bounds = { 4925.0, 3283.3330078125, 4487.5, 11041.666015625, 9412.5, 7758.3330078125 } },
  { mapFile = "Ghostlands", parentContinent = 2, bounds = { 3300.0, 2199.99951171875, 5283.3330078125, 8266.666015625, 8583.3330078125, 6066.66650390625 } },
  { mapFile = "AzuremystIsle", parentContinent = 1, bounds = { 4070.8330078125, 2714.5830078125, 10500.0, -2793.75, 14570.8330078125, -5508.3330078125 } },
  { mapFile = "BloodmystIsle", parentContinent = 1, bounds = { 3262.4990234375, 2174.9999389648438, 10075.0, -758.3333129882812, 13337.4990234375, -2933.333251953125 } },
  { mapFile = "Sunwell", parentContinent = 2, bounds = { 3327.0830078125, 2218.7490234375, 5302.0830078125, 13568.7490234375, 8629.166015625, 11350.0 } },
}

local function FindAstrolabeZoneIndex(continent, mapFile)
  if not Astrolabe or not Astrolabe.ContinentList then return nil end
  local zones = Astrolabe.ContinentList[continent]
  if not zones then return nil end
  for index, name in ipairs(zones) do
    if name == mapFile then return index end
  end
end

local function Map530WorldToSpecialZone(spawnX, spawnY)
  for _, zone in ipairs(MAP530_SPECIAL_ZONES) do
    local b = zone.bounds
    local mapX = ((-spawnY) - b[3]) / b[1]
    local mapY = (b[4] - spawnX) / b[2]
    if mapX >= 0 and mapX <= 1 and mapY >= 0 and mapY <= 1 then
      local zoneIndex = FindAstrolabeZoneIndex(zone.parentContinent, zone.mapFile)
      if zoneIndex then
        return zone.parentContinent, zoneIndex, mapX, mapY
      end
    end
  end
end

local function ResolveSpawnMapPosition(spawn)
  if spawn.map == 530 then
    local continent, zone, x, y = Map530WorldToSpecialZone(spawn.x, spawn.y)
    if continent then return continent, zone, x, y end
  end

  local continent = MAP_TO_CONTINENT[spawn.map]
  if not continent then return nil end
  local x, y = WorldToContinent(continent, spawn.x, spawn.y)
  if not x or not y then return nil end
  return continent, 0, x, y
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

local function BuildPinName(npcID, info)
  local pinName = (RareScanner335_GetNpcName and RareScanner335_GetNpcName(info)) or ("NPC "..npcID)
  if info.minlevel and info.maxlevel then
    local levelColor = RareScanner335_GetLevelColorCode(info.minlevel, info.maxlevel)
    if info.minlevel == info.maxlevel then
      pinName = pinName.." "..levelColor.."("..info.minlevel..")|r"
    else
      pinName = pinName.." "..levelColor.."("..info.minlevel.."-"..info.maxlevel..")|r"
    end
  end
  return pinName
end

local function AddInstancePins(instance, bounds)
  if not instance or not bounds then return end

  local size = 20
  for npcID, info in pairs(RareScanner335_NPCs) do
    if not (RareScannerDB and RareScannerDB.disabled and RareScannerDB.disabled[npcID]) then
      local isKilled = RareScannerDB and RareScannerDB.killed and RareScannerDB.killed[npcID]
      if not isKilled or (RareScannerDB and RareScannerDB.showKilledOnMap == true) then
        for _, spawn in ipairs(info.spawns or {}) do
          if spawn.map == instance.mapID then
            local x, y = InstanceWorldToMap(bounds, spawn.x, spawn.y)
            if x and y then
              AddPin(
                x,
                y,
                npcID,
                BuildPinName(npcID, info),
                size,
                isKilled and KILLED_ICON_TEXTURE or ICON_TEXTURE
              )
            end
          end
        end
      end
    end
  end
end

function RareScanner335_UpdateMapPins()
  HidePins()

  if not WorldMapButton or not WorldMapButton:IsShown() then return end
  if not RareScanner335_NPCs then return end
  if RareScannerDB and RareScannerDB.enabled == false then return end
  if RareScannerDB and RareScannerDB.showOnMap == false then return end

  local instance, instanceBounds = GetDisplayedInstanceMap()
  if instance then
    AddInstancePins(instance, instanceBounds)
    return
  end

  if not Astrolabe then return end

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
            local sourceContinent, sourceZone, x, y = ResolveSpawnMapPosition(spawn)
            if sourceContinent and x and y then
              local canProject = false

              if currentContinent == 0 then
                canProject = sourceContinent ~= 3
              else
                canProject = sourceContinent == currentContinent
              end

              if canProject then
                if currentContinent == 0 then
                  x, y = Astrolabe:TranslateWorldMapPosition(
                    sourceContinent, sourceZone, x, y,
                    0, 0
                  )
                else
                  x, y = Astrolabe:TranslateWorldMapPosition(
                    sourceContinent, sourceZone, x, y,
                    currentContinent, currentZone
                  )
                end

                if x and y and x > 0 and x < 1 and y > 0 and y < 1 then
                  AddPin(
                    x,
                    y,
                    npcID,
                    BuildPinName(npcID, info),
                    size,
                    isKilled and KILLED_ICON_TEXTURE or ICON_TEXTURE
                  )

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

if type(WorldMapFrame_Update) == "function" then
  hooksecurefunc("WorldMapFrame_Update", RareScanner335_UpdateMapPins)
end

if WorldMapButton then
  WorldMapButton:HookScript("OnShow", RareScanner335_UpdateMapPins)
  WorldMapButton:HookScript("OnHide", HidePins)
end
CreateMapOptionsButton()
