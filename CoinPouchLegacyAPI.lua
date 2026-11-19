
-- CoinPouch: Legacy WoW API definitions for LuaLS.
-- Development only. Do NOT include this file in CoinPouch.toc.

---@meta

-- Legacy addon metadata API.
---@param addonName string
---@param field string
---@return string|nil
function GetAddOnMetadata(addonName, field) end

-- Legacy Interface Options APIs.
---@param panel table
function InterfaceOptions_AddCategory(panel) end

---@param panel table
function InterfaceOptionsFrame_OpenToCategory(panel) end

-- Named frame created dynamically by CreateFrame().
---@type Frame
CoinPouchSettingsPanel = nil
