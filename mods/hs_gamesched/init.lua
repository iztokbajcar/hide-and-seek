hs_gamesched = {}

hs_gamesched.STATE_LOBBY = "STATE_LOBBY"
hs_gamesched.STATE_HIDING = "STATE_HIDING"
hs_gamesched.STATE_SEEKING = "STATE_SEEKING"
hs_gamesched.STATE_AFTERROUND = "STATE_AFTERROUND"

local LOBBY_DURATION = 60
local HIDE_DURATION = 30
local SEEK_DURATION = 360
local AFTER_DURATION = 15

-- if duration settings exist, use those, otherwise
-- use the defaults
local lobby_duration_setting = tonumber(core.settings:get("hs_lobby_duration"))
local hide_duration_setting = tonumber(core.settings:get("hs_hide_duration"))
local seek_duration_setting = tonumber(core.settings:get("hs_seek_duration"))
local after_duration_setting = tonumber(core.settings:get("hs_after_duration"))
hs_utils.send_server_message(lobby_duration_setting)

if lobby_duration_setting then
    LOBBY_DURATION = lobby_duration_setting
end
if hide_duration_setting then
    HIDE_DURATION = hide_duration_setting
end
if seek_duration_setting then
    SEEK_DURATION = seek_duration_setting
end
if after_duration_setting then
    AFTER_DURATION = after_duration_setting
end

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
            hs_utils.send_server_message("Round started! Hiders now have time to hide.")
            hs_gamesched.state = hs_gamesched.STATE_HIDING
            hs_gamesched.timer_value = HIDE_DURATION
            hs_players.game_state_callback()
        elseif hs_gamesched.state == hs_gamesched.STATE_HIDING then
            hs_utils.send_server_message("The seekers have been released. Good luck!")
            hs_gamesched.state = hs_gamesched.STATE_SEEKING
            hs_gamesched.timer_value = SEEK_DURATION
            hs_players.game_state_callback()
        elseif hs_gamesched.state == hs_gamesched.STATE_SEEKING then
            hs_utils.send_server_message("Hiders win!")
            hs_gamesched.state = hs_gamesched.STATE_AFTERROUND
            hs_gamesched.timer_value = AFTER_DURATION
            hs_players.hider_win_callback()
            hs_players.game_state_callback()
        elseif hs_gamesched.state == hs_gamesched.STATE_AFTERROUND then
            hs_utils.send_server_message("Lobby time started.")
            hs_gamesched.state = hs_gamesched.STATE_LOBBY
            hs_gamesched.timer_value = LOBBY_DURATION
            hs_players.game_state_callback()
        end
    end
end

function on_seeker_win()
    hs_utils.send_server_message("Seekers win!")
    hs_gamesched.state = hs_gamesched.STATE_AFTERROUND
    hs_gamesched.timer_value = AFTER_DURATION
    hs_players.seeker_win_callback()
    hs_players.game_state_callback()
end

function on_hider_win()
    hs_utils.send_server_message("Hiders win!")
    hs_gamesched.state = hs_gamesched.STATE_AFTERROUND
    hs_gamesched.timer_value = AFTER_DURATION
    hs_players.hider_win_callback()
    hs_players.game_state_callback()
end

core.register_globalstep(global_step)

hs_gamesched.on_seeker_win = on_seeker_win
hs_gamesched.on_hider_win = on_hider_win
