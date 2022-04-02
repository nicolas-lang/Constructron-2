local lib_equipment = require("__Constructron-2__.data.lib.lib_equipment")
local ctron_rocket_powered = {}

--equipment: reactor
local ctron_rocket_powered_reactor =
    lib_equipment.make_equipment(
    "reactor",
    {
        name = "ctron-rocket-powered-reactor-equipment",
        categories = {
            "ctron-rocket-powered-equipment",
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
table.insert(ctron_rocket_powered, ctron_rocket_powered_reactor)
local ctron_rocket_powered_reactor_item =
    lib_equipment.make_equipment(
    "item",
    {
        name = "ctron-rocket-powered-reactor-equipment",
        placed_as_equipment_result = "ctron-rocket-powered-reactor-equipment"
    }
)
table.insert(ctron_rocket_powered, ctron_rocket_powered_reactor_item)

--equipment: roboport
local ctron_rocket_powered_roboport =
    lib_equipment.make_equipment(
    "roboport",
    {
        name = "ctron-rocket-powered-roboport-equipment",
        charging_energy = "500kW",
        charging_station_count = 5,
        robot_limit = 5,
        construction_radius = 7.5,
        energy_source = {
            buffer_capacity = "35MJ",
            input_flow_limit = "5MW"
        },
        categories = {
            "ctron-rocket-powered-equipment",
            "constructron-managed"
        },
        order = "constructron=0;2"
    }
)
table.insert(ctron_rocket_powered, ctron_rocket_powered_roboport)
local ctron_rocket_powered_roboport_item =
    lib_equipment.make_equipment(
    "item",
    {
        name = "ctron-rocket-powered-roboport-equipment",
        placed_as_equipment_result = "ctron-rocket-powered-roboport-equipment"
    }
)
table.insert(ctron_rocket_powered, ctron_rocket_powered_roboport_item)

--equipment: battery
local ctron_rocket_powered_battery_equipment =
    lib_equipment.make_equipment(
    "battery",
    {
        name = "ctron-rocket-powered-battery-equipment",
        energy_source = {buffer_capacity = "40MJ"},
        shape = {width = 2},
        categories = {
            "ctron-rocket-powered-equipment",
            "constructron-managed"
        },
        order = "constructron=3;2"
    }
)
table.insert(ctron_rocket_powered, ctron_rocket_powered_battery_equipment)

local ctron_rocket_powered_battery_item =
    lib_equipment.make_equipment(
    "item",
    {
        name = "ctron-rocket-powered-battery-equipment",
        placed_as_equipment_result = "ctron-rocket-powered-battery-equipment"
    }
)
table.insert(ctron_rocket_powered, ctron_rocket_powered_battery_item)

--equipment: legs x5
for k, v in pairs(
    {
        [1] = -0.5,
        [2] = -0.3,
        [3] = 0.1,
        [4] = 0.3,
        [5] = 0.5
    }
) do
    table.insert(ctron_rocket_powered, lib_equipment.make_equipment("item", {name = "ctron_rocket_powered_leg-" .. k, placed_as_equipment_result = "ctron_rocket_powered_leg-" .. k}))
    table.insert(
        ctron_rocket_powered,
        lib_equipment.make_equipment(
            "movement_bonus",
            {
                name = "ctron_rocket_powered_leg-" .. k,
                movement_bonus = v,
                energy_consumption = v>0 and (k  .. "kW") or "0.1W",
                categories = {
                    "ctron-rocket-powered-equipment",
                    "constructron-managed"
                },
                order = "constructron=2;2"
            }
        )
    )
end

return ctron_rocket_powered
