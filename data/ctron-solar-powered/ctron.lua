local lib_spider = require("__Constructron-2__.data.lib.lib_spider")
lib_spider.spidertron_animations.image_base = "__Constructron-2__/graphics/constructron/mk3-blue/"

local ctron_solar_powered = {}

-- equipment category
local ctron_solar_powered_category = {
    name = "ctron-solar-powered-equipment",
    type = "equipment-category"
}
table.insert(ctron_solar_powered, ctron_solar_powered_category)

--fuel category
local fuel_category = {
    name = "constructron-solar-fuel",
    type = "fuel-category"
}
table.insert(ctron_solar_powered, fuel_category)

--burnable fuel "battery"
local fuel = {
    type = "item",
    name = "constructron-solar-fuel",
    icon = "__base__/graphics/icons/battery-mk2-equipment.png",
    icon_size = 64,
    icon_mipmaps = 4,
    fuel_category = "constructron-solar-fuel",
    fuel_value = "5MJ",
    stack_size = 1
}
table.insert(ctron_solar_powered, fuel)

-- equipment grid
local constructron_grid = {
    name = "constructron-solar-equipment-grid",
    type = "equipment-grid",
    height = 4,
    width = 10,
    equipment_categories = {
        "constructron-unmanaged",
        "ctron-solar-powered-equipment"
    }
}
table.insert(ctron_solar_powered, constructron_grid)

local lightning_smoke_animation = {
    layers = {
        {
            draw_as_glow = true,
            filename = "__base__/graphics/entity/accumulator/accumulator-charge.png",
            frame_count = 24,
            height = 100,
            hr_version = {
                draw_as_glow = true,
                filename = "__base__/graphics/entity/accumulator/hr-accumulator-charge.png",
                frame_count = 24,
                height = 206,
                line_length = 6,
                priority = "high",
                scale = 0.5,
                shift = {0, 0},
                width = 178
            },
            line_length = 6,
            priority = "high",
            shift = {0, -0},
            width = 90
        }
    }
}
local lightning_smoke = {
    affected_by_wind = false,
    animation = lightning_smoke_animation,
    color = {a = 1, b = 1, g = 0.8, r = 0.9},
    cyclic = true,
    duration = 10,
    end_scale = 2.0,
    fade_away_duration = 5,
    fade_in_duration = 0,
    name = "lightning-smoke",
    spread_duration = 5,
    start_scale = 0.5,
    type = "trivial-smoke",
    movement_slow_down_factor = 1
}

table.insert(ctron_solar_powered, lightning_smoke)

-- entity definition
local spidertron_definition = {
    name = "ctron-solar-powered",
    grid = "constructron-solar-equipment-grid",
    inventory_size = 42,
    trash_inventory_size = 20,
    movement_energy_consumption = "500KW",
    guns = {},
    scale = 0.6,
    legs = {
        -- right side
        {
            block = {2},
            angle = 138,
            length = 3.3
        },
        {
            block = {1, 3},
            angle = 90,
            length = 3.0
        },
        {
            block = {2},
            angle = 42,
            length = 3.3
        },
        -- left side
        {
            block = {5, 1},
            angle = -138,
            length = 3.3
        },
        {
            block = {4, 6},
            angle = -90,
            length = 3.0
        },
        {
            block = {5},
            angle = -42,
            length = 3.3
        }
    },
    burner = {
        type = "burner",
        fuel_inventory_size = 1,
        fuel_category = "constructron-solar-fuel",
        effectivity = 1,
        render_no_power_icon = true,
        smoke = {
            {
                name = "lightning-smoke",
                deviation = {0.5, 0.5},
                frequency = 75,
                position = {0, 0},
                starting_frame = 0,
                starting_frame_deviation = 60,
                height = 1,
                height_deviation = 0.5
            }
        }
    }
}
-- spidertron "torso"
local constructron = lib_spider.create_spidertron(spidertron_definition)
table.insert(ctron_solar_powered, constructron)

-- spidertron "legs"
local leg_entities = lib_spider.create_spidertron_legs(spidertron_definition)
for _, leg in pairs(leg_entities) do
    table.insert(ctron_solar_powered, leg)
end

-- item
local constructron_item = {
    icons = {
        {
            icon = "__Constructron-2__/graphics/icon_texture.png",
            icon_size = 256,
            scale = 0.25
        },
        {
            icon = "__base__/graphics/icons/spidertron.png",
            icon_size = 64,
            icon_mipmaps = 4,
            scale = 1
        }
    },
    name = "ctron-solar-powered",
    order = "b[personal-transport]-c[spidertron]-a[spider]b",
    place_result = "ctron-solar-powered",
    stack_size = 1,
    subgroup = "transport",
    type = "item-with-entity-data"
}
table.insert(ctron_solar_powered, constructron_item)

--recipe
local constructron_recipe = {
    type = "recipe",
    name = "ctron-solar-powered",
    enabled = false,
    ingredients = {
        {"raw-fish", 1},
        {"rocket-control-unit", 16},
        {"low-density-structure", 150},
        {"effectivity-module-3", 2},
        {"rocket-launcher", 4},
        {"fusion-reactor-equipment", 2},
        {"exoskeleton-equipment", 4},
        {"radar", 2}
    },
    result = "ctron-solar-powered",
    result_count = 1,
    energy = 1
}
table.insert(ctron_solar_powered, constructron_recipe)

return ctron_solar_powered
