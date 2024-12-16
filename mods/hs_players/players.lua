function determine_player_team(player)
    -- if the teams have a different number of players,
    -- assign the new player into the team with less players
    -- and pick a random team otherwise
    core.log(num_hiders .. " hiders, " .. num_seekers .. " seekers")
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
    core.log("Spawned player " .. player:get_player_name() .. " in lobby")
end

function spawn_player_in_game_map(player)
    local new_pos = get_map_center_pos(hs_maps.map_pos)
    player:set_pos(new_pos)
    core.log("Spawned player " .. player:get_player_name() .. " onto the game map")
end

function add_player_to_game(player, team)
    if team == "hider" then
        add_to_hiders(player)
        hs_utils.send_private_message(player, "You are now a hider.")
    elseif team == "seeker" then
        add_to_seekers(player)
        hs_utils.send_private_message(player, "You are now a seeker.")
    end
end
