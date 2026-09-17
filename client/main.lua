--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗██╗   ██╗██╗  ████████╗██╗ ██████╗██╗  ██╗ █████╗ ██████╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██║   ██║██║  ╚══██╔══╝██║██╔════╝██║  ██║██╔══██╗██╔══██╗
    ██║      ╚███╔╝ ██████╔╝█████╗██╔████╔██║██║   ██║██║     ██║   ██║██║     ███████║███████║██████╔╝
    ██║      ██╔██╗ ██╔══██╗╚════╝██║╚██╔╝██║██║   ██║██║     ██║   ██║██║     ██╔══██║██╔══██║██╔══██╗
    ███████╗██╔╝ ██╗██║  ██║      ██║ ╚═╝ ██║╚██████╔╝███████╗██║   ██║╚██████╗██║  ██║██║  ██║██║  ██║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

    🐺 LXR Core - Multicharacter Client

    Owns the selection scene (camera, hidden interior, preview ped) and the NUI.
    It never decides anything: every button press is relayed to the server,
    which validates and answers. Once a character is loaded the resource is
    idle (0.00 ms) until /logout re-opens the scene.

    Developer:   iBoss21 / LXRCore
    Website:     https://www.lxrcore.com
    © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
]]

local LXRCore = exports['lxr-core']:GetCoreObject()

local state = {
    open = false,
    cam = nil,
    introCam = nil,
    ped = nil,
    previewToken = 0,
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🎥 SCENE
-- ═══════════════════════════════════════════════════════════════════════════════

local function appearance()
    local res = Config.Integrations.appearance and Config.Integrations.appearance.resource
    if res and GetResourceState(res) == 'started' then return exports[res] end
    return nil
end

local function deletePreview()
    if state.ped and DoesEntityExist(state.ped) then
        SetEntityAsMissionEntity(state.ped, true, true)
        DeleteEntity(state.ped)
    end
    state.ped = nil
end

local function destroyCams()
    RenderScriptCams(false, false, 0, true, true)
    if state.cam then DestroyCam(state.cam, true) end
    if state.introCam then DestroyCam(state.introCam, true) end
    state.cam, state.introCam = nil, nil
    SetTimecycleModifier('default')
end

local function setupCams()
    local s = Config.Scene
    state.introCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(state.introCam, s.cameraIntro.coords.x, s.cameraIntro.coords.y, s.cameraIntro.coords.z)
    SetCamRot(state.introCam, s.cameraIntro.rot.x, s.cameraIntro.rot.y, s.cameraIntro.rot.z, 2)
    SetCamFov(state.introCam, s.camera.fov)
    SetCamActive(state.introCam, true)
    RenderScriptCams(true, false, 0, true, true)

    state.cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(state.cam, s.camera.coords.x, s.camera.coords.y, s.camera.coords.z)
    SetCamRot(state.cam, s.camera.rot.x, s.camera.rot.y, s.camera.rot.z, 2)
    SetCamFov(state.cam, s.camera.fov)
    SetCamActiveWithInterp(state.cam, state.introCam, s.cameraIntro.durationMs, 1, 1)
    if s.timecycle and s.timecycle ~= '' then
        SetTimecycleModifier(s.timecycle)
        SetTimecycleModifierStrength(0.6)
    end
end

local function loadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    if not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local tries = 0
    while not HasModelLoaded(hash) and tries < 300 do Wait(10) tries = tries + 1 end
    return HasModelLoaded(hash) and hash or nil
end

---Spawn the preview ped for a character (or a default model). Token guards
---against a slower callback overwriting a newer selection.
local function preview(citizenid, gender)
    state.previewToken = state.previewToken + 1
    local token = state.previewToken
    deletePreview()

    local data
    if citizenid then
        data = LXRCore.Callback.Await('lxr-multicharacter:server:appearance', citizenid)
    end
    if token ~= state.previewToken or not state.open then return end

    local s = Config.Scene
    local model = (data and data.model) or s.previewModels[tonumber(gender) or 0] or 'mp_male'
    local hash = loadModel(model)
    if not hash then return end
    local ped = CreatePed(hash, s.pedCoords.x, s.pedCoords.y, s.pedCoords.z, s.pedCoords.w, false, false, false, false)
    SetModelAsNoLongerNeeded(hash)
    if token ~= state.previewToken then DeleteEntity(ped) return end
    state.ped = ped
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true) -- SetRandomOutfitVariation
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    local tries = 0
    while not Citizen.InvokeNative(0xA0BC8FAED8CFEB3C, ped) and tries < 100 do Wait(10) tries = tries + 1 end -- IsPedReadyToRender
    local app = appearance()
    if app and data then
        pcall(function()
            if data.skin then app:loadSkin(ped, data.skin, false) end
            if data.clothes then app:loadClothes(ped, data.clothes, false) end
        end)
    end
end

local function sceneLoop()
    CreateThread(function()
        local s = Config.Scene
        while state.open do
            Wait(0)
            Citizen.InvokeNative(0xF1622CE88A1946FB) -- hide HUD this frame
            if s.lightRange and s.lightRange > 0 and state.ped and DoesEntityExist(state.ped) then
                local c = GetEntityCoords(state.ped)
                DrawLightWithRange(c.x, c.y, c.z + 1.0, 255, 235, 200, s.lightRange, 40.0)
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🪟 OPEN / CLOSE
-- ═══════════════════════════════════════════════════════════════════════════════

local function sendCharacters()
    local payload = LXRCore.Callback.Await('lxr-multicharacter:server:characters')
    if not payload then
        SendNUIMessage({ action = 'error', message = 'Could not load characters' })
        return
    end
    SendNUIMessage({ action = 'characters', characters = payload.characters, max = payload.max, locale = payload.locale, server = payload.server })
    local first = payload.characters[1]
    if first then preview(first.citizenid, first.gender) else preview(nil, 0) end
end

local function openScene()
    if state.open then return end
    state.open = true
    local s = Config.Scene
    local ped = PlayerPedId()
    DoScreenFadeOut(200)
    Wait(250)
    for _, imap in ipairs(s.imaps or {}) do RequestImap(imap) end
    SetEntityVisible(ped, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, s.playerCoords.x, s.playerCoords.y, s.playerCoords.z, false, false, false, false)
    SetEntityHeading(ped, s.playerCoords.w)
    Wait(600)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    setupCams()
    sceneLoop()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    DoScreenFadeIn(s.fadeMs or 800)
    sendCharacters()
end

local function closeScene()
    if not state.open then return end
    state.open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    deletePreview()
    destroyCams()
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📡 EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════

RegisterNetEvent('lxr-multicharacter:client:open', function() CreateThread(openScene) end)
RegisterNetEvent('lxr-multicharacter:client:chooseChar', function() CreateThread(openScene) end) -- legacy name
RegisterNetEvent('lxr-multicharacter:client:closeUI', function() closeScene() end)
RegisterNetEvent('lxr-multicharacter:client:closeNUI', function() closeScene() end)             -- legacy name
RegisterNetEvent('lxr-multicharacter:client:refresh', function() if state.open then CreateThread(sendCharacters) end end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🖱 NUI CALLBACKS — relay only
-- ═══════════════════════════════════════════════════════════════════════════════

RegisterNUICallback('preview', function(data, cb)
    cb({})
    if not state.open then return end
    CreateThread(function() preview(data and data.citizenid or nil, data and data.gender or 0) end)
end)

RegisterNUICallback('select', function(data, cb)
    cb({})
    if not state.open or type(data) ~= 'table' or type(data.citizenid) ~= 'string' then return end
    DoScreenFadeOut(300)
    TriggerServerEvent('lxr-multicharacter:server:select', data.citizenid)
end)

RegisterNUICallback('create', function(data, cb)
    cb({})
    if not state.open or type(data) ~= 'table' then return end
    TriggerServerEvent('lxr-multicharacter:server:create', {
        firstname = data.firstname, lastname = data.lastname, birthdate = data.birthdate,
        gender = tonumber(data.gender) or 0, nationality = data.nationality,
    })
end)

RegisterNUICallback('delete', function(data, cb)
    cb({})
    if not state.open or type(data) ~= 'table' or type(data.citizenid) ~= 'string' then return end
    TriggerServerEvent('lxr-multicharacter:server:delete', data.citizenid)
end)

RegisterNUICallback('disconnect', function(_, cb)
    cb({})
    TriggerServerEvent('lxr-multicharacter:server:disconnect')
end)

RegisterNUICallback('refresh', function(_, cb)
    cb({})
    if state.open then CreateThread(sendCharacters) end
end)

-- After a character loads the spawn resource fades the screen back in; if no
-- spawn resource is installed, do it here so the player is never stuck black.
AddEventHandler('LXRCore:Client:OnPlayerLoaded', function()
    closeScene()
    SetTimeout(1500, function()
        if IsScreenFadedOut() then DoScreenFadeIn(500) end
    end)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    closeScene()
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🚀 BOOT — wait for the session once, then open; no loop afterwards
-- ═══════════════════════════════════════════════════════════════════════════════

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(250) end
    if LocalPlayer.state.isLoggedIn then return end -- resource restarted mid-session
    Wait(500)
    openScene()
end)
