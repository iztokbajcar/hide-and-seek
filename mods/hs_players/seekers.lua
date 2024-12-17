function on_seeker_death(seeker)
    local seeker_name = seeker:get_player_name()
    core.log("Seeker " .. seeker_name .. " died")

    -- if the last seeker died, the hiders win
    if num_seekers == 1 then
        -- remove the seeker from the seekers table
        -- and end the game
        remove_from_seekers(seeker)
        core.log("All seekers have died")
        hs_gamesched.on_hider_win()
    end
end

function add_to_seekers(player)
    -- table.insert(seekers, player)
    player_team[player:get_player_name()] = "seeker"
    num_seekers = num_seekers + 1

    core.log(player:get_player_name() .. " is now a seeker")

    -- update the seeker count HUD text for all players
    for _, player in ipairs(core.get_connected_players()) do
        update_seeker_count_text(player, num_seekers)
    end
end

function remove_from_seekers(player)
    player_team[player:get_player_name()] = nil
    num_seekers = num_seekers - 1

    core.log(player:get_player_name() .. " is no longer a seeker")

    -- update the seeker count HUD text for all players
    for _, player in ipairs(core.get_connected_players()) do
        update_seeker_count_text(player, num_seekers)
    end
end
