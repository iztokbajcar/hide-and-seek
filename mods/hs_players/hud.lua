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

function update_game_state_hud_text(player, text)
    local player_name = player:get_player_name()
    local game_state_hud = hud_elements[player_name]["game_state"]

    if game_state_hud == nil then
        core.log("warning", "Tried to update game state HUD text for player " .. player_name .. " but it was nil")
        return
    else
        player:hud_change(game_state_hud, "text", text)
    end
end

function update_game_state_timer_hud_text(player, text)
    local player_name = player:get_player_name()
    local state_timer_hud = hud_elements[player_name]["state_timer"]

    if state_timer_hud == nil then
        core.log("warning",
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
        core.log("warning", "Tried to update team HUD text for player " .. player_name .. " but it was nil")
        return
    else
        player:hud_change(team_hud, "text", text)
    end
end

function update_hider_count_text(player, text)
    local player_name = player:get_player_name()
    local hider_count_hud = hud_elements[player_name]["hider_count"]

    if hider_count_hud == nil then
        core.log("warning", "Tried to update hider count HUD text for player " .. player_name .. " but it was nil")
        return
    else
        player:hud_change(hider_count_hud, "text", text)
    end
end

function update_hider_count_desc_text(player, text)
    local player_name = player:get_player_name()
    local hider_count_desc_hud = hud_elements[player_name]["hider_count_desc"]

    if hider_count_desc_hud == nil then
        core.log("warning", "Tried to update hider count description HUD text for player " ..
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
        core.log("warning", "Tried to update seekers count HUD text for player " .. player_name .. " but it was nil")
        return
    else
        player:hud_change(seeker_count_hud, "text", text)
    end
end

function update_seeker_count_desc_text(player, text)
    local player_name = player:get_player_name()
    local seeker_count_desc_hud = hud_elements[player_name]["seeker_count_desc"]

    if seeker_count_desc_hud == nil then
        core.log("warning", "Tried to update seekers count description HUD text for player " ..
            player_name .. " but it was nil")
        return
    else
        player:hud_change(seeker_count_desc_hud, "text", text)
    end
end

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
