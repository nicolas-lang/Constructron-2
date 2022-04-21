--local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Debug = require("__Constructron-2__.script.objects.Debug")

---@class Entity_queue : Debug
local Entity_queue = {
    class_name = "Entity_queue",
    max_chunks_per_call = 20,
    max_entities_per_call = 1000,
    processing_delay = 60 * 2
}
Entity_queue.__index = Entity_queue

setmetatable(
    Entity_queue,
    {
        __index = Debug, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)
---Create a new Entity_queue instance
---@param callback function `callback´(entity, force)` is called when a queued LuaEntity is released from the queue for processing`
function Entity_queue:new(callback)
    Debug.new(self)
    self.entity_processing_callback = function(_, entity, force)
        log("self:callback")
        self:log("callback" .. serpent.block(entity) .. serpent.block(force))
        callback(entity, force)
    end
end

---Setup globals to be used by Entity_queue
function Entity_queue.init_globals()
    --global.entity_processing_queue = {}
    --global.chunk_processing_queue = {}
    global.entity_processing_queue = global.entity_processing_queue or {}
    global.chunk_processing_queue = global.chunk_processing_queue or {}
end

-- Class Methods

---Processes the global entity queue.
---the entity_processing_queue contains entities that needs to be checked for construction tasks
---@see process_chunk_queue
---@see on_built_entity
---@see on_entity_marked
---@return boolean
function Entity_queue:process_entity_queue()
    self:log()
    local c = 0
    local tick_index = next(global.entity_processing_queue)
    if tick_index and tick_index + self.processing_delay < game.tick then
        log("entity processing for tick " .. tick_index .. " was " .. (game.tick - tick_index - self.processing_delay) .. " ticks late")
        while tick_index and c < self.max_entities_per_call do
            log("processing tick " .. tick_index)
            local entities = global.entity_processing_queue[tick_index]
            local entity_index = next(entities)
            while entity_index and c < self.max_entities_per_call do
                local obj = entities[entity_index]
                if obj and obj.entity and obj.entity.valid then
                    -- process it
                    log("processing entity:")
                    log("entity.type " .. (obj.entity.type or "nil"))
                    log("entity.name " .. (obj.entity.name or "nil"))
                    self:entity_processing_callback(obj.entity, obj.force)
                    c = c + 1
                end
                entities[entity_index] = nil
                entity_index = next(entities)
            end
            if (#entities or 0) == 0 then
                global.entity_processing_queue[tick_index] = nil
            end

            tick_index = next(global.entity_processing_queue)
        end
    end
    return (c > 0)
end

---Processes the global chunk queue.
---The chunk_processing_queue contains chunks that needs to be checked for constructable objects
---Identified entities are registered with the entity_processing_queue
---@see process_entity_queue
---@see rescan_all_surfaces
---@return boolean
function Entity_queue:process_chunk_queue()
    ---@param entity LuaEntity
    ---@return LuaForce
    local function get_deconstructring_force(entity)
        if entity.force and entity.force.name ~= "neutral" then
            return entity.force
        end
        for _, force in pairs(game.forces) do
            if entity.is_registered_for_deconstruction(force) then
                return force
            end
        end
    end
    self:log()
    local c = 0
    local index = next(global.chunk_processing_queue)
    while index and c < self.max_chunks_per_call do
        local chunk_data = global.chunk_processing_queue[index]
        local filters = {
            {type = "entity", filter = {type = "entity-ghost"}},
            {type = "entity", filter = {type = "tile-ghost"}},
            {type = "entity", filter = {to_be_upgraded = true}},
            {type = "entity", filter = {to_be_deconstructed = true}, force_fix = true},
            {type = "tile", filter = {to_be_deconstructed = true}}
        }
        if not global.entity_processing_queue[game.tick] then
            global.entity_processing_queue[game.tick] = {}
        end
        if game.surfaces and game.surfaces[chunk_data.surface_key] and game.surfaces[chunk_data.surface_key].valid then
            local surface = game.surfaces[chunk_data.surface_key]
            for _, filter_def in pairs(filters) do
                filter_def.filter.area = {
                    chunk_data.left_top,
                    chunk_data.right_bottom
                }
                local objects
                if filter_def.type == "entity" then
                    objects = surface.find_entities_filtered(filter_def.filter)
                else
                    objects = surface.find_tiles_filtered(filter_def.filter)
                end
                for object in objects do
                    if object.valid then
                        local max_index = #(global.entity_processing_queue[game.tick])
                        local force = object.force
                        if filter_def.force_fix then
                            force = get_deconstructring_force(object)
                        end
                        assert(force, "entity has no force") -- remove this for release version
                        global.entity_processing_queue[game.tick][max_index + 1] = {entity = object, force = force}
                    end
                end
            end
        end
        global.chunk_processing_queue[index] = nil
        index = next(global.chunk_processing_queue)
        c = c + 1
    end
    return (c > 0)
end

---Add a new entity to the queue
---@param entity LuaEntity
---@param force LuaForce
---@param tick int
---@param build_type string
---@return boolean
function Entity_queue:queue_entity(entity, force, tick, build_type)
    self:log()
    if entity and entity.valid then
        tick = tick or game.tick
        if
            (entity.type == "tile-ghost" or build_type ~= "construction" or entity.type == "entity-ghost" or entity.type == "item-request-proxy" or entity.type == "spider-vehicle" or
                entity.type == "roboport")
         then
            -- register entity for processing, conditions are ordered by maximum expected number of build prototypes per tick to allow quick "short-circuiting"
            if not global.entity_processing_queue[tick] then
                global.entity_processing_queue[tick] = {}
            end
            local max_index = #(global.entity_processing_queue[tick])
            global.entity_processing_queue[tick][max_index + 1] = {entity = entity, force = force}
            log("registered entity for processing #" .. max_index + 1)
            return true
        end
    end
end

---queue a chunk for scanning
---@param chunk table
function Entity_queue:queue_chunk(chunk)
    self:log()
    if chunk and chunk.valid then
        local index = #global.chunk_processing_queue
        global.chunk_processing_queue[index + 1] = {
            surface = chunk.surface.index,
            left_top = chunk.area.left_top,
            right_bottom = chunk.area.right_bottom
        }
    end
end

return Entity_queue
