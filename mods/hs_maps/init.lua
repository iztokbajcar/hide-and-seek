function load_map(map_name, pos)
    local map_path = core.get_modpath("hs_maps") .. "/schems/" .. map_name .. ".mts"
    core.log("<hs_maps> Loading test schematic from " .. map_path)

    local result = core.place_schematic(
        { x = pos.x, y = pos.y, z = pos.z },
        map_path
    )

    if result == nil then
        core.log("error", "<hs_maps> Failed to load map '" .. map_name .. "'")
    else
        core.log("<hs_maps> Successfully loaded map '" .. map_name .. "'")
        hs_maps.map_loaded = true
    end
end

function load_lobby()
    load_map("test", hs_maps.lobby_pos)
end

function load_random_map()
    local maps = { "map1" }
    math.randomseed(os.clock())
    local r = math.random(1, #maps)

    load_map(maps[r], hs_maps.map_pos)
end

function load_lobby_and_random_map()
    -- if the map has already been loaded, return
    if hs_maps.map_loaded then
        return
    end

    load_lobby()
    load_random_map()

    hs_maps.map_loaded = true
end

----------------
-- privileges --
----------------
core.register_privilege("hs_loadmap", {
    description = "Allows the player to load maps",
    give_to_singleplayer = true
})

core.register_on_generated(load_lobby_and_random_map)

hs_maps = {}
hs_maps.map_loaded = false
hs_maps.load_map = load_map
hs_maps.load_random_map = load_random_map
hs_maps.load_lobby_and_random_map = load_lobby_and_random_map
hs_maps.map_pos = { x = -100, y = 0, z = -100 }
hs_maps.lobby_pos = { x = 10000, y = 0, z = 0 }
