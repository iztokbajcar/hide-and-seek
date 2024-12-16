player_team = {}       -- maps player names to team names
hider_hiding = {}      -- maps player names to whether they are hiding (stationary) or not
hider_node_name = {}   -- which node is a hider using as their disguise (player name --> node name)
hider_node_pos = {}    -- where is the node that the hider is using as their disguise
hider_entity = {}      -- the entity that is attached to the hider
hider_pos_offsets = {} -- the offset of the player's position from their hiding node (player name --> pos)
disguise_entities = {} -- stores all defined disguise entities (entity name --> entity table)
hud_elements = {}      -- stores all hud elements of a player (player name --> (hud element name --> hud element id))
num_hiders = 0
num_seekers = 0

disguise_entity_prefix = "hs_players:disguise_entity_"
default_disguise_node = "default:brick"

transparent = { "transparent.png", "transparent.png", "transparent.png", "transparent.png", "transparent.png",
    "transparent.png" }

function set_hider_properties(player)
    player:set_properties({
        collisionbox = { -0.4, 0.4, -0.4, 0.5, -0.5, 0.4 }, -- make the player smaller (to fit inside 1x1x1 openings)
        selectionbox = { -0.4, 0.4, -0.4, 0.5, -0.5, 0.4 },
        eye_height = 0.25,
    })
end

function set_default_player_properties(player)
    player:set_properties({
        collisionbox = { -0.3, 0, -0.3, 0.3, 1.7, 0.3 },
        selectionbox = { -0.3, 0, -0.3, 0.3, 1.7, 0.3, rotate = false },
        eye_height = 1.625
    })
end

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
        minetest.log("warning", "Could not find the active disguise entity for player " .. player_name)
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

        local pos_offset_x = x_offset * pos_offset_weight
        local pos_offset_y = y_offset * pos_offset_weight
        local pos_offset_z = z_offset * pos_offset_weight

        hider_pos_offsets[player_name] = {
            x = pos_offset_x,
            y = pos_offset_y,
            z = pos_offset_z
        }

        -- check if the node is air
        if minetest.get_node_or_nil({ x = pos_x + x_offset, y = pos_y + y_offset, z = pos_z + z_offset }).name == "air" then
            pos_x = pos_x + pos_offset_x
            pos_y = pos_y + pos_offset_y
            pos_z = pos_z + pos_offset_z
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

    -- restore the hider's position to the center of their entity
    local pos = player:get_pos()
    local pos_offset = hider_pos_offsets[player_name]

    local pos_x = pos.x - pos_offset.x
    local pos_y = pos.y - pos_offset.y
    local pos_z = pos.z - pos_offset.z
    local new_pos = { x = pos_x, y = pos_y, z = pos_z }
    player:set_pos(new_pos)
    hider_pos_offsets[player_name] = nil

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

function remove_hider_entity(hider_name)
    -- get the entity
    local entity = hider_entity[hider_name]
    entity:set_detach()
    entity:remove()
    hider_entity[hider_name] = nil
    minetest.log("Removed disguise entity for player " .. hider_name)
end

function on_hider_death(hider)
    local hider_name = hider:get_player_name()
    minetest.log("Hider " .. hider_name .. " died")
    -- remove the hider's entity
    remove_hider_entity(hider_name)
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
    set_hider_properties(player)

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

    -- update the hider count HUD text for all players
    for _, player in ipairs(minetest.get_connected_players()) do
        update_hider_count_text(player, num_hiders)
    end
end

function remove_from_hiders(player)
    local player_name = player:get_player_name()

    remove_hider_entity(player_name)
    set_default_player_properties(player)
    unhide_player(player)

    num_hiders = num_hiders - 1
    player_team[player_name] = nil

    minetest.log(player_name .. " is no longer a hider")

    -- update the hider count HUD text for all players
    for _, player in ipairs(minetest.get_connected_players()) do
        update_hider_count_text(player, num_hiders)
    end
end

function add_to_seekers(player)
    -- table.insert(seekers, player)
    player_team[player:get_player_name()] = "seeker"
    num_seekers = num_seekers + 1

    minetest.log(player:get_player_name() .. " is now a seeker")

    -- update the seeker count HUD text for all players
    for _, player in ipairs(minetest.get_connected_players()) do
        update_hider_count_text(player, num_seekers)
    end
end

function remove_from_seekers(player)
    player_team[player:get_player_name()] = nil
    num_seekers = num_seekers - 1

    minetest.log(player:get_player_name() .. " is no longer a seeker")

    -- update the seeker count HUD text for all players
    for _, player in ipairs(minetest.get_connected_players()) do
        update_seeker_count_text(player, num_seekers)
    end
end

function update_game_state_hud_text(player, text)
    local player_name = player:get_player_name()
    local game_state_hud = hud_elements[player_name]["game_state"]

    if game_state_hud == nil then
        minetest.log("warning", "Tried to update game state HUD text for player " .. player_name .. " but it was nil")
        return
    else
        player:hud_change(game_state_hud, "text", text)
    end
end

function update_game_state_timer_hud_text(player, text)
    local player_name = player:get_player_name()
    local state_timer_hud = hud_elements[player_name]["state_timer"]

    if state_timer_hud == nil then
        minetest.log("warning",
            "Tried to update game state timer HUD text for player " .. player_name .. " but it was nil")
        return
    else
        player:hud_change(state_timer_hud, "text", text)
    end
end

function update_team_hud_text(player, text)
    local player_name = player:get_player_name()
    local team_hud = hud_elements[player_name]["team"]

    if team_hud == nil then
        minetest.log("warning", "Tried to update team HUD text for player " .. player_name .. " but it was nil")
        return
    else
        player:hud_change(team_hud, "text", text)
    end
end

function update_hider_count_text(player, text)
    local player_name = player:get_player_name()
    local hider_count_hud = hud_elements[player_name]["hider_count"]

    if hider_count_hud == nil then
        minetest.log("warning", "Tried to update hider count HUD text for player " .. player_name .. " but it was nil")
        return
    else
        player:hud_change(hider_count_hud, "text", text)
    end
end

function update_hider_count_desc_text(player, text)
    local player_name = player:get_player_name()
    local hider_count_desc_hud = hud_elements[player_name]["hider_count_desc"]

    if hider_count_desc_hud == nil then
        minetest.log("warning", "Tried to update hider count description HUD text for player " ..
            player_name .. " but it was nil")
        return
    else
        player:hud_change(hider_count_desc_hud, "text", text)
    end
end

function update_seeker_count_text(player, text)
    local player_name = player:get_player_name()
    local seeker_count_hud = hud_elements[player_name]["seeker_count"]

    if seeker_count_hud == nil then
        minetest.log("warning", "Tried to update seekers count HUD text for player " .. player_name .. " but it was nil")
        return
    else
        player:hud_change(seeker_count_hud, "text", text)
    end
end

function update_seeker_count_desc_text(player, text)
    local player_name = player:get_player_name()
    local seeker_count_desc_hud = hud_elements[player_name]["seeker_count_desc"]

    if seeker_count_desc_hud == nil then
        minetest.log("warning", "Tried to update seekers count description HUD text for player " ..
            player_name .. " but it was nil")
        return
    else
        player:hud_change(seeker_count_desc_hud, "text", text)
    end
end

function determine_player_team(player)
    -- if the teams have a different number of players,
    -- assign the new player into the team with less players
    -- and pick a random team otherwise
    minetest.log(num_hiders .. " hiders, " .. num_seekers .. " seekers")
    if num_hiders > num_seekers then
        return "seeker"
    elseif num_seekers > num_hiders then
        return "hider"
    else
        math.randomseed(os.clock())
        local r = math.random(0, 1)

        if r == 0 then
            return "hider"
        else
            return "seeker"
        end
    end
end

function get_map_center_pos(map_pos)
    return { x = map_pos.x + 100, y = map_pos.y + 3, z = map_pos.z + 100 }
end

function spawn_player_in_lobby(player) -- move the player a few blocks above the
    -- center of the lobby area
    local new_pos = get_map_center_pos(hs_maps.lobby_pos)
    player:set_pos(new_pos)
    minetest.log("Spawned player " .. player:get_player_name() .. " in lobby")
end

function spawn_player_in_game_map(player)
    local new_pos = get_map_center_pos(hs_maps.map_pos)
    player:set_pos(new_pos)
    minetest.log("Spawned player " .. player:get_player_name() .. " onto the game map")
end

function add_player_to_game(player, team)
    if team == "hider" then
        add_to_hiders(player)
    elseif team == "seeker" then
        add_to_seekers(player)
    end
end

function setup_player_hud(player)
    local player_name = player:get_player_name()
    local team_text = player:hud_add({
        type = "text",
        position = { x = 0, y = 1 },
        offset = { x = 10, y = -10 },
        alignment = { x = 1, y = -1 },
        text = "",
        number = 0xFFFF00,
    })

    local game_state_text = player:hud_add({
        type = "text",
        position = { x = 1, y = 0.5 },
        offset = { x = -100, y = 0 },
        alignment = { x = 0, y = 0 },
        text = "",
        number = 0x00FF00,
    })

    local state_timer_text = player:hud_add({
        type = "text",
        position = { x = 1, y = 0.5 },
        offset = { x = -100, y = 20 },
        alignment = { x = 0, y = 0 },
        text = "",
        number = 0xFFFFFF,
    })

    local hider_count_text = player:hud_add({
        type = "text",
        position = { x = 1, y = 0.5 },
        offset = { x = -120, y = 40 },
        alignment = { x = -1, y = 0 },
        text = "",
        number = 0x00FFFF,
    })

    local hider_count_description_text = player:hud_add({
        type = "text",
        position = { x = 1, y = 0.5 },
        offset = { x = -70, y = 40 },
        aligment = { x = 1, y = 0 },
        text = "",
        number = 0xFFFFFF,
    })

    local seeker_count_text = player:hud_add({
        type = "text",
        position = { x = 1, y = 0.5 },
        offset = { x = -120, y = 60 },
        alignment = { x = -1, y = 0 },
        text = "",
        number = 0xFF0000,
    })

    local seeker_count_description_text = player:hud_add({
        type = "text",
        position = { x = 1, y = 0.5 },
        offset = { x = -70, y = 60 },
        aligment = { x = 1, y = 0 },
        text = "",
        number = 0xFFFFFF,
    })

    hud_elements[player_name] = {}
    hud_elements[player_name]["team"] = team_text
    hud_elements[player_name]["game_state"] = game_state_text
    hud_elements[player_name]["state_timer"] = state_timer_text
    hud_elements[player_name]["hider_count"] = hider_count_text
    hud_elements[player_name]["hider_count_desc"] = hider_count_description_text
    hud_elements[player_name]["seeker_count"] = seeker_count_text
    hud_elements[player_name]["seeker_count_desc"] = seeker_count_description_text
end

function player_join(player)
    setup_player_hud(player)

    if hs_gamesched.state == hs_gamesched.STATE_LOBBY then
        on_lobby_start(player)
        update_hud_for_lobby(player)
    elseif
        hs_gamesched.state == hs_gamesched.STATE_HIDING
        or hs_gamesched.state == hs_gamesched.STATE_SEEKING
    then
        -- determine the player's team
        on_hiding_start(player)
        update_hud_for_round(player)
    end
end

function remove_player(player_name)
    local team = player_team[player_name]

    if player_team[player_name] == "hider" then
        hider_hiding[player_name] = nil
        hider_node_name[player_name] = nil
        hider_node_pos[player_name] = nil
        hider_entity[player_name] = nil
        hider_pos_offsets[player_name] = nil
        num_hiders = num_hiders - 1
    elseif player_team[player_name] == "seeker" then
        num_seekers = num_seekers - 1
    end

    player_team[player_name] = nil
    hud_elements[player_name] = nil

    if team == nil then
        minetest.log("Disconnected player " .. player_name)
    else
        minetest.log("Disconnected " .. team .. " " .. player_name)
        minetest.log("New player count: " .. num_hiders .. " hider(s), " .. num_seekers .. " seeker(s)")
    end
end

function player_leave(player)
    -- if the player is a hider, remove their disguise entity
    local player_name = player:get_player_name()

    if player_team[player_name] == "hider" then
        remove_from_hiders(player)
    elseif player_team[player_name] == "seeker" then
        remove_from_seekers(player)
    end
    remove_player(player_name)
end

-- when a player respawns, send them to the lobby area
-- if the lobby is active, otherwise spawn them into the game as a seeker
function player_respawn(player)
    if hs_gamesched.state == hs_gamesched.STATE_LOBBY then
        on_lobby_start(player)
    else
        on_hiding_start(player, "seeker")
    end
    return true
end

-- minetest.register_on_mods_loaded(register_hider_model)
minetest.register_on_joinplayer(player_join)
minetest.register_on_leaveplayer(player_leave)


function update_hud_for_lobby(player)
    update_game_state_hud_text(player, "Lobby")
    update_team_hud_text(player, "")
    update_hider_count_text(player, "")
    update_hider_count_desc_text(player, "")
    update_seeker_count_text(player, "")
    update_seeker_count_desc_text(player, "")
end

function update_hud_for_round(player)
    local team = player_team[player:get_player_name()]
    update_game_state_hud_text(player, "Hiding time")
    update_team_hud_text(player, "You are a " .. team)
    update_hider_count_text(player, num_hiders)
    update_hider_count_desc_text(player, "hider(s)")
    update_seeker_count_text(player, num_seekers)
    update_seeker_count_desc_text(player, "seeker(s)")
end

-- handles the game state change to lobby
function on_lobby_start(player)
    local player_name = player:get_player_name()
    if player_team[player_name] == "hider" and hider_hiding[player_name] then
        -- if the player is a hider and is hiding,
        -- put them out of hiding
        put_hider_out_of_hiding(player)
    end

    if player_team[player_name] == "hider" then
        -- remove the player form the hiders team
        -- and restore their original properties
        remove_from_hiders(player)
    elseif player_team[player_name] == "seeker" then
        -- remove the player from the seekers team
        remove_from_seekers(player)
    end

    unhide_player(player)
    spawn_player_in_lobby(player)
end

function on_hiding_start(player, force_team)
    -- if a team choice is being forced, use that team,
    -- otherwise determine it based on the current player distribution
    -- among teams
    local team = force_team
    if team == nil then
        team = determine_player_team(player)
    end

    add_player_to_game(player, team)
    spawn_player_in_game_map(player)
end

function on_seeking_start(player)
    -- update HUD
    update_game_state_hud_text(player, "Seeking time")
end

function timer_callback()
    -- update timer for all players
    for _, player in ipairs(minetest.get_connected_players()) do
        local time_left = hs_gamesched.timer_value
        local s = nil
        if time_left >= 10 then
            s = string.format("%i", time_left)
        else
            s = string.format("%.1f", time_left)
        end

        update_game_state_timer_hud_text(player, "Time left: " .. s)
    end
end

-- this function is called by gamesched when
-- the game state changes
function game_state_callback()
    if hs_gamesched.state == hs_gamesched.STATE_LOBBY then
        -- move all players to the lobby
        minetest.chat_send_all("Moving you to the lobby.")
        for _, player in ipairs(minetest.get_connected_players()) do
            on_lobby_start(player)
        end
        for _, player in ipairs(minetest.get_connected_players()) do
            update_hud_for_lobby(player)
        end
    elseif hs_gamesched.state == hs_gamesched.STATE_HIDING then
        minetest.chat_send_all("Moving you to the game map.")
        -- TODO shuffle player list, so that they aren't always
        -- put into the same team
        for _, player in ipairs(minetest.get_connected_players()) do
            on_hiding_start(player)
        end
        for _, player in ipairs(minetest.get_connected_players()) do
            update_hud_for_round(player)
        end
    elseif hs_gamesched.state == hs_gamesched.STATE_SEEKING then
        minetest.chat_send_all(minetest.colorize("#FFFF00", "The seekers have been released. Good luck!"))
        for _, player in ipairs(minetest.get_connected_players()) do
            on_seeking_start(player)
        end
    else
        minetest.log("warning", "Unknown game state: " .. hs_gamesched.state)
        return
    end
end

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

hs_players = {}
hs_players.timer_callback = timer_callback
hs_players.game_state_callback = game_state_callback
