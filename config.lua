Config = {}

-- Enable/Disable starting apartments feature
-- If disabled, characters will spawn at the default location (Config.DefaultSpawn)
Config.StartingApartment = false

-- Coordinates for character preview screen (interior)
-- This is where the interior is loaded, and characters are previewed.
Config.Interior = vector3(-814.89, 181.95, 76.85)

-- Default spawn location coordinates if starting apartments are disabled
Config.DefaultSpawn = vector3(-1035.71, -2731.87, 12.86)

-- Ped (character) coordinates for the preview screen
Config.PedCoords = vector4(-813.97, 176.22, 76.74, -7.5)

-- Coordinates to hide the actual player ped while in character selection mode
Config.HiddenCoords = vector4(-812.23, 182.54, 76.74, 156.5)

-- Camera coordinates for character preview screen
Config.CamCoords = vector4(-813.46, 178.95, 76.85, 174.5)

-- Default maximum number of characters a player can create
-- By default, the maximum is set to 5, but this can be adjusted
Config.DefaultNumberOfCharacters = 5

-- Optional: Define the number of characters for specific players by their Rockstar license
-- You can set unique character limits for specific players by adding their Rockstar license
Config.PlayersNumberOfCharacters = {
    { license = "license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", numberOfChars = 2 },
}

-- Random Spawn Configurations
-- Enable/Disable random spawn locations upon character creation or respawn
Config.RandomSpawnsEnabled = true -- Set to true to allow random spawns

-- List of random spawn locations (coordinates and optional heading for direction)
Config.RandomSpawnLocations = {
    { coords = vector4(-1044.71, -2745.87, 12.86, 180.0) }, -- Beach area
    { coords = vector4(425.10, -806.20, 29.49, 90.0) }, -- City square
    { coords = vector4(-500.34, 52.54, 52.38, 0.0) }, -- Quiet neighborhood
    { coords = vector4(200.12, 6600.45, 31.87, 270.0) }, -- Countryside
    { coords = vector4(-1600.13, -300.85, 50.65, 45.0) }, -- Hilltop location
}

-- Function to select a random spawn location from the list
-- If `Config.RandomSpawnsEnabled` is true, this function can be used to return a random spawn location
function Config.GetRandomSpawnLocation()
    local spawnCount = #Config.RandomSpawnLocations
    if spawnCount > 0 then
        -- Use math.random to get a random index from the RandomSpawnLocations table
        local randomIndex = math.random(1, spawnCount)
        return Config.RandomSpawnLocations[randomIndex].coords
    else
        -- Fallback to default spawn if no random locations are defined
        return Config.DefaultSpawn
    end
end
