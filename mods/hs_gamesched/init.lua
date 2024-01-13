hs_gamesched = {}
hs_gamesched.timer_value = 0

function global_step(dtime)
    hs_gamesched.timer_value = hs_gamesched.timer_value + dtime

    if hs_gamesched.timer_value > 10 then
        hs_gamesched.timer_value = hs_gamesched.timer_value - 10
        minetest.chat_send_all("Timer triggered")
    end
end

minetest.register_globalstep(global_step)