hs_utils = {}

local mod_path = core.get_modpath("hs_utils")
dofile(mod_path .. "/chat.lua")

hs_utils.send_server_message = send_server_message
hs_utils.send_private_message = send_private_message
