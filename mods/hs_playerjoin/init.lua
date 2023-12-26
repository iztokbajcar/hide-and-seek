hiders = {}
seekers = {}

transparent = {"transparent.png", "transparent.png", "transparent.png", "transparent.png", "transparent.png", "transparent.png"}

function hide_player(player)
    -- hide the player's nametag
    local c = player:get_nametag_attributes().color
    c.a = 0  -- set alpha to 0 to make it completely transparent
    player:set_nametag_attributes({color = c})

    -- make the player transparent
    default.player_set_textures(player, transparent)

    -- make the player invisible on the minimap
    player:set_properties({
        show_on_minimap = false
    })
end

function add_to_hiders(player)
    table.insert(hiders, player)

    hide_player(player)

    -- make the player shorter (to fit inside 1x1x1 openings)
    player:set_properties({
        collisionbox = {-0.5, 0.5, 0, 1, -0.5, 0.5},
        eye_height = 0.25,
    })

    -- attach the player's disguise to them
    local player_pos = player:get_pos()
    local node = minetest.add_entity(player_pos, "hs_playerjoin:testentity")
    node:set_attach(player, "", {x=0, y=0, z=0})  -- half a node above the ground

    minetest.log(player:get_player_name() .. " is now a hider")
end

function add_to_seekers(player)
    table.insert(seekers, player)
    minetest.log(player:get_player_name() .. " is now a seeker")
end

function player_join(player)
    -- if the teams have a different number of players,
    -- assign the new player into the team with less players
    -- and pick a random team otherwise
    minetest.log(#hiders .. " hiders, " .. #seekers .. " seekers")
    if #hiders > #seekers then
        add_to_seekers(player)
    elseif #seekers > #hiders then
        add_to_hiders(player)
    else
        math.randomseed(os.clock())
        local r = math.random(0, 1)
        
        if r == 0 then
            add_to_hiders(player)
        else
            add_to_seekers(player)
        end
    end
end

-- minetest.register_on_mods_loaded(register_hider_model)
minetest.register_on_joinplayer(player_join)

-- register the node entity
minetest.register_entity("hs_playerjoin:testentity", {
    initial_properties = {
        physical = true,
        collide_with_objects = false,
        collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
        selectionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
        visual = "cube",
        shaded = true,
        show_on_minimap = false,
        textures = {
            "farming_straw.png",
            "farming_straw.png",
            "farming_straw.png",
            "farming_straw.png",
            "farming_straw.png",
            "farming_straw.png",
        },
    },
});
