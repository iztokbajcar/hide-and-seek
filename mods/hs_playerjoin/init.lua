hiders = {}
seekers = {}

function hide_nametag(player)
    local c = player:get_nametag_attributes().color
    c.a = 0  -- set alpha to 0 to make it completely transparent
    player:set_nametag_attributes({color = c})
end

function add_to_hiders(player)
    table.insert(hiders, player)

    -- hide the player's nametag
    -- (to prevent it from giving away the hider's location)
    hide_nametag(player)

    minetest.log(player:get_player_name() .. " is now a hider")
end

function add_to_seekers(player)
    table.insert(seekers, player)
    minetest.log(player:get_player_name() .. " is now a seeker")
end

function player_join(player)
    -- if the teams have a different number of players,
    -- assign the new player into the team with less players
    -- and pick a random team otherwise
    minetest.log(#hiders .. " hiders, " .. #seekers .. " seekers")
    if #hiders > #seekers then
        add_to_seekers(player)
    elseif #seekers > #hiders then
        add_to_hiders(player)
    else
        math.randomseed(os.clock())
        local r = math.random(0, 1)
        
        if r == 0 then
            add_to_hiders(player)
        else
            add_to_seekers(player)
        end
    end
end

minetest.register_on_joinplayer(player_join)