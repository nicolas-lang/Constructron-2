local Ctron = require("__Constructron-2__.script.objects.Ctron")
local control_lib = require("__Constructron-2__.script.lib.control_lib")

---@class Ctron_nuclear_powered : Ctron
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
    construction_robots = {
        type = "ctron-nuclear-powered-robot",
        count = 120
    },
    inventory_filters = {
        ["repair-pack"] = 1,
        ["ctron-nuclear-powered-robot"] = 1
    }
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

---create managed gear, update slot filters, call parent constructor
---@param entity LuaEntity
function Ctron_nuclear_powered:new(entity)
    self:log()
    Ctron.new(self, entity)
    self:setup_gear()
    self:update_slot_filters()
end

---Transfer Power from Nuclear Burner to equippment Grid; also run parent's `tick_update()`
function Ctron_nuclear_powered:tick_update()
    self:log()
    Ctron.tick_update(self)
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

---set items requests to change inventory contents to these exactly items.
---managed construction robots are inored as they have their own handler
---@param request_items table <string,number> the items we want
---@param item_whitelist  table <string,boolean> other items that are also allowed
function Ctron_nuclear_powered:set_request_items(request_items, item_whitelist)
    self:log()
    request_items = request_items or {}
    item_whitelist = item_whitelist or {}
    item_whitelist[self.construction_robots.type] = true
    request_items[self.fuel] = (request_items[self.fuel] or 0) + control_lib.get_stack_size(self.fuel) * #(self.entity.burner.inventory)
    Ctron.set_request_items(self, request_items, item_whitelist)
end

---enable construction: enable roboports and spawn predefined robots
function Ctron_nuclear_powered:enable_construction()
    self:log()
    self:update_slot_filters()
    Ctron.enable_construction(self)
    local inventory = self.entity.get_inventory(defines.inventory.spider_trunk)
    inventory.insert({name = self.construction_robots.type, count = self.construction_robots.count})
end

---disable construction: disable roboports and despawn robots
--- TODO: handle still deployed robots: also drop potentially carried items to the ground and mark them for decosntruction
function Ctron_nuclear_powered:disable_construction()
    self:log()
    self:update_slot_filters()
    Ctron.disable_construction(self)
    local inventory = self.entity.get_inventory(defines.inventory.spider_trunk)
    inventory.remove({name = self.construction_robots.type, count = 999})
end

return Ctron_nuclear_powered
