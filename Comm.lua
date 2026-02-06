-- =========================================================
-- CORE: COMM
-- =========================================================

if not DMA then return end
if not DMA.Core then DMA.Core = {} end

DMA.Core.Comm = {}
DMA.Core.Comm.PREFIX = "DMA"

function DMA.Core.Comm:Register()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_GUILD")
    frame:SetScript("OnEvent", function(_, _, message, sender)
        DMA.Core.Comm:OnGuildMessage(message, sender)
    end)
end

function DMA.Core.Comm:Send(message)
    SendChatMessage(message, "GUILD")
end

function DMA.Core.Comm:OnGuildMessage(message, sender)
    if not message or string.sub(message, 1, 3) ~= self.PREFIX then
        return
    end

    local parts = {}
    if DMA.Utils and DMA.Utils.Split then
        parts = DMA.Utils:Split(message, "|")
    else
        -- Fallback: manual string splitting for WoW Vanilla compatibility
        local start = 1
        local delimiter = "|"
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
    end

    local msgType = parts[2]

    if msgType == "DKP_EVENT" then
        self:HandleDKPEvent(parts, sender)
    elseif msgType == "PERMISSION_ADD" then
        self:HandlePermissionAdd(parts, sender)
    end
end

function DMA.Core.Comm:HandleDKPEvent(parts, sender)
    local players   = parts[3]
    local value     = tonumber(parts[4])
    local reason    = parts[5]
    local master    = parts[6]
    local timestamp = tonumber(parts[7])
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

    local msg = string.format(
        "DMA|DKP_EVENT|%s|%d|%s|%s|%d",
        players,
        value,
        reason,
        master,
        timestamp
    )

    self:Send(msg)
end

DEFAULT_CHAT_FRAME:AddMessage("DMA: Comm module loaded")
