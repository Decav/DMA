-- =========================================================
-- CORE: COMM
-- =========================================================

if not DMA then return end
if not DMA.Core then DMA.Core = {} end

DMA.Core.Comm = {}
DMA.Core.Comm.PREFIX = "DMA"

function DMA.Core.Comm:Register()
    local frame = CreateFrame("Frame")
    -- Registrar recepción de mensajes de addon (estilo PallyPower)
    if RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(self.PREFIX)
    end

    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("CHAT_MSG_GUILD")
    -- Nota importante (WoW 1.12): los handlers de eventos usan las
    -- variables globales 'event', 'arg1', 'arg2', ... igual que en
    -- PallyPowerTW. No se pasan parámetros al callback.
    frame:SetScript("OnEvent", function()
        if event == "CHAT_MSG_ADDON" then
            local prefix  = arg1
            local message = arg2
            local channel = arg3
            local sender  = arg4
            if prefix == DMA.Core.Comm.PREFIX then
                DMA.Core.Comm:OnAddonMessage(message, sender)
            end
        elseif event == "CHAT_MSG_GUILD" then
            local message = arg1
            local sender  = arg2
            DMA.Core.Comm:OnGuildMessage(message, sender)
        end
    end)

    DEFAULT_CHAT_FRAME:AddMessage("DMA: Comm listening for addon messages (prefix '" .. tostring(self.PREFIX) .. "')")
end

function DMA.Core.Comm:Send(message, channel)
    -- Enviar mensaje de addon por canal de hermandad/raid. Esto es invisible en el chat.
    if not SendAddonMessage or not message or message == "" then
        return
    end

    -- En 1.12 el patrón típico (como en PallyPowerTW) es:
    --   SendAddonMessage(prefix, message, "PARTY"/"RAID", UnitName("player"))
    -- No existe canal "GUILD" para mensajes de addon, así que copiamos ese esquema.
    if not channel then
        if GetNumRaidMembers and GetNumRaidMembers() > 0 then
            channel = "RAID"
        else
            channel = "PARTY"
        end
    end

    local playerName = UnitName and UnitName("player") or nil
    SendAddonMessage(self.PREFIX, message, channel, playerName)
end

function DMA.Core.Comm:OnAddonMessage(message, sender)
    if not message or message == "" then
        return
    end

    -- Formato interno: DKP_EVENT^players^value^reason^master^timestamp
    local delimiter = "^"

    local parts = {}
    local start = 1
    while true do
        local pos = string.find(message, delimiter, start, true)
        if pos then
            local part = string.sub(message, start, pos - 1)
            if part ~= "" then
                table.insert(parts, part)
            end
            start = pos + 1
        else
            local part = string.sub(message, start)
            if part ~= "" then
                table.insert(parts, part)
            end
            break
        end
    end

    local msgType = parts[1]

    -- Debug básico para verificar recepción de mensajes
    DEFAULT_CHAT_FRAME:AddMessage("DMA: Recibido mensaje de addon de " .. tostring(sender) .. " tipo " .. tostring(msgType))

    if msgType == "DKP_EVENT" then
        self:HandleDKPEvent(parts, sender)
    elseif msgType == "PERMISSION_ADD" then
        self:HandlePermissionAdd(parts, sender)
    end
end

-- Fallback: replicar eventos a partir de los mensajes de /g ya existentes
-- Ejemplos de formato que enviamos desde MainFrame:
--   "DMA: Otorgados 10 DKP a Player (Reason)"
--   "DMA: Reducidos 5 DKP de Player (Reason)"
function DMA.Core.Comm:OnGuildMessage(message, sender)
    if not message or string.sub(message, 1, 4) ~= "DMA:" then
        return
    end

    -- Ignorar nuestros propios mensajes, ya aplicamos el evento localmente
    local selfName = UnitName and UnitName("player") or nil
    local shortSender = sender and string.gsub(sender, "-.*", "") or sender
    if selfName and shortSender == selfName then
        return
    end

    -- Debug: ver exactamente qué mensaje y remitente estamos intentando parsear
    DEFAULT_CHAT_FRAME:AddMessage("DMA DBG: OnGuildMessage from " .. tostring(shortSender) .. " -> " .. tostring(message))

    local amount, playerName, reason
    local isAward = true

    -- Intentar parsear formato de otorgar DKP
    amount, playerName, reason = string.match(message, "^DMA: Otorgados (%-?%d+) DKP a ([^%s]+) %((.*)%)")

    if not amount then
        -- Intentar formato de reducir DKP
        amount, playerName, reason = string.match(message, "^DMA: Reducidos (%-?%d+) DKP de ([^%s]+) %((.*)%)")
        isAward = false
    end

    if not amount or not playerName then
        DEFAULT_CHAT_FRAME:AddMessage("DMA DBG: OnGuildMessage no match for patrones de Otorgados/Reducidos")
        return
    end

    local baseValue = tonumber(amount)
    if not baseValue then
        DEFAULT_CHAT_FRAME:AddMessage("DMA DBG: OnGuildMessage amount no numérico: " .. tostring(amount))
        return
    end

    local dkpValue = isAward and baseValue or -baseValue
    local master = shortSender or "?"
    local timestamp = time()

    local eventType = "manual_adjust"
    if DMA and DMA.Utils and DMA.Utils.Constants and DMA.Utils.Constants.EVENT_TYPES then
        eventType = DMA.Utils.Constants.EVENT_TYPES.MANUAL_ADJUST or "manual_adjust"
    end

    local event = {
        type    = eventType,
        players = playerName,
        value   = dkpValue,
        reason  = reason or "",
        master  = master,
        time    = timestamp
    }

    -- Sincronizar primero el valor actual de nota pública del jugador
    if DMA.Data and DMA.Data.Cache and DMA.Data.Cache.SyncPlayersFromPublicNote then
        DMA.Data.Cache:SyncPlayersFromPublicNote({ playerName })
    end

    if DMA.Data and DMA.Data.Database then
        DMA.Data.Database:AddEvent(event)
        DEFAULT_CHAT_FRAME:AddMessage("DMA DBG: Evento remoto aplicado para " .. tostring(playerName) .. " (" .. tostring(dkpValue) .. " DKP)")
    end
end

function DMA.Core.Comm:HandleDKPEvent(parts, sender)
    -- parts: { "DKP_EVENT", players, value, reason, master, timestamp }
    local players   = parts[2]
    local value     = tonumber(parts[3])
    local reason    = parts[4]
    local master    = parts[5]
    local timestamp = tonumber(parts[6])
    -- Ignorar nuestro propio mensaje de red (ya aplicamos localmente)
    if sender and UnitName and sender == UnitName("player") then
        return
    end

    -- Construir un evento completo para almacenarlo e incluirlo en el historial
    local eventType = "manual_adjust"
    if DMA and DMA.Utils and DMA.Utils.Constants and DMA.Utils.Constants.EVENT_TYPES then
        eventType = DMA.Utils.Constants.EVENT_TYPES.MANUAL_ADJUST or "manual_adjust"
    end

    local event = {
        type    = eventType,
        players = players,
        value   = value,
        reason  = reason,
        master  = master,
        time    = timestamp
    }

    -- Antes de aplicar el evento, sincronizar el cache con la nota pública
    -- de los jugadores afectados para que el delta se aplique sobre el valor real.
    if DMA.Data and DMA.Data.Cache and DMA.Data.Cache.SyncPlayersFromPublicNote and players and players ~= "" then
        local playerList = {}
        local startIndex = 1
        local delimiter = ","
        while true do
            local pos = string.find(players, delimiter, startIndex, true)
            local name
            if pos then
                name = string.sub(players, startIndex, pos - 1)
                startIndex = pos + 1
            else
                name = string.sub(players, startIndex)
            end

            name = string.gsub(name or "", "^%s*(.-)%s*$", "%1")
            if name ~= "" then
                table.insert(playerList, name)
            end

            if not pos then break end
        end

        if table.getn(playerList) > 0 then
            DMA.Data.Cache:SyncPlayersFromPublicNote(playerList)
        end
    end

    if DMA.Data and DMA.Data.Database then
        DMA.Data.Database:AddEvent(event)
    end
end

function DMA.Core.Comm:HandlePermissionAdd(parts, sender)
    local newMaster = parts[3]

    if DMA.Core.Permissions:IsDKPMaster(sender) then
        DMA.Core.Permissions:AddDKPMaster(newMaster)
    end
end

function DMA.Core.Comm:BroadcastDKPEvent(players, value, reason)
    local master    = UnitName("player")
    local timestamp = time()

    -- Formato interno solo para payload: DKP_EVENT^players^value^reason^master^timestamp
    local payload = string.format(
        "DKP_EVENT^%s^%d^%s^%s^%d",
        players or "",
        value or 0,
        reason or "",
        master or "?",
        timestamp or time()
    )

    -- Enviar siguiendo el mismo patrón que PallyPowerTW: PARTY si no hay raid,
    -- RAID si estamos en raid. La función Send decide el canal apropiado.
    self:Send(payload)

    DEFAULT_CHAT_FRAME:AddMessage("DMA: Enviado DKP_EVENT a la red de addons (" .. (players or "?") .. ")")
end

DEFAULT_CHAT_FRAME:AddMessage("DMA: Comm module loaded")
