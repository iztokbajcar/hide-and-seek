function send_server_message(message)
    local chat_message = core.colorize("#FFFF00", "[SERVER] " .. message)
    core.chat_send_all(chat_message)
end

function send_private_message(player_name, message)
    local chat_message = core.colorize("#FF8000", "[PRIVATE] " .. message)
    core.chat_send_player(player_name, chat_message)
end

function send_private_bank_message(player_name, message)
    local chat_message = core.colorize("#00FFFF", "[BANK] " .. message)
    core.chat_send_player(player_name, chat_message)
end
