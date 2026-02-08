-- DMA - DKP Manager Addon
-- Main entry point - Slash commands and final setup

-- Verify DMA is initialized
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME

if not DMA then
    DEFAULT_CHAT_FRAME:AddMessage("DMA: Error - DMA not initialized")
    return
end

-- Initialize logger if available
local Logger = DMA.Utils and DMA.Utils.Logger

-- =========================================================
-- SLASH COMMANDS
-- =========================================================

SLASH_DMA1 = "/dma"
SLASH_DMA2 = "/dkp"

SlashCmdList["DMA"] = function(msg)
    if not msg or msg == "" then
        -- Toggle main window
        if DMA.UI and DMA.UI.MainFrame then
            DMA.UI.MainFrame:Toggle()
        else
            if Logger then
                Logger:Error("UI not available")
            else
                DEFAULT_CHAT_FRAME:AddMessage("DMA: UI not available")
            end
        end
    else
        -- Handle subcommands
        local command = string.lower(msg)
        if command == "show" then
            if DMA.UI and DMA.UI.MainFrame then
                DMA.UI.MainFrame:Toggle()
                if DMA.UI.MainFrame.frame and not DMA.UI.MainFrame.frame:IsShown() then
                    DMA.UI.MainFrame.frame:Show()
                end
            end
        elseif command == "hide" then
            if DMA.UI and DMA.UI.MainFrame and DMA.UI.MainFrame.frame then
                DMA.UI.MainFrame.frame:Hide()
            end
        elseif command == "reset" then
            if DMA.UI and DMA.UI.MainFrame and DMA.UI.MainFrame.frame then
                DMA.UI.MainFrame.frame:ClearAllPoints()
                DMA.UI.MainFrame.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                if Logger then Logger:Info("Window position reset") else DEFAULT_CHAT_FRAME:AddMessage("DMA: Window position reset") end
            end
        elseif command == "history" or command == "hist" then
            if DMA.UI and DMA.UI.History then
                DMA.UI.History:Toggle()
            else
                if Logger then Logger:Warn("History UI not available") else DEFAULT_CHAT_FRAME:AddMessage("DMA: History UI not available") end
            end
        elseif command == "stats" then
            if DMA.Data and DMA.Data.Cache then
                local stats = DMA.Data.Cache:GetStatistics()
                if Logger then
                    Logger:Info("DKP Statistics: %d players, %d total DKP, %.1f average",
                        stats.totalPlayers, stats.totalDKP, stats.averageDKP)
                else
                    DEFAULT_CHAT_FRAME:AddMessage(string.format("DMA: %d players, %d total DKP, %.1f average",
                        stats.totalPlayers, stats.totalDKP, stats.averageDKP))
                end
            end
        elseif command == "decay" then
            if DMA.Core and DMA.Core.DKPDecay then
                DMA.Core.DKPDecay:ApplyDecay()
            else
                if Logger then
                    Logger:Warn("DKP Decay module not available")
                else
                    DEFAULT_CHAT_FRAME:AddMessage("DMA: DKP Decay module not available")
                end
            end
        elseif command == "resetdata" then
            if DMA.Data and DMA.Data.Cache then
                DMA.Data.Cache:Clear()
                DMA.Data.Cache:CreateTestData()
                DMA.Data.Cache:Rebuild()
                if DMA.UI and DMA.UI.MainFrame then
                    DMA.UI.MainFrame:RefreshPlayerList()
                end
                if Logger then Logger:Info("Test data reset") else DEFAULT_CHAT_FRAME:AddMessage("DMA: Test data reset") end
            end
        elseif command == "loadguild" or command == "guild" then
            if DMA.Data and DMA.Data.Cache then
                DMA.Data.Cache:LoadGuildMembers()
                if DMA.UI and DMA.UI.MainFrame then
                    DMA.UI.MainFrame:RefreshPlayerList()
                end
                if Logger then Logger:Info("Guild members loaded") end
            end
        else
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("Commands: /dma (toggle), /dma show, /dma hide, /dma reset.")
            end
        end
    end
end
