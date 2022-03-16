local cust_lib = require("__Constructron-2__.data.lib.custom_lib")

local lib_equipment = {}
lib_equipment.equipment_templates = {
    reactor = {
        categories = {
            "constructron-managed"
        },
        energy_source = {
            usage_priority = "secondary-input",
            type = "electric"
        },
        name = nil,
        power = "1W",
        shape = {
            height = 3,
            type = "full",
            width = 5
        },
        order = "constructron=0;0",
        sprite = {
            filename = "__base__/graphics/equipment/fusion-reactor-equipment.png",
            height = 128,
            hr_version = {
                filename = "__base__/graphics/equipment/hr-fusion-reactor-equipment.png",
                height = 256,
                priority = "medium",
                scale = 0.5,
                width = 256
            },
            priority = "medium",
            width = 128
        },
        type = "generator-equipment",
        take_result = nil
    },
    solar_panel = {
        categories = {
            "constructron-managed"
        },
        energy_source = {
            type = "electric",
            usage_priority = "primary-output"
        },
        name = "ctron-solar-panel-equipment",
        power = "1W",
        shape = {
            height = 2,
            type = "full",
            width = 4
        },
        order = "constructron=0;0",
        sprite = {
            filename = "__base__/graphics/equipment/solar-panel-equipment.png",
            height = 32,
            hr_version = {
                filename = "__base__/graphics/equipment/hr-solar-panel-equipment.png",
                height = 64,
                priority = "medium",
                scale = 0.5,
                width = 64
            },
            priority = "medium",
            width = 32
        },
        type = "solar-panel-equipment"
    },
    roboport = {
        type = "roboport-equipment",
        name = nil,
        take_result = nil,
        order = "constructron=0;2",
        categories = {
            "constructron-managed"
        },
        charge_approach_distance = 2.6,
        charging_distance = 1.6,
        charging_energy = "1000kW",
        charging_station_count = 10,
        charging_station_shift = {0, 0.5},
        charging_threshold_distance = 5,
        construction_radius = 10,
        energy_source = {
            buffer_capacity = "35MJ",
            input_flow_limit = "3500KW",
            type = "electric",
            usage_priority = "secondary-input"
        },
        recharging_animation = {
            animation_speed = 0.5,
            draw_as_glow = true,
            filename = "__base__/graphics/entity/roboport/roboport-recharging.png",
            frame_count = 16,
            height = 35,
            priority = "high",
            scale = 1.5,
            width = 37
        },
        recharging_light = {
            color = {b = 1, g = 0.5, r = 0.5},
            intensity = 0.2,
            size = 3
        },
        robot_limit = 10,
        robots_shrink_when_entering_and_exiting = true,
        shape = {
            height = 2,
            type = "full",
            width = 2
        },
        spawn_and_station_height = 0.4,
        spawn_and_station_shadow_height_offset = 0.5,
        sprite = {
            filename = "__base__/graphics/equipment/personal-roboport-mk2-equipment.png",
            height = 64,
            hr_version = {
                filename = "__base__/graphics/equipment/hr-personal-roboport-mk2-equipment.png",
                height = 128,
                priority = "medium",
                scale = 0.5,
                width = 128
            },
            priority = "medium",
            width = 64
        },
        stationing_offset = {0, -0.6}
    },
    battery = {
        type = "battery-equipment",
        name = nil,
        categories = {},
        order = "",
        energy_source = {
            buffer_capacity = "1J",
            type = "electric",
            usage_priority = "tertiary"
        },
        shape = {
            height = 2,
            type = "full",
            width = 1
        },
        sprite = {
            filename = "__base__/graphics/equipment/battery-mk2-equipment.png",
            height = 64,
            hr_version = {
                filename = "__base__/graphics/equipment/hr-battery-mk2-equipment.png",
                height = 128,
                priority = "medium",
                scale = 0.5,
                width = 64
            },
            priority = "medium",
            width = 32
        }
    },
    movement_bonus = {
        type = "movement-bonus-equipment",
        name = nil,
        movement_bonus = 0,
        categories = {},
        order = "",
        energy_consumption = "1kW",
        energy_source = {
            type = "void",
            usage_priority = "secondary-input"
        },
        shape = {
            height = 2,
            type = "full",
            width = 1
        },
        sprite = {
            filename = "__base__/graphics/equipment/exoskeleton-equipment.png",
            height = 128,
            hr_version = {
                filename = "__base__/graphics/equipment/hr-exoskeleton-equipment.png",
                height = 256,
                priority = "medium",
                scale = 0.25,
                width = 128
            },
            priority = "medium",
            width = 64,
            scale = 0.5
        }
    },
    item = {
        type = "item",
        name = nil,
        placed_as_equipment_result = nil,
        flags = {
            "hidden"
        },
        icon = "__core__/graphics/empty.png",
        icon_size = 1,
        order = "z",
        stack_size = 1
    }
}

function lib_equipment.make_equipment(template, params)
    if lib_equipment.equipment_templates[template] then
        local equipment = table.deepcopy(lib_equipment.equipment_templates[template])
        cust_lib.merge(equipment, params)
        return equipment
    end
end
--[[
function lib_equipment.make_battery_equipment(params)
    local battery = table.deepcopy(battery_template)
    battery.name = params.name
    battery.energy_source.buffer_capacity = params.buffer_capacity or "1J"
    battery.categories = params.categories or {}
    battery.order = params.order or params.name
    battery.shape.height = params.height or 2
    battery.shape.width = params.width or 1
    local item = table.deepcopy(item_template)
    item.name = params.name
    item.placed_as_equipment_result = params.name
    return {
        equipment = battery,
        item = item
    }
end

function lib_equipment.make_leg_equipment(params)
    local leg = table.deepcopy(leg_template)
    leg.name = params.name
    leg.movement_bonus = params.movement_bonus or 0
    leg.categories = params.categories or {}
    leg.order = params.order or params.name
    local item = table.deepcopy(item_template)
    item.name = params.name
    item.placed_as_equipment_result = params.name
    return {
        equipment = leg,
        item = item
    }
end
]]
return lib_equipment
