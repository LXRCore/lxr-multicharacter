--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-MULTICHARACTER — Offline tests: trait engine, presets, locale coverage
     Requires a sibling checkout of lxr-core (../lxr-core) for the runtime shim.
     Usage (from the lxr-multicharacter folder):  lua tests/run.lua [--mock out.js]
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local CORE = os.getenv('LXR_CORE_PATH') or '../lxr-core'
package.path = CORE .. '/?.lua;' .. package.path
local ok = pcall(function() require('tests.lib.fxshim') end)
if not ok then print('lxr-core shim not found at ' .. CORE .. ' (set LXR_CORE_PATH)') os.exit(2) end
local Shim = require('tests.lib.fxshim')

for _, f in ipairs({ 'shared/main.lua', 'shared/locale.lua', 'locales/en.lua', 'config.lua' }) do Shim.load(CORE .. '/' .. f) end
local CoreConfig = Config
Config = nil
Locale = nil
Shim.load('shared/locale.lua')
Shim.load('locales/en.lua')
Shim.load('locales/ka.lua')
Shim.load('config.lua')
Shim.load('config_traits.lua')
Shim.load('shared/traits.lua')

local passed, failed = 0, 0
local function test(name, fn)
    local okT, err = xpcall(fn, debug.traceback)
    if okT then passed = passed + 1 print('  ^ ok   ' .. name) else failed = failed + 1 print('  x FAIL ' .. name .. '\n' .. err) end
end
local function eq(a, b, msg) if a ~= b then error((msg or 'eq') .. ': expected ' .. tostring(b) .. ' got ' .. tostring(a), 2) end end

local SKILLS = CoreConfig.Player.skills
local RULES = { enabled = true, maxPerSkill = Config.TraitFlow.skills.maxPerSkill, maxTotal = Config.TraitFlow.skills.maxTotal, pointsPerLevel = Config.TraitFlow.skills.pointsPerLevel }
local function firstPerks(n) local out = {} for i = 1, n do out[i] = ConfigTraits.Perks[i].id end return out end
local function flawsFor(points)
    local out, sum = {}, 0
    for _, f in ipairs(ConfigTraits.Flaws) do if sum < points then out[#out + 1] = f.id sum = sum + f.points end end
    return out, sum
end

test('rules: 2–4 advantages, ≤ 12 traits, balance ≥ 0', function()
    local r = ConfigTraits.Rules
    eq(r.basePoints, 0) eq(r.minPerks, 2) eq(r.maxPerks, 4) eq(r.maxTraits, 12)
    local okV, err = Traits.Validate({ perks = { ConfigTraits.Perks[1].id }, flaws = {}, skills = {} }, SKILLS, RULES)
    eq(okV, false) eq(err, 'error.traits_min_perks')
    okV, err = Traits.Validate({ perks = firstPerks(2), flaws = {}, skills = {} }, SKILLS, RULES)
    eq(okV, false) eq(err, 'error.traits_over_budget')
end)

test('a balanced selection validates and folds modifiers', function()
    local preset = ConfigTraits.Presets[1]
    local okV, err, summary = Traits.Validate({ perks = preset.perks, flaws = preset.flaws, skills = preset.skills or {} }, SKILLS, RULES)
    assert(okV, tostring(err))
    assert(summary.free >= 0, 'free points')
    local mods = Traits.Modifiers(summary.selection)
    assert(type(mods) == 'table', 'mods')
end)

test('linked flaws are auto-added and non-removable; conflicts checked both ways', function()
    local perkWithReq
    for _, p in ipairs(ConfigTraits.Perks) do if p.requires and #p.requires > 0 then perkWithReq = p break end end
    assert(perkWithReq, 'a perk with linked flaws exists')
    local flaws = Traits.WithLinkedFlaws({ perkWithReq.id }, {})
    for _, req in ipairs(perkWithReq.requires) do
        local found = false
        for _, f in ipairs(flaws) do if f == req then found = true end end
        assert(found, 'linked flaw ' .. req)
    end
    local a, b
    for _, p in ipairs(ConfigTraits.Perks) do if p.conflicts and #p.conflicts > 0 then a, b = p.id, p.conflicts[1] break end end
    if a and Traits.Get(b) and Traits.Get(b).kind == 'perk' then
        local okV, err = Traits.Validate({ perks = { a, b }, flaws = flawsFor(20), skills = {} }, SKILLS, RULES)
        eq(okV, false) eq(err, 'error.traits_conflict')
        okV, err = Traits.Validate({ perks = { b, a }, flaws = flawsFor(20), skills = {} }, SKILLS, RULES)
        eq(okV, false, 'reverse order')
    end
end)

test('unknown ids, too many traits and skill caps are refused', function()
    local okV, err = Traits.Validate({ perks = { 'nope', firstPerks(2)[2] }, flaws = {}, skills = {} }, SKILLS, RULES)
    eq(okV, false) eq(err, 'error.traits_unknown')
    local all = {} for _, f in ipairs(ConfigTraits.Flaws) do all[#all + 1] = f.id end
    okV, err = Traits.Validate({ perks = firstPerks(2), flaws = all, skills = {} }, SKILLS, RULES)
    eq(okV, false) eq(err, 'error.traits_max_total')
    local perks = firstPerks(2)
    local cost = 0 for _, id in ipairs(perks) do cost = cost + Traits.Get(id).points end
    local flaws = flawsFor(cost + 10)
    okV, err = Traits.Validate({ perks = perks, flaws = flaws, skills = { [SKILLS[1]] = 99 } }, SKILLS, RULES)
    eq(okV, false) eq(err, 'error.skill_limit')
end)

test('all 7 presets are valid', function()
    local valid = Traits.ValidPresets(SKILLS, RULES, false)
    eq(#valid, #ConfigTraits.Presets)
    eq(#valid, 7)
end)

test('every trait / preset / category / skill string exists in en and ka', function()
    local missing = {}
    local function need(key)
        for _, lang in ipairs({ 'en', 'ka' }) do
            if not (Locale.Bundles[lang] and Locale.Bundles[lang][key]) then missing[#missing + 1] = lang .. ':' .. key end
        end
    end
    for _, list in ipairs({ ConfigTraits.Perks, ConfigTraits.Flaws }) do
        for _, d in ipairs(list) do
            need('traits.' .. d.id .. '.name') need('traits.' .. d.id .. '.tag')
            for i = 1, tonumber(d.effects) or 0 do need(('traits.%s.fx%d'):format(d.id, i)) end
            need('traits.cat.' .. d.category)
        end
    end
    for _, p in ipairs(ConfigTraits.Presets) do need('traits.preset.' .. p.id .. '.name') need('traits.preset.' .. p.id .. '.desc') end
    for _, s in ipairs(SKILLS) do need('skills.' .. s) end
    for k in pairs(Locale.Bundles.en) do if not Locale.Bundles.ka[k] then missing[#missing + 1] = 'ka:' .. k end end
    if #missing > 0 then error('missing: ' .. table.concat(missing, ', ', 1, math.min(#missing, 25))) end
end)

print(('\n%d passed, %d failed'):format(passed, failed))

-- optional: write the NUI mock payload (same shape as MC.Traits.Payload + characters message)
if arg and arg[1] == '--mock' and arg[2] then
    local lang = arg[3] or 'en'
    Config.Lang = lang
    local function describe(def)
        local fx = {}
        for i = 1, tonumber(def.effects) or 0 do fx[i] = Lang:t(('traits.%s.fx%d'):format(def.id, i)) end
        return { id = def.id, kind = def.kind, category = def.category, icon = def.icon, points = def.points, conflicts = def.conflicts or {}, requires = def.requires or {},
            name = Lang:t('traits.' .. def.id .. '.name'), tag = Lang:t('traits.' .. def.id .. '.tag'), effects = fx, categoryLabel = Lang:t('traits.cat.' .. def.category), order = Traits.CategoryOrder(def.category) }
    end
    local perks, flaws, presets, skills = {}, {}, {}, {}
    for _, d in ipairs(ConfigTraits.Perks) do perks[#perks + 1] = describe(Traits.Get(d.id)) end
    for _, d in ipairs(ConfigTraits.Flaws) do flaws[#flaws + 1] = describe(Traits.Get(d.id)) end
    for _, p in ipairs(Traits.ValidPresets(SKILLS, RULES, false)) do
        presets[#presets + 1] = { id = p.id, label = Lang:t('traits.preset.' .. p.id .. '.name'), desc = Lang:t('traits.preset.' .. p.id .. '.desc'), perks = p.perks, flaws = Traits.WithLinkedFlaws(p.perks, p.flaws), skills = p.skills or {} }
    end
    for _, s in ipairs(SKILLS) do skills[#skills + 1] = { id = s, label = Lang:t('skills.' .. s) } end
    local payload = {
        locale = Lang.bundle(), max = 5,
        server = { name = 'The Land of Wolves', tagline = 'მგლების მიწა - რჩეულთა ადგილი!' },
        creation = { birthYearMin = Config.Creation.birthYearMin, birthYearMax = Config.Creation.birthYearMax, nameMin = Config.Creation.nameMin, nameMax = Config.Creation.nameMax },
        traits = { enabled = true, rules = ConfigTraits.Rules, skillRules = RULES, perks = perks, flaws = flaws, presets = presets, skills = skills, year = Config.ServerInfo.year },
        characters = {
            { cid = 1, citizenid = 'ABC123', firstname = 'Sadie', lastname = 'Adler', birthdate = '1873-03-02', gender = 1, nationality = 'USA', job = 'Deputy', cash = 12.5, bank = 140, lastPlayed = '2026-09-17', traits = { perks = { Lang:t('traits.' .. ConfigTraits.Perks[1].id .. '.name') }, flaws = { Lang:t('traits.' .. ConfigTraits.Flaws[1].id .. '.name') } } },
            { cid = 2, citizenid = 'DEF456', firstname = 'ლუკა', lastname = 'ბერიძე', birthdate = '1868-11-20', gender = 0, nationality = 'Georgia', job = 'Drifter', cash = 3, bank = 0, lastPlayed = '2026-09-10' },
        },
    }
    local f = assert(io.open(arg[2], 'w'))
    f:write('window.__LXR_MOCK__ = ' .. json.encode(payload) .. ';\n')
    f:close()
    print('mock written to ' .. arg[2])
end
os.exit(failed == 0 and 0 or 1)
