player_team = {}       -- maps player names to team names
hider_hiding = {}      -- maps player names to whether they are hiding (stationary) or not
hider_node_name = {}   -- which node is a hider using as their disguise (player name --> node name)
hider_node_pos = {}    -- where is the node that the hider is using as their disguise
hider_entity = {}      -- the entity that is attached to the hider
hider_pos_offsets = {} -- the offset of the player's position from their hiding node (player name --> pos)
disguise_entities = {} -- stores all defined disguise entities (entity name --> entity table)
hud_elements = {}      -- stores all hud elements of a player (player name --> (hud element name --> hud element id))
num_hiders = 0
num_seekers = 0

disguise_entity_prefix = "hs_players:disguise_entity_"
default_disguise_node = "default:brick"

transparent = { "transparent.png", "transparent.png", "transparent.png", "transparent.png", "transparent.png",
    "transparent.png" }

mod_path = core.get_modpath("hs_players")
dofile(mod_path .. "/game_events.lua")
dofile(mod_path .. "/hiders.lua")
dofile(mod_path .. "/hud.lua")
dofile(mod_path .. "/players.lua")
dofile(mod_path .. "/seekers.lua")

-- core.register_on_mods_loaded(register_hider_model)
core.register_on_joinplayer(player_join)
core.register_on_leaveplayer(player_leave)
core.register_on_respawnplayer(player_respawn)
core.register_on_dieplayer(player_die)

core.register_on_punchnode(on_node_punched)

-- periodically check for hider movement
core.register_globalstep(check_hider_movement)

-- register disguise entities for all nodes in the default mod
register_disguise_entities_for_nodes_in_default_mod()

hs_players = {}
hs_players.timer_callback = timer_callback
hs_players.game_state_callback = game_state_callback
