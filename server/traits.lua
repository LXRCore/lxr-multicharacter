--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗██╗   ██╗██╗  ████████╗██╗ ██████╗██╗  ██╗ █████╗ ██████╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██║   ██║██║  ╚══██╔══╝██║██╔════╝██║  ██║██╔══██╗██╔══██╗
    ██║      ╚███╔╝ ██████╔╝█████╗██╔████╔██║██║   ██║██║     ██║   ██║██║     ███████║███████║██████╔╝
    ██║      ██╔██╗ ██╔══██╗╚════╝██║╚██╔╝██║██║   ██║██║     ██║   ██║██║     ██╔══██║██╔══██║██╔══██╗
    ███████╗██╔╝ ██╗██║  ██║      ██║ ╚═╝ ██║╚██████╔╝███████╗██║   ██║╚██████╗██║  ██║██║  ██║██║  ██║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

    🐺 LXR Core - Multicharacter — Character Traits (server)

    Owns everything about traits after the NUI sends ids: validation through
    the shared engine, persistence in players.metadata.traits, the concrete
    effects this resource can apply itself (inventory capacity, starting skill
    XP) and the published modifier table other resources consume through the
    replicated state bag and the exports documented in docs/API.md.

    Developer:   iBoss21 / LXRCore
    Website:     https://www.lxrcore.com
    © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
]]

local LXRCore = exports['lxr-core']:GetCoreObject()

MC = MC or {}
MC.Traits = {}

local TRAITS_VERSION = 1
local validPresets = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🧭 HELPERS
-- ═══════════════════════════════════════════════════════════════════════════════

local function skillList()
    local list = Config.TraitFlow.skills.list or LXRCore.Config.Player.skills or {}
    return list
end

local function skillRules() return Config.TraitFlow.skills end

local function stored(Player)
    local md = Player and Player.PlayerData and Player.PlayerData.metadata
    local t = md and md.traits
    return type(t) == 'table' and t or nil
end

local function publish(src, record)
    local state = Player(src).state
    if record and record.locked then
        state:set('traits', { perks = record.perks, flaws = record.flaws, mods = record.mods or {} }, true)
    else
        state:set('traits', nil, true)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📦 NUI PAYLOAD — definitions with localized text
-- ═══════════════════════════════════════════════════════════════════════════════

local function describe(def)
    local fx = {}
    for i = 1, tonumber(def.effects) or 0 do fx[i] = Lang:t(('traits.%s.fx%d'):format(def.id, i)) end
    return {
        id = def.id, kind = def.kind, category = def.category, icon = def.icon,
        points = def.points, conflicts = def.conflicts or {}, requires = def.requires or {},
        name = Lang:t('traits.' .. def.id .. '.name'),
        tag = Lang:t('traits.' .. def.id .. '.tag'),
        effects = fx,
        categoryLabel = Lang:t('traits.cat.' .. def.category),
        order = Traits.CategoryOrder(def.category),
    }
end

function MC.Traits.Payload()
    local perks, flaws = {}, {}
    for _, def in ipairs(ConfigTraits.Perks) do perks[#perks + 1] = describe(Traits.Get(def.id)) end
    for _, def in ipairs(ConfigTraits.Flaws) do flaws[#flaws + 1] = describe(Traits.Get(def.id)) end
    local presets = {}
    for _, p in ipairs(validPresets) do
        presets[#presets + 1] = {
            id = p.id, label = Lang:t('traits.preset.' .. p.id .. '.name'), desc = Lang:t('traits.preset.' .. p.id .. '.desc'),
            perks = p.perks, flaws = Traits.WithLinkedFlaws(p.perks, p.flaws), skills = p.skills or {},
        }
    end
    local skills = {}
    if Config.TraitFlow.skills.enabled then
        for _, s in ipairs(skillList()) do skills[#skills + 1] = { id = s, label = Lang:t('skills.' .. s) } end
    end
    return {
        enabled = Config.TraitFlow.enabled,
        rules = ConfigTraits.Rules,
        skillRules = { enabled = Config.TraitFlow.skills.enabled, maxPerSkill = Config.TraitFlow.skills.maxPerSkill, maxTotal = Config.TraitFlow.skills.maxTotal, pointsPerLevel = Config.TraitFlow.skills.pointsPerLevel },
        perks = perks, flaws = flaws, presets = presets, skills = skills,
        year = Config.ServerInfo.year,
    }
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ✅ VALIDATE & APPLY
-- ═══════════════════════════════════════════════════════════════════════════════

---Validate a raw NUI selection. Returns the cleaned summary or nil + error key.
function MC.Traits.Validate(selection)
    if not Config.TraitFlow.enabled then
        return { selection = { perks = {}, flaws = {}, skills = {} }, cost = 0, refund = 0, free = 0 }
    end
    local ok, err, summary = Traits.Validate(selection, skillList(), skillRules())
    if not ok then return nil, err end
    return summary
end

---Persist a validated summary on a loaded player and apply concrete effects.
---@param Player table  LXRCore player object
---@param summary table from MC.Traits.Validate
---@param reason string 'create' | 'existing' | 'retrait'
function MC.Traits.Apply(Player, summary, reason)
    local src = Player.PlayerData.source
    local sel = summary.selection
    local mods = Traits.Modifiers(sel)
    local record = {
        version = TRAITS_VERSION, locked = true, lockedAt = os.time(), reason = reason,
        perks = sel.perks, flaws = sel.flaws, skills = sel.skills, mods = mods,
        points = { base = ConfigTraits.Rules.basePoints, cost = summary.cost, refund = summary.refund, skills = summary.skillCost, free = summary.free },
    }
    Player.Functions.SetMetaData('traits', record)

    -- Inventory capacity: written to the players.slots / players.weight columns the core already persists
    if Config.TraitFlow.applyInventory then
        local baseSlots = tonumber(LXRCore.Config.Player.maxSlots) or Player.PlayerData.slots or 40
        local baseWeight = tonumber(LXRCore.Config.Player.maxWeight) or Player.PlayerData.weight or 120000
        Player.Functions.SetPlayerData('slots', math.floor(baseSlots * (mods.slots_mult or 1.0) + 0.5))
        Player.Functions.SetPlayerData('weight', math.floor(baseWeight * (mods.weight_mult or 1.0) + 0.5))
    end

    -- Starting skill levels → XP through the core so levels/xp stay consistent
    local xpPerLevel = tonumber(LXRCore.Config.Player.xpPerLevel) or 50
    for skill, levels in pairs(sel.skills or {}) do
        local current = tonumber(Player.PlayerData.metadata.xp and Player.PlayerData.metadata.xp[skill]) or 0
        local target = levels * xpPerLevel
        if target > current then Player.Functions.AddXp(skill, target - current) end
    end

    Player.Functions.Save()
    publish(src, record)
    TriggerClientEvent('lxr-multicharacter:client:traitsLocked', src, record.perks, record.flaws, mods)
    TriggerEvent('lxr-multicharacter:server:traitsLocked', src, Player.PlayerData.citizenid, record)
    LXRCore.Log.info('multicharacter', 'traits locked', { source = src, citizenid = Player.PlayerData.citizenid, reason = reason, perks = table.concat(sel.perks, ','), flaws = table.concat(sel.flaws, ',') })
    return record
end

---Clear traits (admin / retrait). Inventory capacity returns to core defaults.
function MC.Traits.Reset(Player, by)
    local src = Player.PlayerData.source
    local old = stored(Player)
    Player.Functions.SetMetaData('traits', { version = TRAITS_VERSION, locked = false, resetAt = os.time(), resetBy = by, previous = old and { perks = old.perks, flaws = old.flaws } or nil })
    if Config.TraitFlow.applyInventory then
        Player.Functions.SetPlayerData('slots', tonumber(LXRCore.Config.Player.maxSlots) or Player.PlayerData.slots)
        Player.Functions.SetPlayerData('weight', tonumber(LXRCore.Config.Player.maxWeight) or Player.PlayerData.weight)
    end
    Player.Functions.Save()
    publish(src, nil)
    TriggerClientEvent('lxr-multicharacter:client:traitsReset', src)
    LXRCore.Log.info('multicharacter', 'traits reset', { source = src, citizenid = Player.PlayerData.citizenid, by = by })
end

function MC.Traits.NeedsPrompt(Player)
    if not Config.TraitFlow.enabled or not Config.TraitFlow.promptExisting then return false end
    local t = stored(Player)
    return not (t and t.locked)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔄 LIFECYCLE — publish on load, prompt legacy characters
-- ═══════════════════════════════════════════════════════════════════════════════

AddEventHandler('LXRCore:Server:PlayerLoaded', function(Player)
    local src = Player.PlayerData.source
    local t = stored(Player)
    publish(src, t)
    if MC.Traits.NeedsPrompt(Player) then
        -- give spawn / appearance a moment, then open the trait screen standalone
        SetTimeout(4000, function()
            local P = LXRCore.Functions.GetPlayer(src)
            if P and MC.Traits.NeedsPrompt(P) then
                TriggerClientEvent('lxr-multicharacter:client:openTraits', src, MC.Traits.Payload(), Lang.bundle())
            end
        end)
    end
end)

AddEventHandler('LXRCore:Server:OnPlayerUnload', function(src)
    if src then Player(src).state:set('traits', nil, true) end
end)

-- Standalone lock (legacy characters / retrait) — the player is already logged in
RegisterNetEvent('lxr-multicharacter:server:lockTraits', function(selection)
    local src = source
    if MC.Limited and MC.Limited(src) then return end
    local Player = LXRCore.Functions.GetPlayer(src)
    if not Player then return end
    if not MC.Traits.NeedsPrompt(Player) then
        LXRCore.Log.exploit(src, 'lockTraits on an already locked character')
        return
    end
    local summary, err = MC.Traits.Validate(selection)
    if not summary then
        return TriggerClientEvent('LXRCore:Notify', src, Lang:t(err), 'error')
    end
    MC.Traits.Apply(Player, summary, 'existing')
    TriggerClientEvent('lxr-multicharacter:client:closeTraits', src)
    TriggerClientEvent('LXRCore:Notify', src, Lang:t('info.traits_locked'), 'success')
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📤 EXPORTS — for inventory / medic / crafting / HUD resources
-- ═══════════════════════════════════════════════════════════════════════════════

---@return table|nil { perks, flaws, skills, mods, locked }
exports('GetTraits', function(src)
    local Player = LXRCore.Functions.GetPlayer(src)
    return Player and stored(Player) or nil
end)

exports('HasTrait', function(src, id)
    local Player = LXRCore.Functions.GetPlayer(src)
    local t = Player and stored(Player)
    if not t or not t.locked then return false end
    for _, v in ipairs(t.perks or {}) do if v == id then return true end end
    for _, v in ipairs(t.flaws or {}) do if v == id then return true end end
    return false
end)

---Summed modifier; `default` is returned when the player has no traits.
exports('GetModifier', function(src, key, default)
    local Player = LXRCore.Functions.GetPlayer(src)
    local t = Player and stored(Player)
    local v = t and t.locked and t.mods and t.mods[key]
    if v == nil then return default end
    return v
end)

exports('GetTraitDefinitions', function() return MC.Traits.Payload() end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🛠 COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════════

LXRCore.Commands.Add('traits', Lang:t('command.traits'), {}, false, function(src)
    local Player = LXRCore.Functions.GetPlayer(src)
    local t = Player and stored(Player)
    if not t or not t.locked then
        return TriggerClientEvent('LXRCore:Notify', src, Lang:t('info.traits_none'), 'primary')
    end
    local names = {}
    for _, id in ipairs(t.perks or {}) do names[#names + 1] = '+ ' .. Lang:t('traits.' .. id .. '.name') end
    for _, id in ipairs(t.flaws or {}) do names[#names + 1] = '− ' .. Lang:t('traits.' .. id .. '.name') end
    TriggerClientEvent('LXRCore:Notify', src, table.concat(names, '  '), 'primary', 8000)
end, 'user')

LXRCore.Commands.Add('resettraits', Lang:t('command.resettraits'), { { name = 'id', help = 'Server ID (empty = yourself)' } }, false, function(src, args)
    local target = tonumber(args[1]) or src
    local Player = LXRCore.Functions.GetPlayer(target)
    if not Player then return TriggerClientEvent('LXRCore:Notify', src, Lang:t('error.player_offline'), 'error') end
    MC.Traits.Reset(Player, 'admin:' .. tostring(src))
    TriggerClientEvent('LXRCore:Notify', src, Lang:t('info.traits_reset', { id = target }), 'success')
    TriggerClientEvent('lxr-multicharacter:client:openTraits', target, MC.Traits.Payload(), Lang.bundle())
end, 'admin')

LXRCore.Commands.Add('retrait', Lang:t('command.retrait'), {}, false, function(src)
    if not Config.TraitFlow.allowRetrait then
        return TriggerClientEvent('LXRCore:Notify', src, Lang:t('error.retrait_disabled'), 'error')
    end
    local Player = LXRCore.Functions.GetPlayer(src)
    local t = Player and stored(Player)
    if not t or not t.locked then return end
    local cooldown = (Config.TraitFlow.retraitCooldownDays or 30) * 86400
    if t.lockedAt and os.time() - t.lockedAt < cooldown then
        local days = math.ceil((cooldown - (os.time() - t.lockedAt)) / 86400)
        return TriggerClientEvent('LXRCore:Notify', src, Lang:t('error.retrait_cooldown', { days = days }), 'error')
    end
    MC.Traits.Reset(Player, 'retrait')
    TriggerClientEvent('lxr-multicharacter:client:openTraits', src, MC.Traits.Payload(), Lang.bundle())
end, 'user')

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🚀 BOOT — validate presets once, report broken ones
-- ═══════════════════════════════════════════════════════════════════════════════

CreateThread(function()
    validPresets = Traits.ValidPresets(skillList(), skillRules(), function(id, err)
        LXRCore.Log.warn('multicharacter', ('preset "%s" hidden: %s'):format(id, Lang:t(err)))
    end)
    if Config.Debug then
        LXRCore.Log.info('multicharacter', ('%d perks, %d flaws, %d/%d presets valid'):format(#ConfigTraits.Perks, #ConfigTraits.Flaws, #validPresets, #ConfigTraits.Presets))
    end
end)
