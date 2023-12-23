-- function nuke(_, _)
--     minetest.log("<hs_testutils> Nuking the map...")

--     local voxelmanip = minetest.get_voxel_manip()
--     local emin, emax = voxelmanip:read_from_map(
--         {x=-200, y=0, z=-200},
--         {x=200, y=200, z=200}
--     )

--     -- generate new data (air)
--     local air_id = minetest.get_content_id("air")
--     local air = minetest.get_name_from_content_id(air_id)
--     minetest.log(air)
--     local new_data = {}
--     for i = 1, 400*200*400 do
--         table.insert(new_data, air_id)
--     end

--     -- replace area with air
--     voxelmanip:set_data(new_data)
--     voxelmanip:write_to_map()
--     hs_maps.map_loaded = false

--     minetest.log("<hs_testutils> Successfully nuked the map")
-- end

function savemap(_, map_name)
    local path = minetest.get_worldpath() .. "/schems/" .. map_name .. ".mts"
        minetest.log("<hs_savemap> Saving map to " .. path)
        local result = minetest.create_schematic(
            {x=-100, y=0, z=-100},
            {x=100, y=100, z=100},
            {},
            path
        )

        if result == nil then
            minetest.log("error", "<hs_savemap> Failed to save map")
        else
            minetest.log("<hs_savemap> Saved map to " .. path)
        end
end

function register_commands()
    minetest.register_chatcommand("hs_nuke", {
        description = "Nukes the map",
        func = nuke
    })
    minetest.register_chatcommand("hs_savemap", {
        description = "Saves the map to a schematic",
        func = savemap
    })
end

minetest.register_on_mods_loaded(register_commands)