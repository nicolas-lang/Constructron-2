local Ctron = require("__Constructron-2__.script.objects.Ctron")
local control_lib = require("__Constructron-2__.script.lib.control_lib")

---@class Ctron_rocket_powered : Ctron
local Ctron_rocket_powered = {
    class_name = "Ctron_rocket_powered",
    gear = {
        "ctron-rocket-powered-roboport-equipment",
        "ctron-rocket-powered-reactor-equipment",
        "ctron_rocket_powered_leg-{movement_research}",
        "ctron-rocket-powered-battery-equipment"
    },
    managed_equipment_cols = 4,
    fuel = "rocket-fuel",
    construction_robots = {
        type = "ctron-rocket-powered-robot",
        count = 5
    },
    inventory_filters = {
        ["repair-pack"] = 1,
        ["ctron-rocket-powered-robot"] = 1
    }
}

Ctron_rocket_powered.__index = Ctron_rocket_powered

setmetatable(
    Ctron_rocket_powered,
    {
        __index = Ctron, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)

-- Ctron_rocket_powered Constructor
function Ctron_rocket_powered:new(entity)
    log("Ctron_rocket_powered.new")
    Ctron.new(self, entity)
    self:setup_gear()
    self:update_slot_filters()
end

function Ctron_rocket_powered:tick_update()
    Ctron.tick_update(self)
    if self:is_valid() then
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

function Ctron_rocket_powered:set_request_items(request_items, item_whitelist)
    request_items = request_items or {}
    request_items[self.fuel] = (request_items[self.fuel] or 0) + control_lib.get_stack_size(self.fuel) * #(self.entity.burner.inventory)
    --request_items["construction-robot"] = (request_items["construction-robot"] or 0) + self.robots
    Ctron.set_request_items(self, request_items, item_whitelist)
end

function Ctron_rocket_powered:go_to(target)
    if self:is_valid() and target then
        -- never pathfind, we can fly
        self:set_autopilot({{position = target}})
    end
end

function Ctron_rocket_powered:enable_construction()
    self:log()
    self:update_slot_filters()
    Ctron.enable_construction(self)
    inventory = self.entity.get_inventory(defines.inventory.spider_trunk)
    inventory.insert({name = self.construction_robots.type , count = self.construction_robots.count})
end

function Ctron_rocket_powered:disable_construction()
    self:log()
    self:update_slot_filters()
    Ctron.disable_construction(self)
    inventory = self.entity.get_inventory(defines.inventory.spider_trunk)
    inventory.remove({name = self.construction_robots.type , count = 999})
end



return Ctron_rocket_powered
