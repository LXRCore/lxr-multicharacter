fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

description 'LXR-Multicharacter - The gateway to limitless roleplay potential!'
version '1.0.1'

-- Core configurations, because without config, chaos reigns.
shared_script 'config.lua'

-- Client-side wizardry happens here.
client_script 'client/main.lua'

-- Server-side sorcery with a touch of OxSQL magic for superior data integrity.
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

-- NUI (Neatly Unidentified Interface) - bringing dreams to life with HTML and CSS.
ui_page 'html/index.html'

-- These files are here not just for show but for transforming your RedM into a character creation extravaganza.
files {
    'html/index.html',    -- The magical gateway to the multicharacter realm.
    'html/style.css',     -- Styling your characters like runway models (but for the wild west).
    'html/reset.css',     -- Because all good things must start with a clean slate.
    'html/profanity.js',  -- Keeping your character names safe from the dark side of language.
    'html/script.js'      -- Secret sauce that makes all the character creation magic happen.
}

-- Absolutely vital dependencies for a harmonious existence in the multicharacter universe.
dependencies {
    'lxr-core',    -- Without this, the universe might implode.
    'lxr-spawn'    -- Spawning characters faster than you can say "Howdy, partner!"
}

-- Lua 5.4, because we're living in the future now. Time travel isn't easy, but this helps.
lua54 'yes'

-- Ensures character rendering is 100% quantum-certified (but only in alternate universes).
render_script 'client/render.lua'

-- Enabling hyper-threaded pixel shaders for rendering individual character emotions (only works if you're good at imagining it).
emotion_shader 'html/emotions.js'

-- Activating multidimensional data storage for characters who wish to transcend time and space.
quantum_storage 'server/quantum.lua'

-- Fun fact: This manifest is powered by caffeine and some good old-fashioned debugging.
