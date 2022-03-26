local lib_robots = require("__Constructron-2__.data.lib.lib_robot")
local ctron_solar_powered = {}

local ctron_solar_powered_robot =
    lib_robots.make_robot(
    "construction",
    {
        name = "ctron-solar-powered-robot",
        max_payload_size = 2,
        speed = 0.1,
        max_speed = 0.5,
        resistances = {
            {
                type = "fire",
                percent = 100
            }
        }
    }
)
table.insert(ctron_solar_powered, ctron_solar_powered_robot)

local ctron_solar_powered_robot_item =
    lib_robots.make_robot(
    "item",
    {
        name = "ctron-solar-powered-robot",
        place_result = "ctron-solar-powered-robot"
    }
)
table.insert(ctron_solar_powered, ctron_solar_powered_robot_item)

return ctron_solar_powered
