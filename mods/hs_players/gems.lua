local storage = core.get_mod_storage()

local KEY_GEM_BALANCE = "gem_balance"

function get_storage_key_for_player(player_name, key)
    return player_name .. "/" .. key
end

function get_gem_balance(player_name)
    local key = get_storage_key_for_player(player_name, KEY_GEM_BALANCE)
    return storage:get_int(key)
end

function set_gem_balance(player_name, value)
    local key = get_storage_key_for_player(player_name, KEY_GEM_BALANCE)
    storage:set_int(key, value)
end

function increase_gem_balance(player_name, value)
    local balance = get_gem_balance(player_name)
    set_gem_balance(player_name, balance + value)
end

function gift_gems(sending_player_name, receiving_player_name, value_str)
    -- check that the amount is a whole number
    local value = tonumber(value_str)
    if not (value ~= nil and type(value) == "number" and math.floor(value) == value) then
        send_private_bank_message(sending_player_name, "Amount must be a whole number (got '" .. value_str .. "')!")
        return
    end

    -- check if the receiving player exists and is connected
    if not core.get_player_by_name(receiving_player_name) then
        send_private_bank_message(sending_player_name,
            "Player " .. receiving_player_name .. " is not online! Please try again later.")
        return
    end

    -- check if the sending player has enough gems
    local sending_balance = get_gem_balance(sending_player_name)
    if sending_balance < value then
        send_private_bank_message(sending_player_name, "You don't have enough gems (you have " .. sending_balance .. ")!")
        return
    end

    -- give the gems
    increase_gem_balance(receiving_player_name, value)
    increase_gem_balance(sending_player_name, -value)

    local new_receiving_balance = get_gem_balance(receiving_player_name)
    local new_sending_balance = get_gem_balance(sending_player_name)

    send_private_bank_message(sending_player_name,
        "You gifted " .. receiving_player_name .. " " .. value .. " gems! You now have " .. new_sending_balance .. ".")
    send_private_bank_message(receiving_player_name,
        "You received a gift of " ..
        value .. " gems from " .. sending_player_name .. "! You now have " .. new_receiving_balance .. ".")
end

core.register_chatcommand("gift", {
    description = "Gifts gems to another player",
    func = function(name, param)
        -- split params to player name and amount
        local parts = string.split(param, " ")
        local receiving_player_name = parts[1]
        local value = parts[2]
        gift_gems(name, receiving_player_name, value)
    end
})

core.register_chatcommand("balance", {
    description = "Shows your current balance of gems",
    func = function(name, param)
        local balance = get_gem_balance(name)
        hs_utils.send_private_bank_message(name, "You have " .. balance .. " gems.")
    end
})
