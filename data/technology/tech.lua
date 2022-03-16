local unlock = {
    "ctron-classic",
    "ctron-steam-powered",
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
