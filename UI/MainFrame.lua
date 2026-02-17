-- =========================================================
-- UI: MAINFRAME
-- =========================================================

if not DMA then return end
if not DMA.UI then DMA.UI = {} end

DMA.UI.MainFrame = {}

local MainFrame = DMA.UI.MainFrame

local FRAME_WIDTH = 600
local FRAME_HEIGHT = 450

function MainFrame:Init()
    if self.frame then return end

    if not UIParent then
        DEFAULT_CHAT_FRAME:AddMessage("DMA: UIParent no disponible aún")
        return
    end

    local frame = CreateFrame("Frame", "DMA_MainFrame", UIParent)
    frame:SetWidth(FRAME_WIDTH)
    frame:SetHeight(FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
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

    self.frame = frame

    -- Permitir cerrar el frame con la tecla ESC como otras ventanas de WoW
    if UISpecialFrames then
        table.insert(UISpecialFrames, "DMA_MainFrame")
    end

    self:CreateTitle()
    self:CreateCloseButton()
    self:CreateConfigButton()
    self:CreateHistoryButton()
    self:CreatePlayerList()
    self:CreateDKPMasterPanel()
end

-- Botón para abrir la configuración de DKP
function MainFrame:CreateConfigButton()
    if not self.frame then return end

    local bgr = {0.2,0.2,0.2,1}
    local bdr = {0.2,0.2,0.2,1}
    local button = CreateFrame("Button", nil, self.frame)
    button:SetWidth(60)
    button:SetHeight(20)
    button:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 5, -5)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    button:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    button:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.text:SetText("Config")
    button:SetScript("OnEnter", function() button:SetBackdropColor(0.5,0.5,0.5,1) end)
    button:SetScript("OnLeave", function() button:SetBackdropColor(0.2,0.2,0.2,1) end)
    button:SetScript("OnClick", function()
        if DMA.UI and DMA.UI.DKPConfig and DMA.UI.DKPConfig.Toggle then
            DMA.UI.DKPConfig:Toggle()
        else
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("DMA: DKPConfig no disponible")
            end
        end
    end)

    self.configButton = button
end

function MainFrame:CreateTitle()
    local title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", self.frame, "TOP", 0, -10)
    title:SetText("DMA - DKP Manager")
    self.title = title
end

function MainFrame:CreateCloseButton()
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

-- Botón para abrir el historial, accesible siempre
function MainFrame:CreateHistoryButton()
    if not self.frame then return end

    local bgr = {0.2,0.2,0.2,1}
    local bdr = {0.2,0.2,0.2,1}
    local button = CreateFrame("Button", nil, self.frame)
    button:SetWidth(70)
    button:SetHeight(20)
    button:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -30, -5)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    button:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    button:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.text:SetText("History")
    button:SetScript("OnEnter", function() button:SetBackdropColor(0.5,0.5,0.5,1) end)
    button:SetScript("OnLeave", function() button:SetBackdropColor(0.2,0.2,0.2,1) end)
    button:SetScript("OnClick", function()
        if not DMA.UI or not DMA.UI.History then return end

        local history = DMA.UI.History
        -- Si el historial ya está visible, actúa como toggle y lo oculta
        if history.frame and history.frame:IsShown() then
            history:Hide()
            return
        end

        -- Si no está visible, mostrarlo anclado al MainFrame cuando sea posible
        if history.ShowAttached and self.frame then
            history:ShowAttached(self.frame)
        else
            history:Toggle()
        end
    end)

    self.historyButton = button
end

-- Create player list with DKP values
function MainFrame:CreatePlayerList()
    local bgr = {0.2,0.2,0.2,1}
    local bdr = {0.2,0.2,0.2,1}
    local listFrame = CreateFrame("Frame", nil, self.frame)
    listFrame:SetWidth(250)
    listFrame:SetHeight(350)
    listFrame:SetPoint("LEFT", self.frame, "LEFT", 12, -30)

    listFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    listFrame:SetBackdropColor(0.04, 0.04, 0.04, 0.95)
    listFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    -- Title (se usará para mostrar el número de jugadores)
    local title = listFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 6, -6)
    title:SetText("Players: 0")
    self.playerTitle = title

    -- Load Guild button
    local loadGuildBtn = CreateFrame("Button", nil, listFrame)
    loadGuildBtn:SetWidth(80)
    loadGuildBtn:SetHeight(20)
    loadGuildBtn:SetPoint("TOPRIGHT", listFrame, "TOPRIGHT", -6, -6)
    loadGuildBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    loadGuildBtn:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    loadGuildBtn:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    loadGuildBtn.text = loadGuildBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    loadGuildBtn.text:SetPoint("CENTER", loadGuildBtn, "CENTER", 0, 0)
    loadGuildBtn.text:SetText("Reload")
    loadGuildBtn:SetScript("OnEnter", function() loadGuildBtn:SetBackdropColor(0.5,0.5,0.5,1) end)
    loadGuildBtn:SetScript("OnLeave", function() loadGuildBtn:SetBackdropColor(0.2,0.2,0.2,1) end)
    loadGuildBtn:SetScript("OnClick", function()
        if DMA.Data and DMA.Data.Cache then
            DMA.Data.Cache:LoadGuildMembers()
            MainFrame:RefreshPlayerList()
        end
    end)

    -- Name filter
    local filterLabel = listFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -15)
    filterLabel:SetText("Filter:")

    local filterBox = CreateFrame("EditBox", nil, listFrame)
    filterBox:SetWidth(150)
    filterBox:SetHeight(18)
    filterBox:SetPoint("LEFT", filterLabel, "RIGHT", 5, 0)
    filterBox:SetAutoFocus(false)
    filterBox:SetMultiLine(false)
    filterBox:SetFontObject(GameFontHighlightSmall)
    filterBox:SetTextColor(1, 1, 1)
    filterBox:SetTextInsets(4, 4, 4, 4)
    filterBox:SetJustifyH("LEFT")
    filterBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    filterBox:SetBackdropColor(0.1, 0.1, 0.1, 1)
    filterBox:SetBackdropBorderColor(0, 0, 0, 1)
    filterBox:SetScript("OnTextChanged", function()
        MainFrame:RefreshPlayerList()
    end)
    filterBox:SetScript("OnEscapePressed", function(self)
        filterBox:ClearFocus()
    end)
    self.playerFilterBox = filterBox

    -- Scroll frame for player list
    local scrollFrame = CreateFrame("ScrollFrame", "DMA_PlayerScroll", listFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetWidth(230)
    scrollFrame:SetHeight(300)
    scrollFrame:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 6, -50)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(230)
    content:SetHeight(1)
    scrollFrame:SetScrollChild(content)

    self.playerListFrame = listFrame
    self.playerScrollFrame = scrollFrame
    self.playerContent = content
    self.playerEntries = {}

    self:RefreshPlayerList()
end

-- Create DKP Master control panel
function MainFrame:CreateDKPMasterPanel()
    local panelFrame = CreateFrame("Frame", nil, self.frame)
    panelFrame:SetWidth(300)
    panelFrame:SetHeight(350)
    panelFrame:SetPoint("RIGHT", self.frame, "RIGHT", -12, -30)

    panelFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    panelFrame:SetBackdropColor(0.04, 0.04, 0.04, 0.95)
    panelFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    -- Store reference to this panel so we can rebuild/replace it later
    self.dkpPanelFrame = panelFrame

    -- Title
    local title = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", panelFrame, "TOP", 0, -6)
    title:SetText("DKP Master Panel")

    -- Check if current player is DKP Master
    local canEdit = (CanEditPublicNote and CanEditPublicNote()) or 0
    local isMaster = (canEdit == 1)

    if not isMaster then
        local noAccessText = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noAccessText:SetPoint("CENTER", panelFrame, "CENTER", 0, 0)
        if canEdit == 0 then
            noAccessText:SetText("You are not a DKP Master")
        else
            -- Información de guild aún no disponible (canEdit nil)
            noAccessText:SetText("Guild info not ready. Please open again in a few seconds or /reload.")
        end
        return
    end

    local bgr = {0.2,0.2,0.2,1}
    local bdr = {0.2,0.2,0.2,1}

    -- Raid status info (recordatorio visual)
    local raidText = "Raid: Not in a raid"
    local zoneName = nil
    if GetRealZoneText then
        zoneName = GetRealZoneText()
    end

    if UnitInRaid and GetNumRaidMembers and UnitInRaid("player") then
        local numMembers = GetNumRaidMembers() or 0
        if numMembers > 0 then
            if zoneName and zoneName ~= "" then
                raidText = "Raid: " .. numMembers .. " members - " .. zoneName
            else
                raidText = "Raid: " .. numMembers .. " members"
            end
        else
            if zoneName and zoneName ~= "" then
                raidText = "Raid: In raid - " .. zoneName
            else
                raidText = "Raid: In raid"
            end
        end
    end

    local raidStatus = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    raidStatus:SetPoint("TOP", panelFrame, "TOP", 0, -26)
    raidStatus:SetText(raidText)
    self.raidStatusText = raidStatus

    -- Player selection buttons
    local selectAllBtn = CreateFrame("Button", nil, panelFrame)
    selectAllBtn:SetWidth(85)
    selectAllBtn:SetHeight(22)
    selectAllBtn:SetPoint("TOPLEFT", panelFrame, "TOPLEFT", 10, -45)
    selectAllBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    selectAllBtn:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    selectAllBtn:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    selectAllBtn.text = selectAllBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectAllBtn.text:SetPoint("CENTER", selectAllBtn, "CENTER", 0, 0)
    selectAllBtn.text:SetText("Select All")
    selectAllBtn:SetScript("OnEnter", function() selectAllBtn:SetBackdropColor(0.5,0.5,0.5,1) end)
    selectAllBtn:SetScript("OnLeave", function() selectAllBtn:SetBackdropColor(0.2,0.2,0.2,1) end)
    selectAllBtn:SetScript("OnClick", function() self:SelectAllPlayers() end)

    local selectNoneBtn = CreateFrame("Button", nil, panelFrame)
    selectNoneBtn:SetWidth(85)
    selectNoneBtn:SetHeight(22)
    selectNoneBtn:SetPoint("LEFT", selectAllBtn, "RIGHT", 10, 0)
    selectNoneBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    selectNoneBtn:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    selectNoneBtn:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    selectNoneBtn.text = selectNoneBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectNoneBtn.text:SetPoint("CENTER", selectNoneBtn, "CENTER", 0, 0)
    selectNoneBtn.text:SetText("Select None")
    selectNoneBtn:SetScript("OnEnter", function() selectNoneBtn:SetBackdropColor(0.5,0.5,0.5,1) end)
    selectNoneBtn:SetScript("OnLeave", function() selectNoneBtn:SetBackdropColor(0.2,0.2,0.2,1) end)
    selectNoneBtn:SetScript("OnClick", function() self:SelectNoPlayers() end)

    local selectRaidBtn = CreateFrame("Button", nil, panelFrame)
    selectRaidBtn:SetWidth(85)
    selectRaidBtn:SetHeight(22)
    selectRaidBtn:SetPoint("LEFT", selectNoneBtn, "RIGHT", 10, 0)
    selectRaidBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    selectRaidBtn:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    selectRaidBtn:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    selectRaidBtn.text = selectRaidBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectRaidBtn.text:SetPoint("CENTER", selectRaidBtn, "CENTER", 0, 0)
    selectRaidBtn.text:SetText("Select Raid")
    selectRaidBtn:SetScript("OnEnter", function() selectRaidBtn:SetBackdropColor(0.5,0.5,0.5,1) end)
    selectRaidBtn:SetScript("OnLeave", function() selectRaidBtn:SetBackdropColor(0.2,0.2,0.2,1) end)
    selectRaidBtn:SetScript("OnClick", function() self:SelectRaidPlayers() end)

    local EVENT_TYPE_OPTIONS = {
        { key = "STAY",    label = "Stay in raid" },
        { key = "EARLY",   label = "Arrive early" },
        { key = "BOSS",    label = "Boss kill" },
        { key = "ITEM",    label = "Item" },
        { key = "PENALTY", label = "Penalty" },
        { key = "MANUAL",  label = "Manual adjust" },
    }

    local function GetRaidLabelFromKey(raidKey)
        if raidKey == "MC" then
            return "Molten Core"
        elseif raidKey == "BWL" then
            return "Blackwing Lair"
        elseif raidKey == "AQ40" then
            return "Ahn'Qiraj 40"
        elseif raidKey == "NAXX" then
            return "Naxxramas"
        end
        return raidKey
    end

    -- Raid label + dropdown (selección de raid para usar config de DKP)
    local raidLabel = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    raidLabel:SetPoint("TOPLEFT", selectAllBtn, "BOTTOMLEFT", 0, -10)
    raidLabel:SetText("Raid:")

    local raidButton = CreateFrame("Button", nil, panelFrame)
    raidButton:SetWidth(140)
    raidButton:SetHeight(20)
    raidButton:SetPoint("LEFT", raidLabel, "RIGHT", 5, 0)
    raidButton:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    raidButton:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    raidButton:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    raidButton.text = raidButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    raidButton.text:SetPoint("CENTER", raidButton, "CENTER", 0, 0)
    raidButton.text:SetText("Select raid")

    raidButton:SetScript("OnEnter", function() raidButton:SetBackdropColor(0.5,0.5,0.5,1) end)
    raidButton:SetScript("OnLeave", function() raidButton:SetBackdropColor(0.2,0.2,0.2,1) end)

    raidButton:SetScript("OnClick", function()
        local btn = raidButton
        if not btn then return end

        if not btn.menu then
            local menu = CreateFrame("Frame", nil, panelFrame)
            menu:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
            menu:SetFrameStrata("DIALOG")
            menu:SetWidth(160)
            menu:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
            menu:SetBackdropColor(0.15,0.15,0.15,1)
            menu:SetBackdropBorderColor(0.2,0.2,0.2,1)
            menu:Hide()
            menu.items = {}
            btn.menu = menu
        end

        local menu = btn.menu
        if not menu then return end

        -- Limpiar items anteriores
        if menu.items then
            for _, item in ipairs(menu.items) do
                if item.Hide then item:Hide() end
            end
            menu.items = {}
        end

        -- Construir opciones de raid a partir de la config de la guild
        local options = {}
        if DMA.Data and DMA.Data.Database and DMA.Data.Database.GetDB and DMA.Data.Database.GetCurrentGuildKey then
            local db = DMA.Data.Database:GetDB()
            if db and db.guilds then
                local guildKey = DMA.Data.Database:GetCurrentGuildKey()
                if guildKey and db.guilds[guildKey] and db.guilds[guildKey].config and db.guilds[guildKey].config.raidDKP then
                    local raidDKP = db.guilds[guildKey].config.raidDKP
                    for raidKey, _ in pairs(raidDKP) do
                        table.insert(options, { key = raidKey, label = GetRaidLabelFromKey(raidKey) })
                    end
                end
            end
        end

        -- Si no hay ninguna raid configurada, mostrar una opción "None"
        if table.getn(options) == 0 then
            table.insert(options, { key = "NONE", label = "None" })
        end

        table.sort(options, function(a, b)
            return string.lower(a.label) < string.lower(b.label)
        end)

        local optionCount = 0
        for _ in ipairs(options) do
            optionCount = optionCount + 1
        end
        menu:SetHeight(optionCount * 20)

        for index, opt in ipairs(options) do
            local b = CreateFrame("Button", nil, menu)
            b:SetWidth(160)
            b:SetHeight(20)
            b:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, -((index - 1) * 20))
            b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
            b:SetBackdropColor(0.2,0.2,0.2,1)
            b:SetBackdropBorderColor(0.2,0.2,0.2,1)
            b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
            b.text:SetText(opt.label or "")

            -- Guardar datos en el propio botón
            b.raidKey = opt.key
            b.raidLabel = opt.label

            local buttonRef = b

            b:SetScript("OnEnter", function() buttonRef:SetBackdropColor(0.5,0.5,0.5,1) end)
            b:SetScript("OnLeave", function() buttonRef:SetBackdropColor(0.2,0.2,0.2,1) end)
            b:SetScript("OnClick", function()
                local label = buttonRef.raidLabel or buttonRef.raidKey or "None"
                if btn and btn.text then
                    btn.text:SetText(label)
                end
                if MainFrame and MainFrame.SetRaidKey then
                    MainFrame:SetRaidKey(buttonRef.raidKey or "NONE", label)
                end
                menu:Hide()
            end)

            table.insert(menu.items, b)
        end

        if menu:IsShown() then
            menu:Hide()
        else
            menu:Show()
        end
    end)

    -- Event type label + dropdown (fila superior del formulario)
    local typeLabel = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    typeLabel:SetPoint("TOPLEFT", raidLabel, "BOTTOMLEFT", 0, -15)
    typeLabel:SetText("Type:")

    local typeButton = CreateFrame("Button", nil, panelFrame)
    typeButton:SetWidth(100)
    typeButton:SetHeight(20)
    typeButton:SetPoint("LEFT", typeLabel, "RIGHT", 5, 0)
    typeButton:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    typeButton:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    typeButton:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    typeButton.text = typeButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    typeButton.text:SetPoint("CENTER", typeButton, "CENTER", 0, 0)
    typeButton.text:SetText("Item")

    typeButton:SetScript("OnEnter", function() typeButton:SetBackdropColor(0.5,0.5,0.5,1) end)
    typeButton:SetScript("OnLeave", function() typeButton:SetBackdropColor(0.2,0.2,0.2,1) end)

    -- Menú colgado del botón de tipo (clonado de simpleAuras, pero usando typeButton)
    typeButton:SetScript("OnClick", function()
        local btn = typeButton
        if not btn then return end

        if not btn.menu then
            local menu = CreateFrame("Frame", nil, panelFrame)
            menu:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
            menu:SetFrameStrata("DIALOG")
            menu:SetWidth(120)
            menu:SetHeight(table.getn(EVENT_TYPE_OPTIONS) * 20)
            menu:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
            menu:SetBackdropColor(0.15,0.15,0.15,1)
            menu:SetBackdropBorderColor(0.2,0.2,0.2,1)
            menu:Hide()
            btn.menu = menu

            local function makeChoice(key, label, index)
                local b = CreateFrame("Button", nil, menu)
                b:SetWidth(120)
                b:SetHeight(20)
                b:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, -((index - 1) * 20))
                b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
                b:SetBackdropColor(0.2,0.2,0.2,1)
                b:SetBackdropBorderColor(0.2,0.2,0.2,1)
                b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
                b.text:SetText(label)
                b:SetScript("OnEnter", function() b:SetBackdropColor(0.5,0.5,0.5,1) end)
                b:SetScript("OnLeave", function() b:SetBackdropColor(0.2,0.2,0.2,1) end)
                b:SetScript("OnClick", function()
                    if btn and btn.text then
                        btn.text:SetText(label)
                    end
                    if MainFrame and MainFrame.SetEventType then
                        MainFrame:SetEventType(key, label)
                    end
                    menu:Hide()
                end)
            end

            -- Construir opciones desde EVENT_TYPE_OPTIONS
            for index, opt in ipairs(EVENT_TYPE_OPTIONS) do
                makeChoice(opt.key, opt.label, index)
            end
        end

        local menu = btn.menu
        if menu then
            if menu:IsShown() then
                menu:Hide()
            else
                menu:Show()
            end
        end
    end)

    -- Penalty label + dropdown (solo relevante cuando Type = PENALTY)
    local penaltyLabel = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    penaltyLabel:SetPoint("LEFT", typeButton, "RIGHT", 15, 0)
    penaltyLabel:SetText("Penalty:")

    local penaltyButton = CreateFrame("Button", nil, panelFrame)
    penaltyButton:SetWidth(120)
    penaltyButton:SetHeight(20)
    penaltyButton:SetPoint("LEFT", typeButton, "RIGHT", 5, 0)
    penaltyButton:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    penaltyButton:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    penaltyButton:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    penaltyButton.text = penaltyButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    penaltyButton.text:SetPoint("CENTER", penaltyButton, "CENTER", 0, 0)
    penaltyButton.text:SetText("Select penalty")

    penaltyButton:SetScript("OnEnter", function() penaltyButton:SetBackdropColor(0.5,0.5,0.5,1) end)
    penaltyButton:SetScript("OnLeave", function() penaltyButton:SetBackdropColor(0.2,0.2,0.2,1) end)

    penaltyButton:SetScript("OnClick", function()
        local btn = penaltyButton
        if not btn then return end

        if not btn.menu then
            local menu = CreateFrame("Frame", nil, panelFrame)
            menu:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
            menu:SetFrameStrata("DIALOG")
            menu:SetWidth(160)
            menu:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
            menu:SetBackdropColor(0.15,0.15,0.15,1)
            menu:SetBackdropBorderColor(0.2,0.2,0.2,1)
            menu:Hide()
            menu.items = {}
            btn.menu = menu
        end

        local menu = btn.menu
        if not menu then return end

        -- Limpiar items anteriores
        if menu.items then
            for _, item in ipairs(menu.items) do
                if item.Hide then item:Hide() end
            end
            menu.items = {}
        end

        local options = {}

        -- Siempre ofrecer una opción "None" para modo manual
        table.insert(options, { key = "NONE", label = "None" })

        -- Construir opciones de penalización a partir de la config de la guild
        if DMA.Data and DMA.Data.Database and DMA.Data.Database.GetDB and DMA.Data.Database.GetCurrentGuildKey then
            local db = DMA.Data.Database:GetDB()
            if db and db.guilds then
                local guildKey = DMA.Data.Database:GetCurrentGuildKey()
                if guildKey and db.guilds[guildKey] and db.guilds[guildKey].config and db.guilds[guildKey].config.penalties then
                    local penalties = db.guilds[guildKey].config.penalties
                    local penList = {}
                    for pKey, cfg in pairs(penalties) do
                        table.insert(penList, { key = pKey, label = cfg.label or pKey })
                    end
                    table.sort(penList, function(a, b)
                        return string.lower(a.label or "") < string.lower(b.label or "")
                    end)
                    for _, opt in ipairs(penList) do
                        table.insert(options, opt)
                    end
                end
            end
        end

        local optionCount = 0
        for _ in ipairs(options) do
            optionCount = optionCount + 1
        end
        menu:SetHeight(optionCount * 20)

        for index, opt in ipairs(options) do
            local b = CreateFrame("Button", nil, menu)
            b:SetWidth(160)
            b:SetHeight(20)
            b:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, -((index - 1) * 20))
            b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
            b:SetBackdropColor(0.2,0.2,0.2,1)
            b:SetBackdropBorderColor(0.2,0.2,0.2,1)
            b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
            b.text:SetText(opt.label or "")

            b.penaltyKey = opt.key
            b.penaltyLabel = opt.label

            local buttonRef = b

            b:SetScript("OnEnter", function() buttonRef:SetBackdropColor(0.5,0.5,0.5,1) end)
            b:SetScript("OnLeave", function() buttonRef:SetBackdropColor(0.2,0.2,0.2,1) end)
            b:SetScript("OnClick", function()
                local label = buttonRef.penaltyLabel or buttonRef.penaltyKey or "None"
                if btn and btn.text then
                    btn.text:SetText(label)
                end
                if MainFrame and MainFrame.SetPenaltyKey then
                    MainFrame:SetPenaltyKey(buttonRef.penaltyKey or "NONE", label)
                end
                menu:Hide()
            end)

            table.insert(menu.items, b)
        end

        if menu:IsShown() then
            menu:Hide()
        else
            menu:Show()
        end
    end)

    -- DKP Value label (fila siguiente del formulario, alineado con el label de Type/Raid)
    local valueLabel = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valueLabel:SetPoint("TOPLEFT", typeLabel, "BOTTOMLEFT", 0, -15)
    valueLabel:SetText("DKP Value:")

    local valueBox = CreateFrame("EditBox", nil, panelFrame)
    valueBox:SetWidth(80)
    valueBox:SetHeight(20)
    valueBox:SetPoint("TOPLEFT", valueLabel, "BOTTOMLEFT", 0, -5)
    valueBox:SetAutoFocus(false)
    valueBox:SetNumeric(true)
    valueBox:SetText("0")
    valueBox:SetMaxLetters("5")
    valueBox:SetMultiLine(false)
    valueBox:SetFontObject(GameFontHighlightSmall)
    valueBox:SetTextColor(1, 1, 1)
    valueBox:SetTextInsets(4, 4, 4, 4)
    valueBox:SetJustifyH("LEFT")
    valueBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    valueBox:SetBackdropColor(0.1, 0.1, 0.1, 1)
    valueBox:SetBackdropBorderColor(0, 0, 0, 1)
    valueBox:SetScript("OnEscapePressed", function(self)
        valueBox:ClearFocus()
    end)

    -- Reason input
    local reasonLabel = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    reasonLabel:SetPoint("TOPLEFT", valueBox, "BOTTOMLEFT", 0, -15)
    reasonLabel:SetText("Reason:")

    local reasonBox = CreateFrame("EditBox", nil, panelFrame)
    reasonBox:SetWidth(280)
    reasonBox:SetHeight(25)
    reasonBox:SetPoint("TOPLEFT", reasonLabel, "BOTTOMLEFT", 0, -5)
    reasonBox:SetMultiLine(false)
    reasonBox:SetAutoFocus(false)
    reasonBox:SetFontObject(GameFontHighlightSmall)
    reasonBox:SetTextColor(1, 1, 1)
    reasonBox:SetMaxLetters(100)
    reasonBox:SetTextInsets(4, 4, 4, 4)
    reasonBox:SetJustifyH("LEFT")
    reasonBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    reasonBox:SetBackdropColor(0.1, 0.1, 0.1, 1)
    reasonBox:SetBackdropBorderColor(0, 0, 0, 1)
    reasonBox:SetScript("OnEscapePressed", function(self)
        reasonBox:ClearFocus()
    end)

    -- Action buttons
    local awardBtn = CreateFrame("Button", nil, panelFrame)
    awardBtn:SetWidth(133)
    awardBtn:SetHeight(25)
    awardBtn:SetPoint("TOPLEFT", reasonBox, "BOTTOMLEFT", 0, -20)
    awardBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    awardBtn:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    awardBtn:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    awardBtn.text = awardBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    awardBtn.text:SetPoint("CENTER", awardBtn, "CENTER", 0, 0)
    awardBtn.text:SetText("Award DKP")
    awardBtn:SetScript("OnEnter", function() awardBtn:SetBackdropColor(0.5,0.5,0.5,1) end)
    awardBtn:SetScript("OnLeave", function() awardBtn:SetBackdropColor(0.2,0.2,0.2,1) end)
    awardBtn:SetScript("OnClick", function() self:AdjustDKP(valueBox:GetText(), reasonBox:GetText(), true) end)

    local deductBtn = CreateFrame("Button", nil, panelFrame)
    deductBtn:SetWidth(133)
    deductBtn:SetHeight(25)
    deductBtn:SetPoint("LEFT", awardBtn, "RIGHT", 10, 0)
    deductBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    deductBtn:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    deductBtn:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    deductBtn.text = deductBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    deductBtn.text:SetPoint("CENTER", deductBtn, "CENTER", 0, 0)
    deductBtn.text:SetText("Deduct DKP")
    deductBtn:SetScript("OnEnter", function() deductBtn:SetBackdropColor(0.5,0.5,0.5,1) end)
    deductBtn:SetScript("OnLeave", function() deductBtn:SetBackdropColor(0.2,0.2,0.2,1) end)
    deductBtn:SetScript("OnClick", function() self:AdjustDKP(valueBox:GetText(), reasonBox:GetText(), false) end)

    -- DKP Decay section
    local decayLabel = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    decayLabel:SetPoint("TOPLEFT", awardBtn, "BOTTOMLEFT", 0, -20)
    decayLabel:SetText("DKP Decay (25%)")

    local decayBtn = CreateFrame("Button", nil, panelFrame)
    decayBtn:SetWidth(276)
    decayBtn:SetHeight(24)
    decayBtn:SetPoint("TOPLEFT", decayLabel, "BOTTOMLEFT", 0, -6)
    decayBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    decayBtn:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    decayBtn:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    decayBtn.text = decayBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    decayBtn.text:SetPoint("CENTER", decayBtn, "CENTER", 0, 0)
    decayBtn.text:SetText("Apply 25% DKP Decay (>= 1 DKP)")
    decayBtn:SetScript("OnEnter", function() decayBtn:SetBackdropColor(0.5,0.5,0.5,1) end)
    decayBtn:SetScript("OnLeave", function() decayBtn:SetBackdropColor(0.2,0.2,0.2,1) end)
    decayBtn:SetScript("OnClick", function() MainFrame:ShowDecayConfirmDialog() end)

    -- Store references for later use when awarding/deducting DKP
    self.valueLabel = valueLabel
    self.valueBox = valueBox
    self.reasonLabel = reasonLabel
    self.reasonBox = reasonBox
    self.eventTypeButton = typeButton

    -- Guardar referencias a los botones de acción para poder
    -- mostrarlos/ocultarlos según el tipo de evento seleccionado.
    self.awardButton = awardBtn
    self.deductButton = deductBtn

    self.raidLabel = raidLabel
    self.raidButton = raidButton

    self.penaltyLabel = penaltyLabel
    self.penaltyButton = penaltyButton

    -- Default raid: intentar usar una raid configurada; si no, "None" (modo manual)
    if MainFrame.SetRaidKey and DMA.Data and DMA.Data.Database and DMA.Data.Database.GetDB and DMA.Data.Database.GetCurrentGuildKey then
        local db = DMA.Data.Database:GetDB()
        local defaultKey = nil
        local defaultLabel = nil

        if db and db.guilds then
            local guildKey = DMA.Data.Database:GetCurrentGuildKey()
            if guildKey and db.guilds[guildKey] and db.guilds[guildKey].config and db.guilds[guildKey].config.raidDKP then
                local raidDKP = db.guilds[guildKey].config.raidDKP
                -- Elegir la primera raid configurada (orden no garantizado)
                for rKey, _ in pairs(raidDKP) do
                    defaultKey = rKey
                    defaultLabel = GetRaidLabelFromKey(rKey)
                    break
                end
            end
        end

        if not defaultKey then
            -- Sin raids configuradas: modo "None"
            MainFrame:SetRaidKey("NONE", "None")
        else
            MainFrame:SetRaidKey(defaultKey, defaultLabel or defaultKey)
        end
    end

    -- Default event type: Stay in raid
    if MainFrame.SetEventType then
        MainFrame:SetEventType("STAY", "Stay in raid")
    else
        self.currentEventType = "STAY"
    end

    -- Penalización por defecto: modo "None" (manual)
    if MainFrame.SetPenaltyKey then
        MainFrame:SetPenaltyKey("NONE", "None")
    else
        self.currentPenaltyKey = "NONE"
    end
end

-- Rebuild DKP Master panel so that permission changes (CanEditPublicNote)
-- are reflected every time the main window is opened
function MainFrame:RefreshDKPMasterPanel()
    -- Hide and detach previous panel (if any)
    if self.dkpPanelFrame then
        self.dkpPanelFrame:Hide()
        self.dkpPanelFrame:SetParent(nil)
        self.dkpPanelFrame = nil
    end

    -- Clear references to old inputs
    self.valueBox = nil
    self.reasonBox = nil
    self.raidButton = nil
    self.currentRaidKey = nil
    self.penaltyButton = nil
    self.currentPenaltyKey = nil

    -- Create a fresh panel based on current permissions
    self:CreateDKPMasterPanel()
end

-- Confirm dialog for DKP Decay
function MainFrame:ShowDecayConfirmDialog()
    if not DMA or not DMA.Core or not DMA.Core.DKPDecay then
        DEFAULT_CHAT_FRAME:AddMessage("DMA: DKP Decay module not available")
        return
    end

    if not self.decayConfirmFrame then
        local frame = CreateFrame("Frame", "DMA_DKPDecayConfirm", UIParent)
        frame:SetFrameStrata("DIALOG")
        frame:SetWidth(380)
        frame:SetHeight(160)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            tile = false,
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        frame:SetBackdropColor(0.04, 0.04, 0.04, 0.95)
        frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
        frame:EnableMouse(false)
        frame:SetMovable(false)

        -- Title
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", frame, "TOP", 0, -8)
        title:SetText("Confirm DKP Decay")

        -- Description (se actualizará dinámicamente con el preview)
        local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        desc:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -30)
        desc:SetWidth(356)
        desc:SetJustifyH("LEFT")
        desc:SetJustifyV("TOP")
        desc:SetText("")

        -- Confirm button
        local confirmBtn = CreateFrame("Button", nil, frame)
        confirmBtn:SetWidth(120)
        confirmBtn:SetHeight(24)
        confirmBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 15)
        confirmBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        confirmBtn:SetBackdropColor(0.2, 0.6, 0.2, 1)
        confirmBtn:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
        confirmBtn.text = confirmBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        confirmBtn.text:SetPoint("CENTER", confirmBtn, "CENTER", 0, 0)
        confirmBtn.text:SetText("Apply Decay")
        confirmBtn:SetScript("OnEnter", function() confirmBtn:SetBackdropColor(0.3,0.8,0.3,1) end)
        confirmBtn:SetScript("OnLeave", function() confirmBtn:SetBackdropColor(0.2,0.6,0.2,1) end)
        confirmBtn:SetScript("OnClick", function()
            DMA.Core.DKPDecay:ApplyDecay()
            frame:Hide()
        end)

        -- Cancel button
        local cancelBtn = CreateFrame("Button", nil, frame)
        cancelBtn:SetWidth(120)
        cancelBtn:SetHeight(24)
        cancelBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 15)
        cancelBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        cancelBtn:SetBackdropColor(0.3, 0.3, 0.3, 1)
        cancelBtn:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
        cancelBtn.text = cancelBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cancelBtn.text:SetPoint("CENTER", cancelBtn, "CENTER", 0, 0)
        cancelBtn.text:SetText("Cancel")
        cancelBtn:SetScript("OnEnter", function() cancelBtn:SetBackdropColor(0.5,0.5,0.5,1) end)
        cancelBtn:SetScript("OnLeave", function() cancelBtn:SetBackdropColor(0.3,0.3,0.3,1) end)
        cancelBtn:SetScript("OnClick", function()
            frame:Hide()
        end)

        -- Allow closing with ESC
        if UISpecialFrames then
            table.insert(UISpecialFrames, "DMA_DKPDecayConfirm")
        end

        -- Guardar referencias para actualizar texto y estado del botón
        frame.desc = desc
        frame.confirmBtn = confirmBtn

        self.decayConfirmFrame = frame
    end

    -- Actualizar preview de a quiénes afectará el decay
    local frame = self.decayConfirmFrame
    if DMA.Core and DMA.Core.DKPDecay and frame and frame.desc and frame.confirmBtn then
        local targets = DMA.Core.DKPDecay:GetDecayTargets() or {}
        local count = table.getn(targets)

        if count == 0 then
            frame.desc:SetText("No players with DKP >= 1 were found. Nothing to decay.")
            frame.confirmBtn:Disable()
        else
            frame.confirmBtn:Enable()

            local maxList = math.min(count, 10)
            local lines = {}
            table.insert(lines, "This will apply a 25% DKP decay (rounded up) to " .. count .. " guild members with 1 DKP or more.")
            table.insert(lines, "")
            table.insert(lines, "Examples:")
            for i = 1, maxList do
                local t = targets[i]
                table.insert(lines, string.format("- %s: %d -> %d", t.name or "?", t.oldDKP or 0, t.newDKP or 0))
            end
            if count > maxList then
                table.insert(lines, string.format("... and %d more.", count - maxList))
            end

            frame.desc:SetText(table.concat(lines, "\n"))
        end
    end

    frame:Show()
end

-- Get current player list (RAID if in raid, otherwise guild)
function MainFrame:GetCurrentPlayerList()
    local players = {}

    -- Si ya tenemos una tabla de roster precalculada, usarla para evitar
    -- volver a recorrer todo el roster de hermandad.
    if self.rosterByName then
        for name, _ in pairs(self.rosterByName) do
            table.insert(players, name)
        end
    elseif DMA.Data and DMA.Data.Cache then
        -- Fallback: usar el método del cache (puede leer del roster internamente)
        local cachePlayers = DMA.Data.Cache:GetAllPlayersByDKP()
        for _, player in ipairs(cachePlayers) do
            table.insert(players, player.name)
        end
    end

    -- Ordenar alfabéticamente (case-insensitive)
    table.sort(players, function(a, b)
        if not a or not b then return false end
        return string.lower(a) < string.lower(b)
    end)

    return players
end

-- Refresh player list display
function MainFrame:RefreshPlayerList()
    if not self.playerContent then return end

    -- Record which players were selected previously to restore selection by name
    local previouslySelected = {}
    if self.playerEntries then
        for _, entry in ipairs(self.playerEntries) do
            if entry.checkbox and entry.checkbox:GetChecked() and entry.checkbox.playerName then
                previouslySelected[entry.checkbox.playerName] = true
            end
        end
    else
        self.playerEntries = {}
    end

    -- Forzar actualización del roster de hermandad antes de obtener los jugadores
    if GuildRoster then GuildRoster() end

    -- Construir una tabla auxiliar con la información de roster por nombre
    self.rosterByName = {}
    if GetNumGuildMembers and GetGuildRosterInfo then
        local numMembers = GetNumGuildMembers()
        for i = 1, numMembers do
            local name, _, _, _, cName, _, note, _, _, _, cTag = GetGuildRosterInfo(i)
            if name then
                name = string.gsub(name, "-.*", "")
                local dkp = 0
                if note and note ~= "" then
                    dkp = tonumber(note) or 0
                end
                self.rosterByName[name] = {
                    dkp = dkp,
                    className = cName,
                    classTag = cTag
                }
            end
        end
    end

    -- Get current players
    local players = self:GetCurrentPlayerList()

    -- Apply name filter if present
    local filter = ""
    if self.playerFilterBox and self.playerFilterBox.GetText then
        filter = self.playerFilterBox:GetText() or ""
        filter = string.lower(string.gsub(filter, "^%s*(.-)%s*$", "%1"))
    end

    -- Create / reuse entries
    local yOffset = 0
    local shown = 0
    for _, playerName in ipairs(players) do
        local include = true
        if filter ~= "" then
            local lowerName = string.lower(playerName)
            if not string.find(lowerName, filter, 1, true) then
                include = false
            end
        end

        if include then
            shown = shown + 1
            local entry = self.playerEntries[shown]
            if not entry then
                entry = self:CreatePlayerEntry(playerName, yOffset)
                self.playerEntries[shown] = entry
            else
                -- Reuse existing frame, just update its contents and position
                entry:SetPoint("TOPLEFT", self.playerContent, "TOPLEFT", 0, yOffset)

                -- Update basic data
                entry.checkbox.playerName = playerName
                entry.nameText:SetText(playerName)

                -- Update class/DKP using the precalculated roster table
                local dkp = 0
                local className = ""
                local classTag = nil
                if self.rosterByName then
                    local info = self.rosterByName[playerName]
                    if info then
                        dkp = info.dkp or 0
                        className = info.className or ""
                        classTag = info.classTag
                    end
                end

                local classDisplay = className or ""
                if RAID_CLASS_COLORS and classTag and RAID_CLASS_COLORS[classTag] and className and className ~= "" then
                    local c = RAID_CLASS_COLORS[classTag]
                    local r = math.floor((c.r or 1) * 255)
                    local g = math.floor((c.g or 1) * 255)
                    local b = math.floor((c.b or 1) * 255)
                    classDisplay = string.format("|cff%02x%02x%02x%s", r, g, b, className)
                end
                entry.classText:SetText(classDisplay)

                local dkpColor = dkp >= 0 and "|cff00ff00" or "|cffff0000"
                entry.dkpText:SetText(dkpColor .. dkp)
            end

            -- Restore selection state by player name
            if previouslySelected[playerName] then
                entry.checkbox:SetChecked(true)
            else
                entry.checkbox:SetChecked(false)
            end

            entry:Show()
            yOffset = yOffset - 20
        end
    end

    -- Hide any leftover entries that are no longer used
    for i = shown + 1, table.getn(self.playerEntries) do
        if self.playerEntries[i] then
            self.playerEntries[i]:Hide()
        end
    end

    -- Resize content y actualizar el rango del scroll
    self.playerContent:SetHeight(math.max(1, math.abs(yOffset)))

    -- Asegurar que el ScrollFrame actualice sus límites y vuelva al inicio
    if self.playerScrollFrame then
        if self.playerScrollFrame.UpdateScrollChildRect then
            self.playerScrollFrame:UpdateScrollChildRect()
        end
        self.playerScrollFrame:SetVerticalScroll(0)
    end

    -- Actualizar título con el número de jugadores mostrados
    if self.playerTitle then
        self.playerTitle:SetText("Players: " .. tostring(shown))
    end
end

-- Create a player entry in the list
function MainFrame:CreatePlayerEntry(playerName, yOffset)
    local entry = CreateFrame("Frame", nil, self.playerContent)
    entry:SetWidth(230)
    entry:SetHeight(20)
    entry:SetPoint("TOPLEFT", self.playerContent, "TOPLEFT", 0, yOffset)

    -- Obtener DKP y clase usando la tabla precalculada de roster
    local dkp = 0
    local className = ""
    local classTag = nil
    if self.rosterByName then
        local info = self.rosterByName[playerName]
        if info then
            dkp = info.dkp or 0
            className = info.className or ""
            classTag = info.classTag
        end
    end

    -- Checkbox for selection
    local checkbox = CreateFrame("CheckButton", nil, entry, "UICheckButtonTemplate")
    checkbox:SetPoint("LEFT", entry, "LEFT", 0, 0)
    checkbox:SetWidth(20)
    checkbox:SetHeight(20)
    checkbox.playerName = playerName

    -- Player name
    local nameText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    nameText:SetWidth(100)
    nameText:SetText(playerName)

    -- Player class
    local classText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    classText:SetPoint("LEFT", nameText, "RIGHT", 5, 0)
    classText:SetWidth(60)
    classText:SetJustifyH("LEFT")

    local classDisplay = className or ""
    if RAID_CLASS_COLORS and classTag and RAID_CLASS_COLORS[classTag] and className and className ~= "" then
        local c = RAID_CLASS_COLORS[classTag]
        local r = math.floor((c.r or 1) * 255)
        local g = math.floor((c.g or 1) * 255)
        local b = math.floor((c.b or 1) * 255)
        classDisplay = string.format("|cff%02x%02x%02x%s", r, g, b, className)
    end
    classText:SetText(classDisplay)

    -- DKP value
    local dkpText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dkpText:SetPoint("RIGHT", entry, "RIGHT", 0, 0)
    dkpText:SetWidth(50)
    dkpText:SetJustifyH("RIGHT")

    local dkpColor = dkp >= 0 and "|cff00ff00" or "|cffff0000"
    dkpText:SetText(dkpColor .. dkp)

    -- Store reference for selection
    entry.checkbox = checkbox
    entry.nameText = nameText
    entry.classText = classText
    entry.dkpText = dkpText

    return entry
end

-- Select all players
function MainFrame:SelectAllPlayers()
    for _, entry in ipairs(self.playerEntries) do
        entry.checkbox:SetChecked(true)
    end
end

-- Select no players
function MainFrame:SelectNoPlayers()
    for _, entry in ipairs(self.playerEntries) do
        entry.checkbox:SetChecked(false)
    end
end

-- Select only players that are currently in the raid
function MainFrame:SelectRaidPlayers()
    local raidNames = {}

    if UnitInRaid and UnitInRaid("player") and GetNumRaidMembers and GetRaidRosterInfo then
        local numMembers = GetNumRaidMembers()
        for i = 1, numMembers do
            local name = GetRaidRosterInfo(i)
            if name then
                name = string.gsub(name, "-.*", "")
                raidNames[name] = true
            end
        end
    end

    for _, entry in ipairs(self.playerEntries) do
        if raidNames[entry.checkbox.playerName] then
            entry.checkbox:SetChecked(true)
        else
            entry.checkbox:SetChecked(false)
        end
    end
end

-- Award DKP to selected players
function MainFrame:AdjustDKP(valueStr, reason, isAward)
    local uiValue = tonumber(valueStr)

    -- Determinar tipo de evento seleccionado
    local eventType = self.currentEventType or "ITEM"

    -- Obtener valor de DKP final según el tipo de evento
    local finalValue = nil
    local finalReason = reason

    -- Helper para saber si existe alguna configuración de raid
    local function HasAnyRaidConfig()
        if not DMA.Data or not DMA.Data.Database or not DMA.Data.Database.GetDB or not DMA.Data.Database.GetCurrentGuildKey then
            return false
        end
        local db = DMA.Data.Database:GetDB()
        if not db or not db.guilds then return false end
        local guildKey = DMA.Data.Database:GetCurrentGuildKey()
        if not guildKey or not db.guilds[guildKey] or not db.guilds[guildKey].config then
            return false
        end
        local raidDKP = db.guilds[guildKey].config.raidDKP
        if not raidDKP then return false end
        return next(raidDKP) ~= nil
    end

    local hasRaidConfig = HasAnyRaidConfig()

    -- Helper para obtener configuración de raid por guild
    local function GetConfiguredRaidDKP(fieldKey)
        if not hasRaidConfig then
            return nil
        end

        if not DMA.Data or not DMA.Data.Database or not DMA.Data.Database.GetDB or not DMA.Data.Database.GetCurrentGuildKey then
            return nil
        end

        local db = DMA.Data.Database:GetDB()
        if not db or not db.guilds then return nil end

        local guildKey = DMA.Data.Database:GetCurrentGuildKey()
        if not guildKey or not db.guilds[guildKey] or not db.guilds[guildKey].config or not db.guilds[guildKey].config.raidDKP then
            return nil
        end

        -- Priorizar raid seleccionada manualmente en el dropdown
        local raidKey = self.currentRaidKey
        if raidKey == "NONE" then
            return nil
        end
        if not raidKey then
            -- Fallback: intentar detectar por nombre de zona actual
            local zoneName = GetRealZoneText and GetRealZoneText() or nil
            if zoneName and zoneName ~= "" then
                local z = string.lower(zoneName)
                if string.find(z, "molten core", 1, true) then
                    raidKey = "MC"
                elseif string.find(z, "blackwing lair", 1, true) then
                    raidKey = "BWL"
                elseif string.find(z, "ahn'qiraj", 1, true) or string.find(z, "ahnqiraj", 1, true) then
                    raidKey = "AQ40"
                elseif string.find(z, "naxxramas", 1, true) then
                    raidKey = "NAXX"
                end
            end
        end

        if not raidKey then
            return nil
        end

        local raidCfg = db.guilds[guildKey].config.raidDKP[raidKey]
        if not raidCfg then
            return nil
        end

        return raidCfg[fieldKey]
    end

    if eventType == "STAY" then
        finalValue = GetConfiguredRaidDKP("stay")
        finalReason = "Permanecer en raid"
    elseif eventType == "EARLY" then
        finalValue = GetConfiguredRaidDKP("early")
        finalReason = "Llegar temprano"
    elseif eventType == "BOSS" then
        finalValue = GetConfiguredRaidDKP("bossKill")
        if not finalReason or finalReason == "" then
            finalReason = "Boss kill"
        end
    else
        -- ITEM y PENALTY (modo manual) usan el valor introducido manualmente
        finalValue = uiValue
        if eventType == "ITEM" and (not finalReason or finalReason == "") then
            finalReason = "Item comprado: "
        end
    end

    -- Helper para obtener la configuración de la penalización seleccionada
    local function GetCurrentPenaltyConfig()
        if not DMA.Data or not DMA.Data.Database or not DMA.Data.Database.GetDB or not DMA.Data.Database.GetCurrentGuildKey then
            return nil
        end
        local db = DMA.Data.Database:GetDB()
        if not db or not db.guilds then return nil end
        local guildKey = DMA.Data.Database:GetCurrentGuildKey()
        if not guildKey or not db.guilds[guildKey] or not db.guilds[guildKey].config then
            return nil
        end
        local penalties = db.guilds[guildKey].config.penalties
        if not penalties then return nil end

        local pKey = self.currentPenaltyKey
        if not pKey or pKey == "NONE" then
            return nil
        end

        return penalties[pKey]
    end

    -- Construir lista de jugadores seleccionados (se reutiliza en todos los casos)
    local selectedPlayers = {}
    for _, entry in ipairs(self.playerEntries) do
        if entry.checkbox:GetChecked() then
            table.insert(selectedPlayers, entry.checkbox.playerName)
        end
    end

    local hasPlayers = false
    for _, _ in ipairs(selectedPlayers) do hasPlayers = true break end
    if not hasPlayers then
        if DMA.Utils and DMA.Utils.Logger then
            DMA.Utils.Logger:Warn("No hay jugadores seleccionados")
        else
            DEFAULT_CHAT_FRAME:AddMessage("DMA: No hay jugadores seleccionados")
        end
        return
    end

    -- Caso especial: penalización con porcentaje configurado y DKP >= 200 por jugador
    if eventType == "PENALTY" then
        local penaltyCfg = GetCurrentPenaltyConfig()
        local percent = penaltyCfg and (penaltyCfg.percent or 0) or 0

        if penaltyCfg and percent > 0 and not isAward then
            if not DMA.Data or not DMA.Data.Database or not DMA.Data.Database.GetDKP then
                -- Fallback: si no podemos leer DKP actual, seguir con lógica clásica
            else
                -- Sincronizar primero desde notas públicas
                if DMA.Data and DMA.Data.Cache and DMA.Data.Cache.SyncPlayersFromPublicNote then
                    DMA.Data.Cache:SyncPlayersFromPublicNote(selectedPlayers)
                end

                local anyApplied = false

                for _, playerName in ipairs(selectedPlayers) do
                    local currentDKP = DMA.Data.Database:GetDKP(playerName) or 0

                    local effective
                    if currentDKP >= 200 then
                        -- Descuento porcentual sobre el DKP actual
                        effective = math.floor((currentDKP * percent) / 100)
                    else
                        -- Usar valor fijo cuando está por debajo del umbral
                        effective = penaltyCfg.fixed or penaltyCfg.value or uiValue or 0
                    end

                    if effective and effective > 0 then
                        anyApplied = true

                        local dkpValue = -effective
                        local eventReason = finalReason or "Penalty"

                        local playerStr = playerName

                        local event = nil
                        if DMA.Data and DMA.Data.EventManager then
                            event = DMA.Data.EventManager:CreateEvent(
                                "manual_adjust",
                                playerStr,
                                dkpValue,
                                eventReason,
                                UnitName("player")
                            )
                        end

                        if event and DMA.Data.Database then
                            DMA.Data.Database:AddEvent(event)

                            if DMA.Core and DMA.Core.Comm then
                                DMA.Core.Comm:BroadcastDKPEvent(
                                    playerStr,
                                    dkpValue,
                                    eventReason
                                )
                            end

                            -- Actualizar nota pública del jugador tras aplicar la penalización
                            if DMA.Data and DMA.Data.Database and DMA.Data.Database.GetDKP and DMA.Data.Cache and DMA.Data.Cache.UpdatePlayerPublicNote then
                                local newDKP = DMA.Data.Database:GetDKP(playerName) or 0
                                DMA.Data.Cache.UpdatePlayerPublicNote(playerName, newDKP)
                            end

                            -- Mensaje informativo en el chat de hermandad, igual que en el flujo clásico
                            local msg = string.format("DMA: Reducidos %d DKP de %s (%s)", effective, playerName, eventReason)
                            if SendChatMessage and IsInGuild and IsInGuild() then
                                SendChatMessage(msg, "GUILD")
                            else
                                if DEFAULT_CHAT_FRAME then
                                    DEFAULT_CHAT_FRAME:AddMessage(msg)
                                end
                            end
                        end
                    end
                end

                if not anyApplied then
                    local msg = "Valor de DKP inválido para deducir"
                    if DMA.Utils and DMA.Utils.Logger then
                        DMA.Utils.Logger:Error(msg)
                    else
                        DEFAULT_CHAT_FRAME:AddMessage("DMA: " .. msg)
                    end
                    return
                end

                -- Forzar actualización del roster y refrescar la lista tras un pequeño delay
                if GuildRoster then GuildRoster() end
                if self.frame then
                    local start = GetTime()
                    local function onUpdate()
                        if GetTime() - start >= 0.5 then
                            self.frame:SetScript("OnUpdate", nil)
                            self:RefreshPlayerList()
                        end
                    end
                    self.frame:SetScript("OnUpdate", onUpdate)
                else
                    self:RefreshPlayerList()
                end

                -- Ya procesamos todo el flujo de penalización porcentual
                return
            end
        end
    end

    -- Flujo clásico: un único valor para todos los jugadores seleccionados
    if not finalValue or finalValue <= 0 then
        local msg = isAward and "Valor de DKP inválido para otorgar" or "Valor de DKP inválido para deducir"
        if DMA.Utils and DMA.Utils.Logger then
            DMA.Utils.Logger:Error(msg)
        else
            DEFAULT_CHAT_FRAME:AddMessage("DMA: " .. msg)
        end
        return
    end

    local dkpValue = isAward and finalValue or -finalValue
    local eventReason = finalReason or (isAward and "Manual award" or "Manual deduction")
    local playerStr = ""
    for i, v in ipairs(selectedPlayers) do
        if i > 1 then playerStr = playerStr .. "," end
        playerStr = playerStr .. v
    end

    -- Sincronizar el cache con la nota pública actual de estos jugadores
    if DMA.Data and DMA.Data.Cache and DMA.Data.Cache.SyncPlayersFromPublicNote then
        DMA.Data.Cache:SyncPlayersFromPublicNote(selectedPlayers)
    end

    if DMA.Data and DMA.Data.EventManager then
        local event = DMA.Data.EventManager:CreateEvent(
            "manual_adjust",
            playerStr,
            dkpValue,
            eventReason,
            UnitName("player")
        )

        if event and DMA.Data.Database then
            DMA.Data.Database:AddEvent(event)

            -- Broadcast to guild
            if DMA.Core and DMA.Core.Comm then
                DMA.Core.Comm:BroadcastDKPEvent(
                    playerStr,
                    dkpValue,
                    eventReason
                )
            end

            -- Forzar actualización del roster y refrescar la lista tras un pequeño delay
            if GuildRoster then GuildRoster() end
            -- Esperar 0.5 segundos antes de refrescar la lista para dar tiempo a la API
            if self.frame then
                local start = GetTime()
                local function onUpdate()
                    if GetTime() - start >= 0.5 then
                        self.frame:SetScript("OnUpdate", nil)
                        self:RefreshPlayerList()
                    end
                end
                self.frame:SetScript("OnUpdate", onUpdate)
            else
                self:RefreshPlayerList()
            end

            local msgFormat = isAward and "DMA: Otorgados %d DKP a %s (%s)" or "DMA: Reducidos %d DKP de %s (%s)"
            for _, playerName in ipairs(selectedPlayers) do
                local msg = string.format(msgFormat, finalValue, playerName, eventReason)
                if SendChatMessage and IsInGuild and IsInGuild() then
                    SendChatMessage(msg, "GUILD")
                else
                    DEFAULT_CHAT_FRAME:AddMessage(msg)
                end
                -- Actualizar nota pública solo al otorgar o reducir DKP manualmente
                if DMA.Data and DMA.Data.Database and DMA.Data.Database.GetDKP and DMA.Data.Cache and DMA.Data.Cache.UpdatePlayerPublicNote then
                    local currentDKP = DMA.Data.Database:GetDKP(playerName) or 0
                    DMA.Data.Cache.UpdatePlayerPublicNote(playerName, currentDKP)
                end
            end

            -- No limpiamos los campos de valor ni razón aquí; quedan
            -- controlados por el tipo de evento (SetEventType) y por el usuario.
            if self.valueBox then
                self.valueBox:ClearFocus()
            end
            if self.reasonBox then
                self.reasonBox:ClearFocus()
            end
        end
    end
end

-- Actualiza el tipo de evento y la visibilidad/prefill de campos
function MainFrame:SetEventType(eventKey, displayLabel)
    self.currentEventType = eventKey

    if self.eventTypeButton and self.eventTypeButton.text then
        self.eventTypeButton.text:SetText(displayLabel or eventKey)
    end

    -- Mostrar/ocultar el selector de penalizaciones según el tipo
    if self.penaltyLabel and self.penaltyButton then
        if eventKey == "PENALTY" then
            self.penaltyLabel:Show()
            self.penaltyButton:Show()
        else
            self.penaltyLabel:Hide()
            self.penaltyButton:Hide()
        end
    end

    -- Mostrar/ocultar y reanclar botones de Award/Deduct según el tipo de evento.
    -- STAY, EARLY, BOSS: sólo Award, ocupando todo el ancho; ITEM y PENALTY:
    -- sólo Deduct, ocupando todo el ancho; MANUAL: ambos botones visibles lado a lado.
    -- Si el tipo es desconocido, se muestran ambos en el layout original.
    if self.awardButton and self.deductButton and self.reasonBox then
        local fullWidth = 276 -- mismo ancho que el botón de decay

        if eventKey == "STAY" or eventKey == "EARLY" or eventKey == "BOSS" then
            -- Sólo Award: ancho completo, anclado bajo Reason
            self.awardButton:ClearAllPoints()
            self.awardButton:SetPoint("TOPLEFT", self.reasonBox, "BOTTOMLEFT", 0, -20)
            self.awardButton:SetWidth(fullWidth)
            self.awardButton:Show()

            self.deductButton:Hide()

        elseif eventKey == "ITEM" or eventKey == "PENALTY" then
            -- Sólo Deduct: ancho completo, anclado bajo Reason
            self.deductButton:ClearAllPoints()
            self.deductButton:SetPoint("TOPLEFT", self.reasonBox, "BOTTOMLEFT", 0, -20)
            self.deductButton:SetWidth(fullWidth)
            self.deductButton:Show()

            self.awardButton:Hide()

        elseif eventKey == "MANUAL" then
            -- Ambos botones visibles en el layout original (dos mitades)
            self.awardButton:ClearAllPoints()
            self.awardButton:SetPoint("TOPLEFT", self.reasonBox, "BOTTOMLEFT", 0, -20)
            self.awardButton:SetWidth(133)

            self.deductButton:ClearAllPoints()
            self.deductButton:SetPoint("LEFT", self.awardButton, "RIGHT", 10, 0)
            self.deductButton:SetWidth(133)

            self.awardButton:Show()
            self.deductButton:Show()

        else
            -- Cualquier otro tipo desconocido: mostrar ambos en el layout
            -- original (dos botones de ~133 de ancho con separación).
            self.awardButton:ClearAllPoints()
            self.awardButton:SetPoint("TOPLEFT", self.reasonBox, "BOTTOMLEFT", 0, -20)
            self.awardButton:SetWidth(133)

            self.deductButton:ClearAllPoints()
            self.deductButton:SetPoint("LEFT", self.awardButton, "RIGHT", 10, 0)
            self.deductButton:SetWidth(133)

            self.awardButton:Show()
            self.deductButton:Show()
        end
    end

    -- Helper para habilitar/deshabilitar campos visualmente
    local function SetFieldEnabled(box, enabled)
        if not box then return end
        if enabled then
            box:EnableMouse(true)
            box:SetTextColor(1, 1, 1)
        else
            box:EnableMouse(false)
            box:ClearFocus()
            box:SetTextColor(0.6, 0.6, 0.6)
        end
    end

    -- ¿Hay alguna raid configurada en la guild?
    local function HasAnyRaidConfig()
        if not DMA.Data or not DMA.Data.Database or not DMA.Data.Database.GetDB or not DMA.Data.Database.GetCurrentGuildKey then
            return false
        end
        local db = DMA.Data.Database:GetDB()
        if not db or not db.guilds then return false end
        local guildKey = DMA.Data.Database:GetCurrentGuildKey()
        if not guildKey or not db.guilds[guildKey] or not db.guilds[guildKey].config then
            return false
        end
        local raidDKP = db.guilds[guildKey].config.raidDKP
        if not raidDKP then return false end
        return next(raidDKP) ~= nil
    end

    local hasRaidConfig = HasAnyRaidConfig()

    -- ¿Hay alguna penalización configurada en la guild?
    local function HasAnyPenaltyConfig()
        if not DMA.Data or not DMA.Data.Database or not DMA.Data.Database.GetDB or not DMA.Data.Database.GetCurrentGuildKey then
            return false
        end
        local db = DMA.Data.Database:GetDB()
        if not db or not db.guilds then return false end
        local guildKey = DMA.Data.Database:GetCurrentGuildKey()
        if not guildKey or not db.guilds[guildKey] or not db.guilds[guildKey].config then
            return false
        end
        local penalties = db.guilds[guildKey].config.penalties
        if not penalties then return false end
        return next(penalties) ~= nil
    end

    local function GetCurrentPenaltyConfig()
        if not DMA.Data or not DMA.Data.Database or not DMA.Data.Database.GetDB or not DMA.Data.Database.GetCurrentGuildKey then
            return nil
        end
        local db = DMA.Data.Database:GetDB()
        if not db or not db.guilds then return nil end
        local guildKey = DMA.Data.Database:GetCurrentGuildKey()
        if not guildKey or not db.guilds[guildKey] or not db.guilds[guildKey].config then
            return nil
        end
        local penalties = db.guilds[guildKey].config.penalties
        if not penalties then return nil end

        local pKey = self.currentPenaltyKey
        if not pKey or pKey == "NONE" then
            return nil
        end

        return penalties[pKey]
    end

    -- Helper para obtener el valor configurado de DKP para la raid actual
    local function GetConfiguredRaidDKP(fieldKey)
        if not hasRaidConfig then
            return nil
        end

        if not DMA.Data or not DMA.Data.Database or not DMA.Data.Database.GetDB or not DMA.Data.Database.GetCurrentGuildKey then
            return nil
        end

        local db = DMA.Data.Database:GetDB()
        if not db or not db.guilds then return nil end

        local guildKey = DMA.Data.Database:GetCurrentGuildKey()
        if not guildKey or not db.guilds[guildKey] or not db.guilds[guildKey].config or not db.guilds[guildKey].config.raidDKP then
            return nil
        end

        -- Priorizar raid seleccionada manualmente en el dropdown
        local raidKey = self.currentRaidKey
        if raidKey == "NONE" then
            return nil
        end
        if not raidKey then
            -- Fallback: intentar detectar por nombre de zona actual
            local zoneName = GetRealZoneText and GetRealZoneText() or nil
            if zoneName and zoneName ~= "" then
                local z = string.lower(zoneName)
                if string.find(z, "molten core", 1, true) then
                    raidKey = "MC"
                elseif string.find(z, "blackwing lair", 1, true) then
                    raidKey = "BWL"
                elseif string.find(z, "ahn'qiraj", 1, true) or string.find(z, "ahnqiraj", 1, true) then
                    raidKey = "AQ40"
                elseif string.find(z, "naxxramas", 1, true) then
                    raidKey = "NAXX"
                end
            end
        end

        if not raidKey then
            return nil
        end

        local raidCfg = db.guilds[guildKey].config.raidDKP[raidKey]
        if not raidCfg then
            return nil
        end

        return raidCfg[fieldKey]
    end

    -- Siempre mostramos ambos campos; sólo cambiamos valores y editable/no editable.
    -- Si NO hay raids configuradas (o se ha elegido "None"), los valores se
    -- introducen manualmente incluso para STAY/EARLY/BOSS.
    if eventKey == "STAY" then
        local cfgVal = GetConfiguredRaidDKP("stay")
        if cfgVal ~= nil then
            if self.valueBox then
                self.valueBox:SetText(tostring(cfgVal))
            end
            if self.reasonBox then
                self.reasonBox:SetText("Permanecer en raid")
            end
            SetFieldEnabled(self.valueBox, false)
            SetFieldEnabled(self.reasonBox, false)
        else
            if self.valueBox then
                local txt = self.valueBox:GetText() or ""
                if txt == "" then
                    self.valueBox:SetText("0")
                end
            end
            if self.reasonBox then
                local current = self.reasonBox:GetText() or ""
                if current == "" then
                    self.reasonBox:SetText("Permanecer en raid")
                end
            end
            SetFieldEnabled(self.valueBox, true)
            SetFieldEnabled(self.reasonBox, true)
        end

    elseif eventKey == "EARLY" then
        local cfgVal = GetConfiguredRaidDKP("early")
        if cfgVal ~= nil then
            if self.valueBox then
                self.valueBox:SetText(tostring(cfgVal))
            end
            if self.reasonBox then
                self.reasonBox:SetText("Llegar temprano")
            end
            SetFieldEnabled(self.valueBox, false)
            SetFieldEnabled(self.reasonBox, false)
        else
            if self.valueBox then
                local txt = self.valueBox:GetText() or ""
                if txt == "" then
                    self.valueBox:SetText("0")
                end
            end
            if self.reasonBox then
                local current = self.reasonBox:GetText() or ""
                if current == "" then
                    self.reasonBox:SetText("Llegar temprano")
                end
            end
            SetFieldEnabled(self.valueBox, true)
            SetFieldEnabled(self.reasonBox, true)
        end

    elseif eventKey == "BOSS" then
        local cfgVal = GetConfiguredRaidDKP("bossKill")
        if cfgVal ~= nil then
            if self.valueBox then
                self.valueBox:SetText(tostring(cfgVal))
            end
            if self.reasonBox then
                self.reasonBox:SetText("Boss kill: ")
            end
            SetFieldEnabled(self.valueBox, false)
            SetFieldEnabled(self.reasonBox, true)
        else
            if self.valueBox then
                local txt = self.valueBox:GetText() or ""
                if txt == "" then
                    self.valueBox:SetText("0")
                end
            end
            if self.reasonBox then
                local current = self.reasonBox:GetText() or ""
                if current == "" then
                    self.reasonBox:SetText("Boss kill: ")
                end
            end
            SetFieldEnabled(self.valueBox, true)
            SetFieldEnabled(self.reasonBox, true)
        end

    elseif eventKey == "ITEM" then
        if self.valueBox then
            -- Mantener el último valor tecleado, o 0 si vacío
            local txt = self.valueBox:GetText() or ""
            if txt == "" then
                self.valueBox:SetText("0")
            end
        end
        if self.reasonBox then
            local prefix = "Item comprado: "
            local current = self.reasonBox:GetText() or ""
            if current == "" or string.sub(current, 1, string.len(prefix)) ~= prefix then
                self.reasonBox:SetText(prefix)
            end
        end
        SetFieldEnabled(self.valueBox, true)
        SetFieldEnabled(self.reasonBox, true)

    elseif eventKey == "MANUAL" then
        -- Ajuste manual: ambos campos habilitados, valor por defecto 0 si vacío
        if self.valueBox then
            local txt = self.valueBox:GetText() or ""
            if txt == "" then
                self.valueBox:SetText("0")
            end
        end
        -- La razón queda completamente a elección del usuario; no forzamos prefijos
        SetFieldEnabled(self.valueBox, true)
        SetFieldEnabled(self.reasonBox, true)

    elseif eventKey == "PENALTY" then
        local hasPenaltyConfig = HasAnyPenaltyConfig()
        local penaltyCfg = nil

        if hasPenaltyConfig then
            penaltyCfg = GetCurrentPenaltyConfig()
        end

        if not hasPenaltyConfig then
            -- Sin penalizaciones configuradas: modo manual (igual que raid NONE)
            if self.penaltyButton and self.penaltyButton.text then
                self.penaltyButton.text:SetText("None")
            end

            if self.valueBox then
                local txt = self.valueBox:GetText() or ""
                if txt == "" then
                    self.valueBox:SetText("0")
                end
            end
            if self.reasonBox then
                local prefix = "Penalty: "
                local current = self.reasonBox:GetText() or ""
                if current == "" or string.sub(current, 1, string.len(prefix)) ~= prefix then
                    self.reasonBox:SetText(prefix)
                end
            end
            SetFieldEnabled(self.valueBox, true)
            SetFieldEnabled(self.reasonBox, true)

        elseif penaltyCfg then
            -- Penalización seleccionada: rellenar y bloquear campos
            local fixedVal = penaltyCfg.fixed or penaltyCfg.value or 0
            local percentVal = penaltyCfg.percent or 0

            if self.valueBox then
                self.valueBox:SetText(tostring(fixedVal or 0))
            end
            if self.reasonBox then
                local label = penaltyCfg.label or self.currentPenaltyKey or "Penalty"
                local text = "Penalty: " .. label
                if percentVal and percentVal ~= 0 then
                    text = text .. string.format(" (%d%%)", percentVal)
                end
                self.reasonBox:SetText(text)
            end

            SetFieldEnabled(self.valueBox, false)
            SetFieldEnabled(self.reasonBox, false)

        else
            -- Hay penalizaciones pero ninguna seleccionada (o "None"): modo manual
            if self.valueBox then
                local txt = self.valueBox:GetText() or ""
                if txt == "" then
                    self.valueBox:SetText("0")
                end
            end
            if self.reasonBox then
                local prefix = "Penalty: "
                local current = self.reasonBox:GetText() or ""
                if current == "" or string.sub(current, 1, string.len(prefix)) ~= prefix then
                    self.reasonBox:SetText(prefix)
                end
            end
            SetFieldEnabled(self.valueBox, true)
            SetFieldEnabled(self.reasonBox, true)
        end

    else
        -- Cualquier otro tipo desconocido: habilitar ambos sin tocar textos
        SetFieldEnabled(self.valueBox, true)
        SetFieldEnabled(self.reasonBox, true)
    end
end

-- Actualiza la raid seleccionada (usada por los tipos STAY/EARLY/BOSS)
function MainFrame:SetRaidKey(raidKey, displayLabel)
    self.currentRaidKey = raidKey

    if self.raidButton and self.raidButton.text then
        self.raidButton.text:SetText(displayLabel or raidKey or "Select raid")
    end

    -- Si tenemos un tipo de evento que usa la config de raid, refrescar campos
    local t = self.currentEventType
    if t == "STAY" or t == "EARLY" or t == "BOSS" then
        if self.SetEventType then
            local label = nil
            if self.eventTypeButton and self.eventTypeButton.text then
                label = self.eventTypeButton.text:GetText()
            end
            self:SetEventType(t, label)
        end
    end
end

-- Actualiza la penalización seleccionada (usada cuando el tipo es PENALTY)
function MainFrame:SetPenaltyKey(penaltyKey, displayLabel)
    self.currentPenaltyKey = penaltyKey

    if self.penaltyButton and self.penaltyButton.text then
        self.penaltyButton.text:SetText(displayLabel or penaltyKey or "Select penalty")
    end

    -- Si el tipo actual es PENALTY, refrescar los campos según la penalización
    local t = self.currentEventType
    if t == "PENALTY" and self.SetEventType then
        local label = nil
        if self.eventTypeButton and self.eventTypeButton.text then
            label = self.eventTypeButton.text:GetText()
        end
        self:SetEventType(t, label)
    end
end

function MainFrame:Toggle()
    if not self.frame then
        self:Init()
    end

    if self.frame:IsShown() then
        self.frame:Hide()
    else
        -- Re-evaluate DKP Master permissions and refresh guild data
        if self.RefreshDKPMasterPanel then
            self:RefreshDKPMasterPanel()
        end

        self:RefreshPlayerList() -- Refresh guild members and DKP when showing
        self.frame:Show()
    end
end

DEFAULT_CHAT_FRAME:AddMessage("DMA: Módulo MainFrame cargado")
