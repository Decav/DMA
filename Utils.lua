-- =========================================================
-- UTILS: GENERAL UTILITIES
-- =========================================================

if not DMA then return end
if not DMA.Utils then DMA.Utils = {} end

DMA.Utils.General = {}

local Utils = DMA.Utils.General

-- String utilities
function Utils:Trim(s)
    if not s then return "" end
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

-- Global trim function for WoW Vanilla compatibility
function strtrim(s)
    if not s then return "" end
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function Utils:Split(str, delimiter)
    local result = {}
    if not str or str == "" then
        return result
    end

    local start = 1
    while true do
        local pos = string.find(str, delimiter, start, true)
        if pos then
            local part = string.sub(str, start, pos - 1)
            if part ~= "" then
                table.insert(result, part)
            end
            start = pos + string.len(delimiter)
        else
            local part = string.sub(str, start)
            if part ~= "" then
                table.insert(result, part)
            end
            break
        end
    end
    return result
end

function Utils:Join(table, delimiter)
    return table.concat(table, delimiter or ",")
end

function Utils:Capitalize(str)
    return (str:gsub("^%l", string.upper))
end

-- Table utilities
function Utils:TableContains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function Utils:TableKeys(table)
    local keys = {}
    for key, _ in pairs(table) do
        table.insert(keys, key)
    end
    return keys
end

function Utils:TableValues(table)
    local values = {}
    for _, value in pairs(table) do
        table.insert(values, value)
    end
    return values
end

function Utils:TableSize(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

function Utils:TableIsEmpty(table)
    return next(table) == nil
end

function Utils:TableCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = self:TableCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

function Utils:TableMerge(t1, t2)
    local result = self:TableCopy(t1)
    for key, value in pairs(t2) do
        result[key] = value
    end
    return result
end

-- Array utilities
function Utils:SortByField(array, field, descending)
    table.sort(array, function(a, b)
        if descending then
            return a[field] > b[field]
        else
            return a[field] < b[field]
        end
    end)
    return array
end

function Utils:SortByValue(array, descending)
    table.sort(array, function(a, b)
        if descending then
            return a > b
        else
            return a < b
        end
    end)
    return array
end

-- WoW specific utilities
function Utils:GetPlayerName()
    return UnitName("player")
end

function Utils:IsInRaid()
    return GetNumRaidMembers() > 0
end

function Utils:IsInParty()
    return GetNumPartyMembers() > 0
end

function Utils:GetRaidMembers()
    local members = {}
    if not self:IsInRaid() then return members end

    for i = 1, GetNumRaidMembers() do
        local name = UnitName("raid" .. i)
        if name then
            table.insert(members, name)
        end
    end

    return members
end

function Utils:GetPartyMembers()
    local members = {}
    if not self:IsInParty() then return members end

    for i = 1, GetNumPartyMembers() do
        local name = UnitName("party" .. i)
        if name then
            table.insert(members, name)
        end
    end

    return members
end

function Utils:GetGroupMembers()
    if self:IsInRaid() then
        return self:GetRaidMembers()
    elseif self:IsInParty() then
        return self:GetPartyMembers()
    else
        return {self:GetPlayerName()}
    end
end

-- Time utilities
function Utils:GetCurrentTime()
    return time()
end

function Utils:FormatTime(timestamp)
    return date("%Y-%m-%d %H:%M:%S", timestamp)
end

function Utils:FormatShortTime(timestamp)
    return date("%m/%d %H:%M", timestamp)
end

function Utils:GetTimeAgo(timestamp)
    local diff = time() - timestamp
    if diff < 60 then
        return diff .. " seconds ago"
    elseif diff < 3600 then
        return math.floor(diff / 60) .. " minutes ago"
    elseif diff < 86400 then
        return math.floor(diff / 3600) .. " hours ago"
    else
        return math.floor(diff / 86400) .. " days ago"
    end
end

-- Validation utilities
function Utils:IsValidPlayerName(name)
    if not name or name == "" then return false end
    -- Basic validation: letters, spaces, apostrophes, no numbers at start
    -- Lua 5.0 no tiene string.match, usamos string.find con patrón completo
    return string.find(name, "^[A-Za-z][A-Za-z ']*$") ~= nil
end

function Utils:IsValidDKPValue(value)
    if type(value) ~= "number" then return false end
    return value >= -999 and value <= 999
end

function Utils:IsValidEventType(eventType)
    if not DMA.Utils.Constants then return false end
    for _, validType in pairs(DMA.Utils.Constants.EVENT_TYPES) do
        if eventType == validType then
            return true
        end
    end
    return false
end

-- UI utilities
function Utils:CreateBackdrop(frame, bgColor, borderColor)
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    bgColor = bgColor or {0, 0, 0, 0.9}
    borderColor = borderColor or {1, 1, 1, 1}

    frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
    frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
end

function Utils:MakeMovable(frame)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
end

-- Debug utilities
function Utils:DumpTable(table, indent)
    indent = indent or 0
    local indentStr = string.rep("  ", indent)

    if type(table) ~= "table" then
        return tostring(table)
    end

    local result = "{\n"
    for key, value in pairs(table) do
        result = result .. indentStr .. "  [" .. tostring(key) .. "] = "

        if type(value) == "table" then
            result = result .. self:DumpTable(value, indent + 1)
        else
            result = result .. tostring(value)
        end

        result = result .. ",\n"
    end
    result = result .. indentStr .. "}"

    return result
end

-- Alias for compatibility
DMA.Utils.Split = DMA.Utils.General.Split
DMA.Utils.Trim = DMA.Utils.General.Trim

DEFAULT_CHAT_FRAME:AddMessage("DMA: Utils module loaded")
