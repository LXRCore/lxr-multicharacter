--[[ ═══════════════════════════════════════════════════════════════════════════
     🐺 LXR-MULTICHARACTER — Trait Effects (client)
     ═══════════════════════════════════════════════════════════════════════════
     Reads the replicated `traits` state bag the server publishes after a
     character loads and applies what this resource can apply natively:
       • move_rate  → SetPedMoveRateOverride, per frame but ONLY while ≠ 1.0
     Everything else is exposed to other client resources through exports and
     the 'lxr-multicharacter:client:traitsApplied' event (see docs/TRAITS.md).
     ═══════════════════════════════════════════════════════════════════════════
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local current = nil       -- { perks, flaws, mods } or nil
local moveLoop = false

local function startMoveLoop(rate)
    if moveLoop then return end
    moveLoop = true
    CreateThread(function()
        while moveLoop do
            local t = current
            local r = t and t.mods and tonumber(t.mods.move_rate) or 1.0
            if not Config.TraitFlow.applyMoveRate or r == 1.0 then break end
            local ped = PlayerPedId()
            if not IsPedOnMount(ped) and not IsPedInAnyVehicle(ped, false) then
                SetPedMoveRateOverride(ped, r)
            end
            Wait(0)
        end
        moveLoop = false
    end)
end

local function apply(t)
    current = t
    if t and t.mods and Config.TraitFlow.applyMoveRate and tonumber(t.mods.move_rate or 1.0) ~= 1.0 then
        startMoveLoop(t.mods.move_rate)
    end
    TriggerEvent('lxr-multicharacter:client:traitsApplied', t and t.mods or nil, t and t.perks or {}, t and t.flaws or {})
end

AddStateBagChangeHandler('traits', nil, function(bagName, _, value)
    if bagName ~= ('player:%d'):format(GetPlayerServerId(PlayerId())) then return end
    apply(type(value) == 'table' and value or nil)
end)

RegisterNetEvent('lxr-multicharacter:client:traitsLocked', function(perks, flaws, mods)
    apply({ perks = perks or {}, flaws = flaws or {}, mods = mods or {} })
end)

RegisterNetEvent('lxr-multicharacter:client:traitsReset', function() apply(nil) end)

AddEventHandler('LXRCore:Client:OnPlayerUnload', function() apply(nil) end)

-- Resource restarted mid-session: pick up the state bag that is already there
CreateThread(function()
    Wait(1000)
    local t = LocalPlayer.state.traits
    if type(t) == 'table' then apply(t) end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📤 EXPORTS (client)
-- ═══════════════════════════════════════════════════════════════════════════════

exports('GetTraits', function() return current end)

exports('HasTrait', function(id)
    if not current then return false end
    for _, v in ipairs(current.perks or {}) do if v == id then return true end end
    for _, v in ipairs(current.flaws or {}) do if v == id then return true end end
    return false
end)

exports('GetModifier', function(key, default)
    local v = current and current.mods and current.mods[key]
    if v == nil then return default end
    return v
end)
