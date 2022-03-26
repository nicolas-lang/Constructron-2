local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local control_lib = require("__Constructron-2__.script.lib.control_lib")
local Task_construction = require("__Constructron-2__.script.objects.Task-construction")
local Task_delivery = require("__Constructron-2__.script.objects.Task-delivery")
local Debug = require("__Constructron-2__.script.objects.Debug")
local Job = require("__Constructron-2__.script.objects.Job")
local Ctron = require("__Constructron-2__.script.objects.Ctron")

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
        self.surface_index = surface.index
        self.surface = surface
        if force then
            self.force = force
            self.id = self.id .. "-" .. force.index
            self.force_index = force.index
        end
        self.chunks = {}
        self.tasks = {}
        self.jobs = {}
        self.job_actions = {}
        self.constructrons = {}
        self.stations = {}

        for k, v in pairs(global.surface_managers[self.id] or {}) do
            self[k] = v
        end

        global.surface_managers[self.id] = global.surface_managers[self.id] or self
        for key, action in pairs(Job.actions) do
            self.job_actions[key] = action(self)
        end
    end
end

-- Static Methods
function Surface_manager.init_globals()
    global.surface_managers = global.surface_managers or {}
end

function Surface_manager.chunk_from_position(position)
    return math.floor((position.x or position[1]) / 32), math.floor((position.y or position[2]) / 32)
end

-- Class Methods
function Surface_manager:destroy()
    self:log()
    -- ToDo call destroy for  all managed entities on force/surface
    if global.surface_managers then
        global.surface_managers[self.id] = nil
    end
end

function Surface_manager:valid()
    self:log()
    if self.surface.valid == false then
        return false
    end
    if self.force and self.force.valid == false then
        return false
    end
    return true
end
-------------------------------------------------------------------------------
--  Surface Processing
-------------------------------------------------------------------------------

function Surface_manager:get_stats()
    return {
        [self.surface.name] = {}
    }
end

function Surface_manager:add_constructron(constructron)
    self.constructrons[constructron.unit_number] = constructron
end

function Surface_manager:add_station(station)
    self.stations[station.unit_number] = station
end

function Surface_manager:remove_constructron(constructron)
    self.constructrons[constructron.unit_number] = nil
end

function Surface_manager:constructron_destroyed(constructron_data) -- luacheck: ignore
    --if self.constructrons[constructron_data.unit_number] then
    --    self.constructrons[constructron_data.unit_number]:destroy()
    --    self.constructrons[constructron_data.unit_number] = nil
    --end
end

function Surface_manager:remove_station(station)
    self.stations[station.unit_number] = nil
end

function Surface_manager:station_destroyed(station_data) -- luacheck: ignore
    --self:remove_station(...)
end

function Surface_manager:update(limit) -- luacheck: ignore
    for key, constructron in pairs(self.constructrons) do
        if constructron:is_valid() then
            constructron:update()
        else
            game.print("unregistered ctron " .. key)
            self.constructrons[key] = nil
        end
    end
    for key, station in pairs(self.stations) do
        if station:is_valid() then
            station:update()
        else
            game.print("unregistered station " .. key)
            self.stations[key] = nil
        end
    end
end

function Surface_manager:get_free_constructron() -- luacheck: ignore
    for _, constructron in pairs(self.constructrons) do
        if constructron:get_status_id() == Ctron.status.free then
            return constructron
        end
    end
end

-------------------------------------------------------------------------------
--  Entity Processing
-------------------------------------------------------------------------------
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

function Surface_manager:register_entity(entity)
    self:log()
    local x, y = Surface_manager.chunk_from_position(entity.position)
    local key = x .. "/" .. y
    self.chunks[key] = self.chunks[key] or {entities = {}}
    local existing_entity = self.chunks[key].entities[control_lib.get_entity_key(entity)]
    if existing_entity then
        return
    else
        self:log("new entity in " .. key)
        self.chunks[key].entities[control_lib.get_entity_key(entity)] = entity
        self:log("chunk" .. serpent.block(self.chunks[key]))
        self:log("entity " .. serpent.block(self.chunks[key].entities[control_lib.get_entity_key(entity)]))
    end
end

function Surface_manager:unregister_entity(entity) -- luacheck: ignore
    self:log()
    local x, y = Surface_manager.chunk_from_position(entity.position)
    local key = x .. "/" .. y
    self.chunks[key] = self.chunks[key] or {entities = {}}
    self.chunks[key].entities[control_lib.get_entity_key(entity)] = nil

    if custom_lib.table_length(self.chunks[key]) == 0 then
        self.chunks[key] = nil
    end
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

-------------------------------------------------------------------------------
--  Job Processing
-------------------------------------------------------------------------------
function Surface_manager:run_jobs()
    self:log()
    for key, job in pairs(self.jobs) do
        -- each job state has a state-named action class which executes a job based action and returnes a state transition
        -- the state action is expected to work only on surfacemanager and job objects and their members
        -- The surfacemanager provides stations and surface related information, the job has task and ctron childs
        local state_based_action = self.job_actions[job:get_state()]
        local new_state = state_based_action.handleStateTransition(job)
        if new_state then
            job:set_state()
        end
        game.print(job:get_state())
        if job:get_state() == Job.state.job_completed then
            job:destroy()
            self.jobs[key] = nil
        end
    end
end

function Surface_manager:assign_jobs(limit)
    self:log()
    limit = limit or 10
    local c = 0
    local key, task = next(self.tasks)
    local unit = self:get_free_constructron()
    while task and unit and c < limit do
        --  select 1st free constructron
        unit:set_status(Ctron.status.idle)
        local job = Job()
        --just simple 1:1  - fix later
        job.add_task(task)
        self.tasks[key] = nil
        self.jobs[#(self.jobs) + 1] = job
        --ToDo
        --      get next task
        --           if job already has tasks: sort by mean distance
        --      assign task
        --          split task if to large
        --          insert task with remainder to front of task-queue if task was split
        --      get next (until >80% full or next task fits in full or distance > 1.5 chunks)
        key, task = next(self.tasks)
        unit = self:get_free_constructron()
        c = c + 1
    end
    return c
end

return Surface_manager
