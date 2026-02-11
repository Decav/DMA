-- DMA - DKP Manager Addon
-- Initialization module following simpleAuras pattern

-- Initialize namespace
DMA = DMA or {}

-- Cache globals for performance
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME

-- Create parent frame for events
local DMAParent = CreateFrame("Frame", "DMAParentFrame", UIParent)
DMAParent:SetFrameStrata("BACKGROUND")
DMAParent:SetAllPoints(UIParent)

-- Initialize SavedVariables
DMA_DB = DMA_DB or {
    meta = {
        version = 1,
        created = time()
    },
    config = {
        historyRetentionDays = 365
    },
    events = {},
    cache = {},
    settings = {
        master = UnitName("player"),
        enabled = true
    }
}

-- Event handler for VARIABLES_LOADED
DMAParent:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        -- Initialize core modules
        if DMA.Core then
            -- Initialize database first
            if DMA.Data and DMA.Data.Database then
                DMA.Data.Database:Init()
            end

            -- Initialize event manager (no init function, just ensure it's loaded)
            -- EventManager is available after loading

            -- Initialize cache
            if DMA.Data and DMA.Data.Cache then
                DMA.Data.Cache:Init()
            end

            -- Initialize permissions
            if DMA.Core.Permissions then
                DMA.Core.Permissions:Init()
            end

            -- Register events
            if DMA.Core.Events then
                DMA.Core.Events:Register()
            end

            -- Register communications
            if DMA.Core.Comm then
                DMA.Core.Comm:Register()
            end
        end

        -- Initialize utils
        if DMA.Utils and DMA.Utils.Logger then
            DMA.Utils.Logger:Init()
        end

        -- Initialize UI
        if DMA.UI then
            if DMA.UI.MainFrame then
                DMA.UI.MainFrame:Init()
            end
            if DMA.UI.History then
                -- History UI is initialized on demand
            end
            if DMA.UI.MinimapButton and DMA.UI.MinimapButton.Init then
                DMA.UI.MinimapButton:Init()
            end
        end
        -- Mensaje único de addon listo, cuando todo está inicializado
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("DMA: Addon cargado - usa /dma para abrir la ventana")
        end
    end
end)

-- Register the event
DMAParent:RegisterEvent("VARIABLES_LOADED")