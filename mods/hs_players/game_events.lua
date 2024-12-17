function player_join(player)
    -- fetch the number of player's gems
    local player_name = player:get_player_name()
    local gems = get_gem_balance(player_name)
    hs_utils.send_private_bank_message(player_name, "You have " .. gems .. " gems.")

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
        core.log("Disconnected player " .. player_name)
    else
        core.log("Disconnected " .. team .. " " .. player_name)
        core.log("New player count: " .. num_hiders .. " hider(s), " .. num_seekers .. " seeker(s)")
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
        -- if the player was a hider, remove them from the team
        if player_team[player:get_player_name()] == "hider" then
            remove_from_hiders(player)
        end
        on_hiding_start(player, "seeker")
    end
    return true
end

function player_die(player, reason)
    if player_team[player:get_player_name()] == "hider" then
        on_hider_death(player)
    end
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

    -- if the lobby state has been triggered by the last
    -- hider dying, that hider would be teleported to the lobby
    -- while dead; to make the change less abrupt, let's leave the
    -- dead player on the game map and leave the lobby spawning to
    -- the player_respawn function
    core.log("Player HP: " .. player:get_hp())
    if player:get_hp() > 0 then
        spawn_player_in_lobby(player)
    end

    -- clear objects (e.g. potential leftover disguise entities on the map)
    core.clear_objects()

    restore_player_hp(player)
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

    -- spawn only hiders onto the game map, so they have time to hide
    -- without the seekers seeing them
    if player_team[player:get_player_name()] == "hider" then
        spawn_player_in_game_map(player)
    end

    restore_player_hp(player)
end

function on_seeking_start(player)
    -- update HUD
    update_game_state_hud_text(player, "Seeking time")

    -- spawn seekers
    if player_team[player:get_player_name()] == "seeker" then
        spawn_player_in_game_map(player)
    end
end

function timer_callback()
    -- update timer for all players
    for _, player in ipairs(core.get_connected_players()) do
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
        core.chat_send_all("Moving you to the lobby.")
        for _, player in ipairs(core.get_connected_players()) do
            on_lobby_start(player)
        end
        for _, player in ipairs(core.get_connected_players()) do
            update_hud_for_lobby(player)
        end
    elseif hs_gamesched.state == hs_gamesched.STATE_HIDING then
        core.chat_send_all("Moving you to the game map.")

        local not_yet_processed = {}
        for i = 1, #(core.get_connected_players()) do
            not_yet_processed[i] = i
        end

        local i = math.random(1, #not_yet_processed)
        while #not_yet_processed > 0 do
            local player = core.get_connected_players()[not_yet_processed[i]]
            on_hiding_start(player)
            table.remove(not_yet_processed, i)
            i = math.random(1, #not_yet_processed)
        end

        for _, player in ipairs(core.get_connected_players()) do
            update_hud_for_round(player)
        end
    elseif hs_gamesched.state == hs_gamesched.STATE_SEEKING then
        for _, player in ipairs(core.get_connected_players()) do
            on_seeking_start(player)
        end
    else
        core.log("warning", "Unknown game state: " .. hs_gamesched.state)
        return
    end
end

function hider_win_callback()
    -- give hiders a reward
    reward_players_in_team_for_winning("hider")
    reward_participants()
end

function seeker_win_callback()
    -- give seekers a reward
    reward_players_in_team_for_winning("seeker")
    reward_participants()
end

function reward_players_in_team_for_winning(team)
    for _, player in ipairs(core.get_connected_players()) do
        local player_name = player:get_player_name()
        if player_team[player_name] == team then
            increase_gem_balance(player_name, hs_players.GEMS_WIN_REWARD)
            local gems = get_gem_balance(player_name)
            hs_utils.send_private_bank_message(player_name, "You received " ..
                hs_players.GEMS_WIN_REWARD .. " gems for winning! You now have " .. gems .. " gems.")
        end
    end
end

function reward_participants()
    for _, player in ipairs(core.get_connected_players()) do
        local player_name = player:get_player_name()
        increase_gem_balance(player_name, hs_players.GEMS_PARTICIPATION_REWARD)
        local gems = get_gem_balance(player_name)
        hs_utils.send_private_bank_message(player_name, "You received " ..
            hs_players.GEMS_PARTICIPATION_REWARD .. " gems for participating! You now have " .. gems .. " gems.")
    end
end

function on_node_punched(pos, node, puncher, pointed_thing)
    local puncher_name = puncher:get_player_name()
    if player_team[puncher_name] == "hider" then
        local textures = core.registered_nodes[node["name"]].tiles

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
                local hider = core.get_player_by_name(hider_name)
                put_hider_out_of_hiding(hider)
                damage_hider(hider, puncher, 3)
            end
        end
    end
end

function on_disguise_entity_punch(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
    local hider_name = self._player_name

    if hider_name == nil then
        return
    end

    local hider = core.get_player_by_name(hider_name)
    core.log("Hider " .. hider_name .. " was punched by " .. puncher:get_player_name())
    damage_hider(hider, puncher, damage)
end
