player_team = {}
num_hiders = 0
num_seekers = 0

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

-- aligns player with the world coordinate system and
-- makes them face towards the positive z-axis
-- (to help hiders hide)
function align_player(player)
    local pos = player:get_pos()
    local yaw = player:get_look_horizontal()

    -- round every position component the to nearest integer
    pos.x = math.round(pos.x)
    pos.y = math.round(pos.y)
    pos.z = math.round(pos.z)

    -- change the player look direction
    player:set_look_horizontal(0)
end

function add_to_hiders(player)
    -- table.insert(hiders, player)
    player_team[player:get_player_name()] = "hider"
    num_hiders = num_hiders + 1

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
    -- table.insert(seekers, player)
    player_team[player:get_player_name()] = "seeker"
    num_seekers = num_seekers + 1

    minetest.log(player:get_player_name() .. " is now a seeker")
end

function player_join(player)
    -- if the teams have a different number of players,
    -- assign the new player into the team with less players
    -- and pick a random team otherwise
    minetest.log(num_hiders .. " hiders, " .. num_seekers .. " seekers")
    if num_hiders > num_seekers then
        add_to_seekers(player)
    elseif num_seekers > num_hiders then
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

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
    local props = puncher:get_properties()

    if player_team[puncher:get_player_name()] == "hider" then
        align_player(puncher)
    end
end)
