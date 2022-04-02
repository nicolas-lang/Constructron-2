local Ctron = require("__Constructron-2__.script.objects.Ctron")

-- class Type Ctron_solar_powered, nil members exist just to describe fields
local Ctron_solar_powered = {
    class_name = "Ctron_solar_powered",
    gear = {
        "ctron-solar-powered-roboport-equipment",
        "ctron-solar-panel-equipment",
        "ctron_solar_powered_leg-{movement_research}",
        "ctron-solar-powered-battery-equipment"
    },
    managed_equipment_cols = 4,
    robots = 20
}
Ctron_solar_powered.__index = Ctron_solar_powered

setmetatable(
    Ctron_solar_powered,
    {
        __index = Ctron, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)

-- Ctron_solar_powered Constructor
function Ctron_solar_powered:new(entity)
    log("Ctron_solar_powered.new")
    Ctron.new(self, entity)
    self:setup_gear()
end

function Ctron_solar_powered:tick_update()
    Ctron.tick_update(self)
    if self.entity.valid then
        local grid = self.entity.grid
        if grid.available_in_batteries > 0 then
            local remaining_burning_fuel = self.entity.burner.remaining_burning_fuel
            --log("remaining_burning_fuel" .. remaining_burning_fuel)
            if not self.entity.burner.currently_burning then
                self.entity.burner.currently_burning = "constructron-solar-fuel"
            end

            local currently_burning = self.entity.burner.currently_burning
            local max_fuel = currently_burning.fuel_value
            --log("max_fuel:" .. max_fuel)

            local required_energy = max_fuel - remaining_burning_fuel
            --log("required_energy " .. math.floor(required_energy))

            for _, equipment in pairs(grid.equipment) do
                if equipment.name == "ctron-solar-powered-battery-equipment" then
                    local transfer_energy = math.min(required_energy, equipment.energy)
                    remaining_burning_fuel = remaining_burning_fuel + transfer_energy
                    equipment.energy = equipment.energy - transfer_energy
                    required_energy = required_energy - transfer_energy
                --log("removed " .. math.floor(transfer_energy) .. " energy from batteries")
                end
            end
            self.entity.burner.remaining_burning_fuel = remaining_burning_fuel
        end
    end
end

function Ctron_solar_powered:status_update()
    if self:is_valid() then
        local status = Ctron.status_update(self)
        if self.entity.burner and not self.entity.burner.currently_burning then
            status = Ctron.status.no_energy
        end
        return status
    end

end

function Ctron_solar_powered:set_request_items(request_items, item_whitelist)
    request_items = request_items or {}
    request_items["construction-robot"] = (request_items["construction-robot"] or 0) + self.robots
    Ctron.set_request_items(self, request_items, item_whitelist)
end

return Ctron_solar_powered
