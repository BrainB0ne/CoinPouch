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

-- Separate Appearance page: leave the main settings layout unchanged.
local appearancePanel = CreateFrame("Frame", "CoinPouchAppearancePanel")
appearancePanel.name = "Appearance"
appearancePanel.parent = "CoinPouch" -- Legacy Interface Options subcategory.

local appearanceTitle = appearancePanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
appearanceTitle:SetPoint("TOPLEFT", 20, -16)
appearanceTitle:SetText("CoinPouch - Appearance")

local appearanceDescription = appearancePanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
appearanceDescription:SetPoint("TOPLEFT", appearanceTitle, "BOTTOMLEFT", 0, -12)
appearanceDescription:SetText("Choose a theme and adjust widget transparency.")

local themeLabel = appearancePanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
themeLabel:SetPoint("TOPLEFT", appearanceDescription, "BOTTOMLEFT", 0, -22)
themeLabel:SetText("Widget Theme")

-- A compact, expandable dropdown instead of a growing radio-button list.
-- Built from basic WoW UI controls to work on both Retail and Forever.
local themeOptions = {
    { key = "classic", label = "Classic Gold" },
    { key = "midnight", label = "Midnight" },
    { key = "emerald", label = "Emerald" },
    { key = "minimal", label = "Minimal" },
    { key = "candyPink", label = "Candy Pink" },
    { key = "peach", label = "Peach" },
    { key = "lavender", label = "Lavender" },
    { key = "electricBlue", label = "Electric Blue" },
}
local refreshingAppearance = false
local refreshAppearance

-- Use Blizzard's native dropdown rather than a custom button/menu.
-- UIDropDownMenu is available in Forever and on Retail clients that retain
-- the legacy dropdown API.
local themeDropdown = CreateFrame("Frame", "CoinPouchThemeDropdown", appearancePanel, "UIDropDownMenuTemplate")
themeDropdown:SetPoint("TOPLEFT", themeLabel, "BOTTOMLEFT", -16, -8)
UIDropDownMenu_SetWidth(themeDropdown, 140)
UIDropDownMenu_JustifyText(themeDropdown, "LEFT")

local function ThemeLabel(key)
    for _, option in ipairs(themeOptions) do
        if option.key == key then return option.label end
    end
    return "Classic Gold"
end

UIDropDownMenu_Initialize(themeDropdown, function(self, level)
    if level ~= 1 then return end
    for _, option in ipairs(themeOptions) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = option.label
        info.value = option.key
        info.checked = nil
        info.func = function()
            api.SetTheme(option.key)
            UIDropDownMenu_SetSelectedValue(themeDropdown, option.key)
            UIDropDownMenu_SetText(themeDropdown, option.label)
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end)

local function MakeOpacitySlider(name, label, offsetY, getter, setter)
    local labelText = appearancePanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    -- Anchor to the common left margin, not to the dropdown template padding.
    labelText:SetPoint("TOPLEFT", themeLabel, "BOTTOMLEFT", 0, offsetY)
    labelText:SetText(label)

    local control = CreateFrame("Slider", name, appearancePanel, "OptionsSliderTemplate")
    control:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 0, -17)
    control:SetWidth(260)
    control:SetMinMaxValues(0, 100)
    control:SetValueStep(5)
    if control.SetObeyStepOnDrag then control:SetObeyStepOnDrag(true) end
    _G[name .. "Low"]:SetText("0%")
    _G[name .. "High"]:SetText("100%")
    _G[name .. "Text"]:SetText("")

    local valueText = appearancePanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    valueText:SetPoint("LEFT", control, "RIGHT", 18, 0)
    control:SetScript("OnValueChanged", function(self, value)
        if refreshingAppearance then return end
        local rounded = math.floor(value / 5 + 0.5) * 5
        setter(rounded)
        valueText:SetText(rounded .. "%")
    end)
    return control, valueText, getter
end

local backgroundSlider, backgroundValue = MakeOpacitySlider(
    "CoinPouchBackgroundOpacitySlider", "Background Opacity", -66,
    api.GetBackgroundOpacity, api.SetBackgroundOpacity)
local borderSlider, borderValue = MakeOpacitySlider(
    "CoinPouchBorderOpacitySlider", "Border Opacity", -136,
    api.GetBorderOpacity, api.SetBorderOpacity)

refreshAppearance = function()
    refreshingAppearance = true
    local selectedTheme = api.GetTheme() or "classic"
    UIDropDownMenu_SetSelectedValue(themeDropdown, selectedTheme)
    UIDropDownMenu_SetText(themeDropdown, ThemeLabel(selectedTheme))
    local background = api.GetBackgroundOpacity()
    local border = api.GetBorderOpacity()
    backgroundSlider:SetValue(background)
    borderSlider:SetValue(border)
    backgroundValue:SetText(background .. "%")
    borderValue:SetText(border .. "%")
    refreshingAppearance = false
end

local resetAppearance = CreateFrame("Button", nil, appearancePanel, "UIPanelButtonTemplate")
resetAppearance:SetSize(160, 26)
resetAppearance:SetPoint("TOPLEFT", themeLabel, "BOTTOMLEFT", 0, -211)
resetAppearance:SetText("Reset Appearance")
resetAppearance:SetScript("OnClick", function()
    api.ResetAppearance()
    refreshAppearance()
end)
appearancePanel:SetScript("OnShow", refreshAppearance)

-- SavedVariables are restored during ADDON_LOADED. Do not initialize the
-- dropdown at file load time: it could display Classic Gold before the saved
-- theme is available, especially when the panel is already shown.
local appearanceEvents = CreateFrame("Frame")
appearanceEvents:RegisterEvent("ADDON_LOADED")
appearanceEvents:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon == "CoinPouch" then
        -- Retail may not invoke OnShow when opening an already-visible
        -- canvas panel. Synchronize both pages after SavedVariables load.
        RefreshScale()
        RefreshThresholds()
        specialCheck:SetChecked(api.GetShowSpecialBags())
        iconCheck:SetChecked(api.GetUseEquippedBagIcons())
        refreshAppearance()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, "CoinPouch")
    Settings.RegisterAddOnCategory(category)
    if Settings.RegisterCanvasLayoutSubcategory then
        local appearanceCategory = Settings.RegisterCanvasLayoutSubcategory(category, appearancePanel, "Appearance")
        Settings.RegisterAddOnCategory(appearanceCategory)
    end

    -- Make the registered category available to slash commands.
    api.settingsCategoryID = category:GetID()

elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
    InterfaceOptions_AddCategory(appearancePanel)
end
