-- Shared bootstrap for standard AddOns and FrameXML/MPQ loading.
local addonName = ...

if addonName == "RareScanner" then
  RareScanner335_ROOT = "Interface\\AddOns\\RareScanner\\"
else
  RareScanner335_ROOT = "Interface\\FrameXML\\RareScanner\\"
end

function RareScanner335_Asset(relativePath)
  return RareScanner335_ROOT .. relativePath
end
