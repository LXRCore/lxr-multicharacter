--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗██╗   ██╗██╗  ████████╗██╗ ██████╗██╗  ██╗ █████╗ ██████╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██║   ██║██║  ╚══██╔══╝██║██╔════╝██║  ██║██╔══██╗██╔══██╗
    ██║      ╚███╔╝ ██████╔╝█████╗██╔████╔██║██║   ██║██║     ██║   ██║██║     ███████║███████║██████╔╝
    ██║      ██╔██╗ ██╔══██╗╚════╝██║╚██╔╝██║██║   ██║██║     ██║   ██║██║     ██╔══██║██╔══██║██╔══██╗
    ███████╗██╔╝ ██╗██║  ██║      ██║ ╚═╝ ██║╚██████╔╝███████╗██║   ██║╚██████╗██║  ██║██║  ██║██║  ██║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

    🐺 LXR Core - Multicharacter & Character Traits — Resource Manifest

    The first screen a player sees on wolves.land. Lists the characters on a
    licence, previews their appearance, creates new characters through a
    three-step "personal file" (identity → character & life experience →
    skills), validates every choice on the server and hands the loaded
    character to the spawn / appearance resources.

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
    Performance Target: 0.00 ms idle (no loops once a character is loaded)

    Framework Support:
    - LXR Core v3 (Native — GetCoreObject)

    ═══════════════════════════════════════════════════════════════════════════════
    CREDITS
    ═══════════════════════════════════════════════════════════════════════════════

    Script Author: iBoss21 / LXRCore

    © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
]]

fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'lxr-multicharacter'
author 'iBoss21 / LXRCore'
description 'LXRCore v3 character selection, creation and character traits (advantages / disadvantages / skills)'
version '3.0.0'
repository 'https://github.com/LXRCore/lxr-multicharacter'

shared_scripts {
    'shared/locale.lua',
    'locales/*.lua',
    'config.lua',
    'config_traits.lua',
    'shared/traits.lua',
}

client_scripts {
    'client/main.lua',
    'client/effects.lua',
}

server_scripts {
    'server/traits.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/lxr-ui.css',
    'html/style.css',
    'html/fonts/*.woff2',
    'html/app.js',
    'html/img/*.png',
}

dependency 'lxr-core'
