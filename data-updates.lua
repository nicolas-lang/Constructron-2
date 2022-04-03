local custom_lib = require("__Constructron-2__.data.lib.custom_lib")

for _, equipment in pairs(data.raw) do --limit loop
    for _, equipment in pairs(equipment) do
        local categories = equipment.categories
        if categories and equipment.sprite and equipment.shape then
            if not custom_lib.table_has_value(categories, "constructron-classic") then
                categories[#categories + 1] = "constructron-classic"
            end
            --if equipment.energy_source and not custom_lib.table_has_value(categories, "constructron-managed") then
            --    categories[#categories + 1] = "constructron-unmanaged"
            --end
        end
    end
end
