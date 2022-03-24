--[[
    local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
for _, equipment in pairs(data.raw) do --limit loop
    for _, equipment in pairs(equipment) do
        local categories = equipment.categories
        if categories and equipment.sprite and equipment.shape and equipment.energy_source and not custom_lib.table_has_value(categories, "constructron-managed") then
            categories[#categories + 1] = "constructron-unmanaged"
        end
    end
end
]]


local collision_mask_util_extended = require("__Constructron-2__.data.lib.collision-mask-util-extended")
local constructron_collision_mask = {
    "water-tile",
    "colliding-with-tiles-only",
    "not-colliding-with-itself"
}
if mods["space-exploration"] then
    local spaceship_collision_layer = collision_mask_util_extended.get_named_collision_mask("moving-tile")
    local empty_space_collision_layer = collision_mask_util_extended.get_named_collision_mask("empty-space-tile")
    table.insert(constructron_collision_mask, spaceship_collision_layer)
    table.insert(constructron_collision_mask, empty_space_collision_layer)
end

for _, leg in pairs(data.raw["spider-leg"]) do
    for _, constructron_name in pairs(
        {
            "ctron-classic",
            "ctron-steam-powered",
            "ctron-solar-powered",
            "ctron-nuclear-powered",
        }) do
        if (leg.name):gmatch(constructron_name .. "-leg-%d+") then
            leg.collision_mask = constructron_collision_mask
        end
    end
end
