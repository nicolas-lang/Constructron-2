local Ctron = require("__Constructron-2__.script.objects.Ctron")

-- class Type Ctron_nuclear_powered, nil members exist just to describe fields
local Ctron_nuclear_powered = {
    class_name = "Ctron_nuclear_powered",
    gear = {
        "ctron-nuclear-powered-roboport-equipment",
        "ctron-nuclear-powered-reactor-equipment",
        "ctron_nuclear_powered_leg-{movement_research}",
        "ctron-nuclear-powered-battery-equipment"
    },
    managed_equipment_cols = 5,
    fuel = "uranium-fuel-cell",
    fuel_count = 50,
    robots = 120
}

Ctron_nuclear_powered.__index = Ctron_nuclear_powered

setmetatable(
    Ctron_nuclear_powered,
    {
        __index = Ctron, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)

-- Ctron_nuclear_powered Constructor
function Ctron_nuclear_powered:new(entity)
    log("Ctron_nuclear_powered.new")
    Ctron.new(self, entity)
    self:setup_gear()
end

function Ctron_nuclear_powered:tick_update()
    Ctron:tick_update()
    if self.entity.valid then
        local transfer_efficiency = 0.5
        local grid = self.entity.grid
        for _, equipment in pairs(grid.equipment) do
            local missing = equipment.max_energy - equipment.energy
            if missing > 0 then
                log("recharge " .. math.floor(missing) .. " energy")
                if self.entity.burner.remaining_burning_fuel < missing / transfer_efficiency then
                    equipment.energy = equipment.energy + self.entity.burner.remaining_burning_fuel * transfer_efficiency
                    self.entity.burner.remaining_burning_fuel = 0
                    break
                else
                    self.entity.burner.remaining_burning_fuel = self.entity.burner.remaining_burning_fuel - missing / transfer_efficiency
                    equipment.energy = equipment.energy + missing
                end
            end
        end
    end
end

function Ctron_nuclear_powered:set_request_items(request_items, item_whitelist)
    request_items = request_items or {}
    request_items[self.fuel] = (request_items[self.fuel] or 0) + self.fuel_count
    request_items["construction-robot"] = (request_items["construction-robot"] or 0) + self.robots
    Ctron.set_request_items(self, request_items, item_whitelist)
end

return Ctron_nuclear_powered
