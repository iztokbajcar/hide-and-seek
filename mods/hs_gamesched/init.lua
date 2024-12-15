hs_gamesched = {}
hs_gamesched.timer_value = 0

hs_gamesched.STATE_LOBBY = "STATE_LOBBY"
hs_gamesched.STATE_HIDING = "STATE_HIDING"
hs_gamesched.STATE_SEEKING = "STATE_SEEKING"

local lobby_time = 60
local hide_time = 30
local seek_time = 30 -- 360

hs_gamesched.state = hs_gamesched.STATE_LOBBY

function global_step(dtime)
    hs_gamesched.timer_value = hs_gamesched.timer_value + dtime

    if hs_gamesched.state == hs_gamesched.STATE_LOBBY
        and hs_gamesched.timer_value > lobby_time
    then
        hs_gamesched.timer_value = hs_gamesched.timer_value - lobby_time
        minetest.chat_send_all("Lobby time ended!")
        minetest.chat_send_all("Hiding time started!")
        hs_gamesched.state = hs_gamesched.STATE_HIDING
        hs_players.timer_callback()
    elseif
        hs_gamesched.state == hs_gamesched.STATE_HIDING
        and hs_gamesched.timer_value > hide_time
    then
        hs_gamesched.timer_value = hs_gamesched.timer_value - hide_time
        minetest.chat_send_all("Hiding time ended!")
        minetest.chat_send_all("Seeking time started!")
        hs_gamesched.state = hs_gamesched.STATE_SEEKING
        hs_players.timer_callback()
    elseif
        hs_gamesched.state == hs_gamesched.STATE_SEEKING
        and hs_gamesched.timer_value > seek_time
    then
        hs_gamesched.timer_value = hs_gamesched.timer_value - seek_time
        minetest.chat_send_all("Seeking time ended!")
        minetest.chat_send_all("Lobby time started!")
        hs_gamesched.state = hs_gamesched.STATE_LOBBY
        hs_players.timer_callback()
    end
end

minetest.register_globalstep(global_step)
