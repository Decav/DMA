-- =========================================================
-- UI: DKP CONFIG
-- =========================================================

if not DMA then return end
if not DMA.UI then DMA.UI = {} end

DMA.UI.DKPConfig = {}

local DKPConfig = DMA.UI.DKPConfig

local FRAME_WIDTH = 450
local FRAME_HEIGHT = 450

-- Raids "por defecto" (sólo para facilitar configuración inicial).
local DEFAULT_RAIDS = {
    { key = "MC",   label = "Molten Core" },
    { key = "BWL",  label = "Blackwing Lair" },
    { key = "AQ40", label = "Ahn'Qiraj 40" },
    { key = "NAXX", label = "Naxxramas" },
}

local function GetDefaultRaidLabel(raidKey)
    for _, raid in ipairs(DEFAULT_RAIDS) do
        if raid.key == raidKey then
            return raid.label
        end
    end
    return nil
end

local function GetDefaultRaidKeyForLabel(label)
    if not label then return nil end
    local lower = string.lower(label)
    for _, raid in ipairs(DEFAULT_RAIDS) do
        if string.lower(raid.label) == lower then
            return raid.key
        end
    end
    return nil
end

local function Trim(str)
    if not str then return "" end
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

function DKPConfig:Init()
    if self.frame then return end
    if not UIParent then return end

    local frame = CreateFrame("Frame", "DMA_DKPConfigFrame", UIParent)
    frame:SetWidth(FRAME_WIDTH)
    frame:SetHeight(FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    -- Config frame is not draggable; it will be shown attached to the main frame
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

    -- Permitir cerrar con ESC
    if UISpecialFrames then
        table.insert(UISpecialFrames, "DMA_DKPConfigFrame")
    end

    self.inputs = {}              -- raids
    self.penaltyInputs = {}       -- penalizaciones unificadas (fijo y %)

    self:CreateTitle()
    self:CreateCloseButton()
    self:CreateGrid()
    self:CreatePenaltySections()
    self:CreateSaveButton()

    self:LoadFromDB()
end

function DKPConfig:CreateTitle()
    local title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", self.frame, "TOP", 0, -10)
    title:SetText("DKP Config")
    self.title = title
end

function DKPConfig:CreateCloseButton()
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

function DKPConfig:CreateGrid()
    local startY = -40
    local rowHeight = 24

    -- Guardar para construir filas dinámicas más tarde
    self.gridStartY = startY
    self.rowHeight = rowHeight

    -- Headers
    local hRaid = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hRaid:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 15, startY)
    hRaid:SetWidth(110)
    hRaid:SetText("Raid")

    local hBoss = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hBoss:SetPoint("LEFT", hRaid, "RIGHT", 10, 0)
    hBoss:SetWidth(70)
    hBoss:SetText("Boss Kill")

    local hEarly = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hEarly:SetPoint("LEFT", hBoss, "RIGHT", 10, 0)
    hEarly:SetWidth(90)
    hEarly:SetText("Arrive early")

    local hStay = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hStay:SetPoint("LEFT", hEarly, "RIGHT", 5, 0)
    hStay:SetWidth(90)
    hStay:SetText("Stay in raid")

    self.inputs = {}
    self.rowFrames = {}

    -- Contenedor con scroll para las filas de raids
    local raidScroll = CreateFrame("ScrollFrame", "DMA_DKPRaidScroll", self.frame, "UIPanelScrollFrameTemplate")
    raidScroll:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 15, startY - 20)
    raidScroll:SetPoint("RIGHT", self.frame, "RIGHT", -30, 0)
    raidScroll:SetHeight(130)

    local raidContent = CreateFrame("Frame", nil, raidScroll)
    raidContent:SetPoint("TOPLEFT", raidScroll, "TOPLEFT", 0, 0)
    raidContent:SetWidth(raidScroll:GetWidth())
    raidContent:SetHeight(1)
    raidScroll:SetScrollChild(raidContent)

    self.raidScrollFrame = raidScroll
    self.raidContent = raidContent

    -- Botón para abrir el cuadro de diálogo de añadir nuevas raids dinámicamente
    local bgr = {0.2,0.2,0.2,1}
    local bdr = {0.2,0.2,0.2,1}
    local addBtn = CreateFrame("Button", nil, self.frame)
    addBtn:SetWidth(80)
    addBtn:SetHeight(20)
    -- Colocar el botón Add Raid abajo, a la izquierda del botón Save
    addBtn:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -105, 12)
    addBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    addBtn:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    addBtn:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    addBtn.text = addBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    addBtn.text:SetPoint("CENTER", addBtn, "CENTER", 0, 0)
    addBtn.text:SetText("Add Raid")
    addBtn:SetScript("OnEnter", function() addBtn:SetBackdropColor(0.5,0.5,0.5,1) end)
    addBtn:SetScript("OnLeave", function() addBtn:SetBackdropColor(0.2,0.2,0.2,1) end)
    addBtn:SetScript("OnClick", function()
        if not self.addRaidDialog then
            self:CreateAddRaidDialog()
        end
        self.addRaidDialog:Show()
        if self.addRaidDialogEditBox then
            self.addRaidDialogEditBox:SetText("")
            self.addRaidDialogEditBox:SetFocus()
        end
    end)

    self.addRaidButton = addBtn
end

-- Secciones para configurar penalizaciones fijas y porcentuales
function DKPConfig:CreatePenaltySections()
    -- Posiciones base para la sección unificada de penalizaciones
    -- Usamos un margen izquierdo similar al de la rejilla de raids
    self.penaltyStartY = -200
    self.penaltyRowHeight = 22

    self.penaltyRows = {}

    -- Título general de penalizaciones
    local penaltyTitle = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- Alineado con el margen izquierdo de la sección de raids
    penaltyTitle:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 15, self.penaltyStartY)
    penaltyTitle:SetText("Penalties")
    self.penaltyTitle = penaltyTitle

    local nameHeader = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    -- Sin desplazamiento extra en X para que quede alineado con el título
    nameHeader:SetPoint("TOPLEFT", penaltyTitle, "BOTTOMLEFT", 0, -4)
    nameHeader:SetWidth(200)
    nameHeader:SetText("Name")

    local fixedHeader = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    -- Misma separación horizontal que las columnas de la sección de raids
    fixedHeader:SetPoint("LEFT", nameHeader, "RIGHT", 10, 0)
    fixedHeader:SetWidth(80)
    fixedHeader:SetText("Fixed")

    local percentHeader = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    percentHeader:SetPoint("LEFT", fixedHeader, "RIGHT", 10, 0)
    percentHeader:SetWidth(80)
    percentHeader:SetText("Percent")

    -- Botón único para añadir penalizaciones, abajo junto a Add Raid/Save
    local bgr = {0.2,0.2,0.2,1}
    local bdr = {0.2,0.2,0.2,1}
    local addPenaltyBtn = CreateFrame("Button", nil, self.frame)
    addPenaltyBtn:SetWidth(80)
    addPenaltyBtn:SetHeight(20)
    addPenaltyBtn:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -195, 12)
    addPenaltyBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    addPenaltyBtn:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    addPenaltyBtn:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    addPenaltyBtn.text = addPenaltyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    addPenaltyBtn.text:SetPoint("CENTER", addPenaltyBtn, "CENTER", 0, 0)
    addPenaltyBtn.text:SetText("Add Penalty")
    addPenaltyBtn:SetScript("OnEnter", function() addPenaltyBtn:SetBackdropColor(0.5,0.5,0.5,1) end)
    addPenaltyBtn:SetScript("OnLeave", function() addPenaltyBtn:SetBackdropColor(0.2,0.2,0.2,1) end)
    addPenaltyBtn:SetScript("OnClick", function()
        if not self.addPenaltyDialog then
            self:CreateAddPenaltyDialog()
        end
        self.addPenaltyDialog:Show()
        if self.addPenaltyDialogEditBox then
            self.addPenaltyDialogEditBox:SetText("")
            self.addPenaltyDialogEditBox:SetFocus()
        end
    end)
    self.addPenaltyButton = addPenaltyBtn
end

function DKPConfig:CreateSaveButton()
    local bgr = {0.2,0.2,0.2,1}
    local bdr = {0.2,0.2,0.2,1}

    local saveBtn = CreateFrame("Button", nil, self.frame)
    saveBtn:SetWidth(80)
    saveBtn:SetHeight(22)
    saveBtn:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -15, 12)
    saveBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    saveBtn:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    saveBtn:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    saveBtn.text = saveBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    saveBtn.text:SetPoint("CENTER", saveBtn, "CENTER", 0, 0)
    saveBtn.text:SetText("Save")
    saveBtn:SetScript("OnEnter", function() saveBtn:SetBackdropColor(0.5,0.5,0.5,1) end)
    saveBtn:SetScript("OnLeave", function() saveBtn:SetBackdropColor(0.2,0.2,0.2,1) end)
    saveBtn:SetScript("OnClick", function() DKPConfig:SaveToDB() end)

    self.saveButton = saveBtn
end

-- Cuadro de diálogo simple para introducir el nombre de una nueva raid
function DKPConfig:CreateAddRaidDialog()
    if self.addRaidDialog then return end

    local dlg = CreateFrame("Frame", "DMA_AddRaidDialog", self.frame)
    dlg:SetFrameStrata("DIALOG")
    dlg:SetToplevel(true)
    dlg:EnableMouse(true)
    if self.frame and self.frame.GetFrameLevel then
        dlg:SetFrameLevel(self.frame:GetFrameLevel() + 20)
    end
    dlg:SetWidth(260)
    dlg:SetHeight(90)
    dlg:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
    dlg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    dlg:SetBackdropColor(0, 0, 0, 0.95)
    dlg:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
    dlg:Hide()

    local text = dlg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOP", dlg, "TOP", 0, -8)
    text:SetText("Enter new raid name:")

    local editBox = CreateFrame("EditBox", nil, dlg)
    editBox:SetWidth(200)
    editBox:SetHeight(20)
    editBox:SetAutoFocus(true)
    editBox:SetMultiLine(false)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetTextColor(1, 1, 1)
    editBox:SetTextInsets(4, 4, 4, 4)
    editBox:SetJustifyH("LEFT")
    editBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    editBox:SetBackdropColor(0.1, 0.1, 0.1, 1)
    editBox:SetBackdropBorderColor(0, 0, 0, 1)
    editBox:SetPoint("TOP", text, "BOTTOM", 0, -8)

    local function DoAccept()
        local name = editBox:GetText() or ""
        if DKPConfig and DKPConfig.AddRaid then
            DKPConfig:AddRaid(name)
        end
        editBox:SetText("")
        dlg:Hide()
    end

    editBox:SetScript("OnEnterPressed", DoAccept)
    editBox:SetScript("OnEscapePressed", function()
        editBox:SetText("")
        dlg:Hide()
    end)

    local bgr = {0.2,0.2,0.2,1}
    local bdr = {0.2,0.2,0.2,1}

    local okBtn = CreateFrame("Button", nil, dlg)
    okBtn:SetWidth(60)
    okBtn:SetHeight(20)
    okBtn:SetPoint("BOTTOMLEFT", dlg, "BOTTOMLEFT", 25, 10)
    okBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    okBtn:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    okBtn:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    okBtn.text = okBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    okBtn.text:SetPoint("CENTER", okBtn, "CENTER", 0, 0)
    okBtn.text:SetText("OK")
    okBtn:SetScript("OnEnter", function() okBtn:SetBackdropColor(0.5,0.5,0.5,1) end)
    okBtn:SetScript("OnLeave", function() okBtn:SetBackdropColor(0.2,0.2,0.2,1) end)
    okBtn:SetScript("OnClick", DoAccept)

    local cancelBtn = CreateFrame("Button", nil, dlg)
    cancelBtn:SetWidth(60)
    cancelBtn:SetHeight(20)
    cancelBtn:SetPoint("BOTTOMRIGHT", dlg, "BOTTOMRIGHT", -25, 10)
    cancelBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    cancelBtn:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    cancelBtn:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    cancelBtn.text = cancelBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cancelBtn.text:SetPoint("CENTER", cancelBtn, "CENTER", 0, 0)
    cancelBtn.text:SetText("Cancel")
    cancelBtn:SetScript("OnEnter", function() cancelBtn:SetBackdropColor(0.5,0.5,0.5,1) end)
    cancelBtn:SetScript("OnLeave", function() cancelBtn:SetBackdropColor(0.2,0.2,0.2,1) end)
    cancelBtn:SetScript("OnClick", function()
        editBox:SetText("")
        dlg:Hide()
    end)

    self.addRaidDialog = dlg
    self.addRaidDialogEditBox = editBox
end

-- Diálogo para añadir penalización (nombre; los valores fijo y % se editan en la tabla)
function DKPConfig:CreateAddPenaltyDialog()
    if self.addPenaltyDialog then return end

    local dlg = CreateFrame("Frame", "DMA_AddPenaltyDialog", self.frame)
    dlg:SetFrameStrata("DIALOG")
    dlg:SetToplevel(true)
    dlg:EnableMouse(true)
    if self.frame and self.frame.GetFrameLevel then
        dlg:SetFrameLevel(self.frame:GetFrameLevel() + 20)
    end
    dlg:SetWidth(260)
    dlg:SetHeight(90)
    dlg:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
    dlg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    dlg:SetBackdropColor(0, 0, 0, 0.95)
    dlg:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
    dlg:Hide()

    local text = dlg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOP", dlg, "TOP", 0, -8)
    text:SetText("Enter penalty name:")

    local editBox = CreateFrame("EditBox", nil, dlg)
    editBox:SetWidth(200)
    editBox:SetHeight(20)
    editBox:SetAutoFocus(true)
    editBox:SetMultiLine(false)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetTextColor(1, 1, 1)
    editBox:SetTextInsets(4, 4, 4, 4)
    editBox:SetJustifyH("LEFT")
    editBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    editBox:SetBackdropColor(0.1, 0.1, 0.1, 1)
    editBox:SetBackdropBorderColor(0, 0, 0, 1)
    editBox:SetPoint("TOP", text, "BOTTOM", 0, -8)

    local function DoAccept()
        local name = editBox:GetText() or ""
        if DKPConfig and DKPConfig.AddPenalty then
            DKPConfig:AddPenalty(name)
        end
        editBox:SetText("")
        dlg:Hide()
    end

    editBox:SetScript("OnEnterPressed", DoAccept)
    editBox:SetScript("OnEscapePressed", function()
        editBox:SetText("")
        dlg:Hide()
    end)

    local bgr = {0.2,0.2,0.2,1}
    local bdr = {0.2,0.2,0.2,1}

    local okBtn = CreateFrame("Button", nil, dlg)
    okBtn:SetWidth(60)
    okBtn:SetHeight(20)
    okBtn:SetPoint("BOTTOMLEFT", dlg, "BOTTOMLEFT", 25, 10)
    okBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    okBtn:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    okBtn:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    okBtn.text = okBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    okBtn.text:SetPoint("CENTER", okBtn, "CENTER", 0, 0)
    okBtn.text:SetText("OK")
    okBtn:SetScript("OnEnter", function() okBtn:SetBackdropColor(0.5,0.5,0.5,1) end)
    okBtn:SetScript("OnLeave", function() okBtn:SetBackdropColor(0.2,0.2,0.2,1) end)
    okBtn:SetScript("OnClick", DoAccept)

    local cancelBtn = CreateFrame("Button", nil, dlg)
    cancelBtn:SetWidth(60)
    cancelBtn:SetHeight(20)
    cancelBtn:SetPoint("BOTTOMRIGHT", dlg, "BOTTOMRIGHT", -25, 10)
    cancelBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    cancelBtn:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
    cancelBtn:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
    cancelBtn.text = cancelBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cancelBtn.text:SetPoint("CENTER", cancelBtn, "CENTER", 0, 0)
    cancelBtn.text:SetText("Cancel")
    cancelBtn:SetScript("OnEnter", function() cancelBtn:SetBackdropColor(0.5,0.5,0.5,1) end)
    cancelBtn:SetScript("OnLeave", function() cancelBtn:SetBackdropColor(0.2,0.2,0.2,1) end)
    cancelBtn:SetScript("OnClick", function()
        editBox:SetText("")
        dlg:Hide()
    end)

    self.addPenaltyDialog = dlg
    self.addPenaltyDialogEditBox = editBox
end

-- Elimina todas las filas actuales de la rejilla y limpia inputs
function DKPConfig:ClearRows()
    if self.rowFrames then
        for _, widget in ipairs(self.rowFrames) do
            if widget.Hide then
                widget:Hide()
            end
        end
    end
    self.rowFrames = {}
    self.inputs = {}
end

-- Construye las filas de raids a partir de la tabla raidDKP
function DKPConfig:BuildRows(raidDKP)
    self:ClearRows()

    if not raidDKP then return end

    local keys = {}
    for raidKey, _ in pairs(raidDKP) do
        table.insert(keys, raidKey)
    end
    table.sort(keys, function(a, b)
        a = string.lower(tostring(a or ""))
        b = string.lower(tostring(b or ""))
        return a < b
    end)

    local rowHeight = self.rowHeight or 24

    local parent = self.raidContent or self.frame

    local function createInput(prev, anchorLabel)
        local box = CreateFrame("EditBox", nil, parent)
        box:SetWidth(80)
        box:SetHeight(18)
        box:SetAutoFocus(false)
        box:SetMultiLine(false)
        box:SetFontObject(GameFontHighlightSmall)
        box:SetTextColor(1, 1, 1)
        box:SetTextInsets(4, 4, 4, 4)
        box:SetJustifyH("CENTER")
        box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        box:SetBackdropColor(0.1, 0.1, 0.1, 1)
        box:SetBackdropBorderColor(0, 0, 0, 1)
        box:SetNumeric(true)
        box:SetMaxLetters(4)
        box:SetScript("OnEscapePressed", function()
            box:ClearFocus()
        end)

        if prev then
            box:SetPoint("TOPLEFT", prev, "TOPRIGHT", 10, 0)
        else
            box:SetPoint("TOPLEFT", anchorLabel, "TOPRIGHT", 10, 0)
        end

        table.insert(self.rowFrames, box)
        return box
    end

    for index, raidKey in ipairs(keys) do
        local cfg = raidDKP[raidKey] or {}
        local rowY = - (rowHeight * (index - 1))

        local raidLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        raidLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, rowY)
        raidLabel:SetWidth(110)
        raidLabel:SetText(GetDefaultRaidLabel(raidKey) or tostring(raidKey))
        table.insert(self.rowFrames, raidLabel)

        self.inputs[raidKey] = {}

        local bossBox = createInput(nil, raidLabel)
        local earlyBox = createInput(bossBox, raidLabel)
        local stayBox  = createInput(earlyBox, raidLabel)

        bossBox:SetText(tostring(cfg.bossKill or 0))
        earlyBox:SetText(tostring(cfg.early or 0))
        stayBox:SetText(tostring(cfg.stay or 0))

        self.inputs[raidKey].bossKill = bossBox
        self.inputs[raidKey].early    = earlyBox
        self.inputs[raidKey].stay     = stayBox

        -- Botón para eliminar esta raid
        local delBtn = CreateFrame("Button", nil, parent)
        delBtn:SetWidth(18)
        delBtn:SetHeight(18)
        delBtn:SetPoint("LEFT", stayBox, "RIGHT", 6, 0)
        delBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        delBtn:SetBackdropColor(0.2,0.2,0.2,1)
        delBtn:SetBackdropBorderColor(0.4,0.1,0.1,1)
        delBtn.text = delBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        delBtn.text:SetPoint("CENTER", delBtn, "CENTER", 0, 0)
        delBtn.text:SetText("X")
        delBtn:SetScript("OnEnter", function() delBtn:SetBackdropColor(0.5,0.2,0.2,1) end)
        delBtn:SetScript("OnLeave", function() delBtn:SetBackdropColor(0.2,0.2,0.2,1) end)
        -- Capturar la clave de esta iteración en una variable local para evitar
        -- el típico problema de cierre sobre la variable del bucle.
        local keyForButton = raidKey
        delBtn:SetScript("OnClick", function()
            DKPConfig:DeleteRaid(keyForButton)
        end)
        table.insert(self.rowFrames, delBtn)
    end

    -- Ajustar altura del contenido del scroll
    if self.raidContent then
        local totalHeight = table.getn(keys) * rowHeight
        if totalHeight < 1 then totalHeight = 1 end
        self.raidContent:SetHeight(totalHeight)
        if self.raidScrollFrame and self.raidScrollFrame.UpdateScrollChildRect then
            self.raidScrollFrame:UpdateScrollChildRect()
        end
    end
end

-- =========================================================
-- Penalizaciones unificadas (valor fijo y porcentual)
-- =========================================================

function DKPConfig:ClearPenaltyRows()
    if self.penaltyRows then
        for _, w in ipairs(self.penaltyRows) do
            if w.Hide then w:Hide() end
        end
    end
    self.penaltyRows = {}
    self.penaltyInputs = {}
end

function DKPConfig:BuildPenaltyRows(penalties)
    self:ClearPenaltyRows()
    if not penalties then return end

    local keys = {}
    for key, _ in pairs(penalties) do
        table.insert(keys, key)
    end
    table.sort(keys, function(a, b)
        return string.lower(tostring(a or "")) < string.lower(tostring(b or ""))
    end)

    local rowHeight = self.penaltyRowHeight or 22

    -- Dibujar directamente sobre el frame principal (sin scroll para asegurar visibilidad)
    local parent = self.frame
    -- Margen izquierdo consistente con el header Name
    local startX = 15

    for index, key in ipairs(keys) do
        local cfg = penalties[key] or {}
        -- Un poco por debajo de los headers de penalizaciones
        local startY = (self.penaltyStartY or -200) - 32
        local rowY = startY - (rowHeight * (index - 1))

        local label = cfg.label or tostring(key)
        local fixedVal = cfg.fixed or cfg.value or 0
        local percentVal = cfg.percent or 0

        -- Nombre fijo (no editable), usando el mismo font que las raids
        local nameLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", startX, rowY)
        nameLabel:SetWidth(200)
        nameLabel:SetJustifyH("LEFT")
        nameLabel:SetText(label)
        table.insert(self.penaltyRows, nameLabel)

        -- Valor fijo
        local fixedBox = CreateFrame("EditBox", nil, parent)
        fixedBox:SetWidth(80)
        fixedBox:SetHeight(18)
        fixedBox:SetAutoFocus(false)
        fixedBox:SetMultiLine(false)
        fixedBox:SetFontObject(GameFontHighlightSmall)
        fixedBox:SetTextColor(1, 1, 1)
        fixedBox:SetTextInsets(4, 4, 4, 4)
        fixedBox:SetJustifyH("CENTER")
        fixedBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        fixedBox:SetBackdropColor(0.1, 0.1, 0.1, 1)
        fixedBox:SetBackdropBorderColor(0, 0, 0, 1)
        fixedBox:SetNumeric(true)
        fixedBox:SetMaxLetters(5)
        fixedBox:SetScript("OnEscapePressed", function() fixedBox:ClearFocus() end)
        fixedBox:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
        fixedBox:SetText(tostring(fixedVal or 0))
        table.insert(self.penaltyRows, fixedBox)

        -- Valor porcentual
        local percentBox = CreateFrame("EditBox", nil, parent)
        percentBox:SetWidth(80)
        percentBox:SetHeight(18)
        percentBox:SetAutoFocus(false)
        percentBox:SetMultiLine(false)
        percentBox:SetFontObject(GameFontHighlightSmall)
        percentBox:SetTextColor(1, 1, 1)
        percentBox:SetTextInsets(4, 4, 4, 4)
        percentBox:SetJustifyH("CENTER")
        percentBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        percentBox:SetBackdropColor(0.1, 0.1, 0.1, 1)
        percentBox:SetBackdropBorderColor(0, 0, 0, 1)
        percentBox:SetNumeric(true)
        percentBox:SetMaxLetters(3)
        percentBox:SetScript("OnEscapePressed", function() percentBox:ClearFocus() end)
        percentBox:SetPoint("LEFT", fixedBox, "RIGHT", 10, 0)
        percentBox:SetText(tostring(percentVal or 0))
        table.insert(self.penaltyRows, percentBox)

        -- Botón eliminar
        local delBtn = CreateFrame("Button", nil, parent)
        delBtn:SetWidth(18)
        delBtn:SetHeight(18)
        delBtn:SetPoint("LEFT", percentBox, "RIGHT", 6, 0)
        delBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        delBtn:SetBackdropColor(0.2,0.2,0.2,1)
        delBtn:SetBackdropBorderColor(0.4,0.1,0.1,1)
        delBtn.text = delBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        delBtn.text:SetPoint("CENTER", delBtn, "CENTER", 0, 0)
        delBtn.text:SetText("X")
        delBtn:SetScript("OnEnter", function() delBtn:SetBackdropColor(0.5,0.2,0.2,1) end)
        delBtn:SetScript("OnLeave", function() delBtn:SetBackdropColor(0.2,0.2,0.2,1) end)
        local k = key
        delBtn:SetScript("OnClick", function()
            DKPConfig:DeletePenalty(k)
        end)
        table.insert(self.penaltyRows, delBtn)

        self.penaltyInputs[key] = {
            label = label,
            fixedBox = fixedBox,
            percentBox = percentBox,
        }
    end

    -- Sin scroll adicional: el contenido se pinta directamente y siempre es visible
end

function DKPConfig:AddPenalty(name)
    name = Trim(name)
    if name == "" then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("DMA: Penalty name cannot be empty")
        end
        return
    end

    if not DMA.Data or not DMA.Data.Database or not DMA.Data.Database.GetDB then
        return
    end

    local db = DMA.Data.Database:GetDB()
    db.config = db.config or {}
    db.guilds = db.guilds or {}
    local guildKey = DMA.Data.Database:GetCurrentGuildKey()
    if not guildKey then return end
    db.guilds[guildKey] = db.guilds[guildKey] or {}

    local guildData = db.guilds[guildKey]
    guildData.config = guildData.config or {}
    guildData.config.penalties = guildData.config.penalties or {}

    local penalties = guildData.config.penalties
    local key = name
    if penalties[key] then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("DMA: Penalty already exists: " .. tostring(name))
        end
        return
    end

    penalties[key] = { label = name, fixed = 0, percent = 0 }
    self:BuildPenaltyRows(penalties)
end

function DKPConfig:DeletePenalty(key)
    if not key then return end
    if not DMA.Data or not DMA.Data.Database or not DMA.Data.Database.GetDB then
        return
    end

    local db = DMA.Data.Database:GetDB()
    db.config = db.config or {}
    db.guilds = db.guilds or {}
    local guildKey = DMA.Data.Database:GetCurrentGuildKey()
    if not guildKey then return end
    db.guilds[guildKey] = db.guilds[guildKey] or {}

    local guildData = db.guilds[guildKey]
    guildData.config = guildData.config or {}
    guildData.config.penalties = guildData.config.penalties or {}

    local penalties = guildData.config.penalties
    if not penalties[key] then return end

    penalties[key] = nil
    self:BuildPenaltyRows(penalties)
end

function DKPConfig:AddRaid(name)
    name = Trim(name)
    if name == "" then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("DMA: Raid name cannot be empty")
        end
        return
    end

    if not DMA.Data or not DMA.Data.Database or not DMA.Data.Database.GetDB then
        return
    end

    local db = DMA.Data.Database:GetDB()
    db.config = db.config or {}
    db.guilds = db.guilds or {}
    local guildKey = DMA.Data.Database:GetCurrentGuildKey()
    if not guildKey then
        return
    end
    db.guilds[guildKey] = db.guilds[guildKey] or {}

    local guildData = db.guilds[guildKey]
    guildData.config = guildData.config or {}
    guildData.config.raidDKP = guildData.config.raidDKP or {}

    local raidDKP = guildData.config.raidDKP

    -- Si el nombre coincide con una raid por defecto, usar su key clásica
    local key = GetDefaultRaidKeyForLabel(name) or name

    if raidDKP[key] then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("DMA: Raid already exists: " .. tostring(name))
        end
        return
    end

    raidDKP[key] = { bossKill = 0, early = 0, stay = 0 }
    self:BuildRows(raidDKP)
end

function DKPConfig:DeleteRaid(raidKey)
    if not raidKey then return end
    if not DMA.Data or not DMA.Data.Database or not DMA.Data.Database.GetDB then
        return
    end

    local db = DMA.Data.Database:GetDB()
    db.config = db.config or {}
    db.guilds = db.guilds or {}
    local guildKey = DMA.Data.Database:GetCurrentGuildKey()
    if not guildKey then
        return
    end
    db.guilds[guildKey] = db.guilds[guildKey] or {}

    local guildData = db.guilds[guildKey]
    guildData.config = guildData.config or {}
    guildData.config.raidDKP = guildData.config.raidDKP or {}

    local raidDKP = guildData.config.raidDKP
    if not raidDKP[raidKey] then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("DMA: Raid not found to delete: " .. tostring(raidKey))
        end
        return
    end

    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("DMA: Deleting raid config for " .. tostring(raidKey))
    end
    raidDKP[raidKey] = nil
    self:BuildRows(raidDKP)
end

function DKPConfig:LoadFromDB()
    if not DMA.Data or not DMA.Data.Database or not DMA.Data.Database.GetDB then
        return
    end

    local db = DMA.Data.Database:GetDB()
    db.config = db.config or {}

    -- Configuración por hermandad/personaje
    db.guilds = db.guilds or {}
    local guildKey = DMA.Data.Database:GetCurrentGuildKey()
    if not guildKey then
        return
    end
    db.guilds[guildKey] = db.guilds[guildKey] or {}

    local guildData = db.guilds[guildKey]
    guildData.config = guildData.config or {}
    guildData.config.raidDKP = guildData.config.raidDKP or {}

    local raidDKP = guildData.config.raidDKP
    local globalRaidDKP = db.config.raidDKP -- para migrar valores antiguos globales, si existen

    -- Migración única desde la config global antigua: si no hay ninguna raid
    -- configurada aún para esta hermandad pero sí existen datos globales,
    -- copiamos esos valores y luego limpiamos la config global.
    if (not next(raidDKP)) and globalRaidDKP then
        for rKey, src in pairs(globalRaidDKP) do
            raidDKP[rKey] = {
                bossKill = src.bossKill or 0,
                early    = src.early    or 0,
                stay     = src.stay     or 0,
            }
        end
        -- Evitar que en futuros /rl se vuelvan a recrear raids borradas.
        db.config.raidDKP = nil
    end

    -- Construir filas dinámicamente según raidDKP
    self:BuildRows(raidDKP)

    -- Penalizaciones unificadas (migración desde estructuras antiguas si hace falta)
    guildData.config.penalties = guildData.config.penalties or {}

    -- Si la lista nueva está vacía pero existen estructuras viejas, migramos
    if not next(guildData.config.penalties) then
        local hadOld = false

        if guildData.config.fixedPenalties then
            for key, cfg in pairs(guildData.config.fixedPenalties) do
                local entry = guildData.config.penalties[key] or {}
                entry.label = cfg.label or entry.label or tostring(key)
                entry.fixed = cfg.value or entry.fixed or 0
                entry.percent = entry.percent or 0
                guildData.config.penalties[key] = entry
                hadOld = true
            end
        end

        if guildData.config.percentPenalties then
            for key, cfg in pairs(guildData.config.percentPenalties) do
                local entry = guildData.config.penalties[key] or {}
                entry.label = cfg.label or entry.label or tostring(key)
                entry.percent = cfg.percent or entry.percent or 0
                entry.fixed = entry.fixed or 0
                guildData.config.penalties[key] = entry
                hadOld = true
            end
        end

        if hadOld then
            -- Limpiar las estructuras antiguas para no seguir duplicando datos
            guildData.config.fixedPenalties = nil
            guildData.config.percentPenalties = nil
        end
    end

    self:BuildPenaltyRows(guildData.config.penalties)
end

function DKPConfig:SaveToDB()
    if not DMA.Data or not DMA.Data.Database or not DMA.Data.Database.GetDB then
        return
    end

    local db = DMA.Data.Database:GetDB()
    db.config = db.config or {}

    -- Configuración por hermandad/personaje
    db.guilds = db.guilds or {}
    local guildKey = DMA.Data.Database:GetCurrentGuildKey()
    if not guildKey then
        return
    end
    db.guilds[guildKey] = db.guilds[guildKey] or {}

    local guildData = db.guilds[guildKey]
    guildData.config = guildData.config or {}
    guildData.config.raidDKP = guildData.config.raidDKP or {}

    local raidDKP = guildData.config.raidDKP

    -- Volcar todos los valores visibles en la UI sobre raidDKP.
    for raidKey, inputs in pairs(self.inputs) do
        raidDKP[raidKey] = raidDKP[raidKey] or {}
        local cfg = raidDKP[raidKey]

        local bossVal = tonumber(inputs.bossKill:GetText() or "0") or 0
        local earlyVal = tonumber(inputs.early:GetText() or "0") or 0
        local stayVal  = tonumber(inputs.stay:GetText() or "0") or 0

        cfg.bossKill = bossVal
        cfg.early    = earlyVal
        cfg.stay     = stayVal
    end

    -- Guardar penalizaciones unificadas (fijo + %)
    guildData.config.penalties = guildData.config.penalties or {}
    -- Limpiamos primero para reflejar exactamente lo que hay en la UI
    for k in pairs(guildData.config.penalties) do
        guildData.config.penalties[k] = nil
    end

    for key, boxes in pairs(self.penaltyInputs or {}) do
        local label = boxes.label or tostring(key)
        local fixedVal = tonumber(boxes.fixedBox:GetText() or "0") or 0
        local percentVal = tonumber(boxes.percentBox:GetText() or "0") or 0
        guildData.config.penalties[key] = {
            label = label,
            fixed = fixedVal,
            percent = percentVal,
        }
    end

    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("DMA: DKP config saved")
    end
end

function DKPConfig:Show()
    if not self.frame then
        self:Init()
    end

    self:LoadFromDB()
    -- If main frame exists, attach to its left side; otherwise center
    if DMA.UI and DMA.UI.MainFrame and DMA.UI.MainFrame.frame then
        self.frame:ClearAllPoints()
        self.frame:SetPoint("TOPRIGHT", DMA.UI.MainFrame.frame, "TOPLEFT", -10, 0)
    end

    self.frame:Show()
end

function DKPConfig:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function DKPConfig:Toggle()
    if not self.frame then
        self:Init()
    end

    if self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end
