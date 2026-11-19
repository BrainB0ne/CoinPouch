-- CoinPouch settings: built-in UI, no external libraries.
local api = _G.CoinPouchAPI
local panel = CreateFrame("Frame", "CoinPouchSettingsPanel")
panel.name = "CoinPouch"

-- Compact layout; no scroll frame required.
local content = panel

local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 20, -16)
title:SetText("CoinPouch")

local version = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)

local addonVersion = C_AddOns and C_AddOns.GetAddOnMetadata
    and C_AddOns.GetAddOnMetadata("CoinPouch", "Version")
    or GetAddOnMetadata and GetAddOnMetadata("CoinPouch", "Version")

version:SetText("Version " .. (addonVersion or "Unknown"))

local description = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
description:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -12)
description:SetText("Customize the size, position, and bag-space colors of your CoinPouch widget.")

local scaleLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
scaleLabel:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -16)
scaleLabel:SetText("Widget Scale")

local slider = CreateFrame("Slider", "CoinPouchScaleSlider", content, "OptionsSliderTemplate")
slider:SetPoint("TOPLEFT", scaleLabel, "BOTTOMLEFT", 0, -17)
slider:SetWidth(260)
slider:SetMinMaxValues(0.5, 2.0)
slider:SetValueStep(0.05)
if slider.SetObeyStepOnDrag then
    slider:SetObeyStepOnDrag(true)
end

_G[slider:GetName() .. "Low"]:SetText("50%")
_G[slider:GetName() .. "High"]:SetText("200%")
_G[slider:GetName() .. "Text"]:SetText("")

local valueLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
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

local resetScale = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
resetScale:SetSize(130, 26)
resetScale:SetPoint("LEFT", valueLabel, "RIGHT", 22, 0)
resetScale:SetText("Reset Scale")
resetScale:SetScript("OnClick", function()
    api.ResetScale()
    RefreshScale()
end)

local positionLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
positionLabel:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -22)
positionLabel:SetText("Position")

local positionHelp = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
positionHelp:SetPoint("TOPLEFT", positionLabel, "BOTTOMLEFT", 0, -10)
positionHelp:SetText("Right-drag the widget to move it anywhere on your screen.")

local resetPosition = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
resetPosition:SetSize(140, 26)
resetPosition:SetPoint("TOPLEFT", positionHelp, "BOTTOMLEFT", 0, -8)
resetPosition:SetText("Reset Position")
resetPosition:SetScript("OnClick", function()
    api.ResetPosition()
end)

-- Bag-space color thresholds. Keep the red threshold <= yellow threshold.
local bagColorsLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
bagColorsLabel:SetPoint("TOPLEFT", resetPosition, "BOTTOMLEFT", 0, -16)
bagColorsLabel:SetText("Bag Space Colors")

local redLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
redLabel:SetPoint("TOPLEFT", bagColorsLabel, "BOTTOMLEFT", 0, -12)
redLabel:SetText("Red below")

local redSlider = CreateFrame("Slider", "CoinPouchRedThresholdSlider", content, "OptionsSliderTemplate")
redSlider:SetPoint("TOPLEFT", redLabel, "BOTTOMLEFT", 0, -16)
redSlider:SetWidth(260)
redSlider:SetMinMaxValues(0, 100)
redSlider:SetValueStep(1)
if redSlider.SetObeyStepOnDrag then redSlider:SetObeyStepOnDrag(true) end
_G[redSlider:GetName() .. "Low"]:SetText("0%")
_G[redSlider:GetName() .. "High"]:SetText("100%")
_G[redSlider:GetName() .. "Text"]:SetText("")

local redValue = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
redValue:SetPoint("LEFT", redSlider, "RIGHT", 18, 0)

local yellowLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
yellowLabel:SetPoint("TOPLEFT", redSlider, "BOTTOMLEFT", 0, -17)
yellowLabel:SetText("Yellow through")

local yellowSlider = CreateFrame("Slider", "CoinPouchYellowThresholdSlider", content, "OptionsSliderTemplate")
yellowSlider:SetPoint("TOPLEFT", yellowLabel, "BOTTOMLEFT", 0, -16)
yellowSlider:SetWidth(260)
yellowSlider:SetMinMaxValues(0, 100)
yellowSlider:SetValueStep(1)
if yellowSlider.SetObeyStepOnDrag then yellowSlider:SetObeyStepOnDrag(true) end
_G[yellowSlider:GetName() .. "Low"]:SetText("0%")
_G[yellowSlider:GetName() .. "High"]:SetText("100%")
_G[yellowSlider:GetName() .. "Text"]:SetText("")

local yellowValue = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
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

local resetThresholds = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
resetThresholds:SetSize(150, 26)
resetThresholds:SetPoint("TOPLEFT", yellowSlider, "BOTTOMLEFT", 0, -12)
resetThresholds:SetText("Reset Thresholds")
resetThresholds:SetScript("OnClick", function()
    api.ResetThresholds()
    RefreshThresholds()
end)

-- Special bag display preference.
local specialLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
specialLabel:SetPoint("TOPLEFT", resetThresholds, "BOTTOMLEFT", 0, -16)
specialLabel:SetText("Bags")

local specialCheck = CreateFrame("CheckButton", "CoinPouchSpecialBagsCheck", content, "UICheckButtonTemplate")
specialCheck:SetPoint("TOPLEFT", specialLabel, "BOTTOMLEFT", -4, -5)
specialCheck:SetScript("OnClick", function(self)
    api.SetShowSpecialBags(self:GetChecked())
end)

local specialCheckText = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
specialCheckText:SetPoint("LEFT", specialCheck, "RIGHT", 4, 0)
specialCheckText:SetText("Show special bag slots")

-- Keep both bag-display preferences together to avoid a scroll frame.
local iconCheck = CreateFrame("CheckButton", "CoinPouchEquippedBagIconsCheck", content, "UICheckButtonTemplate")
iconCheck:SetPoint("TOPLEFT", specialCheck, "BOTTOMLEFT", 0, -1)
iconCheck:SetScript("OnClick", function(self)
    api.SetUseEquippedBagIcons(self:GetChecked())
end)

local iconCheckText = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
iconCheckText:SetPoint("LEFT", iconCheck, "RIGHT", 4, 0)
iconCheckText:SetText("Use equipped bag icons")

local specialHelp = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
specialHelp:SetPoint("TOPLEFT", iconCheck, "BOTTOMLEFT", 4, -2)
specialHelp:SetWidth(440)
specialHelp:SetJustifyH("LEFT")
specialHelp:SetText("Use default bag icons when unchecked; special slots appear only when equipped and enabled.")

panel:SetScript("OnShow", function()
    RefreshScale()
    RefreshThresholds()
    specialCheck:SetChecked(api.GetShowSpecialBags())
    iconCheck:SetChecked(api.GetUseEquippedBagIcons())
end)

if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, "CoinPouch")
    Settings.RegisterAddOnCategory(category)

    -- Make the registered category available to slash commands.
    api.settingsCategoryID = category:GetID()

elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
end
