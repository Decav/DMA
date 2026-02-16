-- =========================================================
-- DATA: CACHE
-- =========================================================

if not DMA then return end
if not DMA.Data then DMA.Data = {} end

DMA.Data.Cache = {}

local Cache = DMA.Data.Cache

-- Initialize cache
function Cache:Init()
    if not DMA_DB then
        return
    end

    -- Obtener la tabla de eventos de la guild actual desde Database
    if not DMA.Data or not DMA.Data.Database or
       not DMA.Data.Database.GetDB or not DMA.Data.Database.GetCurrentGuildKey then
        return
    end

    local db = DMA.Data.Database:GetDB()
    if not db or not db.guilds then
        return
    end

    local guildKey = DMA.Data.Database:GetCurrentGuildKey()
    if not guildKey or not db.guilds[guildKey] then
        return
    end

    local bucket = db.guilds[guildKey]
    bucket.cache  = bucket.cache  or {}
    bucket.events = bucket.events or {}

    -- Hacer que DMA_DB.cache apunte al cache de la guild actual para
    -- mantener compatibilidad con funciones que lo usan directamente.
    DMA_DB.cache = bucket.cache

    -- Si hay eventos en la hermandad actual, reconstruimos el cache
    -- a partir de ellos. No se crea ningún dato de prueba.
    if next(bucket.events) ~= nil then
        self:Rebuild()
    end
end

-- Rebuild entire cache from events
function Cache:Rebuild()
    if not DMA.Data or not DMA.Data.Database or
       not DMA.Data.Database.GetDB or not DMA.Data.Database.GetCurrentGuildKey then
        return
    end

    local db = DMA.Data.Database:GetDB()
    if not db or not db.guilds then
        return
    end

    local guildKey = DMA.Data.Database:GetCurrentGuildKey()
    if not guildKey or not db.guilds[guildKey] then
        return
    end

    local bucket = db.guilds[guildKey]
    bucket.cache  = bucket.cache  or {}
    bucket.events = bucket.events or {}

    -- Clear current cache
    bucket.cache = {}
    DMA_DB.cache = bucket.cache

    -- Process all events in chronological order
    local events = {}
    for eventId, event in pairs(bucket.events) do
        table.insert(events, event)
    end

    -- Sort events by timestamp
    table.sort(events, function(a, b) return a.time < b.time end)

    -- Apply events in order
    for _, event in ipairs(events) do
        self:ApplyEvent(event, false) -- Don't save to DB during rebuild
    end
end

-- Apply a single event to the cache
function Cache:ApplyEvent(event, saveToDB)
    if saveToDB == nil then saveToDB = true end

    -- Parse players string
    local players
    if DMA.Utils and DMA.Utils.Split then
        players = DMA.Utils:Split(event.players, ",")
    else
        -- Fallback: manual string splitting for WoW Vanilla compatibility
        players = {}
        local s_start = 1
        local s_delimiter = ","
        while true do
            local s_pos = string.find(event.players, s_delimiter, s_start, true)
            if s_pos then
                local s_part = string.sub(event.players, s_start, s_pos - 1)
                if s_part ~= "" then
                    table.insert(players, string.gsub(s_part, "^%s*(.-)%s*$", "%1"))
                end
                s_start = s_pos + 1
            else
                local s_part = string.sub(event.players, s_start)
                if s_part ~= "" then
                    table.insert(players, string.gsub(s_part, "^%s*(.-)%s*$", "%1"))
                end
                break
            end
        end
    end

    for _, playerName in ipairs(players) do
        playerName = string.gsub(playerName, "^%s*(.-)%s*$", "%1") -- Remove whitespace

        if playerName ~= "" then
            -- Initialize player if not exists
            if not DMA_DB.cache[playerName] then
                DMA_DB.cache[playerName] = 0
            end

            -- Apply DKP change
            DMA_DB.cache[playerName] = DMA_DB.cache[playerName] + event.value


            -- Ensure non-negative DKP (opcional)
            -- DMA_DB.cache[playerName] = math.max(0, DMA_DB.cache[playerName])
        end
    end

    if saveToDB then
        -- Save to persistent storage
        -- This is handled by the Database module
    end
end

-- Get DKP for a specific player
function Cache:GetPlayerDKP(playerName)
    if not playerName then return 0 end
    return DMA_DB.cache[playerName] or 0
end

-- Set DKP for a player (used for corrections/migrations)
function Cache:SetPlayerDKP(playerName, dkpValue)
    if not playerName then return end

    DMA_DB.cache[playerName] = dkpValue or 0

    -- Create correction event for audit trail
    if DMA.Data.EventManager then
        local correctionEvent = DMA.Data.EventManager:CreateEvent(
            "manual_adjust",
            playerName,
            (dkpValue or 0) - (DMA_DB.cache[playerName] or 0),
            "DKP correction",
            UnitName("player")
        )

        if correctionEvent and DMA.Data.Database then
            DMA.Data.Database:AddEvent(correctionEvent)
        end
    end
end

-- Get all players sorted by DKP (highest first)
function Cache:GetAllPlayersByDKP()
    local players = {}
    if not GetNumGuildMembers or not GetGuildRosterInfo then
        return players
    end
    local numMembers = GetNumGuildMembers()
    for i = 1, numMembers do
        local name, _, _, _, _, _, note = GetGuildRosterInfo(i)
        if name then
            name = string.gsub(name, "-.*", "")
            local dkp = 0
            -- Si la nota pública no es numérica, se considera como 0 DKP
            if note and note ~= "" then
                dkp = tonumber(note) or 0
            end
            table.insert(players, { name = name, dkp = dkp })
        end
    end
    table.sort(players, function(a, b) return a.dkp > b.dkp end)
    return players
end

-- Get players with DKP above threshold
function Cache:GetPlayersAboveThreshold(threshold)
    threshold = threshold or 0
    local players = {}

    for playerName, dkp in pairs(DMA_DB.cache) do
        if dkp >= threshold then
            table.insert(players, {
                name = playerName,
                dkp = dkp
            })
        end
    end

    -- Sort by DKP descending
    table.sort(players, function(a, b) return a.dkp > b.dkp end)

    return players
end

-- Get total number of players with DKP
function Cache:GetPlayerCount()
    local count = 0
    for _ in pairs(DMA_DB.cache) do
        count = count + 1
    end
    return count
end

-- Get total DKP in circulation
function Cache:GetTotalDKP()
    local total = 0
    for _, dkp in pairs(DMA_DB.cache) do
        total = total + dkp
    end
    return total
end

-- Get DKP statistics
function Cache:GetStatistics()
    local players = self:GetAllPlayersByDKP()

    local count = table.getn(players)

    if count == 0 then
        return {
            totalPlayers = 0,
            totalDKP = 0,
            averageDKP = 0,
            highestDKP = 0,
            lowestDKP = 0
        }
    end

    local totalDKP = self:GetTotalDKP()

    return {
        totalPlayers = count,
        totalDKP = totalDKP,
        averageDKP = totalDKP / count,
        highestDKP = players[1] and players[1].dkp or 0,
        lowestDKP = players[count] and players[count].dkp or 0
    }
end

-- Clear cache (for debugging/admin purposes)
function Cache:Clear()
    DMA_DB.cache = {}
    DEFAULT_CHAT_FRAME:AddMessage("DMA: DKP cache cleared")
end

-- Load guild members and initialize their DKP to 0
function Cache:LoadGuildMembers()
    -- Check if guild functions are available
    if not GetGuildInfo or not GuildRoster or not GetGuildRosterInfo or not GetNumGuildMembers then
        DEFAULT_CHAT_FRAME:AddMessage("DMA: Guild functions not available")
        return
    end

    -- Check if player is in a guild
    local guildName = GetGuildInfo("player")
    if not guildName then
        DEFAULT_CHAT_FRAME:AddMessage("DMA: You are not in a guild")
        return
    end

    -- Update guild roster
    GuildRoster()

    -- Small delay to let roster update, then load members
    -- In a real implementation, this would listen to GUILD_ROSTER_UPDATE event
    self:DelayedLoadGuildMembers()
end

-- Delayed loading of guild members (simulates waiting for GUILD_ROSTER_UPDATE)
function Cache:DelayedLoadGuildMembers()
    if not GetNumGuildMembers then
        DEFAULT_CHAT_FRAME:AddMessage("DMA: GetNumGuildMembers not available")
        return
    end

    local numMembers = GetNumGuildMembers()
    local loadedCount = 0
    local removedCount = 0

    if numMembers > 0 then
        local currentMembers = {}
        for i = 1, numMembers do
            local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(i)
            if name then
                -- Remove realm name if present (format: "Name-Realm")
                name = string.gsub(name, "-.*", "")

                currentMembers[name] = true

                -- Read DKP from public note, default to 0
                local dkp = 0
                if note and note ~= "" then
                    dkp = tonumber(note) or 0
                end
                DMA_DB.cache[name] = dkp
            end
        end

        -- Remove players not in current guild
        for name, _ in pairs(DMA_DB.cache) do
            if not currentMembers[name] then
                DMA_DB.cache[name] = nil
                removedCount = removedCount + 1
            end
        end

        -- Silenciar mensajes de depuración sobre miembros cargados/eliminados
    else
        DEFAULT_CHAT_FRAME:AddMessage("DMA: No guild members found")
    end
end

-- Sincroniza el cache interno (DMA_DB.cache) con la nota pública
-- para una lista concreta de jugadores. Esto asegura que, antes de
-- aplicar un evento de ajuste de DKP, partimos del valor real que
-- hay en la hermandad y no de datos antiguos de pruebas/eventos.
function Cache:SyncPlayersFromPublicNote(playerList)
    if not playerList or table.getn(playerList) == 0 then
        return
    end

    if not GetNumGuildMembers or not GetGuildRosterInfo then
        return
    end

    -- Asegurar que la tabla de cache existe (puede no estar inicializada
    -- aún si Database:Init/Cache:Init no se han ejecutado por timing).
    if not DMA_DB then
        return
    end
    DMA_DB.cache = DMA_DB.cache or {}

    -- Crear un set con los nombres que queremos sincronizar
    local wanted = {}
    for _, name in ipairs(playerList) do
        if name and name ~= "" then
            wanted[name] = true
        end
    end

    if next(wanted) == nil then
        return
    end

    -- Actualizar roster y leer notas públicas solo de esos jugadores
    GuildRoster()
    local numMembers = GetNumGuildMembers()
    for i = 1, numMembers do
        local name, _, _, _, _, _, note = GetGuildRosterInfo(i)
        if name then
            name = string.gsub(name, "-.*", "")
            if wanted[name] then
                local dkp = 0
                if note and note ~= "" then
                    dkp = tonumber(note) or 0
                end
                DMA_DB.cache[name] = dkp
            end
        end
    end
end

-- Actualiza la nota pública de un jugador con el nuevo DKP (requiere que SetGuildMemberPublicNote exista)
function Cache.UpdatePlayerPublicNote(playerName, newDKP)
    GuildRoster()
    for i = 1, GetNumGuildMembers() do
        local name = GetGuildRosterInfo(i)
        -- Elimina el sufijo '-Realm' si existe
        local shortName = nil
        if name and type(name) == "string" then
            shortName = string.gsub(name, "%-.*", "")
        end
        if shortName == playerName then
            if GuildRosterSetPublicNote then
                GuildRosterSetPublicNote(i, tostring(newDKP))
            else
                -- Cliente sin soporte para editar notas públicas
            end
            break
        end
    end
end
