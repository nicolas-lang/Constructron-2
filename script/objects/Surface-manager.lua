local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Task_construction = require("__Constructron-2__.script.objects.Task-construction")
local Task_delivery = require("__Constructron-2__.script.objects.Task-delivery")
local Debug = require("__Constructron-2__.script.objects.Debug")

-- class Type Surface_manager, nil members exist just to describe fields
local Surface_manager = {
    class_name = "Surface_manager"
}
Surface_manager.__index = Surface_manager

setmetatable(
    Surface_manager,
    {
        __index = Debug, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)

-- Surface_manager Constructor
function Surface_manager:new(surface, force)
    -- if force needs to be added it should be sufficient to modify control.lua
    self:log()
    global.surface_managers = global.surface_managers or {}
    if surface.valid then
        self.id = surface.index
        self.surface_id = surface.index
        if force then
            self.id = self.id .. "-" .. force.index
            self.force_id = force.index
        end
        global.surface_managers[self.id] =
            global.surface_managers[self.id] or
            {
                surface_id = self.surface_id,
                force_id = self.force_id,
                chunks = {},
                tasks = {}
            }
        -- fix/remove or {}
        global.surface_managers[self.id].chunks = global.surface_managers[self.id].chunks or {}
        global.surface_managers[self.id].tasks = global.surface_managers[self.id].tasks or {}
        global.surface_managers[self.id].jobs = global.surface_managers[self.id].jobs or {}
        self.chunks = global.surface_managers[self.id].chunks
        self.tasks = global.surface_managers[self.id].tasks
        self.jobs = global.surface_managers[self.id].jobs
    end
end

-- Generic Type based initialization
function Surface_manager.init_globals()
    global.surface_managers = global.surface_managers or {}
end

function Surface_manager.chunk_from_position(position)
    return math.floor((position.x or position[1]) / 32), math.floor((position.y or position[2]) / 32)
end

-- Class Methods
function Surface_manager:destroy()
    self:log()
    global.surface_managers[self.id] = nil
end

function Surface_manager:register_entity(entity)
    self:log()
    local x, y = Surface_manager.chunk_from_position(entity.position)
    local key = x .. "/" .. y
    self.chunks[key] = self.chunks[key] or {entities = {}}
    local existing_entity = self.chunks[key].entities[entity]
    if existing_entity then
        return
    else
        self:log("new entity in " .. key)
        self.chunks[key].entities[entity] = entity
        self:log("chunk" .. serpent.block(self.chunks[key]))
        self:log("entity " .. serpent.block(self.chunks[key].entities[entity]))
    end
end

function Surface_manager:unregister_entity(entity)-- luacheck: ignore
    self:log()
    local x, y = Surface_manager.chunk_from_position(entity.position)
    local key = x .. "/" .. y
    self.chunks[key] = self.chunks[key] or {entities = {}}
    self.chunks[key].entities[entity] = nil
    if custom_lib.table_length(self.chunks[key]) == 0 then
        self.chunks[key] = nil
    end
end

function Surface_manager:run_jobs(limit)-- luacheck: ignore
    self:log()
    limit = limit or 10
    local key, chunk = next({})
    local c = 0
    while key and c < limit do
    -- loop through jobs
    --      run each job's action driver & state transition
    end
    return c
end


function Surface_manager:assign_jobs(limit)
    self:log()
    limit = limit or 10
    local key, chunk = next({})
    local c = 0
    while key and c < limit do
        --  select 1st free constructron
        --      get next task
        --           if job already has tasks: sort by mean distance
        --      assign task
        --          split task if to large
        --          insert task with remainder to front of task-queue if task was split
        --      get next (until >80% full or next task fits in full or distance > 1.5 chunks)
    end
    return c
end

function Surface_manager:assign_tasks(limit)
    self:log()
    limit = limit or 10
    local key, chunk = next(self.chunks)
    local c = 0
    while key and c < limit do
        self:log("key " .. serpent.block(key))
        self:log("chunk " .. serpent.block(chunk))
        -- fix/remove or {}
        local entities = self.chunks[key].entities or {}
        self:log("self.chunks[" .. key .. "].entities " .. serpent.block(entities))
        local task = Task_construction()
        local delivery = Task_delivery()
        for k, entity in pairs(entities) do
            if entity.name == "ctron-buffer-chest" then
                delivery:add_entity(entity)
            else
                task:add_entity(entity)
            end
        end
        task:update()
        delivery:update()
        if task:get_items() then
            self.tasks[#(self.tasks)] = task
            self:log("registered task: " .. serpent.block(task))
        else
            task:destroy()
        end
        if delivery:get_items() then
            self.tasks[#(self.tasks)] = delivery
            self:log("registered delivery: " .. serpent.block(delivery))
        else
            delivery:destroy()
        end
        self.chunks[key] = nil
        key, chunk = next(self.chunks)
        c = c + 1
    end
    return c
end

function Surface_manager:process_entity(entity)
    self:log()
    if
        entity and entity.valid and
            (entity.type == "entity-ghost" or entity.type == "tile-ghost" or entity.to_be_upgraded() or entity.to_be_deconstructed() or entity.get_health_ratio() < 0.95 or
                entity.type == "item-request-proxy" or
                entity.name == "ctron-buffer-chest")
     then
        self:register_entity(entity)
    end
end

return Surface_manager
