local unlock = {
    "ctron-classic",
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
