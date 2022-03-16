local constructron_grid = {
    name = "ctron-classic-equipment-grid",
    type = "equipment-grid",
    height = 6,
    width = 10,
    equipment_categories = {"constructron-unmanaged"}
}

local lib_spider = require("__Constructron-2__.data.lib.lib_spider")
local spidertron_definition = {
    name = "ctron-classic",
    grid = "ctron-classic-equipment-grid"
}
local constructron = lib_spider.create_spidertron(spidertron_definition)

local leg_entities = lib_spider.create_spidertron_legs(spidertron_definition)

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
    name = "ctron-classic",
    order = "b[personal-transport]-c[spidertron]-a[spider]b",
    place_result = "ctron-classic",
    stack_size = 1,
    subgroup = "transport",
    type = "item-with-entity-data"
}

local constructron_recipe = {
    type = "recipe",
    name = "ctron-classic",
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
    result = "ctron-classic",
    result_count = 1,
    energy = 1
}

local ctron_classic = {constructron, constructron_grid, constructron_item, constructron_recipe}

for _, leg in pairs(leg_entities) do
    table.insert(ctron_classic, leg)
end

return ctron_classic
