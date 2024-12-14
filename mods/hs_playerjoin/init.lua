player_team = {}       -- maps player names to team names
hider_hiding = {}      -- maps player names to whether they are hiding (stationary) or not
hider_node_name = {}   -- which node is a hider using as their disguise (player name --> node name)
hider_node_pos = {}    -- where is the node that the hider is using as their disguise
hider_entity = {}      -- the entity that is attached to the hider
disguise_entities = {} -- stores all defined disguise entities (entity name --> entity table)
num_hiders = 0
num_seekers = 0

disguise_entity_prefix = "hs_playerjoin:disguise_entity_"
default_disguise_node = "default:brick"

transparent = { "transparent.png", "transparent.png", "transparent.png", "transparent.png", "transparent.png",
    "transparent.png" }

function hide_player(player)
    -- hide the player's nametag
    local c = player:get_nametag_attributes().color
    c.a = 0 -- set alpha to 0 to make it completely transparent
    player:set_nametag_attributes({ color = c })

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
    player:set_nametag_attributes({ color = c })

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
function put_hider_into_hiding(player, node_name)
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


    -- change the player look direction
    player:set_look_horizontal(0)

    -- hide the player and their block entity
    local entity = hider_entity[player_name]

    if entity ~= nil then
        entity:set_properties({ is_visible = false })
        player:set_properties({ pointable = false })
        minetest.log("Hid the disguise entity for player " .. player_name)
    else
        minetest.warn("Could not find the active disguise entity for player " .. player_name)
    end

    -- place a node at the player's position
    -- local node_name = hider_node_name[player_name]
    if node_name == nil then
        node_name = node_name
    end

    local new_pos = { x = pos_x, y = pos_y, z = pos_z }
    minetest.set_node(new_pos, { name = node_name })
    hider_node_pos[player_name] = new_pos
    hider_hiding[player_name] = true

    -- move the player so they can see around their block
    -- try to place the player into all neighboring
    -- nodes until one is empty
    local pos_offsets = {
        0, 1, 0,
        -1, 0, 0,
        1, 0, 0,
        0, 0, -1,
        0, 0, 1,
        0, -1, 0
    }
    local pos_offset_weight = 1 -- how far to actually move the player

    for i = 1, 16, 3 do
        local x_offset = pos_offsets[i]
        local y_offset = pos_offsets[i + 1]
        local z_offset = pos_offsets[i + 2]

        -- check if the node is air
        if minetest.get_node_or_nil({ x = pos_x + x_offset, y = pos_y + y_offset, z = pos_z + z_offset }).name == "air" then
            pos_x = pos_x + (x_offset * pos_offset_weight)
            pos_y = pos_y + (y_offset * pos_offset_weight)
            pos_z = pos_z + (z_offset * pos_offset_weight)
            break
        end
    end

    local new_pos = { x = pos_x, y = pos_y, z = pos_z }
    player:set_pos(new_pos)

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

    -- change the player's entity to the new one
    if hider_entity[player_name] ~= nil then
        hider_entity[player_name]:remove()
        hider_entity[player_name] = nil
    end

    -- make the player and their block entity visible again
    -- local entity = hider_entity[player_name]
    local node_name = hider_node_name[player_name]
    local entity_name = disguise_entity_prefix .. node_name:gsub(":", "_")
    local entity = minetest.add_entity(player:get_pos(), entity_name)

    -- define the on_punch callback for the entity
    attach_punch_callback_to_disguise_entity(entity)

    hider_entity[player_name] = entity
    attach_disguise_entity_to_player(entity, player)


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
        hider:set_hp(hider_hp - damage, { type = "punch", object = puncher.object })
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

function attach_disguise_entity_to_player(entity, player)
    local player_name = player:get_player_name()
    entity:get_luaentity()._player_name = player_name
    entity:set_attach(player, "", { x = 0, y = 0, z = 0 })
    hider_entity[player_name] = entity
end

function attach_punch_callback_to_disguise_entity(entity)
    entity:get_luaentity().on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
        on_disguise_entity_punch(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
    end
end

function add_to_hiders(player)
    local player_name = player:get_player_name()

    -- table.insert(hiders, player)
    player_team[player_name] = "hider"
    num_hiders = num_hiders + 1

    hide_player(player)

    player:set_properties({
        collisionbox = { -0.4, 0.4, -0.4, 0.5, -0.4, 0.4 }, -- make the player smaller (to fit inside 1x1x1 openings)
        eye_height = 0.25,
    })

    -- attach the player's disguise to them
    -- we use a hardcoded default entity for the hider which
    -- they get when they join and retain it before they punch a node
    -- but we could instead choose a random block
    local player_pos = player:get_pos()
    local entity = minetest.add_entity(player_pos, disguise_entity_prefix .. default_disguise_node:gsub(":", "_"))
    attach_punch_callback_to_disguise_entity(entity)
    hider_node_name[player_name] = default_disguise_node
    attach_disguise_entity_to_player(entity, player)

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
        position = { x = 0, y = 1 },
        offset = { x = 10, y = -10 },
        alignment = { x = 1, y = -1 },
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

function player_leave(player)
    -- if the player is a hider, remove their disguise entity
    local player_name = player:get_player_name()

    if player_team[player_name] == "hider" then
        remove_hider_entity(player)
    end
end

-- when a player respawns, send them to the spawn area
function player_respawn(player)
    local pos = hs_maps.spawn_pos
    pos.x = pos.x + 100
    pos.y = pos.y + 1
    pos.z = pos.z + 100
    player:set_pos(pos)

    if player_team[player:get_player_name()] == "hider" then
        put_hider_out_of_hiding(player)
    end

    return true
end

-- minetest.register_on_mods_loaded(register_hider_model)
minetest.register_on_joinplayer(player_join)
minetest.register_on_leaveplayer(player_leave)

-- registers disguise entities for all nodes in the default mod
function register_disguise_entities_for_nodes_in_default_mod()
    for _, node in pairs(minetest.registered_nodes) do
        if node.drawtype == "normal" then
            register_disguise_entity(node.name)
        end
    end
end

-- registers a disguise entity for the given node
function register_disguise_entity(node_name)
    -- check if the node is registered
    if minetest.registered_nodes[node_name] == nil then
        return
    end

    local node = minetest.registered_nodes[node_name]
    local entity_name = disguise_entity_prefix .. node_name:gsub(":", "_")

    -- check if the disguise entity has already been registered
    -- for this node
    if minetest.registered_entities[entity_name] ~= nil then
        return
    end

    -- generate the texture table
    local entity_textures = {}
    if #node.tiles == 1 then
        local t = node.tiles[1]
        entity_textures = { t, t, t, t, t, t }
    elseif #node.tiles == 2 then
        local t1 = node.tiles[1]
        local t2 = node.tiles[2]
        entity_textures = { t1, t1, t2, t2, t2, t2 }
    else
        for _, t in pairs(node.tiles) do
            table.insert(entity_textures, t)
        end
        while #entity_textures < 6 do
            table.insert(entity_textures, entity_textures[#entity_textures])
        end
    end

    for i = 1, 6 do
        -- an element of the tiles table can also be another table
        -- which contains the texture name, but also defines some additional
        -- properties; we need to extract the texture name in that case
        if type(entity_textures[i]) == "table" then
            if entity_textures[i].name ~= nil then
                entity_textures[i] = entity_textures[i].name
            elseif entity_textures[i].image ~= nil then
                entity_textures[i] = entity_textures[i].image
            end
        end
    end

    -- create the entity
    local disguise_entity = {
        initial_properties = {
            hp_max = 50,
            physical = true,
            collide_with_objects = false,
            collisionbox = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
            selectionbox = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
            visual = "cube",
            shaded = true,
            show_on_minimap = false,
            textures = entity_textures,
        },
        _player_name = nil
    }



    -- register the entity
    minetest.register_entity(entity_name, disguise_entity)
    disguise_entities[entity_name] = disguise_entity
    minetest.log("Registered a disguise entity for node " .. node_name)
end

function on_disguise_entity_punch(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
    local hider_name = self._player_name

    if hider_name == nil then
        return
    end

    local hider = minetest.get_player_by_name(hider_name)
    minetest.log("Hider " .. hider_name .. " was punched by " .. puncher:get_player_name())
    damage_hider(hider, puncher, damage)
end

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
    local puncher_name = puncher:get_player_name()
    if player_team[puncher_name] == "hider" then
        local textures = minetest.registered_nodes[node["name"]].tiles

        -- if the puncher is a hider and they are not already hiding,
        -- put them in hiding
        if not hider_hiding[puncher_name] then
            -- get the name of the punched block
            local node_name = node["name"]

            local entity_name = disguise_entity_prefix .. node_name:gsub(":", "_")

            -- if the disguise entity for this node exists,
            -- put the hider in hiding
            if disguise_entities[entity_name] ~= nil then
                -- set the hider's node to the punched node
                hider_node_name[puncher_name] = node_name

                put_hider_into_hiding(puncher, hider_node_name[puncher_name])
            else
                -- TODO notify the player that they cannot hide as this node
            end
        end
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

-- register disguise entities for all nodes in the default mod
register_disguise_entities_for_nodes_in_default_mod()
