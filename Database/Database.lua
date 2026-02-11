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

-- Obtiene una clave estable para la "identidad" de la hermandad/ personaje
local function GetCurrentGuildKey()
    local guildName = nil
    if GetGuildInfo then
        guildName = GetGuildInfo("player")
    end

    if guildName and guildName ~= "" then
        return "GUILD:" .. guildName
    end

    local playerName = UnitName and UnitName("player") or "UNKNOWN"
    local realmName = GetRealmName and GetRealmName() or ""
    if realmName ~= "" then
        return "CHAR:" .. playerName .. "-" .. realmName
    else
        return "CHAR:" .. playerName
    end
end

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
    else
        for k, v in pairs(DEFAULT_DB) do
            if DMA_DB[k] == nil then
                DMA_DB[k] = DeepCopy(v)
            end
        end
    end

    -- Aislar eventos y cache por hermandad/personaje.
    -- Se usa un contenedor DMA_DB.guilds[clave] con sus propias
    -- tablas events/cache/history.
    local guildKey = GetCurrentGuildKey()

    -- Inicializar contenedor de guilds sin borrar datos existentes
    if not DMA_DB.guilds then
        DMA_DB.guilds = {}

        -- Si venimos de una versión antigua y hay datos globales,
        -- podemos migrarlos a la guild actual en lugar de borrarlos.
        if DMA_DB.events and next(DMA_DB.events) ~= nil then
            DMA_DB.guilds[guildKey] = DMA_DB.guilds[guildKey] or {}
            DMA_DB.guilds[guildKey].events = DMA_DB.events
        end
        if DMA_DB.cache and next(DMA_DB.cache) ~= nil then
            DMA_DB.guilds[guildKey] = DMA_DB.guilds[guildKey] or {}
            DMA_DB.guilds[guildKey].cache = DMA_DB.cache
        end
        if DMA_DB.history and next(DMA_DB.history) ~= nil then
            DMA_DB.guilds[guildKey] = DMA_DB.guilds[guildKey] or {}
            DMA_DB.guilds[guildKey].history = DMA_DB.history
        end
    end

    if not DMA_DB.guilds[guildKey] then
        DMA_DB.guilds[guildKey] = {
            events = {},
            cache = {},
            history = {}
        }
    else
        -- Asegurar que las subtablas existen aunque sean de una versión anterior
        local g = DMA_DB.guilds[guildKey]
        g.events = g.events or {}
        g.cache  = g.cache  or {}
        g.history = g.history or {}
    end

    -- Reasignar accesos directos globales a la hermandad actual
    local current = DMA_DB.guilds[guildKey]
    DMA_DB.events  = current.events
    DMA_DB.cache   = current.cache
    DMA_DB.history = current.history
end

-- Limpia todos los datos (eventos, cache, historial) de la guild/personaje actual
function DMA.Data.Database:ClearCurrentGuildData()
    if not DMA_DB then return end

    local guildKey = GetCurrentGuildKey()
    DMA_DB.guilds = DMA_DB.guilds or {}

    DMA_DB.guilds[guildKey] = {
        events = {},
        cache = {},
        history = {}
    }

    -- Reapuntar los accesos directos globales a la guild actual
    DMA_DB.events  = DMA_DB.guilds[guildKey].events
    DMA_DB.cache   = DMA_DB.guilds[guildKey].cache
    DMA_DB.history = DMA_DB.guilds[guildKey].history
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
    -- Evitar duplicar eventos si ya existen (por ejemplo, eventos replicados por red)
    if DMA_DB.events[eventId] then
        return eventId
    end

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
    -- Para compatibilidad, simplemente reutilizamos AddEvent,
    -- que ya es idempotente e incluye el historial textual.
    self:AddEvent(event)
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


