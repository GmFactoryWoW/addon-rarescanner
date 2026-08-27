-- Shared bootstrap for standard AddOns and FrameXML/MPQ loading.
local addonName = ...

RareScanner335_IS_FRAME_XML = addonName ~= "RareScanner"

if RareScanner335_IS_FRAME_XML then
  RareScanner335_ROOT = "Interface\\FrameXML\\RareScanner\\"

  -- FrameXML files are not associated with an addon TOC SavedVariables entry.
  -- This client exposes RegisterForSave for persistent FrameXML globals.
  RareScannerDB = RareScannerDB or {}
  if type(RegisterForSave) == "function" then
    RegisterForSave("RareScannerDB")
  end
else
  RareScanner335_ROOT = "Interface\\AddOns\\RareScanner\\"
end

function RareScanner335_Asset(relativePath)
  return RareScanner335_ROOT .. relativePath
end
