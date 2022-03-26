--local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Debug = require("__Constructron-2__.script.objects.Debug")

-- class Type Task, nil members exist just to describe fields
local Entity_queue = {
    class_name = "Entity_queue",
    max_chunks_per_call = 20,
    max_entities_per_call = 5000,
    processing_delay = 60 * 5
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
-- Task Constructor
function Entity_queue:new(callback)
    Debug.new(self)
    self.entity_processing_callback = function(_, entity)
        log("self:callback")
        self:log("callback" .. serpent.block(entity))
        callback(entity)
    end
end

-- Generic Type based initialization
function Entity_queue.init_globals()
    global.entity_processing_queue = global.entity_processing_queue or {}
    global.chunk_processing_queue = global.chunk_processing_queue or {}
end

-- Class Methods

--- Processes the global entity queue.
-- the entity_processing_queue contains entities that needs to be checked for construction tasks
-- @see process_chunk_queue
-- @see on_built_entity
-- @see on_entity_marked
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
                local entity = entities[entity_index]
                if entity and entity.valid then
                    -- process it
                    log("processing entity:")
                    log("entity.type " .. (entity.type or "nil"))
                    log("entity.name " .. (entity.name or "nil"))
                    self:entity_processing_callback(entity)
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

--- Processes the global chunk queue.
-- the chunk_processing_queue contains chunks that needs to be checked for constructable objects
-- identified entities are registered with the entity_processing_queue
-- @see process_entity_queue
-- @see rescan_all_surfaces
function Entity_queue:process_chunk_queue()
    self:log()
    local c = 0
    local index = next(global.chunk_processing_queue)
    while index and c < self.max_chunks_per_call do
        local chunk_data = global.chunk_processing_queue[index]
        local filters = {
            {type = "entity", filter = {type = "entity-ghost"}},
            {type = "entity", filter = {type = "tile-ghost"}},
            {type = "entity", filter = {to_be_deconstructed = true}},
            {type = "entity", filter = {to_be_upgraded = true}},
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
                    local max_index = #(global.entity_processing_queue[game.tick])
                    global.entity_processing_queue[game.tick][max_index + 1] = object
                end
            end
        end
        global.chunk_processing_queue[index] = nil
        index = next(global.chunk_processing_queue)
        c = c + 1
    end
    return (c > 0)
end

--- queue entity
-- @param event from factorio framework
function Entity_queue:queue_entity(entity, tick, build_type)
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
            global.entity_processing_queue[tick][max_index + 1] = entity
            log("registered entity for processing #" .. max_index + 1)
            return true
        end
    end
end

--- queue chunk
-- @param event from factorio framework
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
