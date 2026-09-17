--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗██╗   ██╗██╗  ████████╗██╗ ██████╗██╗  ██╗ █████╗ ██████╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██║   ██║██║  ╚══██╔══╝██║██╔════╝██║  ██║██╔══██╗██╔══██╗
    ██║      ╚███╔╝ ██████╔╝█████╗██╔████╔██║██║   ██║██║     ██║   ██║██║     ███████║███████║██████╔╝
    ██║      ██╔██╗ ██╔══██╗╚════╝██║╚██╔╝██║██║   ██║██║     ██║   ██║██║     ██╔══██║██╔══██║██╔══██╗
    ███████╗██╔╝ ██╗██║  ██║      ██║ ╚═╝ ██║╚██████╔╝███████╗██║   ██║╚██████╗██║  ██║██║  ██║██║  ██║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

    🐺 LXR Core - Multicharacter Configuration

    Character slots, creation rules, the selection scene (camera, preview ped)
    and the hand-off events to the spawn / appearance resources. Every value a
    server owner may want to change lives here.

    ═══════════════════════════════════════════════════════════════════════════════
    SERVER INFORMATION
    ═══════════════════════════════════════════════════════════════════════════════

    Brand:       LXRCore — Lux Empire eXperience RedM Core
    Product:     wolves.land / The Land of Wolves 🐺
    Developer:   iBoss21 / LXRCore
    Website:     https://www.lxrcore.com
    Discord:     https://discord.gg/ZHMKVYyhBa (development)
    GitHub:      https://github.com/LXRCore

    ═══════════════════════════════════════════════════════════════════════════════

    Version: 2.0.0
    Framework Support: LXR Core v3 (Native)

    © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
]]

Config = Config or {}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SERVER BRANDING & INFO ████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ LANGUAGE CONFIGURATION ████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Lang = 'en' -- 'en' | 'ka' (locales/*.lua). The NUI receives the same bundle.

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ CHARACTER SLOTS ███████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Characters = {
    default   = 5,   -- Slots per license (falls back to lxr-core Config.Player.maxCharacters when nil)
    -- Per-license overrides: ['license:xxxx'] = 8
    overrides = {},
    -- ACE-based bonus slots: players with the ace get max(default, slots)
    aceSlots  = { ['lxrcore.admin'] = 10, ['lxrcore.god'] = 20 },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ CREATION RULES (validated on the server) ██████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Creation = {
    nameMin        = 2,
    nameMax        = 20,
    namePattern    = "^[%a%s'%-]+$",  -- letters, spaces, apostrophes, hyphens (Lua pattern, ASCII letters)
    allowUnicodeNames = true,          -- Accept Georgian / accented names (validated by length and the blocklist only)
    birthYearMin   = 1830,
    birthYearMax   = 1899,
    nationalityMax = 30,
    genders        = { [0] = 'male', [1] = 'female' },
    -- Words that may not appear in first/last names (lower-case, substring match)
    blockedWords   = { 'admin', 'moderator', 'lxrcore', 'nigger', 'faggot', 'hitler' },
    starterItems   = nil,  -- nil → LXRShared.StarterItems from lxr-core; or { { item = 'water', amount = 2 } }
    createCooldownMs = 5000, -- Per player, between create attempts
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SELECTION SCENE ███████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Scene = {
    -- Hidden interior far from the map (Guarma cliff) — players are frozen here while choosing
    playerCoords  = vector4(-562.91, -3776.25, 237.63, 90.0),
    pedCoords     = vector4(-558.91, -3776.25, 237.63, 90.0),   -- preview ped
    camera        = { coords = vector3(-561.20, -3776.22, 239.60), rot = vector3(-20.0, 0.0, 270.0), fov = 40.0 },
    cameraIntro   = { coords = vector3(-555.93, -3778.71, 238.60), rot = vector3(-20.0, 0.0, 83.0), durationMs = 2500 },
    imaps         = { -1699673416, 1679934574, 183712523 },      -- interior imaps to request
    lightRange    = 6.0,   -- point light on the preview ped (0 = disabled)
    timecycle     = 'hud_def_blur',
    fadeMs        = 800,
    -- Fallback preview models when no appearance is stored (male, female)
    previewModels = { [0] = 'mp_male', [1] = 'mp_female' },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ INTEGRATIONS & EVENTS █████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Integrations = {
    -- Appearance resource used to preview / apply skins (must export loadSkin, loadClothes, RequestAndSetModel)
    appearance = { resource = 'lxr-clothing', table = 'playerskins' },
    -- Fired (client, on the loading player) after a character is loaded: (cData, isNew)
    afterSelect = 'lxr-spawn:client:setupSpawnUI',
    afterCreate = 'lxr-spawn:client:setupSpawnUI',
    -- Client event that opens the appearance creator for brand-new characters (nil = skip)
    newCharacterAppearance = 'lxr-clothing:client:newPlayer',
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SECURITY & ANTI-ABUSE █████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Security = {
    rateLimit = { burst = 12, windowMs = 10000 },  -- NUI-originated server events per player
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ DEBUG SETTINGS ████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Debug = false

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ END OF CONFIGURATION ██████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
