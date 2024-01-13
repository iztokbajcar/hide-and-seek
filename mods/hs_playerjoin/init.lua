player_team = {}  -- maps player names to team names
hider_hiding = {}  -- maps player names to whether they are hiding (stationary) or not
hider_node_name = {}  -- which node is a hider using as their disguise
hider_node_pos = {}  -- where is the node that the hider is using as their disguise
hider_entity = {} -- the entity that is attached to the hider
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

function unhide_player(player)
    -- show the player's nametag
    local c = player:get_nametag_attributes().color
    c.a = 255
    player:set_nametag_attributes({color = c})

    -- set the player's default texture back
    default.player_set_textures(player, nil)

    -- make the player visible on the minimap
    player:set_properties({
        show_on_minimap = true
    })
end

-- aligns the hider with the world coordinate system,
-- makes them face towards the positive z-axis,
-- makes their disguise invisible
-- and spawns a new node at their location
function put_hider_into_hiding(player)
    local player_name = player:get_player_name()
    if player_team[player_name] ~= "hider" then
        return
    end

    if hider_hiding[player_name] then
        return
    end

    local pos = player:get_pos()
    local yaw = player:get_look_horizontal()

    -- round every position component the to nearest integer
    local pos_x = math.round(pos.x)
    local pos_y = math.round(pos.y)
    local pos_z = math.round(pos.z)
    local new_pos = {x=pos_x, y=pos_y, z=pos_z}
    player:set_pos(new_pos)

    -- change the player look direction
    player:set_look_horizontal(0)

    -- hide the player and their block entity
    local entity = hider_entity[player_name]
    entity:set_properties({is_visible = false})
    player:set_properties({pointable = false})

    -- place a node at the player's position
    local node_name = hider_node_name[player_name]
    if node_name == nil then
        node_name = "farming:straw"
    end
    minetest.set_node(new_pos, {name=node_name})
    hider_node_pos[player_name] = new_pos
    hider_hiding[player_name] = true

    minetest.log(player_name .. " is now in hiding")
end

-- undoes the effects of put_hider_into_hiding
function put_hider_out_of_hiding(player)
    local player_name = player:get_player_name()

    -- mark the player as not hiding
    hider_hiding[player_name] = false

    -- remove the node at the player's position
    if hider_node_pos[player_name] ~= nil then
        minetest.remove_node(hider_node_pos[player_name])
    end

    -- make the player and their block entity visible again
    local entity = hider_entity[player_name]
    entity:set_properties({is_visible = true})
    player:set_properties({pointable = true})


    minetest.log(player_name .. " is no longer in hiding")
end

function check_hider_movement()
    for _, player in ipairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()
        if player_team[player_name] == "hider" and hider_hiding[player_name] == true then
            -- check if the player is moving
            local c = player:get_player_control()
            if c["up"] or c["down"] or c["left"] or c["right"] or c["jump"] then
               put_hider_out_of_hiding(player)
            end
        end
    end
end

function damage_hider(hider, puncher, damage)
    local hider_hp = hider:get_hp()
    if hider_hp > 0 then
        hider:set_hp(hider_hp - damage, {type = "punch", object = puncher})
        minetest.log("Hider " .. hider:get_player_name() .. " damaged by " .. puncher:get_player_name())
    end
end

function remove_hider_entity(hider)
    -- get the entity
    local entity = hider_entity[hider:get_player_name()]
    entity:remove()
end

function on_hider_death(hider)
    minetest.log("Hider " .. hider:get_player_name() .. " died")
    -- remove the hider's entity
    remove_hider_entity(hider)
end

function add_to_hiders(player)
    local player_name = player:get_player_name()

    -- table.insert(hiders, player)
    player_team[player_name] = "hider"
    num_hiders = num_hiders + 1

    hide_player(player)

    player:set_properties({
        collisionbox = {-0.4, 0.4, -0.4, 0.5, -0.4, 0.4},  -- make the player smaller (to fit inside 1x1x1 openings)
        eye_height = 0.25,
    })

    -- attach the player's disguise to them
    local player_pos = player:get_pos()
    local entity = minetest.add_entity(player_pos, "hs_playerjoin:disguise_entity")
    hider_node_name[player_name] = "farming:straw"  -- TODO change later
    entity:get_luaentity()._player_name = player_name
    entity:set_attach(player, "", {x=0, y=0, z=0})
    hider_entity[player_name] = entity

    minetest.log(player_name .. " is now a hider")
end

function add_to_seekers(player)
    -- table.insert(seekers, player)
    player_team[player:get_player_name()] = "seeker"
    num_seekers = num_seekers + 1

    minetest.log(player:get_player_name() .. " is now a seeker")
end

function display_team_text_on_hud(player)
    player:hud_add({
        hud_elem_type = "text",
        position = {x=0, y=1},
        offset = {x=10, y=-10},
        alignment = {x=1, y=-1},
        text = "You are a " .. player_team[player:get_player_name()],
        number = 0xFFFF00,
    })
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

    display_team_text_on_hud(player)
end

-- when a player respawns, send them to the spawn area
function player_respawn(player)
    pos = hs_maps.spawn_pos
    pos.x = pos.x + 100
    pos.y = pos.y + 1
    pos.z = pos.z + 100
    player:set_pos(pos)
    return true
end

-- minetest.register_on_mods_loaded(register_hider_model)
minetest.register_on_joinplayer(player_join)

-- register the node entity
local disguise_entity = {
    initial_properties = {
        hp_max = 50,
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
    _player_name = nil
}

function disguise_entity:on_punch(puncher, time_from_last_punch, tool_capabilities, dir, damage)
    local hider_name = self._player_name

    if hider_name == nil then
        return
    end

    local hider = minetest.get_player_by_name(hider_name)
    minetest.log("Hider " .. hider_name .. " was punched")
    damage_hider(hider, puncher, damage)
end

minetest.register_entity("hs_playerjoin:disguise_entity", disguise_entity)

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
    if player_team[puncher:get_player_name()] == "hider" then
        -- if the puncher is a hider, put them in hiding
        put_hider_into_hiding(puncher)
    elseif player_team[puncher:get_player_name()] == "seeker" then
        -- if the puncher is a seeker, check if they punched a node hiding a hider
        -- if so, unhide the punched hider and damage them
        for hider_name, hider_node in pairs(hider_node_pos) do
            if hider_node.x == pos.x and hider_node.y == pos.y and hider_node.z == pos.z then
                local hider = minetest.get_player_by_name(hider_name)
                put_hider_out_of_hiding(hider)
                damage_hider(hider, puncher, 3)
            end
        end
    end
end)

-- periodically check for hider movement
minetest.register_globalstep(check_hider_movement)

minetest.register_on_dieplayer(function(player, reason)
    if player_team[player:get_player_name()] == "hider" then
        on_hider_death(player)
    end
end)

minetest.register_on_respawnplayer(player_respawn)
