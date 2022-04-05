local lib_spider = require("__Constructron-2__.data.lib.lib_spider")
lib_spider.spidertron_animations.image_base = "__Constructron-2__/graphics/constructron/prototype-green/"

local ctron_nuclear_powered = {}

-- equipment category
local ctron_nuclear_powered_category = {
    name = "ctron-nuclear-powered-equipment",
    type = "equipment-category"
}
table.insert(ctron_nuclear_powered, ctron_nuclear_powered_category)

-- equipment grid
local constructron_grid = {
    name = "constructron-nuclear-equipment-grid",
    type = "equipment-grid",
    height = 5,
    width = 10,
    equipment_categories = {
        "constructron-unmanaged",
        "ctron-nuclear-powered-equipment"
    }
}
table.insert(ctron_nuclear_powered, constructron_grid)

-- entity definition
local spidertron_definition = {
    name = "ctron-nuclear-powered",
    grid = "constructron-nuclear-equipment-grid",
    inventory_size = 82,
    trash_inventory_size = 30,
    movement_energy_consumption = "1MW",
    guns = {
        "spidertron-rocket-launcher-1"
    },
    scale = 1.5,
    legs = {
        -- right side
        {
            block = {2},
            angle = 138,
            length = 4.3
        },
        {
            block = {1, 3},
            angle = 108,
            length = 3,
            scale = 0.5
        },
        {
            block = {2, 4},
            angle = 72,
            length = 3,
            scale = 0.5
        },
        {
            block = {3},
            angle = 42,
            length = 4.3
        }, -- left side
        {
            block = {6, 1},
            angle = -138,
            length = 4.3
        },
        {
            block = {5, 7},
            angle = -108,
            length = 3,
            scale = 0.5
        },
        {
            block = {6, 8},
            angle = -72,
            length = 3,
            scale = 0.5
        },
        {
            block = {7},
            angle = -42,
            length = 4.3
        }
    },
    burner = {
        type = "burner",
        fuel_inventory_size = 1,
        burnt_inventory_size = 1,
        fuel_category = "nuclear",
        effectivity = 0.5
    }
}

-- spidertron "torso"
local constructron = lib_spider.create_spidertron(spidertron_definition)
constructron.graphics_set.light[1] = {
	color = {0.3, 1, 0.3},
	intensity = 0.6,
	minimum_darkness = 0.3,
	size = 25
}
table.insert(ctron_nuclear_powered, constructron)

-- spidertron "legs"
local leg_entities = lib_spider.create_spidertron_legs(spidertron_definition)
for _, leg in pairs(leg_entities) do
    table.insert(ctron_nuclear_powered, leg)
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
    name = "ctron-nuclear-powered",
    order = "b[personal-transport]-c[spidertron]-a[spider]b",
    place_result = "ctron-nuclear-powered",
    stack_size = 1,
    subgroup = "transport",
    type = "item-with-entity-data"
}
table.insert(ctron_nuclear_powered, constructron_item)

--recipe
local constructron_recipe = {
    type = "recipe",
    name = "ctron-nuclear-powered",
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
    result = "ctron-nuclear-powered",
    result_count = 1,
    energy = 1
}
table.insert(ctron_nuclear_powered, constructron_recipe)

return ctron_nuclear_powered
