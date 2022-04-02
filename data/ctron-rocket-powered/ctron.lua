local util = require("util")
local lib_spider = require("__Constructron-2__.data.lib.lib_spider")
lib_spider.spidertron_animations.image_base = "__Constructron-2__/graphics/constructron/bulwark/"

local ctron_rocket_powered = {}

-- equipment category
local ctron_rocket_powered_category = {
    name = "ctron-rocket-powered-equipment",
    type = "equipment-category"
}
table.insert(ctron_rocket_powered, ctron_rocket_powered_category)

-- equipment grid
local constructron_grid = {
    name = "constructron-rocket-equipment-grid",
    type = "equipment-grid",
    height = 4,
    width = 5,
    equipment_categories = {
        "ctron-rocket-powered-equipment"
    }
}
table.insert(ctron_rocket_powered, constructron_grid)

-- entity definition
local spidertron_definition = {
    name = "ctron-rocket-powered",
    grid = "constructron-rocket-equipment-grid",
    inventory_size = 10,
    trash_inventory_size = 10,
    guns = {},
    scale = 1.5,
    leg_scale = 0,
    legs = {
        {
            block = {1},
            angle = 0,
            length = 1
        }
    },
    burner = {
        type = "burner",
        fuel_inventory_size = 2,
        burnt_inventory_size = 0,
        fuel_category = "chemical",
        effectivity = 0.5,
        emissions_per_minute = 150
    }
}

-- spidertron "torso"
local constructron = lib_spider.create_spidertron(spidertron_definition)

--Rocket flames
local layers = constructron.graphics_set.base_animation.layers
for k, layer in pairs(layers) do
    layer.repeat_count = 8
    layer.hr_version.repeat_count = 8
end
table.insert(
    layers,
    1,
    {
        filename = "__base__/graphics/entity/rocket-silo/10-jet-flame.png",
        priority = "medium",
        blend_mode = "additive",
        draw_as_glow = true,
        width = 87,
        height = 128,
        frame_count = 8,
        line_length = 8,
        animation_speed = 0.5,
        scale = 1.25,
        shift = util.by_pixel(-0.5, 55),
        direction_count = 1,
        hr_version = {
            filename = "__base__/graphics/entity/rocket-silo/hr-10-jet-flame.png",
            priority = "medium",
            blend_mode = "additive",
            draw_as_glow = true,
            width = 172,
            height = 256,
            frame_count = 8,
            line_length = 8,
            animation_speed = 0.5,
            scale = 1.25 / 2,
            shift = util.by_pixel(-1, 80),
            direction_count = 1
        }
    }
)

table.insert(ctron_rocket_powered, constructron)

-- spidertron "legs"
local leg_entities = lib_spider.create_spidertron_legs(spidertron_definition)
for _, leg in pairs(leg_entities) do
    table.insert(ctron_rocket_powered, leg)
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
    name = "ctron-rocket-powered",
    order = "b[personal-transport]-c[spidertron]-a[spider]b",
    place_result = "ctron-rocket-powered",
    stack_size = 1,
    subgroup = "transport",
    type = "item-with-entity-data"
}
table.insert(ctron_rocket_powered, constructron_item)

--recipe
local constructron_recipe = {
    type = "recipe",
    name = "ctron-rocket-powered",
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
    result = "ctron-rocket-powered",
    result_count = 1,
    energy = 1
}
table.insert(ctron_rocket_powered, constructron_recipe)

return ctron_rocket_powered
