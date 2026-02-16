-- =========================================================
-- UI: DKP CONFIG
-- =========================================================

if not DMA then return end
if not DMA.UI then DMA.UI = {} end

DMA.UI.DKPConfig = {}

local DKPConfig = DMA.UI.DKPConfig

local FRAME_WIDTH = 420
local FRAME_HEIGHT = 260

local RAID_CONFIG = {
    { key = "MC",   label = "Molten Core" },
    { key = "BWL",  label = "Blackwing Lair" },
    { key = "AQ40", label = "Ahn'Qiraj 40" },
    { key = "NAXX", label = "Naxxramas" },
}

local FIELDS = {
    { key = "bossKill",  label = "Boss Kill" },
    { key = "early",     label = "Arrive early" },
    { key = "stay",      label = "Stay in raid" },
}

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

    self.inputs = {}

    self:CreateTitle()
    self:CreateCloseButton()
    self:CreateGrid()
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

    for index, raid in ipairs(RAID_CONFIG) do
        local rowY = startY - (rowHeight * index)

        local raidLabel = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        raidLabel:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 15, rowY)
        raidLabel:SetWidth(110)
        raidLabel:SetText(raid.label)

        self.inputs[raid.key] = {}

        local function createInput(prev, width)
            local box = CreateFrame("EditBox", nil, self.frame)
            box:SetWidth(width)
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
            box:SetScript("OnEscapePressed", function(self)
                box:ClearFocus()
            end)

            if prev then
                box:SetPoint("TOPLEFT", prev, "TOPRIGHT", 10, 0)
            else
                box:SetPoint("TOPLEFT", raidLabel, "TOPRIGHT", 10, 0)
            end

            return box
        end

        local bossBox = createInput(nil, 80)
        local earlyBox = createInput(bossBox, 80)
        local stayBox  = createInput(earlyBox, 80)

        self.inputs[raid.key].bossKill = bossBox
        self.inputs[raid.key].early    = earlyBox
        self.inputs[raid.key].stay     = stayBox
    end
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

    for _, raid in ipairs(RAID_CONFIG) do
        local rKey = raid.key

        local raidData = raidDKP[rKey]
        if not raidData then
            local src = globalRaidDKP and globalRaidDKP[rKey]
            raidData = {
                bossKill = src and src.bossKill or 0,
                early    = src and src.early    or 0,
                stay     = src and src.stay     or 0,
            }
            raidDKP[rKey] = raidData
        end

        local inputs = self.inputs[rKey]
        if inputs then
            inputs.bossKill:SetText(tostring(raidData.bossKill or 0))
            inputs.early:SetText(tostring(raidData.early or 0))
            inputs.stay:SetText(tostring(raidData.stay or 0))
        end
    end
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

    for _, raid in ipairs(RAID_CONFIG) do
        local rKey = raid.key
        raidDKP[rKey] = raidDKP[rKey] or {}
        local cfg = raidDKP[rKey]
        local inputs = self.inputs[rKey]
        if inputs then
            local bossVal = tonumber(inputs.bossKill:GetText() or "0") or 0
            local earlyVal = tonumber(inputs.early:GetText() or "0") or 0
            local stayVal  = tonumber(inputs.stay:GetText() or "0") or 0

            cfg.bossKill = bossVal
            cfg.early    = earlyVal
            cfg.stay     = stayVal
        end
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
