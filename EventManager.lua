-- =========================================================
-- DATA: EVENT MANAGER
-- =========================================================

if not DMA then return end
if not DMA.Data then DMA.Data = {} end

DMA.Data.EventManager = {}

local EventManager = DMA.Data.EventManager

-- Event types constants
EventManager.EVENT_TYPES = DMA.Utils.Constants.EVENT_TYPES

-- Create a new DKP event
function EventManager:CreateEvent(eventType, players, value, reason, master)
    if not eventType or not players or not value or not master then
        DEFAULT_CHAT_FRAME:AddMessage("DMA: Invalid event parameters")
        return nil
    end

    -- Validate master permissions
    if not DMA.Core.Permissions:IsDKPMaster(master) then
        DEFAULT_CHAT_FRAME:AddMessage("DMA: ", master , " is not a DKP Master")
        return nil
    end

    local timestamp = time()
    local eventId = self:GenerateEventId(master, timestamp, players, value)

    local event = {
        id = eventId,
        type = eventType,
        players = players,
        value = value,
        reason = reason or "",
        master = master,
        time = timestamp
    }

    return event
end

-- Generate unique event ID
function EventManager:GenerateEventId(master, timestamp, players, value)
    -- Sort players for consistent ID generation
    local sortedPlayers = {}
    if DMA.Utils and DMA.Utils.General and DMA.Utils.General.Split then
        sortedPlayers = DMA.Utils.General:Split(players, ",")
    else
        -- Fallback: manual string splitting for WoW Vanilla compatibility
        local start = 1
        local delimiter = ","
        while true do
            local pos = string.find(players, delimiter, start, true)
            if pos then
                local part = string.sub(players, start, pos - 1)
                if part ~= "" then
                    table.insert(sortedPlayers, part)
                end
                start = pos + 1
            else
                local part = string.sub(players, start)
                if part ~= "" then
                    table.insert(sortedPlayers, part)
                end
                break
            end
        end
    end

    -- Trim whitespace from player names
    for i, player in ipairs(sortedPlayers) do
        sortedPlayers[i] = DMA.Utils and DMA.Utils.Trim and DMA.Utils:Trim(player) or string.gsub(player, "^%s*(.-)%s*$", "%1")
    end

    table.sort(sortedPlayers)
    local playersStr = table.concat(sortedPlayers, ",")

    return string.format("%s_%d_%s_%d", master, timestamp, playersStr, value)
end

-- Validate event structure
function EventManager:ValidateEvent(event)
    if not event.id or not event.type or not event.players or
       not event.value or not event.master or not event.time then
        return false, "Missing required fields"
    end

    -- Validate event type
    local validType = false
    for _, eventType in pairs(self.EVENT_TYPES) do
        if event.type == eventType then
            validType = true
            break
        end
    end

    if not validType then
        return false, "Invalid event type:", event.type
    end

    -- Validate master permissions
    if not DMA.Core.Permissions:IsDKPMaster(event.master) then
        return false, "Invalid DKP Master:", event.master
    end

    -- Validate timestamp (not too old or future)
    local currentTime = time()
    if event.time > currentTime + 300 or event.time < currentTime - 86400 then
        return false, "Invalid timestamp"
    end

    return true
end

-- Process incoming event from network
function EventManager:ProcessIncomingEvent(event, sender)
    local valid, errorMsg = self:ValidateEvent(event)
    if not valid then
        DEFAULT_CHAT_FRAME:AddMessage("DMA: Invalid event from", sender, ":", errorMsg)
        return false
    end

    -- Check if event already exists
    if DMA_DB.events[event.id] then
        return true -- Already processed, ignore
    end

    -- Store event
    DMA_DB.events[event.id] = event

    -- Apply to cache
    if DMA.Data.Cache then
        DMA.Data.Cache:ApplyEvent(event)
    end

    DEFAULT_CHAT_FRAME:AddMessage("DMA: Processed event", event.id, "from", sender)
    return true
end

-- Get events for a specific player
function EventManager:GetPlayerEvents(playerName)
    local playerEvents = {}

    for eventId, event in pairs(DMA_DB.events) do
        if string.find(event.players, playerName) then
            table.insert(playerEvents, event)
        end
    end

    -- Sort by timestamp (newest first)
    table.sort(playerEvents, function(a, b) return a.time > b.time end)

    return playerEvents
end

-- Get recent events (last N events)
function EventManager:GetRecentEvents(limit)
    limit = limit or 50

    local events = {}
    for eventId, event in pairs(DMA_DB.events) do
        table.insert(events, event)
    end

    -- Sort by timestamp (newest first)
    table.sort(events, function(a, b) return a.time > b.time end)

    -- Return only the most recent
    local result = {}
    local count = table.getn(events)
    local maxIndex = math.min(limit, count)
    for i = 1, maxIndex do
        table.insert(result, events[i])
    end

    return result
end

-- Get events by type
function EventManager:GetEventsByType(eventType)
    local filteredEvents = {}

    for eventId, event in pairs(DMA_DB.events) do
        if event.type == eventType then
            table.insert(filteredEvents, event)
        end
    end

    -- Sort by timestamp (newest first)
    table.sort(filteredEvents, function(a, b) return a.time > b.time end)

    return filteredEvents
end

DEFAULT_CHAT_FRAME:AddMessage("DMA: EventManager module loaded")
