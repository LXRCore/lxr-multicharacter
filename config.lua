--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗██╗   ██╗██╗  ████████╗██╗ ██████╗██╗  ██╗ █████╗ ██████╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██║   ██║██║  ╚══██╔══╝██║██╔════╝██║  ██║██╔══██╗██╔══██╗
    ██║      ╚███╔╝ ██████╔╝█████╗██╔████╔██║██║   ██║██║     ██║   ██║██║     ███████║███████║██████╔╝
    ██║      ██╔██╗ ██╔══██╗╚════╝██║╚██╔╝██║██║   ██║██║     ██║   ██║██║     ██╔══██║██╔══██║██╔══██╗
    ███████╗██╔╝ ██╗██║  ██║      ██║ ╚═╝ ██║╚██████╔╝███████╗██║   ██║╚██████╗██║  ██║██║  ██║██║  ██║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

    🐺 LXR Core - Multicharacter Configuration

    Character slots, creation rules, the selection scene (camera, preview ped),
    the trait step behaviour and the hand-off events to the spawn / appearance
    resources. Every value a server owner may want to change lives here.
    Trait definitions (advantages, disadvantages, presets, budgets) live in
    config_traits.lua.

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

    Version: 3.0.0
    Framework Support: LXR Core v3 (Native)

    © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
]]

Config = Config or {}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SERVER BRANDING & INFO ████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.ServerInfo = {
    year = 1901,  -- "Personal file · 1901" label on the trait screen (branding itself comes from LXRCore.Brand)
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ LANGUAGE CONFIGURATION ████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Lang = 'en' -- 'en' | 'ka' (locales/*.lua). The NUI receives the same bundle.

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ CHARACTER SLOTS ███████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Characters = {
    default   = 5,   -- Slots per licence (falls back to lxr-core Config.Player.maxCharacters when nil)
    -- Per-licence overrides: ['license:xxxx'] = 8
    overrides = {},
    -- ACE-based bonus slots: players with the ace get max(default, slots)
    aceSlots  = { ['lxrcore.admin'] = 10, ['lxrcore.god'] = 20 },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ CREATION RULES (validated on the server) ██████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Creation = {
    nameMin           = 2,
    nameMax           = 20,
    namePattern       = "^[%a%s'%-]+$", -- letters, spaces, apostrophes, hyphens (Lua pattern, ASCII letters)
    allowUnicodeNames = true,           -- Accept Georgian / Cyrillic / accented names (length + blocklist only)
    birthYearMin      = 1830,
    birthYearMax      = 1889,           -- Characters must be adults in Config.ServerInfo.year
    nationalityMax    = 30,
    genders           = { [0] = 'male', [1] = 'female' },
    -- Words that may not appear in first/last names (lower-case, substring match)
    blockedWords      = { 'admin', 'moderator', 'lxrcore', 'nigger', 'faggot', 'hitler' },
    starterItems      = nil,   -- nil → LXRShared.StarterItems from lxr-core; or { { item = 'water', amount = 2 } }
    createCooldownMs  = 5000,  -- Per player, between create attempts
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ TRAIT STEP BEHAVIOUR ██████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.TraitFlow = {
    enabled          = true,   -- false → creation is identity-only (classic multicharacter)
    promptExisting   = true,   -- Characters created before this resource get the trait screen once on login
    allowRetrait     = false,  -- true → players may /retrait once per retraitCooldownDays
    retraitCooldownDays = 30,
    applyInventory   = true,   -- Apply slots_mult / weight_mult to the players.slots / players.weight columns
    applyMoveRate    = true,   -- Client applies move_rate via SetPedMoveRateOverride (per-frame only while ≠ 1)
    -- Skills tab: leftover free points become starting skill levels
    skills = {
        enabled        = true,
        list           = nil,  -- nil → lxr-core Config.Player.skills; or { 'main', 'hunting', 'fishing' }
        maxPerSkill    = 3,    -- Max starting levels per skill
        maxTotal       = 6,    -- Max levels across all skills
        pointsPerLevel = 1,    -- Free points spent per level
    },
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
    rotateStep    = 22.5,  -- Degrees per arrow press on the trait screen
    -- Fallback preview models when no appearance is stored (male, female)
    previewModels = { [0] = 'mp_male', [1] = 'mp_female' },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ INTEGRATIONS & EVENTS █████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Integrations = {
    -- Appearance resource used to preview / apply skins (must export loadSkin, loadClothes)
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
    adminAce  = 'lxrcore.admin',                   -- Ace for /resettraits and /logout
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ DEBUG SETTINGS ████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Debug = false

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ END OF CONFIGURATION ██████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
