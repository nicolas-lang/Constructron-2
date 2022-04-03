local Ctron = require("__Constructron-2__.script.objects.Ctron")
local control_lib = require("__Constructron-2__.script.lib.control_lib")

-- class Type Ctron_steam_powered, nil members exist just to describe fields
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
    robots = 5
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
    item_whitelist["ctron-steam-powered-robot"] = true
    request_items[self.fuel] = (request_items[self.fuel] or 0) + control_lib.get_stack_size(self.fuel) * #(self.entity.burner.inventory)
    --request_items["construction-robot"] = (request_items["construction-robot"] or 0) + self.robots
    Ctron.set_request_items(self, request_items, item_whitelist)
end

function Ctron_steam_powered:update_slot_filters()
    self:log()
    inventory = self.entity.get_inventory(defines.inventory.spider_trunk)
    local filters = {
        ["ctron-steam-powered-robot"] = #inventory ,
        ["repair-pack"] = #inventory - 1
    }
    for item, slot in pairs(filters) do
        if not inventory.set_filter(slot, item) then
            inventory[slot].clear()
            inventory.set_filter(slot, item)
        end
    end
end

function Ctron_steam_powered:enable_construction()
    self:log()
    self:update_slot_filters()
    Ctron.enable_construction(self)
    inventory = self.entity.get_inventory(defines.inventory.spider_trunk)
    inventory[#inventory].set_stack({name = "ctron-steam-powered-robot", count = 5})
end

function Ctron_steam_powered:disable_construction()
    self:log()
    self:update_slot_filters()
    Ctron.disable_construction(self)
    inventory[#inventory - 1].clear()
end

return Ctron_steam_powered
