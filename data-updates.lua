local custom_lib = require("__Constructron-2__.data.lib.custom_lib")

for _, category in pairs(data.raw) do --limit loop
    for _, equipment in pairs(category) do
        local equipment_categories = equipment.categories
        if equipment_categories and equipment.sprite and equipment.shape then
            if not custom_lib.table_has_value(equipment_categories, "constructron-classic") then
                equipment_categories[#equipment_categories + 1] = "constructron-classic"
            end
            --if equipment.energy_source and not custom_lib.table_has_value(equipment_categories, "constructron-managed") then
            --    equipment_categories[#equipment_categories + 1] = "constructron-unmanaged"
            --end
        end
    end
end
