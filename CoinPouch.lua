local addonName = ...

local DEFAULT_X = 0
local DEFAULT_Y = 150
local DEFAULT_SCALE = 1
local MIN_SCALE = 0.5
local MAX_SCALE = 2.0
local DEFAULT_RED_THRESHOLD = 10
local DEFAULT_YELLOW_THRESHOLD = 25
local DEFAULT_THEME = "classic"
local DEFAULT_BACKGROUND_OPACITY = 85
local DEFAULT_BORDER_OPACITY = 100

-- The classic preset reproduces the existing widget colors exactly.
local THEMES = {
    classic = { background = { 0.05, 0.05, 0.05 }, border = { 0.65, 0.52, 0.30 }, hover = { 1, 0.82, 0.35 } },
    midnight = { background = { 0.10, 0.11, 0.15 }, border = { 0.42, 0.49, 0.60 }, hover = { 0.65, 0.77, 0.95 } },
    emerald = { background = { 0.07, 0.14, 0.10 }, border = { 0.29, 0.60, 0.40 }, hover = { 0.52, 0.85, 0.62 } },
    minimal = { background = { 0.07, 0.07, 0.09 }, border = { 0.34, 0.34, 0.40 }, hover = { 0.67, 0.67, 0.73 } },
    candyPink = { background = { 0.25, 0.07, 0.19 }, border = { 0.98, 0.38, 0.72 }, hover = { 1.00, 0.67, 0.87 } },
    peach = { background = { 0.28, 0.13, 0.12 }, border = { 1.00, 0.61, 0.45 }, hover = { 1.00, 0.79, 0.63 } },
    lavender = { background = { 0.17, 0.10, 0.27 }, border = { 0.70, 0.49, 0.98 }, hover = { 0.84, 0.70, 1.00 } },
    electricBlue = { background = { 0.04, 0.14, 0.25 }, border = { 0.20, 0.79, 1.00 }, hover = { 0.55, 0.92, 1.00 } },
}

local function ClampOpacity(value, default)
    value = tonumber(value) or default
    return math.max(0, math.min(100, math.floor(value + 0.5)))
end

local frame = CreateFrame(
    "Frame",
    "CoinPouchFrame",
    UIParent,
    "BackdropTemplate"
)

frame:SetSize(180, 30)
frame:SetPoint("CENTER", UIParent, "CENTER", DEFAULT_X, DEFAULT_Y)

-- Classic WoW-style background and border
frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = {
        left = 4,
        right = 4,
        top = 4,
        bottom = 4
    }
})

local function ApplyAppearance()
    local db = CoinPouchDB or {}
    local theme = THEMES[db.theme] or THEMES[DEFAULT_THEME]
    local backgroundAlpha = ClampOpacity(db.backgroundOpacity, DEFAULT_BACKGROUND_OPACITY) / 100
    local borderAlpha = ClampOpacity(db.borderOpacity, DEFAULT_BORDER_OPACITY) / 100
    frame:SetBackdropColor(theme.background[1], theme.background[2], theme.background[3], backgroundAlpha)
    local border = frame:IsMouseOver() and theme.hover or theme.border
    frame:SetBackdropBorderColor(border[1], border[2], border[3], borderAlpha)
end

ApplyAppearance()

local function GetAddonVersion()
    local version

    if C_AddOns and C_AddOns.GetAddOnMetadata then
        version = C_AddOns.GetAddOnMetadata(addonName, "Version")
    elseif GetAddOnMetadata then
        version = GetAddOnMetadata(addonName, "Version")
    end

    return version or "Unknown"
end

-- Keep general-purpose and special-purpose storage separate.
-- The second return value is the bag-family mask (nonzero for specialty bags).
-- Retail also has a dedicated reagent bag at container index 5.
local function GetBagSlotInfo()
    local regularFree, regularTotal = 0, 0
    local specialFree, specialTotal = 0, 0

    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        local numFree, bagFamily = C_Container.GetContainerNumFreeSlots(bag)
        if numSlots and numFree and numSlots > 0 then
            if bagFamily and bagFamily ~= 0 then
                specialFree = specialFree + numFree
                specialTotal = specialTotal + numSlots
            else
                regularFree = regularFree + numFree
                regularTotal = regularTotal + numSlots
            end
        end
    end

    -- Container 5 is the reagent bag on Retail; older clients may not have it.
    local reagentBag = (Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag)
    if reagentBag then
        local numSlots = C_Container.GetContainerNumSlots(reagentBag)
        local numFree = C_Container.GetContainerNumFreeSlots(reagentBag)
        if numSlots and numFree and numSlots > 0 then
            specialFree = specialFree + numFree
            specialTotal = specialTotal + numSlots
        end
    end

    return regularFree, regularTotal, specialFree, specialTotal
end

-- Use equipped bag textures rather than fixed generic icons.
-- Slot 1 is preferred for regular bags; Retail's reagent slot for special bags.
local function GetEquippedBagIcon(bag)
    -- Ask WoW for the actual inventory slot instead of assuming numeric IDs.
    -- Fixed slot IDs can point at profession equipment on newer Retail clients.
    local inventorySlot
    local getSlotInfo = (C_PaperDollInfo and C_PaperDollInfo.GetInventorySlotInfo) or GetInventorySlotInfo
    if bag >= 1 and bag <= 4 then
        if getSlotInfo then
            inventorySlot = getSlotInfo("Bag" .. (bag - 1) .. "Slot")
        end
    elseif Enum and Enum.BagIndex and bag == Enum.BagIndex.ReagentBag then
        if getSlotInfo then
            -- Different client builds may expose the reagent bag under
            -- different inventory slot names.
            ---@diagnostic disable-next-line: param-type-mismatch
            inventorySlot = getSlotInfo("ReagentBagSlot")
                ---@diagnostic disable-next-line: param-type-mismatch
                or getSlotInfo("ReagentBag0Slot")
                ---@diagnostic disable-next-line: param-type-mismatch
                or getSlotInfo("Bag4Slot")
        end
    end

    -- Empty equipment slots can have a placeholder texture (not nil).
    -- Only accept an icon when a bag item is actually equipped.
    if not inventorySlot or not GetInventoryItemID
        or not GetInventoryItemID("player", inventorySlot) then
        return nil
    end

    if GetInventoryItemTexture then
        local texture = GetInventoryItemTexture("player", inventorySlot)
        if texture then return texture end
    end

    return nil
end

local function UseEquippedBagIcons()
    return not CoinPouchDB or CoinPouchDB.useEquippedBagIcons ~= false
end

local function GetBagIcons()
    if not UseEquippedBagIcons() then
        return "Interface\\Icons\\INV_Misc_Bag_08", "Interface\\Icons\\INV_Misc_Bag_10"
    end

    local regularIcon
    local specialIcon
    local firstRegularIcon
    local firstSpecialIcon

    for bag = 1, 4 do
        local slots = C_Container.GetContainerNumSlots(bag)
        if slots and slots > 0 then
            local _, family = C_Container.GetContainerNumFreeSlots(bag)
            local icon = GetEquippedBagIcon(bag)
            if family and family ~= 0 then
                firstSpecialIcon = firstSpecialIcon or icon
            else
                firstRegularIcon = firstRegularIcon or icon
                if bag == 1 then regularIcon = icon end
            end
        end
    end

    local reagentBag = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag
    if reagentBag then
        local slots = C_Container.GetContainerNumSlots(reagentBag)
        if slots and slots > 0 then
            specialIcon = GetEquippedBagIcon(reagentBag)
        end
    end

    return regularIcon or firstRegularIcon or "Interface\\Icons\\INV_Misc_Bag_08",
           specialIcon or firstSpecialIcon or "Interface\\Icons\\INV_Misc_Bag_10"
end

local function ShowSpecialBags()
    return not CoinPouchDB or CoinPouchDB.showSpecialBags ~= false
end

local function GetThresholds()
    local red = CoinPouchDB and CoinPouchDB.redThreshold or DEFAULT_RED_THRESHOLD
    local yellow = CoinPouchDB and CoinPouchDB.yellowThreshold or DEFAULT_YELLOW_THRESHOLD
    return red, yellow
end

local function GetBagSlotColor(freeSlots, totalSlots)
    if totalSlots == 0 then
        return "ff69d36e"
    end

    local percentage = (freeSlots / totalSlots) * 100

    local red, yellow = GetThresholds()

    if percentage > yellow then
        return "ff69d36e" -- Green
    elseif percentage >= red then
        return "ffffd700" -- Yellow
    else
        return "ffff4040" -- Red
    end
end

-- Mouse hover: highlight border and show tooltip
local function ShowCoinPouchTooltip()
    if not IsShiftKeyDown() then
        return
    end

    local version = GetAddonVersion()

    local freeSlots, totalSlots, specialFree, specialTotal = GetBagSlotInfo()
    local percentage = totalSlots > 0
        and (freeSlots / totalSlots * 100) or 0

    GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
    GameTooltip:ClearLines()

    GameTooltip:AddLine("CoinPouch", 1, 0.82, 0)
    GameTooltip:AddLine("Version " .. version, 0.6, 0.6, 0.6)

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(
        string.format(
            "Bag space: %d / %d free (%.0f%%)",
            freeSlots, totalSlots, percentage
        ),
        1, 1, 1
    )

    if ShowSpecialBags() and specialTotal > 0 then
        local specialPercentage = specialFree / specialTotal * 100
        GameTooltip:AddLine(string.format(
            "Special bag space: %d / %d free (%.0f%%)",
            specialFree, specialTotal, specialPercentage
        ), 1, 1, 1)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click: Toggle bags", 1, 1, 1)
    GameTooltip:AddLine("Right-drag: Move widget", 1, 1, 1)

    GameTooltip:Show()
end

frame:SetScript("OnEnter", function(self)
    ApplyAppearance()
    ShowCoinPouchTooltip()
end)

frame:SetScript("OnLeave", function(self)
    ApplyAppearance()
    GameTooltip:Hide()
end)

-- Keep the complete widget inside the visible UIParent area.
-- Offsets passed to SetPoint are in the widget's scaled coordinate space.
local SCREEN_MARGIN = 8

local function KeepOnScreen()
    if not CoinPouchDB then return end

    -- GetLeft/Right/Top/Bottom return coordinates in each frame's
    -- effective-scale space. Convert to physical UI pixels first.
    local frameScale = frame:GetEffectiveScale()
    local parentScale = UIParent:GetEffectiveScale()
    if frameScale <= 0 or parentScale <= 0 then return end

    local left, right = frame:GetLeft(), frame:GetRight()
    local bottom, top = frame:GetBottom(), frame:GetTop()
    local parentLeft, parentRight = UIParent:GetLeft(), UIParent:GetRight()
    local parentBottom, parentTop = UIParent:GetBottom(), UIParent:GetTop()
    if not (left and right and bottom and top and
            parentLeft and parentRight and parentBottom and parentTop) then
        return
    end

    -- Compare actual displayed bounds, rather than estimating the bounds
    -- from the saved position. This avoids a second inward correction on reload.
    local dx, dy = 0, 0
    local minX = parentLeft * parentScale + SCREEN_MARGIN * parentScale
    local maxX = parentRight * parentScale - SCREEN_MARGIN * parentScale
    local minY = parentBottom * parentScale + SCREEN_MARGIN * parentScale
    local maxY = parentTop * parentScale - SCREEN_MARGIN * parentScale
    local leftPx, rightPx = left * frameScale, right * frameScale
    local bottomPx, topPx = bottom * frameScale, top * frameScale

    if leftPx < minX then
        dx = minX - leftPx
    elseif rightPx > maxX then
        dx = maxX - rightPx
    end
    if bottomPx < minY then
        dy = minY - bottomPx
    elseif topPx > maxY then
        dy = maxY - topPx
    end

    if dx == 0 and dy == 0 then return end

    -- SetPoint offsets use the widget's scale, so convert pixel deltas.
    local x = (CoinPouchDB.x or DEFAULT_X) + dx / frameScale
    local y = (CoinPouchDB.y or DEFAULT_Y) + dy / frameScale
    CoinPouchDB.x, CoinPouchDB.y = x, y
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
end

-- Enable dragging
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("RightButton")

frame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()

    local frameX, frameY = self:GetCenter()
    local parentX, parentY = UIParent:GetCenter()

    if not frameX or not frameY or not parentX or not parentY then
        print("CoinPouch: Unable to determine position.")
        return
    end

    -- GetCenter() values are expressed in each frame's own scaled coordinates.
    -- SetPoint() offsets are expressed in CoinPouch's coordinate system.
    local scaleRatio = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local x = frameX - parentX / scaleRatio
    local y = frameY - parentY / scaleRatio

    CoinPouchDB.x = x
    CoinPouchDB.y = y
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "CENTER", x, y)
    KeepOnScreen()
end)

-- Left-click toggles all bags
local mouseDownX, mouseDownY

frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        mouseDownX, mouseDownY = GetCursorPosition()
    end
end)

frame:SetScript("OnMouseUp", function(self, button)
    if button ~= "LeftButton" then
        return
    end

    if not mouseDownX or not mouseDownY then
        return
    end

    local mouseUpX, mouseUpY = GetCursorPosition()

    local dx = mouseUpX - mouseDownX
    local dy = mouseUpY - mouseDownY

    -- Allow up to 5 pixels of mouse movement
    local distanceSquared = dx * dx + dy * dy

    if distanceSquared <= 25 then
        ToggleAllBags()
    end

    mouseDownX, mouseDownY = nil, nil
end)

-- Create money display
local moneyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
moneyText:SetPoint("CENTER", frame, "CENTER")

local function FormatMoney(amount)
    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount % 10000) / 100)
    local copper = amount % 100

    return string.format(
        "|cffffd700%d|r |TInterface\\MoneyFrame\\UI-GoldIcon:14:14|t  " ..
        "|cffc7c7cf%d|r |TInterface\\MoneyFrame\\UI-SilverIcon:14:14|t  " ..
        "|cffeda55f%d|r |TInterface\\MoneyFrame\\UI-CopperIcon:14:14|t",
        gold, silver, copper
    )
end

local function UpdateMoney()
    local money = FormatMoney(GetMoney())

    -- Get inventory capacity
    local freeSlots, totalSlots, specialFree, specialTotal = GetBagSlotInfo()
    local bagColor = GetBagSlotColor(freeSlots, totalSlots)
    local regularIcon, specialIcon = GetBagIcons()

    -- Format money and inventory display
    local display = string.format(
        "%s  |c%s%d|r |T%s:14:14|t",
        money,
        bagColor,
        freeSlots,
        regularIcon
    )

    if ShowSpecialBags() and specialTotal > 0 then
        local specialColor = GetBagSlotColor(specialFree, specialTotal)
        display = display .. string.format(
            "  |c%s%d|r |T%s:14:14|t",
            specialColor, specialFree, specialIcon
        )
    end

    moneyText:SetText(display)

    -- Automatically adjust widget width
    local textWidth = moneyText:GetStringWidth()
    local padding = 24

    frame:SetWidth(math.max(80, math.ceil(textWidth + padding)))
    KeepOnScreen()
end

-- Initialize saved settings
local function Initialize()
    CoinPouchDB = CoinPouchDB or {}
    if not THEMES[CoinPouchDB.theme] then
        CoinPouchDB.theme = DEFAULT_THEME
    end
    CoinPouchDB.backgroundOpacity = ClampOpacity(CoinPouchDB.backgroundOpacity, DEFAULT_BACKGROUND_OPACITY)
    CoinPouchDB.borderOpacity = ClampOpacity(CoinPouchDB.borderOpacity, DEFAULT_BORDER_OPACITY)
    ApplyAppearance()
    if CoinPouchDB.showSpecialBags == nil then
        CoinPouchDB.showSpecialBags = true
    end
    if CoinPouchDB.useEquippedBagIcons == nil then
        CoinPouchDB.useEquippedBagIcons = true
    end

    local red = tonumber(CoinPouchDB.redThreshold) or DEFAULT_RED_THRESHOLD
    local yellow = tonumber(CoinPouchDB.yellowThreshold) or DEFAULT_YELLOW_THRESHOLD
    red = math.max(0, math.min(100, math.floor(red + 0.5)))
    yellow = math.max(red, math.min(100, math.floor(yellow + 0.5)))
    CoinPouchDB.redThreshold = red
    CoinPouchDB.yellowThreshold = yellow

    local x = CoinPouchDB.x or DEFAULT_X
    local y = CoinPouchDB.y or DEFAULT_Y

    local scale = tonumber(CoinPouchDB.scale) or DEFAULT_SCALE
    scale = math.max(MIN_SCALE, math.min(MAX_SCALE, scale))
    CoinPouchDB.scale = scale
    frame:SetScale(scale)

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)

    UpdateMoney()
    KeepOnScreen()
end

-- Events
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_MONEY")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("MODIFIER_STATE_CHANGED")
frame:RegisterEvent("UI_SCALE_CHANGED")
frame:RegisterEvent("DISPLAY_SIZE_CHANGED")

frame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        Initialize()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_MONEY" or event == "BAG_UPDATE_DELAYED" then
        UpdateMoney()
        if event == "BAG_UPDATE_DELAYED" and frame:IsMouseOver() and IsShiftKeyDown() then
            ShowCoinPouchTooltip()
        end
    elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        KeepOnScreen()
    elseif event == "MODIFIER_STATE_CHANGED" then
        if frame:IsMouseOver() then
            if IsShiftKeyDown() then
                ShowCoinPouchTooltip()
            else
                GameTooltip:Hide()
            end
        end
    end
end)

-- Bag-space color thresholds (whole percentages).
local function SetThresholds(red, yellow)
    CoinPouchDB = CoinPouchDB or {}
    red = tonumber(red) or DEFAULT_RED_THRESHOLD
    yellow = tonumber(yellow) or DEFAULT_YELLOW_THRESHOLD
    red = math.max(0, math.min(100, math.floor(red + 0.5)))
    yellow = math.max(red, math.min(100, math.floor(yellow + 0.5)))
    CoinPouchDB.redThreshold = red
    CoinPouchDB.yellowThreshold = yellow
    UpdateMoney()
end

-- Shared API used by the settings panel.
local function SetScale(scale)
    scale = tonumber(scale) or DEFAULT_SCALE
    scale = math.max(MIN_SCALE, math.min(MAX_SCALE, scale))
    CoinPouchDB = CoinPouchDB or {}
    CoinPouchDB.scale = scale
    frame:SetScale(scale)
    KeepOnScreen()
end

local function ResetPosition()
    CoinPouchDB = CoinPouchDB or {}
    CoinPouchDB.x = DEFAULT_X
    CoinPouchDB.y = DEFAULT_Y
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", DEFAULT_X, DEFAULT_Y)
end

_G.CoinPouchAPI = {
    GetScale = function() return frame:GetScale() end,
    SetScale = SetScale,
    ResetScale = function() SetScale(DEFAULT_SCALE) end,
    ResetPosition = ResetPosition,
    GetTheme = function() return CoinPouchDB and CoinPouchDB.theme or DEFAULT_THEME end,
    SetTheme = function(theme)
        if not THEMES[theme] then return end
        CoinPouchDB = CoinPouchDB or {}
        CoinPouchDB.theme = theme
        ApplyAppearance()
    end,
    GetBackgroundOpacity = function()
        return ClampOpacity(CoinPouchDB and CoinPouchDB.backgroundOpacity, DEFAULT_BACKGROUND_OPACITY)
    end,
    SetBackgroundOpacity = function(value)
        CoinPouchDB = CoinPouchDB or {}
        CoinPouchDB.backgroundOpacity = ClampOpacity(value, DEFAULT_BACKGROUND_OPACITY)
        ApplyAppearance()
    end,
    GetBorderOpacity = function()
        return ClampOpacity(CoinPouchDB and CoinPouchDB.borderOpacity, DEFAULT_BORDER_OPACITY)
    end,
    SetBorderOpacity = function(value)
        CoinPouchDB = CoinPouchDB or {}
        CoinPouchDB.borderOpacity = ClampOpacity(value, DEFAULT_BORDER_OPACITY)
        ApplyAppearance()
    end,
    ResetAppearance = function()
        CoinPouchDB = CoinPouchDB or {}
        CoinPouchDB.theme = DEFAULT_THEME
        CoinPouchDB.backgroundOpacity = DEFAULT_BACKGROUND_OPACITY
        CoinPouchDB.borderOpacity = DEFAULT_BORDER_OPACITY
        ApplyAppearance()
    end,
    GetUseEquippedBagIcons = UseEquippedBagIcons,
    SetUseEquippedBagIcons = function(enabled)
        CoinPouchDB = CoinPouchDB or {}
        CoinPouchDB.useEquippedBagIcons = not not enabled
        UpdateMoney()
    end,
    GetShowSpecialBags = ShowSpecialBags,
    SetShowSpecialBags = function(enabled)
        CoinPouchDB = CoinPouchDB or {}
        CoinPouchDB.showSpecialBags = not not enabled
        UpdateMoney()
    end,
    GetThresholds = GetThresholds,
    SetThresholds = SetThresholds,
    ResetThresholds = function()
        SetThresholds(DEFAULT_RED_THRESHOLD, DEFAULT_YELLOW_THRESHOLD)
    end,
}

-- Slash commands
SLASH_COINPOUCH1 = "/coinpouch"

SlashCmdList["COINPOUCH"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")

    if msg == "reset" then
        ResetPosition()
        print("|cff00ff00CoinPouch position reset!|r")

    elseif msg == "settings" then
        if Settings and Settings.OpenToCategory and
        _G.CoinPouchAPI.settingsCategoryID then

            Settings.OpenToCategory(_G.CoinPouchAPI.settingsCategoryID)

        elseif InterfaceOptionsFrame_OpenToCategory then
            InterfaceOptionsFrame_OpenToCategory(
                _G.CoinPouchSettingsPanel
            )
        else
            print("|cffff4040CoinPouch: Unable to open settings.|r")
        end

    else
        print("|cffffd700CoinPouch commands:|r")
        print("/coinpouch reset - Reset widget position")
        print("/coinpouch settings - Open addon settings")
    end
end
