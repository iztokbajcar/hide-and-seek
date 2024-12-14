function load_map(map_name, pos)
    local map_path = minetest.get_modpath("hs_maps") .. "/schems/" .. map_name .. ".mts"
    minetest.log("<hs_maps> Loading test schematic from " .. map_path)

    local result = minetest.place_schematic(
        { x = pos.x, y = pos.y, z = pos.z },
        map_path
    )

    if result == nil then
        minetest.log("error", "<hs_maps> Failed to load map '" .. map_name .. "'")
    else
        minetest.log("<hs_maps> Successfully loaded map '" .. map_name .. "'")
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
minetest.register_privilege("hs_loadmap", {
    description = "Allows the player to load maps",
    give_to_singleplayer = true
})

minetest.register_on_generated(load_lobby_and_random_map)

hs_maps = {}
hs_maps.map_loaded = false
hs_maps.load_map = load_map
hs_maps.load_random_map = load_random_map
hs_maps.load_lobby_and_random_map = load_lobby_and_random_map
hs_maps.map_pos = { x = -100, y = 0, z = -100 }
hs_maps.lobby_pos = { x = 10000, y = 0, z = 0 }
