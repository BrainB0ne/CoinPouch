-- CoinPouch settings: built-in UI, no external libraries.
local api = _G.CoinPouchAPI
local panel = CreateFrame("Frame", "CoinPouchSettingsPanel")
panel.name = "CoinPouch"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 20, -20)
title:SetText("CoinPouch")

local version = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)

local addonVersion = C_AddOns and C_AddOns.GetAddOnMetadata
    and C_AddOns.GetAddOnMetadata("CoinPouch", "Version")
    or GetAddOnMetadata and GetAddOnMetadata("CoinPouch", "Version")

version:SetText("Version " .. (addonVersion or "Unknown"))

local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
description:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -12)
description:SetText("Customize the size, position, and bag-space colors of your CoinPouch widget.")

local scaleLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
scaleLabel:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -32)
scaleLabel:SetText("Widget Scale")

local slider = CreateFrame("Slider", "CoinPouchScaleSlider", panel, "OptionsSliderTemplate")
slider:SetPoint("TOPLEFT", scaleLabel, "BOTTOMLEFT", 0, -24)
slider:SetWidth(260)
slider:SetMinMaxValues(0.5, 2.0)
slider:SetValueStep(0.05)
if slider.SetObeyStepOnDrag then
    slider:SetObeyStepOnDrag(true)
end

_G[slider:GetName() .. "Low"]:SetText("50%")
_G[slider:GetName() .. "High"]:SetText("200%")
_G[slider:GetName() .. "Text"]:SetText("")

local valueLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
valueLabel:SetPoint("LEFT", slider, "RIGHT", 18, 0)

local function RefreshScale()
    local value = api.GetScale()
    slider:SetValue(value)
    valueLabel:SetText(string.format("%d%%", math.floor(value * 100 + 0.5)))
end

slider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value * 20 + 0.5) / 20
    api.SetScale(value)
    valueLabel:SetText(string.format("%d%%", math.floor(value * 100 + 0.5)))
end)

local resetScale = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetScale:SetSize(130, 26)
resetScale:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -32)
resetScale:SetText("Reset Scale")
resetScale:SetScript("OnClick", function()
    api.ResetScale()
    RefreshScale()
end)

local positionLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
positionLabel:SetPoint("TOPLEFT", resetScale, "BOTTOMLEFT", 0, -34)
positionLabel:SetText("Position")

local positionHelp = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
positionHelp:SetPoint("TOPLEFT", positionLabel, "BOTTOMLEFT", 0, -10)
positionHelp:SetText("Right-drag the widget to move it anywhere on your screen.")

local resetPosition = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetPosition:SetSize(140, 26)
resetPosition:SetPoint("TOPLEFT", positionHelp, "BOTTOMLEFT", 0, -18)
resetPosition:SetText("Reset Position")
resetPosition:SetScript("OnClick", function()
    api.ResetPosition()
end)

-- Bag-space color thresholds. Keep the red threshold <= yellow threshold.
local bagColorsLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
bagColorsLabel:SetPoint("TOPLEFT", resetPosition, "BOTTOMLEFT", 0, -32)
bagColorsLabel:SetText("Bag Space Colors")

local redLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
redLabel:SetPoint("TOPLEFT", bagColorsLabel, "BOTTOMLEFT", 0, -18)
redLabel:SetText("Red below")

local redSlider = CreateFrame("Slider", "CoinPouchRedThresholdSlider", panel, "OptionsSliderTemplate")
redSlider:SetPoint("TOPLEFT", redLabel, "BOTTOMLEFT", 0, -20)
redSlider:SetWidth(260)
redSlider:SetMinMaxValues(0, 100)
redSlider:SetValueStep(1)
if redSlider.SetObeyStepOnDrag then redSlider:SetObeyStepOnDrag(true) end
_G[redSlider:GetName() .. "Low"]:SetText("0%")
_G[redSlider:GetName() .. "High"]:SetText("100%")
_G[redSlider:GetName() .. "Text"]:SetText("")

local redValue = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
redValue:SetPoint("LEFT", redSlider, "RIGHT", 18, 0)

local yellowLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
yellowLabel:SetPoint("TOPLEFT", redSlider, "BOTTOMLEFT", 0, -24)
yellowLabel:SetText("Yellow through")

local yellowSlider = CreateFrame("Slider", "CoinPouchYellowThresholdSlider", panel, "OptionsSliderTemplate")
yellowSlider:SetPoint("TOPLEFT", yellowLabel, "BOTTOMLEFT", 0, -20)
yellowSlider:SetWidth(260)
yellowSlider:SetMinMaxValues(0, 100)
yellowSlider:SetValueStep(1)
if yellowSlider.SetObeyStepOnDrag then yellowSlider:SetObeyStepOnDrag(true) end
_G[yellowSlider:GetName() .. "Low"]:SetText("0%")
_G[yellowSlider:GetName() .. "High"]:SetText("100%")
_G[yellowSlider:GetName() .. "Text"]:SetText("")

local yellowValue = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
yellowValue:SetPoint("LEFT", yellowSlider, "RIGHT", 18, 0)

local updatingThresholdSliders = false
local function RefreshThresholds()
    local red, yellow = api.GetThresholds()
    updatingThresholdSliders = true
    redSlider:SetValue(red)
    yellowSlider:SetValue(yellow)
    updatingThresholdSliders = false
    redValue:SetText(red .. "%")
    yellowValue:SetText(yellow .. "%")
end

redSlider:SetScript("OnValueChanged", function(self, value)
    if updatingThresholdSliders then return end
    local _, yellow = api.GetThresholds()
    api.SetThresholds(math.min(math.floor(value + 0.5), yellow), yellow)
    RefreshThresholds()
end)

yellowSlider:SetScript("OnValueChanged", function(self, value)
    if updatingThresholdSliders then return end
    local red = api.GetThresholds()
    api.SetThresholds(red, math.max(math.floor(value + 0.5), red))
    RefreshThresholds()
end)

local resetThresholds = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetThresholds:SetSize(150, 26)
resetThresholds:SetPoint("TOPLEFT", yellowSlider, "BOTTOMLEFT", 0, -30)
resetThresholds:SetText("Reset Thresholds")
resetThresholds:SetScript("OnClick", function()
    api.ResetThresholds()
    RefreshThresholds()
end)

panel:SetScript("OnShow", function()
    RefreshScale()
    RefreshThresholds()
end)

if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, "CoinPouch")
    Settings.RegisterAddOnCategory(category)
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
end
