--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗██╗   ██╗██╗  ████████╗██╗ ██████╗██╗  ██╗ █████╗ ██████╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██║   ██║██║  ╚══██╔══╝██║██╔════╝██║  ██║██╔══██╗██╔══██╗
    ██║      ╚███╔╝ ██████╔╝█████╗██╔████╔██║██║   ██║██║     ██║   ██║██║     ███████║███████║██████╔╝
    ██║      ██╔██╗ ██╔══██╗╚════╝██║╚██╔╝██║██║   ██║██║     ██║   ██║██║     ██╔══██║██╔══██║██╔══██╗
    ███████╗██╔╝ ██╗██║  ██║      ██║ ╚═╝ ██║╚██████╔╝███████╗██║   ██║╚██████╗██║  ██║██║  ██║██║  ██║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

    🐺 LXR Core - Multicharacter Server

    Everything that matters happens here: listing characters for the license,
    validating new-character data, enforcing slot limits, selecting (Login),
    deleting (ownership enforced by the core) and handing off to spawn /
    appearance. The client only relays UI intent.

    Developer:   iBoss21 / LXRCore
    Website:     https://www.lxrcore.com
    © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
]]

local LXRCore = exports['lxr-core']:GetCoreObject()
local RES = GetCurrentResourceName()

local buckets = {}
local lastCreate = {}
local preloaded = {} -- source → true once other resources had time to react to PlayerLoaded

local function limited(src)
    local rl = Config.Security.rateLimit
    if LXRCore.RateLimit(buckets, src, rl.burst, rl.windowMs) then return false end
    LXRCore.Log.warn('multicharacter', 'rate limit exceeded', { source = src })
    return true
end

local function notify(src, key, kind)
    TriggerClientEvent('LXRCore:Notify', src, Lang:t(key), kind or 'error')
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 👥 SLOTS
-- ═══════════════════════════════════════════════════════════════════════════════

local function maxCharacters(src)
    local license = GetPlayerIdentifierByType(src, 'license')
    local n = Config.Characters.default or LXRCore.Config.Player.maxCharacters or 5
    if license and Config.Characters.overrides[license] then
        n = Config.Characters.overrides[license]
    end
    for ace, slots in pairs(Config.Characters.aceSlots or {}) do
        if IsPlayerAceAllowed(src, ace) and slots > n then n = slots end
    end
    return n
end
exports('GetMaxCharacters', maxCharacters)

local function summarise(row)
    local charinfo = row.charinfo or {}
    local job = row.job or {}
    local money = row.money or {}
    return {
        citizenid = row.citizenid,
        cid = tonumber(row.cid) or 1,
        firstname = charinfo.firstname or '',
        lastname = charinfo.lastname or '',
        birthdate = charinfo.birthdate or '',
        gender = tonumber(charinfo.gender) or 0,
        nationality = charinfo.nationality or '',
        job = job.label or job.name or '',
        grade = job.grade and job.grade.name or '',
        cash = tonumber(money.cash) or 0,
        bank = tonumber(money.bank) or 0,
        lastPlayed = row.last_updated and tostring(row.last_updated) or '',
    }
end

local function characterList(src)
    local rows = LXRCore.Player.GetCharacters(src)
    local out = {}
    for _, row in ipairs(rows) do out[#out + 1] = summarise(row) end
    table.sort(out, function(a, b) return a.cid < b.cid end)
    return out
end

local function freeCid(list, max)
    local used = {}
    for _, c in ipairs(list) do used[c.cid] = true end
    for i = 1, max do
        if not used[i] then return i end
    end
    return nil
end

local function ownsCharacter(src, citizenid)
    if not LXRCore.Player.ValidateCitizenId(citizenid) then return false end
    for _, c in ipairs(characterList(src)) do
        if c.citizenid == citizenid then return true end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ✅ CREATION VALIDATION
-- ═══════════════════════════════════════════════════════════════════════════════

local function utf8len(s)
    local ok, n = pcall(utf8.len, s)
    if ok and n then return n end
    return #s
end

local function validName(value)
    if type(value) ~= 'string' then return false end
    value = value:gsub('^%s+', ''):gsub('%s+$', '')
    local len = utf8len(value)
    if len < Config.Creation.nameMin or len > Config.Creation.nameMax then return false end
    if value:find('[%c<>{}%[%]\\/]') then return false end
    if not Config.Creation.allowUnicodeNames and not value:match(Config.Creation.namePattern) then return false end
    local lower = value:lower()
    for _, word in ipairs(Config.Creation.blockedWords or {}) do
        if lower:find(word, 1, true) then return false end
    end
    return true, value
end

local function validBirthdate(value)
    if type(value) ~= 'string' then return false end
    local y, m, d = value:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
    if not y then return false end
    y, m, d = tonumber(y), tonumber(m), tonumber(d)
    if y < Config.Creation.birthYearMin or y > Config.Creation.birthYearMax then return false end
    if m < 1 or m > 12 or d < 1 or d > 31 then return false end
    return true, ('%04d-%02d-%02d'):format(y, m, d)
end

---@return table|nil charinfo, string|nil errorKey
local function validateCreation(data)
    if type(data) ~= 'table' then return nil, 'error.invalid_data' end
    local okF, first = validName(data.firstname)
    if not okF then return nil, 'error.invalid_firstname' end
    local okL, last = validName(data.lastname)
    if not okL then return nil, 'error.invalid_lastname' end
    local okB, birth = validBirthdate(data.birthdate)
    if not okB then return nil, 'error.invalid_birthdate' end
    local gender = tonumber(data.gender)
    if gender == nil or not Config.Creation.genders[gender] then return nil, 'error.invalid_gender' end
    local nationality = type(data.nationality) == 'string' and data.nationality:gsub('^%s+', ''):gsub('%s+$', '') or ''
    if nationality == '' then nationality = 'USA' end
    if utf8len(nationality) > Config.Creation.nationalityMax or nationality:find('[%c<>{}%[%]\\/]') then
        return nil, 'error.invalid_nationality'
    end
    return { firstname = first, lastname = last, birthdate = birth, gender = gender, nationality = nationality }
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔄 LIFECYCLE HAND-OFF
-- ═══════════════════════════════════════════════════════════════════════════════

AddEventHandler('LXRCore:Server:PlayerLoaded', function(Player)
    local src = Player.PlayerData.source
    SetTimeout(750, function() preloaded[src] = true end)
end)

AddEventHandler('LXRCore:Server:OnPlayerUnload', function(src)
    preloaded[src] = nil
end)

AddEventHandler('playerDropped', function()
    preloaded[source] = nil
    buckets[source] = nil
    lastCreate[source] = nil
end)

local function waitPreload(src)
    local tries = 0
    while not preloaded[src] and tries < 100 do
        Wait(20)
        tries = tries + 1
    end
end

local function giveStarterItems(src)
    local Player = LXRCore.Functions.GetPlayer(src)
    if not Player then return end
    local list = Config.Creation.starterItems or LXRCore.Shared.StarterItems or {}
    for _, entry in ipairs(list) do
        Player.Functions.AddItem(entry.item, entry.amount or 1, nil, nil, 'starter')
    end
end

local function handOff(src, isNew)
    local Player = LXRCore.Functions.GetPlayer(src)
    if not Player then return end
    local pd = Player.PlayerData
    local cData = { citizenid = pd.citizenid, cid = pd.cid, charinfo = pd.charinfo, job = pd.job, money = pd.money, position = pd.position }
    TriggerClientEvent('lxr-multicharacter:client:closeUI', src)
    local ev = isNew and Config.Integrations.afterCreate or Config.Integrations.afterSelect
    if ev then TriggerClientEvent(ev, src, cData, isNew) end
    if isNew and Config.Integrations.newCharacterAppearance then
        TriggerClientEvent(Config.Integrations.newCharacterAppearance, src)
    end
    LXRCore.Log.info('multicharacter', isNew and 'character created' or 'character selected', { source = src, citizenid = pd.citizenid })
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📡 CALLBACKS & EVENTS (all rate limited)
-- ═══════════════════════════════════════════════════════════════════════════════

LXRCore.Callback.Register('lxr-multicharacter:server:characters', function(src)
    if limited(src) then return nil end
    return { characters = characterList(src), max = maxCharacters(src), locale = Lang.bundle(), server = Config.ServerInfo }
end)

LXRCore.Callback.Register('lxr-multicharacter:server:appearance', function(src, citizenid)
    if limited(src) or not ownsCharacter(src, citizenid) then return nil end
    local res = Config.Integrations.appearance
    if not res or GetResourceState(res.resource) ~= 'started' then return nil end
    if not LXRCore.DB.TableExists(res.table) then return nil end
    local row = LXRCore.DB.Single(('SELECT model, skin, clothes FROM `%s` WHERE citizenid = ? AND active = 1 LIMIT 1'):format(res.table), { citizenid })
    if not row then
        row = LXRCore.DB.Single(('SELECT model, skin, clothes FROM `%s` WHERE citizenid = ? LIMIT 1'):format(res.table), { citizenid })
    end
    if not row then return nil end
    return { model = tonumber(row.model) or row.model, skin = LXRCore.Shared.JsonDecode(row.skin, nil), clothes = LXRCore.Shared.JsonDecode(row.clothes, nil) }
end)

RegisterNetEvent('lxr-multicharacter:server:select', function(citizenid)
    local src = source
    if limited(src) then return end
    if not ownsCharacter(src, citizenid) then
        LXRCore.Log.exploit(src, 'select character not owned', { citizenid = tostring(citizenid) })
        return notify(src, 'error.not_owned')
    end
    if LXRCore.Player.Login(src, citizenid) then
        waitPreload(src)
        handOff(src, false)
    else
        notify(src, 'error.login_failed')
    end
end)

RegisterNetEvent('lxr-multicharacter:server:create', function(data)
    local src = source
    if limited(src) then return end
    local now = GetGameTimer()
    if lastCreate[src] and now - lastCreate[src] < (Config.Creation.createCooldownMs or 5000) then
        return notify(src, 'error.too_fast')
    end
    lastCreate[src] = now

    local list = characterList(src)
    local max = maxCharacters(src)
    if #list >= max then return notify(src, 'error.character_limit') end
    local charinfo, err = validateCreation(data)
    if not charinfo then return notify(src, err) end
    local cid = freeCid(list, max)
    if not cid then return notify(src, 'error.character_limit') end

    if LXRCore.Player.Login(src, false, { cid = cid, charinfo = charinfo }) then
        waitPreload(src)
        giveStarterItems(src)
        handOff(src, true)
    else
        notify(src, 'error.login_failed')
    end
end)

RegisterNetEvent('lxr-multicharacter:server:delete', function(citizenid)
    local src = source
    if limited(src) then return end
    if not ownsCharacter(src, citizenid) then
        LXRCore.Log.exploit(src, 'delete character not owned', { citizenid = tostring(citizenid) })
        return notify(src, 'error.not_owned')
    end
    if LXRCore.Player.DeleteCharacter(src, citizenid) then
        notify(src, 'info.deleted', 'success')
    end
    TriggerClientEvent('lxr-multicharacter:client:refresh', src)
end)

RegisterNetEvent('lxr-multicharacter:server:disconnect', function()
    DropPlayer(source, Lang:t('info.disconnected'))
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🛠 COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════════

LXRCore.Commands.Add('logout', Lang:t('command.logout'), {}, false, function(src)
    if not LXRCore.Functions.GetPlayer(src) then return end
    LXRCore.Player.Logout(src)
    TriggerClientEvent('lxr-multicharacter:client:open', src)
end, 'admin')

LXRCore.Commands.Add('closemulti', Lang:t('command.closemulti'), {}, false, function(src)
    TriggerClientEvent('lxr-multicharacter:client:closeUI', src)
end, 'user')

LXRCore.Log.info('multicharacter', ('%s v%s ready'):format(RES, GetResourceMetadata(RES, 'version', 0)))
