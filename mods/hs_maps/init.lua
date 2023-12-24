function load_map(map_name)
    local map_path = minetest.get_modpath("hs_maps") .. "/schems/" .. map_name ..".mts"
    minetest.log("<hs_maps> Loading test schematic from " .. map_path)

    local result = minetest.place_schematic(
        {x=-100, y=0, z=-100},
        map_path
    )

    if result == nil then
        minetest.log("error", "<hs_maps> Failed to load map '" .. map_name .. "'")
    else
        minetest.log("<hs_maps> Successfully loaded map '" .. map_name .. "'")
        hs_maps.map_loaded = true
    end
end

function load_random_map()
    -- if the map has already been loaded, return
    if hs_maps.map_loaded then
        return
    end

    math.randomseed(os.clock())
    local r = math.random(0, 1)

    -- TODO change map names
    if r == 0 then
        load_map("test")
    else
        load_map("test")
    end
end

----------------
-- privileges --
----------------
minetest.register_privilege("hs_loadmap", {
    description = "Allows the player to load maps",
    give_to_singleplayer = true
})

-- minetest.register_on_mods_loaded(load_map)
minetest.register_on_generated(load_random_map)

hs_maps = {}
hs_maps.map_loaded = false
hs_maps.load_map = load_map
hs_maps.load_random_map = load_random_map