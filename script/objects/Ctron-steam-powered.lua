local Ctron = require("__Constructron-2__.script.objects.Ctron")
local control_lib = require("__Constructron-2__.script.lib.control_lib")

---@class Ctron_steam_powered : Ctron
local Ctron_steam_powered = {
    class_name = "Ctron_steam_powered",
    gear = {
        "ctron-steam-powered-roboport-equipment",
        "ctron-steam-powered-reactor-equipment",
        "ctron_steam_powered_leg-{movement_research}",
        "ctron-steam-powered-battery-equipment"
    },
    managed_equipment_cols = 4,
    fuel = "coal",
    construction_robots = {
        type = "ctron-steam-powered-robot",
        count = 5
    },
    inventory_filters = {
        ["repair-pack"] = 1,
        ["ctron-steam-powered-robot"] = 1
    }
}

Ctron_steam_powered.__index = Ctron_steam_powered

setmetatable(
    Ctron_steam_powered,
    {
        __index = Ctron, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)

-- Ctron_steam_powered Constructor
function Ctron_steam_powered:new(entity)
    log("Ctron_steam_powered.new")
    Ctron.new(self, entity)
    self:setup_gear()
    self:update_slot_filters()
end

function Ctron_steam_powered:tick_update()
    self:log()
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

function Ctron_steam_powered:set_request_items(request_items, item_whitelist)
    self:update_slot_filters()
    request_items = request_items or {}
    item_whitelist = item_whitelist or {}
    item_whitelist[self.construction_robots.type] = true
    request_items[self.fuel] = (request_items[self.fuel] or 0) + control_lib.get_stack_size(self.fuel) * #(self.entity.burner.inventory)
    Ctron.set_request_items(self, request_items, item_whitelist)
end

function Ctron_steam_powered:enable_construction()
    self:log()
    self:update_slot_filters()
    Ctron.enable_construction(self)
    local inventory = self.entity.get_inventory(defines.inventory.spider_trunk)
    inventory.insert({name = self.construction_robots.type , count = self.construction_robots.count})
end

function Ctron_steam_powered:disable_construction()
    self:log()
    self:update_slot_filters()
    Ctron.disable_construction(self)
    local inventory = self.entity.get_inventory(defines.inventory.spider_trunk)
    inventory.remove({name = self.construction_robots.type , count = 999})
end

return Ctron_steam_powered
