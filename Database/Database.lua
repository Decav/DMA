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
    }
}


-- Obtiene una clave estable para la "identidad" de la hermandad/ personaje
function DMA.Data.Database:GetCurrentGuildKey()
    local guildName = nil
    if GetGuildInfo then
        guildName = GetGuildInfo("player")
    end

    -- Solo trabajamos con datos a nivel de hermandad.
    -- Si el personaje no está en una hermandad, no devolvemos
    -- ninguna clave (evita crear buckets "CHAR:" en DMA_DB.guilds).
    if guildName and guildName ~= "" then
        return "GUILD:" .. guildName
    end

    return nil
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

    -- Eliminar buckets antiguos a nivel de personaje ("CHAR:") que ya
    -- no deben existir en la estructura de datos.
    if DMA_DB.guilds then
        for key, _ in pairs(DMA_DB.guilds) do
            if type(key) == "string" and string.sub(key, 1, 5) == "CHAR:" then
                DMA_DB.guilds[key] = nil
            end
        end
    end

    -- Aislar eventos y cache por hermandad/personaje.
    -- Se usa un contenedor DMA_DB.guilds[clave] con sus propias
    -- tablas events/cache/history.
    local guildKey = self:GetCurrentGuildKey()

    -- Si no hay hermandad (personaje sin guild), no inicializamos
    -- ningún bucket de datos de DKP.
    if not guildKey then
        return
    end

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

    -- A partir de aquí, todos los datos de eventos/historial viven en
    -- DMA_DB.guilds[guildKey].*; las claves globales ya no se usan.
    DMA_DB.events  = nil
    DMA_DB.history = nil

    if not DMA_DB.guilds[guildKey] then
        DMA_DB.guilds[guildKey] = {
            events = {},
            cache = {},
            history = {},
            config = {},
        }
    else
        -- Asegurar que las subtablas existen aunque sean de una versión anterior
        local g = DMA_DB.guilds[guildKey]
        g.events  = g.events  or {}
        g.cache   = g.cache   or {}
        g.history = g.history or {}
        g.config  = g.config  or {}
    end

    -- Reasignar acceso directo global solo para cache, manteniendo
    -- events/history únicamente dentro de DMA_DB.guilds[guildKey].
    local current = DMA_DB.guilds[guildKey]
    DMA_DB.cache = current.cache
end

-- Limpia todos los datos (eventos, cache, historial) de la guild/personaje actual
function DMA.Data.Database:ClearCurrentGuildData()
    if not DMA_DB then return end

    local guildKey = self:GetCurrentGuildKey()
    if not guildKey then return end
    DMA_DB.guilds = DMA_DB.guilds or {}

    DMA_DB.guilds[guildKey] = {
        events = {},
        cache = {},
        history = {},
        config = {},
    }

    -- Reapuntar el acceso directo global de cache a la guild actual
    DMA_DB.cache = DMA_DB.guilds[guildKey].cache
end

function DMA.Data.Database:GetDB()
    return DMA_DB
end

function DMA.Data.Database:ApplyEvent(event)
    if not DMA_DB then
        DMA_DB = DeepCopy(DEFAULT_DB)
    end

    -- Asegurarnos de trabajar siempre sobre el bucket de la guild/char actual
    local guildKey = self:GetCurrentGuildKey()
    if not guildKey then
        -- Personaje sin hermandad: no aplicamos eventos de DKP
        return
    end
    DMA_DB.guilds = DMA_DB.guilds or {}
    DMA_DB.guilds[guildKey] = DMA_DB.guilds[guildKey] or {
        events  = {},
        cache   = {},
        history = {},
        config  = {},
    }
    local bucket = DMA_DB.guilds[guildKey]
    bucket.cache = bucket.cache or {}

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
            if not bucket.cache[player] then
                bucket.cache[player] = 0
            end
            bucket.cache[player] = bucket.cache[player] + event.value
        end

        if not pos then break end
    end
end

function DMA.Data.Database:AddEvent(event)
    if not DMA_DB then
        DMA_DB = DeepCopy(DEFAULT_DB)
    end

    local guildKey = self:GetCurrentGuildKey()
    if not guildKey then
        -- Personaje sin hermandad: no registramos eventos de DKP
        return nil
    end
    DMA_DB.guilds = DMA_DB.guilds or {}
    DMA_DB.guilds[guildKey] = DMA_DB.guilds[guildKey] or {
        events  = {},
        cache   = {},
        history = {},
        config  = {},
    }
    local bucket = DMA_DB.guilds[guildKey]
    bucket.events  = bucket.events  or {}
    bucket.history = bucket.history or {}

    local eventId = GenerateEventId(event)
    -- Evitar duplicar eventos si ya existen (por ejemplo, eventos replicados por red)
    if bucket.events[eventId] then
        return eventId
    end

    event.id = eventId

    bucket.events[eventId] = event
    self:ApplyEvent(event)

    -- Registrar una entrada de historial legible en SavedVariables
    if not bucket.history then
        bucket.history = {}
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

    table.insert(bucket.history, {
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
    if not DMA_DB then return 0 end

    local guildKey = self:GetCurrentGuildKey()
    if not guildKey or not DMA_DB.guilds or not DMA_DB.guilds[guildKey] or not DMA_DB.guilds[guildKey].cache then
        return 0
    end

    return DMA_DB.guilds[guildKey].cache[playerName] or 0
end

function DMA.Data.Database:CleanupHistory()
    if not DMA_DB or not DMA_DB.config then return end

    local cutoff = time() - (DMA_DB.config.historyRetentionDays * 86400)

    local guildKey = self:GetCurrentGuildKey()
    if not guildKey or not DMA_DB.guilds or not DMA_DB.guilds[guildKey] or not DMA_DB.guilds[guildKey].events then
        return
    end

    local events = DMA_DB.guilds[guildKey].events
    for id, event in pairs(events) do
        if event.time < cutoff then
            events[id] = nil
        end
    end
end


