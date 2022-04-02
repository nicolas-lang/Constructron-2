local lib_equipment = require("__Constructron-2__.data.lib.lib_equipment")
local ctron_nuclear_powered = {}

--equipment: reactor
local ctron_nuclear_powered_reactor =
    lib_equipment.make_equipment(
    "reactor",
    {
        name = "ctron-nuclear-powered-reactor-equipment",
        categories = {
            "ctron-nuclear-powered-equipment",
            "constructron-managed"
        },
        power = "1W",
        order = "constructron=0;0"
    }
)
table.insert(ctron_nuclear_powered, ctron_nuclear_powered_reactor)
local ctron_nuclear_powered_reactor_item =
    lib_equipment.make_equipment(
    "item",
    {
        name = "ctron-nuclear-powered-reactor-equipment",
        placed_as_equipment_result = "ctron-nuclear-powered-reactor-equipment"
    }
)
table.insert(ctron_nuclear_powered, ctron_nuclear_powered_reactor_item)

--equipment: roboport
local ctron_nuclear_powered_roboport =
    lib_equipment.make_equipment(
    "roboport",
    {
        name = "ctron-nuclear-powered-roboport-equipment",
        charging_energy = "1000kW",
        charging_station_count = 40,
        robot_limit = 120,
        construction_radius = 10,
        energy_source = {
            buffer_capacity = "50MJ",
            input_flow_limit = "25MW"
        },
        categories = {
            "ctron-nuclear-powered-equipment",
            "constructron-managed"
        },
        order = "constructron=0;3"
    }
)
table.insert(ctron_nuclear_powered, ctron_nuclear_powered_roboport)
local ctron_nuclear_powered_roboport_item =
    lib_equipment.make_equipment(
    "item",
    {
        name = "ctron-nuclear-powered-roboport-equipment",
        placed_as_equipment_result = "ctron-nuclear-powered-roboport-equipment"
    }
)
table.insert(ctron_nuclear_powered, ctron_nuclear_powered_roboport_item)

--equipment: battery
local ctron_nuclear_powered_battery_equipment =
    lib_equipment.make_equipment(
    "battery",
    {
        name = "ctron-nuclear-powered-battery-equipment",
        energy_source = {buffer_capacity = "100MJ"},
        shape = {width = 2},
        categories = {
            "ctron-nuclear-powered-equipment",
            "constructron-managed"
        },
        order = "constructron=3;3"
    }
)
table.insert(ctron_nuclear_powered, ctron_nuclear_powered_battery_equipment)

local ctron_nuclear_powered_battery_item =
    lib_equipment.make_equipment(
    "item",
    {
        name = "ctron-nuclear-powered-battery-equipment",
        placed_as_equipment_result = "ctron-nuclear-powered-battery-equipment"
    }
)
table.insert(ctron_nuclear_powered, ctron_nuclear_powered_battery_item)

--equipment: legs x5
for k, v in pairs(
    {
        [1] = -0.7,
        [2] = -0.6,
        [3] = -0.5,
        [4] = -0.4,
        [5] = -0.3
    }
) do
    table.insert(
        ctron_nuclear_powered,
        lib_equipment.make_equipment("item", {name = "ctron_nuclear_powered_leg-" .. k, placed_as_equipment_result = "ctron_nuclear_powered_leg-" .. k})
    )
    table.insert(
        ctron_nuclear_powered,
        lib_equipment.make_equipment(
            "movement_bonus",
            {
                name = "ctron_nuclear_powered_leg-" .. k,
                movement_bonus = v,
                energy_consumption = v>0 and (k  .. "kW") or "0.1W",
                categories = {
                    "ctron-nuclear-powered-equipment",
                    "constructron-managed"
                },
                order = "constructron=2;3"
            }
        )
    )
end

return ctron_nuclear_powered
