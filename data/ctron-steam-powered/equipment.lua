local lib_equipment = require("__Constructron-2__.data.lib.lib_equipment")
local ctron_steam_powered = {}

--equipment: reactor
local ctron_steam_powered_reactor =
    lib_equipment.make_equipment(
    "reactor",
    {
        name = "ctron-steam-powered-reactor-equipment",
        categories = {
            "ctron-steam-powered-equipment",
            "constructron-managed"
        },
        power = "1W",
        order = "constructron=0;0",
        shape = {height = 2},
        sprite = {
            filename = "__base__/graphics/entity/steam-engine/steam-engine-H.png",
            height = 128,
            width = 176,
            shift = {0.03125, -0.15625},
            hr_version = {
                filename = "__base__/graphics/entity/steam-engine/hr-steam-engine-H.png",
                height = 257,
                scale = 0.5,
                width = 352,
                shift = {0.03125, -0.1484375}
            }
        }
    }
)
table.insert(ctron_steam_powered, ctron_steam_powered_reactor)
local ctron_steam_powered_reactor_item =
    lib_equipment.make_equipment(
    "item",
    {
        name = "ctron-steam-powered-reactor-equipment",
        placed_as_equipment_result = "ctron-steam-powered-reactor-equipment"
    }
)
table.insert(ctron_steam_powered, ctron_steam_powered_reactor_item)

--equipment: roboport
local ctron_steam_powered_roboport =
    lib_equipment.make_equipment(
    "roboport",
    {
        name = "ctron-steam-powered-roboport-equipment",
        charging_energy = "500kW",
        charging_station_count = 5,
        robot_limit = 5,
        construction_radius = 7.5,
        energy_source = {
            buffer_capacity = "35MJ",
            input_flow_limit = "5MW"
        },
        categories = {
            "ctron-steam-powered-equipment",
            "constructron-managed"
        },
        order = "constructron=0;2"
    }
)
table.insert(ctron_steam_powered, ctron_steam_powered_roboport)
local ctron_steam_powered_roboport_item =
    lib_equipment.make_equipment(
    "item",
    {
        name = "ctron-steam-powered-roboport-equipment",
        placed_as_equipment_result = "ctron-steam-powered-roboport-equipment"
    }
)
table.insert(ctron_steam_powered, ctron_steam_powered_roboport_item)

--equipment: battery
local ctron_steam_powered_battery_equipment =
    lib_equipment.make_equipment(
    "battery",
    {
        name = "ctron-steam-powered-battery-equipment",
        energy_source = {buffer_capacity = "40MJ"},
        shape = {width = 2},
        categories = {
            "ctron-steam-powered-equipment",
            "constructron-managed"
        },
        order = "constructron=3;2"
    }
)
table.insert(ctron_steam_powered, ctron_steam_powered_battery_equipment)

local ctron_steam_powered_battery_item =
    lib_equipment.make_equipment(
    "item",
    {
        name = "ctron-steam-powered-battery-equipment",
        placed_as_equipment_result = "ctron-steam-powered-battery-equipment"
    }
)
table.insert(ctron_steam_powered, ctron_steam_powered_battery_item)

--equipment: legs x5
for k, v in pairs(
    {
        [1] = -0.4,
        [2] = -0.2,
        [3] = 0.0,
        [4] = 0.2,
        [5] = 0.4
    }
) do
    table.insert(ctron_steam_powered, lib_equipment.make_equipment("item", {name = "ctron_steam_powered_leg-" .. k, placed_as_equipment_result = "ctron_steam_powered_leg-" .. k}))
    table.insert(
        ctron_steam_powered,
        lib_equipment.make_equipment(
            "movement_bonus",
            {
                name = "ctron_steam_powered_leg-" .. k,
                movement_bonus = v,
                categories = {
                    "ctron-steam-powered-equipment",
                    "constructron-managed"
                },
                order = "constructron=2;2"
            }
        )
    )
end

return ctron_steam_powered
