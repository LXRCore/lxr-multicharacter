--[[
    ██╗     ██╗  ██╗██████╗        ██╗   ██╗██╗   ██╗██╗  ████████╗██╗ ██████╗██╗  ██╗ █████╗ ██████╗
    ██║     ╚██╗██╔╝██╔══██╗       ███╗ ███║██║   ██║██║  ╚══██╔══╝██║██╔════╝██║  ██║██╔══██╗██╔══██╗
    ██║      ╚███╔╝ ██████╔╝ █████╗██╔████╔██║██║ ██║██║     ██║   ██║██║     ███████║███████║██████╔╝
    ██║      ██╔██╗ ██╔══██╗ ╚════╝██║╚██╔╝██║██║ ██║██║     ██║   ██║██║     ██╔══██║██╔══██║██╔══██╗
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║╚██████╔╝███████╗██║ ██║╚██████╗██║  ██║██║  ██║██║  ██║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝ ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

    🐺 LXR Multicharacter System — Server

    ═══════════════════════════════════════════════════════════════════════════════
    SERVER INFORMATION
    ═══════════════════════════════════════════════════════════════════════════════

    Server:      The Land of Wolves 🐺
    Developer:   iBoss21 / The Lux Empire
    Website:     https://www.wolves.land
    Discord:     https://discord.gg/CrKcWdfd3A
    Store:       https://theluxempire.tebex.io

    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
    ═══════════════════════════════════════════════════════════════════════════════
]]

-- Functions

local StarterItems = {
    ['apple'] = { amount = 5, item = 'apple' },
    ['water'] = { amount = 5, item = 'water' }

}


local function GiveStarterItems(source)
    local Player = exports['lxr-core']:GetPlayer(source)
    for k, v in pairs(StarterItems) do
        Player.Functions.AddItem(v.item, 1)
    end
end

local function loadHouseData()
    local HouseGarages = {}
    local Houses = {}
    local result = MySQL.query.await('SELECT * FROM houselocations')
    if result[1] ~= nil then
        for k, v in pairs(result) do
            local owned = false
            if tonumber(v.owned) == 1 then
                owned = true
            end
            local garage = v.garage ~= nil and json.decode(v.garage) or {}
            Houses[v.name] = {
                coords = json.decode(v.coords),
                owned = v.owned,
                price = v.price,
                locked = true,
                adress = v.label,
                tier = v.tier,
                garage = garage,
                decorations = {},
            }
            HouseGarages[v.name] = {
                label = v.label,
                takeVehicle = garage,
            }
        end
    end
    TriggerClientEvent("lxr-garages:client:houseGarageConfig", -1, HouseGarages)
    TriggerClientEvent("lxr-houses:client:setHouseConfig", -1, Houses)
end

RegisterNetEvent('lxr-multicharacter:server:disconnect', function(source)
    DropPlayer(source, "You have disconnected from LXRCore RedM")
end)

RegisterNetEvent('lxr-multicharacter:server:loadUserData', function(cData)
    local src = source
    if exports['lxr-core']:Login(src, cData.citizenid) then
        print('^2[lxr-core]^7 '..GetPlayerName(src)..' (Citizen ID: '..cData.citizenid..') has succesfully loaded!')
        exports['lxr-core']:RefreshCommands(src)
        TriggerClientEvent("lxr-multicharacter:client:closeNUI", src)
        TriggerClientEvent('lxr-spawn:client:setupSpawnUI', src, cData, false)
        TriggerEvent("lxr-log:server:CreateLog", "joinleave", "Loaded", "green", "**".. GetPlayerName(src) .. "** ("..cData.citizenid.." | "..src..") loaded..")
	end
end)

RegisterNetEvent('lxr-multicharacter:server:createCharacter', function(data, enabledhouses)
    local newData = {}
    local src = source
    newData.cid = data.cid
    newData.charinfo = data
    if exports['lxr-core']:Login(src, false, newData) then
        exports['lxr-core']:ShowSuccess(GetCurrentResourceName(), GetPlayerName(src)..' has succesfully loaded!')
        exports['lxr-core']:RefreshCommands(src)
        --[[if enabledhouses then loadHouseData() end]] -- Enable once housing is ready
        TriggerClientEvent("lxr-multicharacter:client:closeNUI", src)
        TriggerClientEvent('lxr-spawn:client:setupSpawnUI', src, newData, true)
        GiveStarterItems(src)
	end
end)

RegisterNetEvent('lxr-multicharacter:server:deleteCharacter', function(citizenid)
    exports['lxr-core']:DeleteCharacter(source, citizenid)
end)

-- Callbacks

exports['lxr-core']:CreateCallback("lxr-multicharacter:server:setupCharacters", function(source, cb)
    local license = exports['lxr-core']:GetIdentifier(source, 'license')
    local plyChars = {}
    MySQL.query('SELECT * FROM players WHERE license = @license', {['@license'] = license}, function(result)
        for i = 1, (#result), 1 do
            result[i].charinfo = json.decode(result[i].charinfo)
            result[i].money = json.decode(result[i].money)
            result[i].job = json.decode(result[i].job)
            plyChars[#plyChars+1] = result[i]
        end
        cb(plyChars)
    end)
end)

exports['lxr-core']:CreateCallback("lxr-multicharacter:server:GetNumberOfCharacters", function(source, cb)
    local license = exports['lxr-core']:GetIdentifier(source, 'license')
    local numOfChars = 0
    if next(Config.PlayersNumberOfCharacters) then
        for i, v in pairs(Config.PlayersNumberOfCharacters) do
            if v.license == license then
                numOfChars = v.numberOfChars
                break
            else
                numOfChars = Config.DefaultNumberOfCharacters
            end
        end
    else
        numOfChars = Config.DefaultNumberOfCharacters
    end
    cb(numOfChars)
end)

exports['lxr-core']:CreateCallback("lxr-multicharacter:server:getSkin", function(source, cb, cid)
    MySQL.query('SELECT * FROM playerskins WHERE citizenid = ? AND active = ?', {cid, 1}, function(result)
        if result[1] ~= nil then
            result[1].skin = json.decode(result[1].skin)
            result[1].clothes = json.decode(result[1].clothes)
            cb(result[1])
        else
            cb(false)
        end
    end)
end)

-- Commands

exports['lxr-core']:AddCommand("logout", "Logout of Character (Admin Only)", {}, false, function(source)
    exports['lxr-core']:Logout(source)
    TriggerClientEvent('lxr-multicharacter:client:chooseChar', source)
end, 'admin')

exports['lxr-core']:AddCommand("closeNUI", "Close Multi NUI", {}, false, function(source)
    TriggerClientEvent('lxr-multicharacter:client:closeNUI', source)
end, 'user')
