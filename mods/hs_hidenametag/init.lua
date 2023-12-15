function hide_nametag(player)
    local c = player:get_nametag_attributes().color
    c.a = 0  -- set alpha to 0 to make it completely transparent
    player:set_nametag_attributes({color = c})
end

minetest.register_on_joinplayer(hide_nametag)