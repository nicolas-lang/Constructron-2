local lib_equipment = require("__Constructron-2__.data.lib.lib_equipment")
local ctron_solar_powered = {}

--equipment: reactor
local ctron_solar_powered_reactor =
    lib_equipment.make_equipment(
    "solar_panel",
    {
        name = "ctron-solar-panel-equipment",
        categories = {
            "ctron-solar-powered-equipment",
            "constructron-managed"
        },
        power = "3000kW",
        order = "constructron=0;0"
    }
)
table.insert(ctron_solar_powered, ctron_solar_powered_reactor)
local ctron_solar_powered_reactor_item =
    lib_equipment.make_equipment(
    "item",
    {
        name = "ctron-solar-panel-equipment",
        placed_as_equipment_result = "ctron-solar-panel-equipment"
    }
)
table.insert(ctron_solar_powered, ctron_solar_powered_reactor_item)

--equipment: roboport
local ctron_solar_powered_roboport =
    lib_equipment.make_equipment(
    "roboport",
    {
        name = "ctron-solar-powered-roboport-equipment",
        charging_station_count = 20,
        energy_source = {
            buffer_capacity = "5MJ",
            input_flow_limit = "7500KW"
        },
        robot_limit = 20,
        categories = {
            "ctron-solar-powered-equipment",
            "constructron-managed"
        },
        order = "constructron=0;2"
    }
)
table.insert(ctron_solar_powered, ctron_solar_powered_roboport)
local ctron_solar_powered_roboport_item =
    lib_equipment.make_equipment(
    "item",
    {
        name = "ctron-solar-powered-roboport-equipment",
        placed_as_equipment_result = "ctron-solar-powered-roboport-equipment"
    }
)
table.insert(ctron_solar_powered, ctron_solar_powered_roboport_item)

--equipment: battery
local ctron_solar_powered_battery_equipment =
    lib_equipment.make_equipment(
    "battery",
    {
        name = "ctron-solar-powered-battery-equipment",
        energy_source = {buffer_capacity = "4MJ"},
        categories = {
            "ctron-solar-powered-equipment",
            "constructron-managed"
        },
        order = "constructron=3;2"
    }
)
table.insert(ctron_solar_powered, ctron_solar_powered_battery_equipment)

local ctron_solar_powered_battery_item =
    lib_equipment.make_equipment(
    "item",
    {
        name = "ctron-solar-powered-battery-equipment",
        placed_as_equipment_result = "ctron-solar-powered-battery-equipment"
    }
)
table.insert(ctron_solar_powered, ctron_solar_powered_battery_item)

--equipment: legs x5
for k, v in pairs(
    {
        [1] = 0.5,
        [2] = 1.25,
        [3] = 2.0,
        [4] = 2.75,
        [5] = 3.5
    }
) do
    table.insert(ctron_solar_powered, lib_equipment.make_equipment("item", {name = "ctron_solar_powered_leg-" .. k, placed_as_equipment_result = "ctron_solar_powered_leg-" .. k}))
    table.insert(
        ctron_solar_powered,
        lib_equipment.make_equipment(
            "movement_bonus",
            {
                name = "ctron_solar_powered_leg-" .. k,
                movement_bonus = v,
                energy_consumption = v>0 and ((k * 3) .. "kW") or "0.1W",
                categories = {
                    "ctron-solar-powered-equipment",
                    "constructron-managed"
                },
                order = "constructron=2;2"
            }
        )
    )
end

return ctron_solar_powered
