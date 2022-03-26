local lib_robots = require("__Constructron-2__.data.lib.lib_robot")
local ctron_nuclear_powered = {}

local ctron_nuclear_powered_robot =
    lib_robots.make_robot(
    "construction",
    {
        name = "ctron-nuclear-powered-robot",
        max_payload_size = 5,
        speed = 0.5,
        max_speed = 1.5,
        resistances = {
            {
                type = "fire",
                percent = 100
            }
        }
    }
)
table.insert(ctron_nuclear_powered, ctron_nuclear_powered_robot)

local ctron_nuclear_powered_robot_item =
    lib_robots.make_robot(
    "item",
    {
        name = "ctron-nuclear-powered-robot",
        place_result = "ctron-nuclear-powered-robot"
    }
)
table.insert(ctron_nuclear_powered, ctron_nuclear_powered_robot_item)

return ctron_nuclear_powered
