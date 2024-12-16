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
