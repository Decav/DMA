-- =========================================================
-- DATA: DATABASE
-- =========================================================

if not DMA then return end
if not DMA.Data then DMA.Data = {} end

DMA.Data.Database = {}

local DEFAULT_DB = {
    meta = {
        version = 1,
        created = time()
    },

    config = {
        historyRetentionDays = 365
    },

    events = {},

    cache = {},

    -- Historial textual de eventos DKP
    history = {}
}

local function DeepCopy(src, dest)
    if type(src) ~= "table" then return src end
    dest = dest or {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = DeepCopy(v, {})
        else
            dest[k] = v
        end
    end
    return dest
end

local function GenerateEventId(event)
    return string.format(
        "%s_%d_%s_%d",
        event.master,
        event.time,
        event.players,
        event.value
    )
end

function DMA.Data.Database:Init()
    if not DMA_DB then
        DMA_DB = DeepCopy(DEFAULT_DB)
        return
    end

    for k, v in pairs(DEFAULT_DB) do
        if DMA_DB[k] == nil then
            DMA_DB[k] = DeepCopy(v)
        end
    end
end

function DMA.Data.Database:GetDB()
    return DMA_DB
end

function DMA.Data.Database:ApplyEvent(event)
    -- Parse players string manually for WoW Vanilla compatibility
    local start = 1
    local delimiter = ","
    while true do
        local pos = string.find(event.players, delimiter, start, true)
        local player
        if pos then
            player = string.sub(event.players, start, pos - 1)
            start = pos + 1
        else
            player = string.sub(event.players, start)
            if player == "" then break end
        end

        player = string.gsub(player, "^%s*(.-)%s*$", "%1")
        if player ~= "" then
            if not DMA_DB.cache[player] then
                DMA_DB.cache[player] = 0
            end
            DMA_DB.cache[player] = DMA_DB.cache[player] + event.value
        end

        if not pos then break end
    end
end

function DMA.Data.Database:AddEvent(event)
    local eventId = GenerateEventId(event)
    event.id = eventId

    DMA_DB.events[eventId] = event
    self:ApplyEvent(event)

    -- Registrar una entrada de historial legible en SavedVariables
    if not DMA_DB.history then
        DMA_DB.history = {}
    end

    local amount = event.value or 0
    local sign = amount >= 0 and "+" or "-"
    local absAmount = math.abs(amount)
    local master = event.master or "?"
    local players = event.players or "?"
    local reason = event.reason or ""

    local action
    if amount >= 0 then
        action = "otorgó"
    else
        action = "quitó"
    end

    local summary
    if reason ~= "" then
        summary = string.format("%s %s %d DKP a %s (%s)", master, action, absAmount, players, reason)
    else
        summary = string.format("%s %s %d DKP a %s", master, action, absAmount, players)
    end

    table.insert(DMA_DB.history, {
        time = event.time or time(),
        text = summary,
        id = eventId
    })

    return eventId
end

function DMA.Data.Database:ReplicateEvent(event)
    local eventId = GenerateEventId(event)

    if DMA_DB.events[eventId] then
        return
    end

    event.id = eventId
    DMA_DB.events[eventId] = event
    self:ApplyEvent(event)
end

function DMA.Data.Database:GetDKP(playerName)
    return DMA_DB.cache[playerName] or 0
end

function DMA.Data.Database:CleanupHistory()
    local cutoff = time() - (DMA_DB.config.historyRetentionDays * 86400)

    for id, event in pairs(DMA_DB.events) do
        if event.time < cutoff then
            DMA_DB.events[id] = nil
        end
    end
end

DEFAULT_CHAT_FRAME:AddMessage("DMA: Database module loaded")
