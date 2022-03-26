local lib_robots = require("__Constructron-2__.data.lib.lib_robot")
local ctron_steam_powered = {}

local ctron_steam_powered_robot =
    lib_robots.make_robot(
    "construction",
    {
        name = "ctron-steam-powered-robot",
        max_payload_size = 1,
        speed = 0.01,
        max_speed = 0.1,
        emissions_per_second = 10,
        resistances = {
            {
                type = "fire",
                percent = 100
            }
        }
    }
)
table.insert(ctron_steam_powered, ctron_steam_powered_robot)

local ctron_steam_powered_robot_item =
    lib_robots.make_robot(
    "item",
    {
        name = "ctron-steam-powered-robot",
        place_result = "ctron-steam-powered-robot"
    }
)
table.insert(ctron_steam_powered, ctron_steam_powered_robot_item)

return ctron_steam_powered
