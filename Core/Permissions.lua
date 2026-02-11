-- =========================================================
-- CORE: PERMISSIONS
-- =========================================================

if not DMA then return end
if not DMA.Core then DMA.Core = {} end

DMA.Core.Permissions = {}

function DMA.Core.Permissions:Init()
    if not DMA_DB.permissions then
        DMA_DB.permissions = {
            dkpMasters = {}
        }
    end

    -- Add current player as DKP Master for testing/demo purposes
    local currentPlayer = UnitName("player")
    if currentPlayer and not self:IsDKPMaster(currentPlayer) then
        self:AddDKPMaster(currentPlayer)
    end
end

function DMA.Core.Permissions:IsDKPMaster(playerName)
    if CanEditPublicNote and CanEditPublicNote() == 1 then
        return true
    end

    return false
end

function DMA.Core.Permissions:AddDKPMaster(playerName)
    if not playerName or playerName == "" then return end
    DMA_DB.permissions.dkpMasters[playerName] = true
end

function DMA.Core.Permissions:RemoveDKPMaster(playerName)
    if not playerName or playerName == "" then return end
    DMA_DB.permissions.dkpMasters[playerName] = nil
end

function DMA.Core.Permissions:GetAllDKPMasters()
    local list = {}
    for name in pairs(DMA_DB.permissions.dkpMasters) do
        table.insert(list, name)
    end
    return list
end


