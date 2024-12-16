hs_gamesched = {}

hs_gamesched.STATE_LOBBY = "STATE_LOBBY"
hs_gamesched.STATE_HIDING = "STATE_HIDING"
hs_gamesched.STATE_SEEKING = "STATE_SEEKING"

local LOBBY_DURATION = 60
local HIDE_DURATION = 30
local SEEK_DURATION = 30 -- 360

hs_gamesched.timer_value = LOBBY_DURATION
hs_gamesched.state = hs_gamesched.STATE_LOBBY

function global_step(dtime)
    hs_gamesched.timer_value = hs_gamesched.timer_value - dtime

    check_for_state_change()
    hs_players.timer_callback()
end

function check_for_state_change()
    if hs_gamesched.timer_value <= 0 then
        if hs_gamesched.state == hs_gamesched.STATE_LOBBY then
            core.chat_send_all("Lobby time ended!")
            core.chat_send_all("Hiding time started!")
            hs_gamesched.state = hs_gamesched.STATE_HIDING
            hs_gamesched.timer_value = HIDE_DURATION
            hs_players.game_state_callback()
        elseif hs_gamesched.state == hs_gamesched.STATE_HIDING then
            core.chat_send_all("Hiding time ended!")
            core.chat_send_all("Seeking time started!")
            hs_gamesched.state = hs_gamesched.STATE_SEEKING
            hs_gamesched.timer_value = SEEK_DURATION
            hs_players.game_state_callback()
        elseif hs_gamesched.state == hs_gamesched.STATE_SEEKING then
            core.chat_send_all("Seeking time ended!")
            core.chat_send_all("Lobby time started!")
            hs_gamesched.state = hs_gamesched.STATE_LOBBY
            hs_gamesched.timer_value = LOBBY_DURATION
            hs_players.game_state_callback()
        end
    end
end

core.register_globalstep(global_step)
