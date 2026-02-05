-- =========================================================
-- UTILS: CONSTANTS
-- =========================================================

if not DMA then return end
if not DMA.Utils then DMA.Utils = {} end

DMA.Utils.Constants = {}

local Constants = DMA.Utils.Constants

-- Communication
Constants.COMM_PREFIX = "DMA_DKP"
Constants.COMM_DELIMITER = "|"

-- Event Types
Constants.EVENT_TYPES = {
    RAID_START = "raid_start",
    BOSS_KILL = "boss_kill",
    RAID_END = "raid_end",
    AUCTION_WIN = "auction_win",
    MANUAL_ADJUST = "manual_adjust"
}

-- Legacy constants (for compatibility)
Constants.EVENT_ADD = "ADD"
Constants.EVENT_SUB = "SUB"

-- UI Constants
Constants.UI = {
    FRAME_WIDTH = 600,
    FRAME_HEIGHT = 450,
    ENTRY_HEIGHT = 20,
    MAX_VISIBLE_ENTRIES = 15,
    SCROLL_FRAME_WIDTH = 560,
    SCROLL_FRAME_HEIGHT = 330
}

-- DKP Constants
Constants.DKP = {
    DEFAULT_RAID_START = 10,
    DEFAULT_BOSS_KILL = 5,
    DEFAULT_RAID_END = 15,
    MIN_DKP_VALUE = -999,
    MAX_DKP_VALUE = 999
}

-- Time Constants
Constants.TIME = {
    EVENT_EXPIRY_DAYS = 365,
    MAX_EVENT_AGE_SECONDS = 86400, -- 24 hours
    CACHE_REBUILD_INTERVAL = 300   -- 5 minutes
}

-- Permission Levels
Constants.PERMISSIONS = {
    NONE = 0,
    PLAYER = 1,
    DKP_MASTER = 2,
    ADMIN = 3
}

-- Colors (for UI)
Constants.COLORS = {
    POSITIVE_DKP = {r = 0, g = 1, b = 0},      -- Green
    NEGATIVE_DKP = {r = 1, g = 0, b = 0},      -- Red
    NEUTRAL_DKP = {r = 1, g = 1, b = 1},       -- White
    MASTER_TEXT = {r = 1, g = 0.8, b = 0},     -- Gold
    ERROR_TEXT = {r = 1, g = 0.2, b = 0.2},    -- Red
    SUCCESS_TEXT = {r = 0.2, g = 1, b = 0.2}   -- Green
}

-- Default Settings
Constants.DEFAULTS = {
    SETTINGS = {
        master = "",
        enabled = true,
        historyRetentionDays = 365,
        autoSync = true
    },
    PERMISSIONS = {
        dkpMasters = {}
    }
}

-- Error Messages
Constants.ERRORS = {
    NO_PERMISSION = "No DKP Master permissions",
    INVALID_MASTER = "Invalid DKP Master",
    EVENT_EXISTS = "Event already exists",
    INVALID_EVENT = "Invalid event data",
    NETWORK_ERROR = "Network communication failed",
    DB_ERROR = "Database error"
}

-- Success Messages
Constants.SUCCESS = {
    EVENT_CREATED = "DKP event created",
    EVENT_SYNCED = "Event synchronized",
    PERMISSION_GRANTED = "DKP Master permission granted",
    CACHE_REBUILT = "DKP cache rebuilt"
}

DEFAULT_CHAT_FRAME:AddMessage("DMA: Constants module loaded")
