-- =========================================================
-- UI: MINIMAP BUTTON
-- =========================================================

if not DMA then DMA = {} end
if not DMA.UI then DMA.UI = {} end

DMA.UI.MinimapButton = {}

local MinimapButton = DMA.UI.MinimapButton

function MinimapButton:Init()
	if self.button or not Minimap then
		return
	end

	local button = CreateFrame("Button", "DMA_MinimapButton", Minimap)
	button:SetWidth(32)
	button:SetHeight(32)

	-- Posición por defecto: esquina superior izquierda del minimapa
	button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)

	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)

	-- Fondo y borde tipo minimap button clásico
	local overlay = button:CreateTexture(nil, "OVERLAY")
	overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	overlay:SetWidth(54)
	overlay:SetHeight(54)
	overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

	local icon = button:CreateTexture(nil, "BACKGROUND")
	-- Icono genérico tipo moneda para representar DKP
	icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
	icon:SetWidth(20)
	icon:SetHeight(20)
	icon:SetPoint("CENTER", button, "CENTER", 0, 0)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")

	-- Tooltip sencillo (Vanilla no pasa self al handler, usamos el botón cerrado)
	button:SetScript("OnEnter", function()
		if GameTooltip and button:IsVisible() then
			GameTooltip:SetOwner(button, "ANCHOR_LEFT")
			GameTooltip:SetText("DMA - DKP Manager", 1, 1, 1)
			GameTooltip:AddLine("Click: abrir/cerrar ventana DMA", 0.8, 0.8, 0.8)
			GameTooltip:Show()
		end
	end)

	button:SetScript("OnLeave", function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)

	-- Click: alternar ventana principal de DMA
	button:SetScript("OnClick", function()
		if DMA and DMA.UI and DMA.UI.MainFrame and DMA.UI.MainFrame.Toggle then
			DMA.UI.MainFrame:Toggle()
		elseif DEFAULT_CHAT_FRAME then
			DEFAULT_CHAT_FRAME:AddMessage("DMA: Ventana principal no disponible (/dma)")
		end
	end)

	self.button = button
end

