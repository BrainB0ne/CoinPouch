local addonName = ...

local DEFAULT_X = 0
local DEFAULT_Y = 150

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

-- Dark background
frame:SetBackdropColor(0.05, 0.05, 0.05, 0.85)

-- Subtle golden border
frame:SetBackdropBorderColor(0.65, 0.52, 0.30, 1)

local function GetAddonVersion()
    local version

    if C_AddOns and C_AddOns.GetAddOnMetadata then
        version = C_AddOns.GetAddOnMetadata(addonName, "Version")
    elseif GetAddOnMetadata then
        version = GetAddOnMetadata(addonName, "Version")
    end

    return version or "Unknown"
end

local function GetBagSlotInfo()
    local freeSlots = 0
    local totalSlots = 0

    -- Backpack (0) and equipped bags (1-4)
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        local numFree = C_Container.GetContainerNumFreeSlots(bag)

        if numSlots and numFree then
            totalSlots = totalSlots + numSlots
            freeSlots = freeSlots + numFree
        end
    end

    return freeSlots, totalSlots
end

local function GetBagSlotColor(freeSlots, totalSlots)
    if totalSlots == 0 then
        return "ff69d36e"
    end

    local percentage = (freeSlots / totalSlots) * 100

    if percentage > 25 then
        return "ff69d36e" -- Green
    elseif percentage >= 10 then
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

    local freeSlots, totalSlots = GetBagSlotInfo()
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

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click: Toggle bags", 1, 1, 1)
    GameTooltip:AddLine("Right-drag: Move widget", 1, 1, 1)

    GameTooltip:Show()
end

frame:SetScript("OnEnter", function(self)
    self:SetBackdropBorderColor(1, 0.82, 0.35, 1)
    ShowCoinPouchTooltip()
end)

frame:SetScript("OnLeave", function(self)
    self:SetBackdropBorderColor(0.65, 0.52, 0.30, 1)
    GameTooltip:Hide()
end)

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

    local x = frameX - parentX
    local y = frameY - parentY

    CoinPouchDB.x = x
    CoinPouchDB.y = y

    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "CENTER", x, y)
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
    local freeSlots, totalSlots = GetBagSlotInfo()
    local bagColor = GetBagSlotColor(freeSlots, totalSlots)

    -- Format money and inventory display
    local display = string.format(
        "%s  |c%s%d|r |TInterface\\Icons\\INV_Misc_Bag_08:14:14|t",
        money,
        bagColor,
        freeSlots
    )

    moneyText:SetText(display)

    -- Automatically adjust widget width
    local textWidth = moneyText:GetStringWidth()
    local padding = 24

    frame:SetWidth(math.max(80, math.ceil(textWidth + padding)))
end

-- Initialize saved settings
local function Initialize()
    CoinPouchDB = CoinPouchDB or {}

    local x = CoinPouchDB.x or DEFAULT_X
    local y = CoinPouchDB.y or DEFAULT_Y

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)

    UpdateMoney()
end

-- Events
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_MONEY")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("MODIFIER_STATE_CHANGED")

frame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        Initialize()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_MONEY" or event == "BAG_UPDATE_DELAYED" then
        UpdateMoney()
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

-- Slash command
SLASH_COINPOUCH1 = "/coinpouch"

SlashCmdList["COINPOUCH"] = function(msg)
    if msg == "reset" then
        CoinPouchDB.x = DEFAULT_X
        CoinPouchDB.y = DEFAULT_Y

        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", DEFAULT_X, DEFAULT_Y)

        print("|cff00ff00CoinPouch position reset!|r")
    else
        print("|cffffd700CoinPouch commands:|r")
        print("/coinpouch reset - Reset coinpouch position")
    end
end
