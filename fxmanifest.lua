--[[
    ██╗     ██╗  ██╗██████╗        ██╗   ██╗██╗   ██╗██╗  ████████╗██╗ ██████╗██╗  ██╗ █████╗ ██████╗
    ██║     ╚██╗██╔╝██╔══██╗       ███╗ ███║██║   ██║██║  ╚══██╔══╝██║██╔════╝██║  ██║██╔══██╗██╔══██╗
    ██║      ╚███╔╝ ██████╔╝ █████╗██╔████╔██║██║ ██║██║     ██║   ██║██║     ███████║███████║██████╔╝
    ██║      ██╔██╗ ██╔══██╗ ╚════╝██║╚██╔╝██║██║ ██║██║     ██║   ██║██║     ██╔══██║██╔══██║██╔══██╗
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║╚██████╔╝███████╗██║ ██║╚██████╗██║  ██║██║  ██║██║  ██║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝ ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

    🐺 LXR Multicharacter System - FiveM Resource Manifest

    ═══════════════════════════════════════════════════════════════════════════════
    RESOURCE INFORMATION
    ═══════════════════════════════════════════════════════════════════════════════

    Resource Name:  lxr-multicharacter
    Version:        1.0.1
    Author:         iBoss21 / The Lux Empire
    Description:    Multi-framework multicharacter system for RedM — the gateway
                    to limitless roleplay potential on The Land of Wolves.

    Server:         The Land of Wolves 🐺
    Website:        https://www.wolves.land
    Discord:        https://discord.gg/CrKcWdfd3A
    Store:          https://theluxempire.tebex.io

    ═══════════════════════════════════════════════════════════════════════════════
    FRAMEWORK SUPPORT
    ═══════════════════════════════════════════════════════════════════════════════

    Primary:
    - LXR Core (lxr-core)
    - RSG Core (rsg-core)

    Supported:
    - VORP Core (vorp_core)

    ═══════════════════════════════════════════════════════════════════════════════

    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
]]

fx_version 'cerulean'
game 'rdr3'

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

-- Resource Metadata
name 'LXR Multicharacter System'
author 'iBoss21 / The Lux Empire'
description 'Multi-framework multicharacter system — the gateway to limitless roleplay potential'
version '1.0.1'

-- Lua 5.4
lua54 'yes'

-- Shared Scripts
shared_script 'config.lua'

-- Client Scripts
client_script 'client/main.lua'

-- Server Scripts
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

-- NUI
ui_page 'html/index.html'

-- NUI Files
files {
    'html/index.html',
    'html/style.css',
    'html/reset.css',
    'html/profanity.js',
    'html/script.js'
}

-- Dependencies
dependencies {
    'lxr-core',
    'lxr-spawn'
}
