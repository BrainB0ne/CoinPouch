local addonName = ...

-- Create the main frame
local frame = CreateFrame("Frame", "GoldTrackerFrame", UIParent)

frame:SetSize(180, 30)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)

-- Create the money display
local moneyText = frame:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontNormal"
)

moneyText:SetPoint("CENTER", frame, "CENTER")

-- Convert copper into gold, silver and copper
local function FormatMoney(amount)
    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount % 10000) / 100)
    local copper = amount % 100

    return string.format(
        "|cffffd700%dg|r  |cffc7c7cf%ds|r  |cffeda55f%dc|r",
        gold,
        silver,
        copper
    )
end

-- Update the displayed money
local function UpdateMoney()
    moneyText:SetText(FormatMoney(GetMoney()))
end

-- Register events
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_MONEY")

frame:SetScript("OnEvent", function(self, event)
    UpdateMoney()
end)

-- Confirm that the addon Lua file has loaded
print("|cff00ff00GoldTracker v0.1 loaded!|r")