local custom_lib = require("__Constructron-2__.data.lib.custom_lib")

-- class Type Surface_manager, nil members exist just to describe fields
local Surface_manager = {}
Surface_manager.__index = Surface_manager

setmetatable(
    Surface_manager,
    {
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)

-- Surface_manager Constructor
function Surface_manager:new(surface, force)
    if surface.valid then
        self.id = surface.id
        self.surface_id = surface.id
        if force then
            self.id = self.id .. "-" .. force.index
            self.force_id = force.index
        end
    end
    log("Surface_manager.new")
    global.surface_managers[self.id] =
        global.surface_managers[self.id] or
        {
            surface_id = self.surface_id,
            force_id = self.force_id,
            chunks = {}
        }
    self.chunks = global.surface_managers[self.id].chunks
end

-- Generic Type based initialization
function Surface_manager.init_globals()
    global.Surface_managers = global.Surface_managers or {}
end

function Surface_manager.chunk_from_position(position)
    return math.floor((position.x or position[1]) / 32), math.floor((position.y or position[2]) / 32)
end

-- Class Methods
function Surface_manager:destroy()
    global.surface_managers[self.id] = nil
end

function Surface_manager:register_entity(entity)
    local x, y = Surface_manager.chunk_from_position(entity.position)
    local key = x .. "/" .. y
    self.chunks[key] = self.chunks[key] or {entities = {}, tasks = {}, calculated = false}
    local existing_entity = self.chunks[key].entities[entity.unit_number]
    if existing_entity then
        return
    else
        self.chunks[key].entities[entity.unit_number] = entity
        self.chunks[key].calculated = false
    end
end

function Surface_manager:unregister_entity(entity)
    local x, y = Surface_manager.chunk_from_position(entity.position)
    local key = x .. "/" .. y
    self.chunks[key] = self.chunks[key] or {entities = {}}
    self.chunks[key].entities[entity.unit_number] = nil

    if custom_lib.table_length(self.chunks[key]) == 0 then
        self.chunks[key] = nil
    end
end

function Surface_manager:process_entity(entity)
    if
        -- todo we need to ghet it done without entity.unit_number
        entity and entity.valid and entity.unit_number and
            (entity.type == "entity-ghost" or entity.type == "tile-ghost" or entity.to_be_upgraded() or entity.to_be_deconstructed() or entity.get_health_ratio() < 0.95 or
                entity.type == "item-request-proxy")
     then
        self:register_entity(entity)
    end
end

return Surface_manager
