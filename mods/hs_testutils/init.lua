function nuke()
    hs_maps.load_map("empty", { x = -100, y = 0, z = -100 })
    -- hs_maps.map_loaded = false
    core.log("<hs_testutils> Successfully nuked the map")
end

function savemap(map_name)
    -- make the schems directory, if it doesn't yet exist
    local schems_dir = core.get_worldpath() .. "/schems"
    core.mkdir(schems_dir)

    local path = schems_dir .. "/" .. map_name .. ".mts"
    core.log("<hs_savemap> Saving map to " .. path)
    local result = core.create_schematic(
        { x = -100, y = 0, z = -100 },
        { x = 100, y = 100, z = 100 },
        {},
        path
    )

    if result == nil then
        core.log("error", "<hs_savemap> Failed to save map")
    else
        core.log("<hs_savemap> Saved map to " .. path)
        print(result)
    end
end

function register_commands()
    core.register_chatcommand("hs_nuke", {
        privs = {
            hs_loadmap = true
        },
        description = "Nukes the map",
        func = nuke
    })
    core.register_chatcommand("hs_savemap", {
        description = "Saves the map to a schematic",
        func = function(name, param)
            savemap(param)
        end
    })
    core.register_chatcommand("hs_loadmap", {
        privs = {
            hs_loadmap = true
        },
        description = "Loads a map",
        func = function(name, param)
            hs_maps.load_map(param, { x = -100, y = 0, z = -100 })
        end
    })
end

core.register_on_mods_loaded(register_commands)
