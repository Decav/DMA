-- =========================================================
-- CORE: EVENTS
-- =========================================================

if not DMA then return end
if not DMA.Core then DMA.Core = {} end

DMA.Core.Events = {}

function DMA.Core.Events:Register()
    -- Create event frame if it doesn't exist
    if not self.frame then
        self.frame = CreateFrame("Frame")
    end

    local f = self.frame

    f:RegisterEvent("PLAYER_LOGIN")
    f:RegisterEvent("PLAYER_LOGOUT")
    f:RegisterEvent("GUILD_ROSTER_UPDATE")

    f:SetScript("OnEvent", function(_, event, arg1)
        DMA.Core.Events:OnEvent(event, arg1)
    end)
end

function DMA.Core.Events:OnEvent(event, arg1)
    if event == "PLAYER_LOGIN" then
        self:OnPlayerLogin()
    elseif event == "PLAYER_LOGOUT" then
        self:OnPlayerLogout()
    elseif event == "GUILD_ROSTER_UPDATE" then
        if DMA and DMA.UI and DMA.UI.MainFrame and DMA.UI.MainFrame.RefreshPlayerList then
            DMA.UI.MainFrame:RefreshPlayerList()
        end
    end
end

function DMA.Core.Events:OnAddonLoaded(addonName)
    if addonName ~= "DMA" then return end

    if DMA.Core and DMA.Core.Init then
        DMA.Core.Init:Initialize()
    end
end

function DMA.Core.Events:OnPlayerLogin()
    -- Crear UI después de que UIParent esté disponible
    if DMA.UI and DMA.UI.MainFrame then
        DMA.UI.MainFrame:Init()
    end
end

function DMA.Core.Events:OnPlayerLogout()
    -- Punto seguro para limpieza si fuese necesario
end
