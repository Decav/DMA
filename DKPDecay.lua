-- =========================================================
-- CORE: DKP DECAY
-- =========================================================

if not DMA then return end
if not DMA.Core then DMA.Core = {} end

DMA.Core.DKPDecay = {}

local DKPDecay = DMA.Core.DKPDecay

local function Print(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("DMA: " .. msg)
	end
end

-- Lee todos los miembros de la hermandad desde el roster, forzando a mostrar desconectados
local function CollectGuildPlayersFromRoster()
	local result = {}
	if not GetNumGuildMembers or not GetGuildRosterInfo then
		return result
	end

	local prevShowOffline = nil
	if GetGuildRosterShowOffline and SetGuildRosterShowOffline then
		prevShowOffline = GetGuildRosterShowOffline()
		SetGuildRosterShowOffline(1)
	end

	if GuildRoster then GuildRoster() end

	local numMembers = GetNumGuildMembers() or 0
	for i = 1, numMembers do
		local name, _, _, _, _, _, note = GetGuildRosterInfo(i)
		if name then
			name = string.gsub(name, "-.*", "")
			local dkp = 0
			if note and note ~= "" then
				dkp = tonumber(note) or 0
			end
			table.insert(result, { name = name, dkp = dkp })
		end
	end

	if prevShowOffline ~= nil and SetGuildRosterShowOffline then
		SetGuildRosterShowOffline(prevShowOffline)
	end

	return result
end

-- Devuelve una lista de objetivos de decay con old/new DKP y delta
function DKPDecay:GetDecayTargets()
	local playersByDKP = CollectGuildPlayersFromRoster() or {}
	local targets = {}

	for _, info in ipairs(playersByDKP) do
		local name = info.name
		local oldDKP = info.dkp or 0

		if oldDKP >= 1 then
			local newDKP = math.ceil(oldDKP * 0.75)
			if newDKP ~= oldDKP then
				table.insert(targets, {
					name = name,
					oldDKP = oldDKP,
					newDKP = newDKP,
					delta = newDKP - oldDKP
				})
			end
		end
	end

	return targets
end

-- Aplica un decay del 25% a todos los miembros de la hermandad
-- que tengan 1 DKP o más (según la nota pública),
-- redondeando SIEMPRE hacia arriba.
function DKPDecay:ApplyDecay()
	-- Validar que estamos en hermandad
	if not IsInGuild or not IsInGuild() or not GetGuildInfo or not GetGuildInfo("player") then
		Print("No estás en una hermandad; no se puede aplicar DKP Decay.")
		return
	end

	-- Validar permisos para editar nota pública (mismo criterio que DKP Master)
	if not CanEditPublicNote or CanEditPublicNote() ~= 1 then
		Print("No tienes permiso para editar la nota pública; no se puede aplicar DKP Decay.")
		return
	end

	if not DMA.Data or not DMA.Data.EventManager or not DMA.Data.Database then
		Print("Módulos de datos no disponibles para aplicar DKP Decay.")
		return
	end

	local targets = self:GetDecayTargets()
	if table.getn(targets) == 0 then
		Print("No se aplicó DKP Decay; ningún jugador con DKP >= 1 tuvo cambios.")
		return
	end

	local master = UnitName("player") or "?"
	local decayedCount = 0

	for _, t in ipairs(targets) do
		local name = t.name
		local oldDKP = t.oldDKP or 0
		local newDKP = t.newDKP or 0
		local delta = t.delta or 0

		-- Sincronizar cache con el valor actual antes del evento
		if not DMA_DB.cache then DMA_DB.cache = {} end
		DMA_DB.cache[name] = oldDKP

		local event = DMA.Data.EventManager:CreateEvent(
			DMA.Utils.Constants.EVENT_TYPES.MANUAL_ADJUST,
			name,
			delta,
			"Monthly DKP Decay 25%",
			master
		)

		if event then
			DMA.Data.Database:AddEvent(event)

			-- Actualizar nota pública al nuevo DKP
			if DMA.Data.Cache and DMA.Data.Cache.UpdatePlayerPublicNote then
				DMA.Data.Cache.UpdatePlayerPublicNote(name, newDKP)
			end

			decayedCount = decayedCount + 1
		end
	end

	if decayedCount > 0 then
		Print("DKP Decay del 25% aplicado a " .. decayedCount .. " jugadores (DKP >= 1).")
		-- Aviso general por hermandad (sin detallar jugadores)
		if SendChatMessage and IsInGuild and IsInGuild() then
			SendChatMessage("Se ha aplicado el DKP Decay mensual del 25% a los miembros de la hermandad.", "GUILD")
		end
		-- Refrescar ventana principal si está abierta
		if DMA.UI and DMA.UI.MainFrame then
			DMA.UI.MainFrame:RefreshPlayerList()
		end
	else
		Print("No se aplicó DKP Decay; ningún jugador con DKP >= 1 tuvo cambios.")
	end
end

