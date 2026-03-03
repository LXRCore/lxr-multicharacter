--[[
    ██╗     ██╗  ██╗██████╗        ██╗   ██╗██╗   ██╗██╗  ████████╗██╗ ██████╗██╗  ██╗ █████╗ ██████╗
    ██║     ╚██╗██╔╝██╔══██╗       ███╗ ███║██║   ██║██║  ╚══██╔══╝██║██╔════╝██║  ██║██╔══██╗██╔══██╗
    ██║      ╚███╔╝ ██████╔╝ █████╗██╔████╔██║██║ ██║██║     ██║   ██║██║     ███████║███████║██████╔╝
    ██║      ██╔██╗ ██╔══██╗ ╚════╝██║╚██╔╝██║██║ ██║██║     ██║   ██║██║     ██╔══██║██╔══██║██╔══██╗
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║╚██████╔╝███████╗██║ ██║╚██████╗██║  ██║██║  ██║██║  ██║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝ ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

    🐺 LXR Multicharacter System — Configuration

    This configuration file controls the multicharacter selection system for RedM.
    Players can create, select, and delete characters through an NUI interface.

    ═══════════════════════════════════════════════════════════════════════════════
    SERVER INFORMATION
    ═══════════════════════════════════════════════════════════════════════════════

    Server:      The Land of Wolves 🐺
    Developer:   iBoss21 / The Lux Empire
    Website:     https://www.wolves.land
    Discord:     https://discord.gg/CrKcWdfd3A
    GitHub:      https://github.com/iBoss21
    Store:       https://theluxempire.tebex.io

    ═══════════════════════════════════════════════════════════════════════════════

    Version: 1.0.1
    Performance Target: Optimized for minimal server overhead and client FPS impact

    Framework Support:
    - LXR Core (Primary)
    - RSG Core (Compatible)
    - VORP Core (Compatible)

    ═══════════════════════════════════════════════════════════════════════════════
    CREDITS
    ═══════════════════════════════════════════════════════════════════════════════

    Script Author: iBoss21 / The Lux Empire for The Land of Wolves

    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
]]

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🐺 RESOURCE NAME PROTECTION - RUNTIME CHECK
-- ═══════════════════════════════════════════════════════════════════════════════

local REQUIRED_RESOURCE_NAME = "lxr-multicharacter"
local currentResourceName = GetCurrentResourceName()

if currentResourceName ~= REQUIRED_RESOURCE_NAME then
    error(string.format([[

        ═══════════════════════════════════════════════════════════════════════════════
        ❌ CRITICAL ERROR: RESOURCE NAME MISMATCH ❌
        ═══════════════════════════════════════════════════════════════════════════════

        Expected: %s
        Got: %s

        This resource is branded and must maintain the correct name.
        Rename the folder to "%s" to continue.

        🐺 wolves.land - The Land of Wolves

        ═══════════════════════════════════════════════════════════════════════════════

    ]], REQUIRED_RESOURCE_NAME, currentResourceName, REQUIRED_RESOURCE_NAME))
end

Config = {}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SERVER BRANDING & INFO ████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.ServerInfo = {
    name = 'The Land of Wolves 🐺',
    developer = 'iBoss21 / The Lux Empire',
    website = 'https://www.wolves.land',
    discord = 'https://discord.gg/CrKcWdfd3A',
    github = 'https://github.com/iBoss21',
    store = 'https://theluxempire.tebex.io',
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ FRAMEWORK CONFIGURATION ███████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

--[[
    Framework Priority (in order):
    1. LXR-Core  (Primary)
    2. RSG-Core  (Primary)
    3. VORP Core (Supported)
]]

Config.Framework = 'lxr-core' -- 'lxr-core', 'rsg-core', 'vorp_core'

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SPAWN CONFIGURATION ███████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

-- Enable/Disable starting apartments feature
-- If disabled, characters will spawn at the default location (Config.DefaultSpawn)
Config.StartingApartment = false

-- Coordinates for character preview screen (interior)
-- This is where the interior is loaded, and characters are previewed.
Config.Interior = vector3(-814.89, 181.95, 76.85)

-- Default spawn location coordinates if starting apartments are disabled
Config.DefaultSpawn = vector3(-1035.71, -2731.87, 12.86)

-- Ped (character) coordinates for the preview screen
Config.PedCoords = vector4(-813.97, 176.22, 76.74, -7.5)

-- Coordinates to hide the actual player ped while in character selection mode
Config.HiddenCoords = vector4(-812.23, 182.54, 76.74, 156.5)

-- Camera coordinates for character preview screen
Config.CamCoords = vector4(-813.46, 178.95, 76.85, 174.5)

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ CHARACTER LIMITS ██████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

-- Default maximum number of characters a player can create
Config.DefaultNumberOfCharacters = 5

-- Optional: Define the number of characters for specific players by their Rockstar license
Config.PlayersNumberOfCharacters = {
    { license = "license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", numberOfChars = 2 },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ RANDOM SPAWN CONFIGURATION ████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

-- Enable/Disable random spawn locations upon character creation or respawn
Config.RandomSpawnsEnabled = true

-- List of random spawn locations (coordinates and optional heading for direction)
Config.RandomSpawnLocations = {
    { coords = vector4(-1044.71, -2745.87, 12.86, 180.0) }, -- Beach area
    { coords = vector4(425.10, -806.20, 29.49, 90.0) },     -- City square
    { coords = vector4(-500.34, 52.54, 52.38, 0.0) },       -- Quiet neighborhood
    { coords = vector4(200.12, 6600.45, 31.87, 270.0) },    -- Countryside
    { coords = vector4(-1600.13, -300.85, 50.65, 45.0) },   -- Hilltop location
}

-- Function to select a random spawn location from the list
function Config.GetRandomSpawnLocation()
    local spawnCount = #Config.RandomSpawnLocations
    if spawnCount > 0 then
        local randomIndex = math.random(1, spawnCount)
        return Config.RandomSpawnLocations[randomIndex].coords
    else
        return Config.DefaultSpawn
    end
end
