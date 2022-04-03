local lib_spider = require("__Constructron-2__.data.lib.lib_spider")
lib_spider.spidertron_animations.image_base = "__Constructron-2__/graphics/constructron/bulwark/"

local ctron_steam_powered = {}

-- equipment category
local ctron_steam_powered_category = {
    name = "ctron-steam-powered-equipment",
    type = "equipment-category"
}
table.insert(ctron_steam_powered, ctron_steam_powered_category)

-- equipment grid
local constructron_grid = {
    name = "constructron-steam-equipment-grid",
    type = "equipment-grid",
    height = 4,
    width = 8,
    equipment_categories = {
        "constructron-unmanaged",
        "ctron-steam-powered-equipment"
    }
}
table.insert(ctron_steam_powered, constructron_grid)

-- entity definition
local spidertron_definition = {
    name = "ctron-steam-powered",
    grid = "constructron-steam-equipment-grid",
    inventory_size = 12,
    trash_inventory_size = 10,
    guns = {},
    scale = 0.5,
    legs = {
        -- right side
        {
            block = {2},
            angle = 138,
            length = 3.3
        },
        {
            block = {1},
            angle = 42,
            length = 3.3
        }, -- left side
        {
            block = {4},
            angle = -138,
            length = 3.3
        },
        {
            block = {3},
            angle = -42,
            length = 3.3
        }
    },
    burner = {
        type = "burner",
        fuel_inventory_size = 2,
        burnt_inventory_size = 0,
        fuel_category = "chemical",
        effectivity = 0.5,
        emissions_per_minute = 150,
        smoke = {
            {
                name = "train-smoke",
                deviation = {0.3, 0.3},
                frequency = 200,
                position = {0, 0},
                starting_frame = 0,
                starting_frame_deviation = 60,
                height = 1,
                height_deviation = 1,
                starting_vertical_speed = 0.1,
                starting_vertical_speed_deviation = 0.2
            }
        }
    }
}

-- spidertron "torso"
local constructron = lib_spider.create_spidertron(spidertron_definition)
table.insert(ctron_steam_powered, constructron)

-- spidertron "legs"
local leg_entities = lib_spider.create_spidertron_legs(spidertron_definition)
for _, leg in pairs(leg_entities) do
    table.insert(ctron_steam_powered, leg)
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
    name = "ctron-steam-powered",
    order = "b[personal-transport]-c[spidertron]-a[spider]b",
    place_result = "ctron-steam-powered",
    stack_size = 1,
    subgroup = "transport",
    type = "item-with-entity-data"
}
table.insert(ctron_steam_powered, constructron_item)

--recipe
local constructron_recipe = {
    type = "recipe",
    name = "ctron-steam-powered",
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
    result = "ctron-steam-powered",
    result_count = 1,
    energy = 1
}
table.insert(ctron_steam_powered, constructron_recipe)

return ctron_steam_powered
