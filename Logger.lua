-- =========================================================
-- UTILS: LOGGER
-- =========================================================

if not DMA then return end
if not DMA.Utils then DMA.Utils = {} end

DMA.Utils.Logger = {}

local Logger = DMA.Utils.Logger

-- Log levels
Logger.LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    NONE = 5
}

-- Current log level
Logger.currentLevel = Logger.LEVELS.INFO

-- Log destinations
Logger.DESTINATIONS = {
    CHAT = "chat",
    CONSOLE = "console",
    FILE = "file" -- Not available in Vanilla
}

-- Set log level
function Logger:SetLevel(level)
    if type(level) == "string" then
        level = Logger.LEVELS[level:upper()]
    end

    if level and level >= Logger.LEVELS.DEBUG and level <= Logger.LEVELS.NONE then
        self.currentLevel = level
    end
end

-- Get current level name
function Logger:GetLevelName(level)
    for name, value in pairs(self.LEVELS) do
        if value == level then
            return name
        end
    end
    return "UNKNOWN"
end

-- Format log message
function Logger:FormatMessage(level, message)
    local timestamp = date("%H:%M:%S")
    local levelName = self:GetLevelName(level)
    local formatted = string.format("[%s] DMA %s: %s", timestamp, levelName, message)
    return formatted
end

-- Log to chat frame
function Logger:LogToChat(level, message)
    if level < self.currentLevel then return end

    local formatted = self:FormatMessage(level, message)
    DEFAULT_CHAT_FRAME:AddMessage(formatted)
end

-- Log to console (for debugging)
function Logger:LogToConsole(level, message)
    if level < self.currentLevel then return end

    local formatted = self:FormatMessage(level, message)
    -- In Vanilla, console logging is limited, but we can try
    if Console then
        Console:AddMessage(formatted)
    end
end

-- Main logging function
function Logger:Log(level, message)
    self:LogToChat(level, message)
    self:LogToConsole(level, message)
end

-- Convenience methods
function Logger:Debug(message)
    self:Log(self.LEVELS.DEBUG, message)
end

function Logger:Info(message)
    self:Log(self.LEVELS.INFO, message)
end

function Logger:Warn(message)
    self:Log(self.LEVELS.WARN, message)
end

function Logger:Error(message)
    self:Log(self.LEVELS.ERROR, message)
end

-- Log with context
function Logger:LogWithContext(level, context, message)
    local contextMsg = string.format("[%s] %s", context, message)
    self:Log(level, contextMsg)
end

-- Log event creation
function Logger:LogEvent(event, action)
    if not event then return end

    local msg = string.format("Event %s: %s by %s for %s (%d DKP) - %s",
        action or "processed",
        event.type,
        event.master,
        event.players,
        event.value,
        event.reason or "No reason"
    )
    self:Info(msg)
end

-- Log DKP change
function Logger:LogDKPChange(player, oldDKP, newDKP, reason)
    local change = newDKP - oldDKP
    local changeStr = change >= 0 and "+" .. change or change

    local msg = string.format("DKP %s: %s (%d → %d) - %s",
        change >= 0 and "gained" or "lost",
        player,
        oldDKP,
        newDKP,
        reason or "No reason"
    )
    self:Info(msg)
end

-- Log permission change
function Logger:LogPermissionChange(player, granted, master)
    local msg = string.format("Permission %s: %s %s DKP Master status (by %s)",
        granted and "granted" or "revoked",
        granted and "to" or "from",
        player,
        master or "system"
    )
    self:Info(msg)
end

-- Log sync event
function Logger:LogSync(eventId, source, success)
    local msg = string.format("Sync %s: Event %s from %s",
        success and "success" or "failed",
        eventId,
        source
    )
    self:Info(msg)
end

-- Initialize logger
function Logger:Init()
    -- Set default level based on debug mode
    if DMA_DEBUG then
        self:SetLevel(self.LEVELS.DEBUG)
    else
        -- En modo normal, solo mostrar avisos y errores para no
        -- llenar el chat con mensajes informativos.
        self:SetLevel(self.LEVELS.WARN)
    end
end

