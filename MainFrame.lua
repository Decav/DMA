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
    self:CreateHistoryButton()
    self:CreatePlayerList()
    self:CreateDKPMasterPanel()
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
        if DMA.UI and DMA.UI.History and DMA.UI.History.ShowAttached then
            DMA.UI.History:ShowAttached(self.frame)
        elseif DMA.UI and DMA.UI.History then
            DMA.UI.History:Toggle()
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

    -- Title
    local title = listFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 6, -6)
    title:SetText("Players & DKP")

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

    -- Player selection buttons
    local selectAllBtn = CreateFrame("Button", nil, panelFrame)
    selectAllBtn:SetWidth(85)
    selectAllBtn:SetHeight(22)
    selectAllBtn:SetPoint("TOPLEFT", panelFrame, "TOPLEFT", 10, -25)
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

    -- DKP Value input
    local valueLabel = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valueLabel:SetPoint("TOPLEFT", selectAllBtn, "BOTTOMLEFT", 0, -15)
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
    self.valueBox = valueBox
    self.reasonBox = reasonBox
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

    -- Siempre usar miembros de la hermandad (no solo raid)
    if DMA.Data and DMA.Data.Cache then
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

    -- Clear existing entries
    for _, entry in ipairs(self.playerEntries) do
        entry:Hide()
    end
    self.playerEntries = {}

    -- Forzar actualización del roster de hermandad antes de obtener los jugadores
    if GuildRoster then GuildRoster() end
    -- Get current players
    local players = self:GetCurrentPlayerList()

    -- Apply name filter if present
    local filter = ""
    if self.playerFilterBox and self.playerFilterBox.GetText then
        filter = self.playerFilterBox:GetText() or ""
        filter = string.lower(string.gsub(filter, "^%s*(.-)%s*$", "%1"))
    end

    -- Create entries
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
            if shown > 50 then break end -- Limit for performance

            local entry = self:CreatePlayerEntry(playerName, yOffset)
            table.insert(self.playerEntries, entry)
            yOffset = yOffset - 20
        end
    end

    -- Resize content
    self.playerContent:SetHeight(math.max(1, math.abs(yOffset)))
end

-- Create a player entry in the list
function MainFrame:CreatePlayerEntry(playerName, yOffset)
    local entry = CreateFrame("Frame", nil, self.playerContent)
    entry:SetWidth(230)
    entry:SetHeight(20)
    entry:SetPoint("TOPLEFT", self.playerContent, "TOPLEFT", 0, yOffset)

    -- Obtener DKP y clase directamente del roster de hermandad
    local dkp = 0
    local className = ""
    local classTag = nil
    if GetNumGuildMembers and GetGuildRosterInfo then
        local numMembers = GetNumGuildMembers()
        for i = 1, numMembers do
            local name, _, _, _, cName, _, note, _, _, _, cTag = GetGuildRosterInfo(i)
            if name then
                name = string.gsub(name, "-.*", "")
                if name == playerName then
                    if note and note ~= "" then
                        dkp = tonumber(note) or 0
                    end
                    className = cName or ""
                    classTag = cTag
                    break
                end
            end
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
    local value = tonumber(valueStr)
    if not value or value <= 0 then
        local msg = isAward and "Valor de DKP inválido para otorgar" or "Valor de DKP inválido para deducir"
        if DMA.Utils and DMA.Utils.Logger then
            DMA.Utils.Logger:Error(msg)
        else
            DEFAULT_CHAT_FRAME:AddMessage("DMA: " .. msg)
        end
        return
    end

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

    local dkpValue = 0
    if (isAward) then
        dkpValue = value
    else
        dkpValue = -value
    end
    local eventReason = reason or (isAward and "Manual award" or "Manual deduction")
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
                local msg = string.format(msgFormat, value, playerName, eventReason)
                if SendChatMessage and IsInGuild and IsInGuild() then
                    SendChatMessage(msg, "GUILD")
                else
                    DEFAULT_CHAT_FRAME:AddMessage(msg)
                end
                -- Actualizar nota pública solo al otorgar o reducir DKP manualmente
                if DMA.Data and DMA.Data.Cache and DMA.Data.Cache.UpdatePlayerPublicNote then
                    DMA.Data.Cache.UpdatePlayerPublicNote(playerName, DMA_DB.cache[playerName] or 0)
                end
            end

            -- Clear form
            self.valueBox:SetText("0")
            self.reasonBox:SetText("")
            self.valueBox:ClearFocus()
            self.reasonBox:ClearFocus()
        end
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
