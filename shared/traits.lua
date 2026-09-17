--[[ ═══════════════════════════════════════════════════════════════════════════
     🐺 LXR-MULTICHARACTER — Trait Engine (shared, pure logic, no I/O)
     ═══════════════════════════════════════════════════════════════════════════
     Indexes ConfigTraits, validates a selection against the budget rules and
     sums modifiers. The server is the only authority — the NUI uses the same
     math for live feedback, but nothing it computes is trusted.

     Traits.Validate(selection, skillList, skillRules) → ok, errorKey, summary
       selection = { perks = { id, … }, flaws = { id, … }, skills = { [skill] = levels } }
       Linked flaws (perk.requires) are added automatically before validation.
     Traits.Modifiers(selection) → flat modifier table
     ═══════════════════════════════════════════════════════════════════════════
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

Traits = Traits or {}

local index = {}          -- id → definition (with .kind = 'perk' | 'flaw')
local categoryOrder = {}  -- category → sort index

local function build()
    index, categoryOrder = {}, {}
    for i, cat in ipairs(ConfigTraits.Categories or {}) do categoryOrder[cat] = i end
    for _, def in ipairs(ConfigTraits.Perks or {}) do
        def.kind = 'perk'
        def.points = tonumber(def.cost) or 0
        def.requires = def.requires or {}
        def.conflicts = def.conflicts or {}
        index[def.id] = def
    end
    for _, def in ipairs(ConfigTraits.Flaws or {}) do
        def.kind = 'flaw'
        def.points = tonumber(def.refund) or 0
        def.requires = {}
        def.conflicts = def.conflicts or {}
        index[def.id] = def
    end
end
build()

function Traits.Get(id) return index[id] end
function Traits.Index() return index end
function Traits.CategoryOrder(cat) return categoryOrder[cat] or 99 end

---Normalise a client-sent id list: strings only, unique, known ids, matching kind.
---@return table|nil ids, string|nil errorKey
local function cleanList(list, kind)
    if list == nil then return {} end
    if type(list) ~= 'table' then return nil, 'error.traits_invalid' end
    local out, seen = {}, {}
    for _, id in ipairs(list) do
        if type(id) ~= 'string' then return nil, 'error.traits_invalid' end
        local def = index[id]
        if not def or def.kind ~= kind then return nil, 'error.traits_unknown' end
        if not seen[id] then
            seen[id] = true
            out[#out + 1] = id
        end
    end
    return out
end

---Normalise the skills table: { [skill] = integer levels }.
local function cleanSkills(skills, skillList, rules)
    if skills == nil then return {}, nil, 0 end
    if type(skills) ~= 'table' then return nil, 'error.traits_invalid' end
    if not rules or not rules.enabled then return {}, nil, 0 end
    local allowed = {}
    for _, s in ipairs(skillList or {}) do allowed[s] = true end
    local out, total = {}, 0
    for skill, lvl in pairs(skills) do
        if type(skill) ~= 'string' or not allowed[skill] then return nil, 'error.skill_unknown' end
        lvl = math.floor(tonumber(lvl) or 0)
        if lvl < 0 or lvl > (rules.maxPerSkill or 3) then return nil, 'error.skill_limit' end
        if lvl > 0 then
            out[skill] = lvl
            total = total + lvl
        end
    end
    if total > (rules.maxTotal or 6) then return nil, 'error.skill_limit' end
    return out, nil, total
end

---Add linked flaws for every chosen perk (idempotent, keeps order).
function Traits.WithLinkedFlaws(perks, flaws)
    local out, seen = {}, {}
    for _, id in ipairs(flaws or {}) do
        if not seen[id] then seen[id] = true; out[#out + 1] = id end
    end
    for _, pid in ipairs(perks or {}) do
        local def = index[pid]
        for _, fid in ipairs(def and def.requires or {}) do
            if index[fid] and not seen[fid] then seen[fid] = true; out[#out + 1] = fid end
        end
    end
    return out
end

---@param selection table
---@param skillList table|nil   allowed skill names
---@param skillRules table|nil  Config.TraitFlow.skills
---@return boolean ok, string|nil errorKey, table summary
function Traits.Validate(selection, skillList, skillRules)
    local R = ConfigTraits.Rules
    local summary = { cost = 0, refund = 0, perks = 0, flaws = 0, total = 0, skillLevels = 0, skillCost = 0, free = R.basePoints or 0 }
    if type(selection) ~= 'table' then return false, 'error.traits_invalid', summary end

    local perks, err = cleanList(selection.perks, 'perk')
    if not perks then return false, err, summary end
    local flaws, err2 = cleanList(selection.flaws, 'flaw')
    if not flaws then return false, err2, summary end
    flaws = Traits.WithLinkedFlaws(perks, flaws)
    local skills, err3, levels = cleanSkills(selection.skills, skillList, skillRules)
    if not skills then return false, err3, summary end

    summary.perks, summary.flaws, summary.total = #perks, #flaws, #perks + #flaws
    if #perks < (R.minPerks or 0) then return false, 'error.traits_min_perks', summary end
    if #perks > (R.maxPerks or 99) then return false, 'error.traits_max_perks', summary end
    if summary.total > (R.maxTraits or 99) then return false, 'error.traits_max_total', summary end

    local chosen = {}
    for _, id in ipairs(perks) do chosen[id] = true; summary.cost = summary.cost + index[id].points end
    for _, id in ipairs(flaws) do chosen[id] = true; summary.refund = summary.refund + index[id].points end

    -- conflicts are declared on either side; check both directions
    for id in pairs(chosen) do
        for _, other in ipairs(index[id].conflicts) do
            if chosen[other] then return false, 'error.traits_conflict', summary end
        end
    end

    summary.skillLevels = levels or 0
    summary.skillCost = (levels or 0) * ((skillRules and skillRules.pointsPerLevel) or 1)
    summary.free = (R.basePoints or 0) + summary.refund - summary.cost - summary.skillCost
    if summary.free < 0 then return false, 'error.traits_over_budget', summary end

    summary.selection = { perks = perks, flaws = flaws, skills = skills }
    return true, nil, summary
end

---Sum the modifiers of every trait in the selection (see config_traits.lua header).
function Traits.Modifiers(selection)
    local out = {}
    local function fold(list)
        for _, id in ipairs(list or {}) do
            local def = index[id]
            for key, value in pairs(def and def.modifiers or {}) do
                if type(value) == 'boolean' then
                    if key:sub(1, 4) == 'can_' then
                        if out[key] == nil then out[key] = value else out[key] = out[key] and value end
                    else
                        out[key] = out[key] or value
                    end
                elseif key == 'move_rate' or key:sub(-5) == '_mult' then
                    out[key] = (out[key] or 1.0) * value
                elseif key:sub(-4) == '_min' then
                    out[key] = math.min(out[key] or value, value)
                elseif key:sub(-4) == '_max' then
                    out[key] = math.max(out[key] or value, value)
                else
                    out[key] = (out[key] or 0) + value
                end
            end
        end
    end
    if type(selection) == 'table' then
        fold(selection.perks)
        fold(selection.flaws)
    end
    return out
end

---Validate every preset on start; returns the ones that pass.
function Traits.ValidPresets(skillList, skillRules, report)
    local ok = {}
    for _, p in ipairs(ConfigTraits.Presets or {}) do
        local pass, err = Traits.Validate({ perks = p.perks, flaws = p.flaws, skills = p.skills }, skillList, skillRules)
        if pass then
            ok[#ok + 1] = p
        elseif report then
            report(p.id, err)
        end
    end
    return ok
end
