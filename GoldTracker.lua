local addonName = ...

local DEFAULT_X = 0
local DEFAULT_Y = 150

local frame = CreateFrame("Frame", "GoldTrackerFrame", UIParent)

frame:SetSize(180, 30)
frame:SetPoint("CENTER", UIParent, "CENTER", DEFAULT_X, DEFAULT_Y)

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
        print("GoldTracker: Unable to determine position.")
        return
    end

    local x = frameX - parentX
    local y = frameY - parentY

    GoldTrackerDB.x = x
    GoldTrackerDB.y = y

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
        "|cffffd700%dg|r  |cffc7c7cf%ds|r  |cffeda55f%dc|r",
        gold, silver, copper
    )
end

local function UpdateMoney()
    moneyText:SetText(FormatMoney(GetMoney()))
end

-- Initialize saved settings
local function Initialize()
    GoldTrackerDB = GoldTrackerDB or {}

    local x = GoldTrackerDB.x or DEFAULT_X
    local y = GoldTrackerDB.y or DEFAULT_Y

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)

    UpdateMoney()
end

-- Events
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_MONEY")

frame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        Initialize()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_MONEY" then
        UpdateMoney()
    end
end)

-- Slash command
SLASH_GOLDTRACKER1 = "/goldtracker"

SlashCmdList["GOLDTRACKER"] = function(msg)
    if msg == "reset" then
        GoldTrackerDB.x = DEFAULT_X
        GoldTrackerDB.y = DEFAULT_Y

        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", DEFAULT_X, DEFAULT_Y)

        print("|cff00ff00GoldTracker position reset!|r")
    else
        print("|cffffd700GoldTracker commands:|r")
        print("/goldtracker reset - Reset tracker position")
    end
end
