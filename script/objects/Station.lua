local Debug = require("__Constructron-2__.script.objects.Debug")

---@class Station : Debug
local Station = {
    class_name = "Station",
    -- <base game spidertron entity unit_number used as PK for everything>
    unit_number = nil,
    -- <base game spidertron entity>
    entity = nil,
    name = nil,
    force = nil,
    registration_id = nil
}
Station.__index = Station

setmetatable(
    Station,
    {
        __index = Debug, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)

-- Station Constructor
function Station:new(entity)
    self:log()
    if entity and entity.valid then
        self.entity = entity
        self.unit_number = entity.unit_number
        self.name = entity.name
        self.force = entity.force

        self.registration_id = script.register_on_entity_destroyed(entity)
        global.service_stations.entity_registration[self.registration_id] = {
            unit_number = entity.unit_number,
            surface_index = entity.surface.index,
            force_index = entity.force.index
        }
        global.service_stations.entities[entity.unit_number] = entity
    end
end

-- Generic Type based initialization
function Station.init_globals()
    global.service_stations = global.service_stations or {}
    global.service_stations.entities = global.service_stations.entities or {}
    global.service_stations.entity_registration = global.service_stations.entity_registration or {}
end

function Station.get_registered_entity(entity_registration_number)
    return global.service_stations.entity_registration[entity_registration_number]
end
-- Class Methods
function Station:destroy()
    self:log()
    global.service_stations.entity_registration[self.registration_id] = nil
    global.service_stations.entities[self.unit_number] = nil
end

function Station:is_valid()
    self:log()
    return (self.entity and self.entity.valid)
end

function Station:get_inventory(requested_items)
    self:log()
    local items = {}
    if self:is_valid() then
        for item, _ in pairs(requested_items) do
            items[item] = self.entity.logistic_network.get_item_count(item) or 0
        end
    end
    return items
end

function Station:get_position()
    self:log()
    if self:is_valid() then
        return {
            position = self.entity.position,
            surface = self.entity.surface
        }
    end
end

function Station:distance_to(position)
    self:log()
    if self:is_valid() and position then
        return math.sqrt((self.entity.position.x - position.x) ^ 2 + (self.entity.position.y - position.y) ^ 2)
    end
end

function Station:get_logistic_network_id()
    self:log()
    if self:is_valid() then
        global.logistic_networks = global.logistic_networks or {}
        for id, n in pairs(global.logistic_networks) do
            if n == self.entity.logistic_network then
                return id
            end
        end
        -- register the network as id =  count(global.logistic_networks)+1
        global.logistic_networks[#(global.logistic_networks) + 1] = self.entity.logistic_network
        return #(global.logistic_networks)
    end
end

return Station
