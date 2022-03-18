local tech = {}

local unlock = {
    "ctron-classic",
    "ctron-steam-powered",
    "ctron-solar-powered",
    "ctron-nuclear-powered",
    "service-station",
    "ctron-buffer-chest"
}

for _, name in pairs(unlock) do
    if data.raw["recipe"][name] then
        table.insert(
            data.raw["technology"]["spidertron"].effects,
            {
                type = "unlock-recipe",
                recipe = name
            }
        )
    end
end

local movement_tech_template = {
    type = "technology",
    icon_size = 256,
    icon_mipmaps = 4,
    icons = util.technology_icon_constant_equipment("__base__/graphics/technology/exoskeleton-equipment.png"), -- luacheck: ignore
    prerequisites = {"exoskeleton-equipment", "spidertron"},
    unit = {
        count = 50,
        ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}, {"chemical-science-pack", 1}},
        time = 30
    },
    order = "g-h"
}
for _, i in pairs({1, 2, 3, 4}) do
    local movement_tech = table.deepcopy(movement_tech_template)
    movement_tech.name = "ctron-exoskeleton-equipment-" .. (i+1)
    if i > 1 then
        movement_tech.prerequisites = {"ctron-exoskeleton-equipment-" .. (i)}
    end
    table.insert(tech, movement_tech)
end

return tech
