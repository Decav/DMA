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
        end
    end)
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

    -- Formato interno: DKP_EVENT^players^value^reason^master^timestamp[^zone]
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
    if msgType == "DKP_EVENT" then
        self:HandleDKPEvent(parts, sender)
    elseif msgType == "PERMISSION_ADD" then
        self:HandlePermissionAdd(parts, sender)
    end
end

-- Nota: Hemos eliminado el fallback basado en mensajes de hermandad (/g)
-- para evitar que cualquiera pueda falsificar eventos de DKP escribiendo
-- texto que parezca provenir del addon. Solo los mensajes de addon (invisibles
-- en el chat y enviados con SendAddonMessage) se usan para replicar eventos.

function DMA.Core.Comm:HandleDKPEvent(parts, sender)
    -- parts (nuevo formato): { "DKP_EVENT", players, value, reason, master, timestamp, [zone] }
    -- Nota: por compatibilidad con versiones antiguas o razones vacías, algunos campos pueden
    -- desplazarse si están vacíos, ya que el parser actual omite segmentos vacíos. Asumimos
    -- que 'reason' suele venir relleno en uso normal.
    local players   = parts[2]
    local value     = tonumber(parts[3])
    local reason    = parts[4]
    local master    = parts[5]
    local timestamp = tonumber(parts[6])
    local zone      = parts[7]
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
        time    = timestamp,
        zone    = zone or ""
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
    local zone      = nil
    if GetRealZoneText then
        zone = GetRealZoneText()
    end

    -- Formato interno solo para payload: DKP_EVENT^players^value^reason^master^timestamp[^zone]
    local payload = string.format(
        "DKP_EVENT^%s^%d^%s^%s^%d^%s",
        players or "",
        value or 0,
        reason or "",
        master or "?",
        timestamp or time(),
        zone or ""
    )

    -- Enviar siguiendo el mismo patrón que PallyPowerTW: PARTY si no hay raid,
    -- RAID si estamos en raid. La función Send decide el canal apropiado.
    self:Send(payload)
end
