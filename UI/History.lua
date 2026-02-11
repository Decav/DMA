-- =========================================================
-- UI: HISTORY
-- =========================================================

if not DMA then return end
if not DMA.UI then DMA.UI = {} end

DMA.UI.History = {}

local History = DMA.UI.History

local FRAME_WIDTH = 680
local FRAME_HEIGHT = 400
local ENTRY_HEIGHT = 20
local MAX_VISIBLE_ENTRIES = 15

-- Popup de confirmación para limpiar historial/cache de la guild actual
StaticPopupDialogs = StaticPopupDialogs or {}
StaticPopupDialogs["DMA_CLEAR_GUILD_DATA"] = {
    text = "Esto borrará TODO el historial DKP y el cache de la hermandad/personaje actual.\n\n¿Seguro que quieres continuar?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        if DMA.Data and DMA.Data.Database and DMA.Data.Database.ClearCurrentGuildData then
            DMA.Data.Database:ClearCurrentGuildData()
        end
        -- Refrescar UI después de limpiar
        if DMA.UI and DMA.UI.History then
            DMA.UI.History:Refresh()
        end
        if DMA.UI and DMA.UI.MainFrame and DMA.UI.MainFrame.RefreshPlayerList then
            DMA.UI.MainFrame:RefreshPlayerList()
        end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

-- Initialize history UI
function History:Init()
    if self.frame then return end

    local frame = CreateFrame("Frame", "DMA_HistoryFrame", UIParent)
    frame:SetWidth(FRAME_WIDTH)
    frame:SetHeight(FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetMovable(false)
    frame:EnableMouse(false)
    frame:Hide()

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.85)
    frame:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)

    -- Permitir cerrar el frame de historial con la tecla ESC
    if UISpecialFrames then
        table.insert(UISpecialFrames, "DMA_HistoryFrame")
    end

    self.frame = frame
    self:CreateTitle()
    self:CreateCloseButton()
    self:CreateScrollFrame()
    self:CreateFilterControls()
end

-- Create title bar
function History:CreateTitle()
    local title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", self.frame, "TOP", 0, -10)
    title:SetText("DKP History")
    self.title = title
end

-- Create close button
function History:CreateCloseButton()
    local bgr = {0.2,0.2,0.2,1}
    local bdr = {0.2,0.2,0.2,1}
    local button = CreateFrame("Button", nil, self.frame)
    button:SetWidth(20)
    button:SetHeight(20)
    button:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -5, -5)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    button:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    button:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.text:SetText(" X ")
    button:SetScript("OnEnter", function() button:SetBackdropColor(0.5,0.5,0.5,1) end)
    button:SetScript("OnLeave", function() button:SetBackdropColor(0.2,0.2,0.2,1) end)
    button:SetScript("OnClick", function() self.frame:Hide() end)
    self.closeButton = button
end

-- Create scrollable content area
function History:CreateScrollFrame()
    local scrollFrame = CreateFrame("ScrollFrame", "DMA_HistoryScrollFrame", self.frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetWidth(FRAME_WIDTH - 40)
    scrollFrame:SetHeight(FRAME_HEIGHT - 120)
    scrollFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 15, -60)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(FRAME_WIDTH - 40)
    content:SetHeight(1) -- Will be resized dynamically
    scrollFrame:SetScrollChild(content)

    self.scrollFrame = scrollFrame
    self.content = content
    self.entries = {}

    -- Encabezados de columnas
    local header = CreateFrame("Frame", nil, self.frame)
    header:SetWidth(FRAME_WIDTH - 40)
    header:SetHeight(ENTRY_HEIGHT)
    header:SetPoint("BOTTOMLEFT", scrollFrame, "TOPLEFT", 0, 2)

    local hTime = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hTime:SetPoint("LEFT", header, "LEFT", 0, 0)
    hTime:SetWidth(80)
    hTime:SetText("Date")

    local hMaster = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hMaster:SetPoint("LEFT", hTime, "RIGHT", 10, 0)
    hMaster:SetWidth(80)
    hMaster:SetText("Master")

    local hPlayers = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hPlayers:SetPoint("LEFT", hMaster, "RIGHT", 10, 0)
    hPlayers:SetWidth(80)
    hPlayers:SetText("Players")

    local hValue = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hValue:SetPoint("LEFT", hPlayers, "RIGHT", 10, 0)
    hValue:SetWidth(60)
    hValue:SetText("DKP")

    local hZone = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hZone:SetPoint("LEFT", hValue, "RIGHT", 10, 0)
    hZone:SetWidth(90)
    hZone:SetText("Zone")

    local hReason = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hReason:SetPoint("LEFT", hZone, "RIGHT", -25, 0)
    hReason:SetWidth(280)
    hReason:SetText("Reason")
end

-- Create filter controls
function History:CreateFilterControls()
    -- Player filter
    local playerLabel = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerLabel:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 15, 15)
    playerLabel:SetText("Player:")

    local playerBox = CreateFrame("EditBox", nil, self.frame)
    playerBox:SetWidth(100)
    playerBox:SetHeight(20)
    playerBox:SetPoint("LEFT", playerLabel, "RIGHT", 5, 0)
    playerBox:SetAutoFocus(false)
    playerBox:SetMultiLine(false)
    playerBox:SetFontObject(GameFontHighlightSmall)
    playerBox:SetTextColor(1, 1, 1)
    playerBox:SetTextInsets(4, 4, 4, 4)
    playerBox:SetJustifyH("LEFT")
    playerBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    playerBox:SetBackdropColor(0.1, 0.1, 0.1, 1)
    playerBox:SetBackdropBorderColor(0, 0, 0, 1)
    playerBox:SetScript("OnTextChanged", function()
        History:Refresh()
    end)
    playerBox:SetScript("OnEscapePressed", function(self)
        playerBox:ClearFocus()
    end)
    self.playerFilter = playerBox

    -- Refresh button
    local bgr = {0.2,0.2,0.2,1}
    local bdr = {0.2,0.2,0.2,1}
    local refreshBtn = CreateFrame("Button", nil, self.frame)
    refreshBtn:SetWidth(80)
    refreshBtn:SetHeight(22)
    refreshBtn:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -15, 12)
    refreshBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    refreshBtn:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    refreshBtn:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    refreshBtn.text = refreshBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    refreshBtn.text:SetPoint("CENTER", refreshBtn, "CENTER", 0, 0)
    refreshBtn.text:SetText("Refresh")
    refreshBtn:SetScript("OnEnter", function() refreshBtn:SetBackdropColor(0.5,0.5,0.5,1) end)
    refreshBtn:SetScript("OnLeave", function() refreshBtn:SetBackdropColor(0.2,0.2,0.2,1) end)
    
    refreshBtn:SetScript("OnClick", function() History:Refresh() end)

    -- Clear button (limpiar historial/cache de la guild actual)
    local clearBtn = CreateFrame("Button", nil, self.frame)
    clearBtn:SetWidth(80)
    clearBtn:SetHeight(22)
    clearBtn:SetPoint("RIGHT", refreshBtn, "LEFT", -10, 0)
    clearBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    clearBtn:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    clearBtn:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    clearBtn.text = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    clearBtn.text:SetPoint("CENTER", clearBtn, "CENTER", 0, 0)
    clearBtn.text:SetText("Clear")
    clearBtn:SetScript("OnEnter", function() clearBtn:SetBackdropColor(0.5,0.5,0.5,1) end)
    clearBtn:SetScript("OnLeave", function() clearBtn:SetBackdropColor(0.2,0.2,0.2,1) end)
    clearBtn:SetScript("OnClick", function()
        if StaticPopup_Show then
            StaticPopup_Show("DMA_CLEAR_GUILD_DATA")
        end
    end)
end

-- Show history window
function History:Show()
    if not self.frame then
        self:Init()
    end

    self:Refresh()
    self.frame:Show()
end

-- Mostrar el historial anclado a la derecha de otra ventana (por ejemplo, el mainframe)
function History:ShowAttached(parentFrame)
    if not self.frame then
        self:Init()
    end

    if parentFrame then
        self.frame:ClearAllPoints()
        self.frame:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", 10, 0)
    end

    self:Refresh()
    self.frame:Show()
end

-- Hide history window
function History:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

-- Toggle history window
function History:Toggle()
    if not self.frame then
        self:Init()
    end

    if self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- Refresh history display
function History:Refresh()
    if not DMA.Data.EventManager then return end

    -- Clear existing entries
    for _, entry in ipairs(self.entries) do
        entry:Hide()
    end
    self.entries = {}

    -- Get events based on filters
    local events = self:GetFilteredEvents()

    -- Create entries
    local yOffset = 0
    for i, event in ipairs(events) do
        if i > 50 then break end -- Limit to prevent UI lag

        local entry = self:CreateEntry(event, yOffset)
        table.insert(self.entries, entry)
        yOffset = yOffset - ENTRY_HEIGHT
    end

    -- Resize content frame
    self.content:SetHeight(math.max(1, math.abs(yOffset)))
end

-- Get filtered events
function History:GetFilteredEvents()
    local allEvents = DMA.Data.EventManager:GetRecentEvents(200)
    local filteredEvents = {}

    -- Proteger por si los controles aún no están creados
    local playerFilter = ""
    if self.playerFilter and self.playerFilter.GetText then
        playerFilter = string.gsub(self.playerFilter:GetText() or "", "^%s*(.-)%s*$", "%1")
    end

    -- De momento no usamos filtro por tipo; se devuelven todos los tipos
    local typeFilter = "all"

    -- Para que cada jugador de un evento multi-jugador aparezca en su propia fila,
    -- descomponemos event.players ("A,B,C") en varios eventos lógicos de un solo jugador.
    for _, event in ipairs(allEvents) do
        if typeFilter == "all" or event.type == typeFilter then
            local playersStr = event.players or ""

            if playersStr == "" then
                -- Evento sin jugadores explícitos
                local include = true
                if playerFilter ~= "" then
                    include = false
                end
                if include then
                    table.insert(filteredEvents, event)
                end
            else
                local startIndex = 1
                local delimiter = ","
                while true do
                    local pos = string.find(playersStr, delimiter, startIndex, true)
                    local name
                    if pos then
                        name = string.sub(playersStr, startIndex, pos - 1)
                        startIndex = pos + 1
                    else
                        name = string.sub(playersStr, startIndex)
                    end

                    name = string.gsub(name, "^%s*(.-)%s*$", "%1")

                    if name ~= "" then
                        local include = true
                        if playerFilter ~= "" then
                            local lowerName = string.lower(name)
                            local lowerFilter = string.lower(playerFilter)
                            if not string.find(lowerName, lowerFilter, 1, true) then
                                include = false
                            end
                        end

                        if include then
                            local singleEvent = {
                                id = event.id,
                                type = event.type,
                                players = name,
                                value = event.value,
                                reason = event.reason,
                                master = event.master,
                                time = event.time,
                                zone = event.zone,
                            }
                            table.insert(filteredEvents, singleEvent)
                        end
                    end

                    if not pos then break end
                end
            end
        end
    end

    return filteredEvents
end

-- Create a history entry
function History:CreateEntry(event, yOffset)
    local entry = CreateFrame("Frame", nil, self.content)
    entry:SetWidth(FRAME_WIDTH - 60)
    entry:SetHeight(ENTRY_HEIGHT)
    entry:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, yOffset)

    -- Timestamp
    local timeValue = event.time or time()
    local timeStr = date("%m/%d %H:%M", timeValue)
    entry.timeText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    entry.timeText:SetPoint("LEFT", entry, "LEFT", 0, 0)
    entry.timeText:SetWidth(80)
    entry.timeText:SetText(timeStr)

    -- Master
    entry.masterText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    entry.masterText:SetPoint("LEFT", entry.timeText, "RIGHT", 10, 0)
    entry.masterText:SetWidth(80)
    entry.masterText:SetText(event.master or "?")

    -- Players
    local playersText = event.players or ""
    if strlen(playersText) > 14 then
        playersText = strsub(playersText, 1, 12) .. "..."
    end
    entry.playersText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    entry.playersText:SetPoint("LEFT", entry.masterText, "RIGHT", 10, 0)
    entry.playersText:SetWidth(80)
    entry.playersText:SetText(playersText)

    -- Value
    local value = tonumber(event.value) or 0
    local valueColor = value >= 0 and "|cff00ff00" or "|cffff0000"
    entry.valueText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    entry.valueText:SetPoint("LEFT", entry.playersText, "RIGHT", 10, 0)
    entry.valueText:SetWidth(60)
    entry.valueText:SetText(valueColor .. value)

    -- Zone / instancia
    local zoneText = event.zone or ""
    if strlen(zoneText) > 14 then
        zoneText = strsub(zoneText, 1, 12) .. "..."
    end
    entry.zoneText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    entry.zoneText:SetPoint("LEFT", entry.valueText, "RIGHT", 10, 0)
    entry.zoneText:SetWidth(90)
    entry.zoneText:SetText(zoneText)

    -- Reason: mostrar lo máximo posible sin tooltip, solo con truncado suave
    local reasonText = event.reason or ""
    if strlen(reasonText) > 40 then
        reasonText = strsub(reasonText, 1, 38) .. "..."
    end
    entry.reasonText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    entry.reasonText:SetPoint("LEFT", entry.zoneText, "RIGHT", -25, 0)
    entry.reasonText:SetWidth(280)
    entry.reasonText:SetText(reasonText)

    return entry
end
