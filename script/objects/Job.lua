local Debug = require("__Constructron-2__.script.objects.Debug")
local custom_lib = require("__Constructron-2__.data.lib.custom_lib")

---@class Job : Debug
---@field public id uint
---@field public status table<string,uint>
---@field public actions table<string,Action>
---@field private current_status uint
---@field private tasks table<uint,Task>
local Job = {
    class_name = "Job",
    actions = {
        check_service = require("__Constructron-2__.script.objects.actions.Action_check_service"),
        completed = require("__Constructron-2__.script.objects.actions.Action_completed"),
        do_task = require("__Constructron-2__.script.objects.actions.Action_do_task"),
        failed = require("__Constructron-2__.script.objects.actions.Action_failed"),
        get_service = require("__Constructron-2__.script.objects.actions.Action_get_service"),
        new = require("__Constructron-2__.script.objects.actions.Action_new"),
        paused = require("__Constructron-2__.script.objects.actions.Action_paused"),
        start = require("__Constructron-2__.script.objects.actions.Action_start"),
        validate = require("__Constructron-2__.script.objects.actions.Action_validate")
    },
    status = {
        check_service = 10,
        completed = 20,
        do_task = 30,
        failed = 40,
        get_service = 50,
        new = 60,
        paused = 70,
        start = 80,
        validate = 90
    }
}
Job.__index = Job

setmetatable(
    Job,
    {
        __index = Debug, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)

---comment
---@param obj any
function Job:new(obj)
    Debug.new(self)
    self:log()
    for k, v in pairs(obj or {}) do
        self[k] = v
    end
    global.Jobs = global.Jobs or {}
    self.id = self.id or #(global.Jobs) + 1
    global.Jobs[self.id] = self
    self.tasks = {}
    self.current_status = Job.status.new
    self:log("id " .. self.id)
end

-- Generic Type based initialization
function Job.init_globals()
    global.Jobs = global.Jobs or {}
end

-- Class Methods

---Set the job's status
---@param status string|uint
function Job:set_status(status)
    self:log()
    local text_status
    local parsed_status
    if type(status) == "number" then
        for key, value in pairs(Job.status) do
            if value == status then
                parsed_status = status
                text_status = key
            end
        end
    else
        text_status = status
        parsed_status = Job.status[status]
    end
    if not parsed_status then
        log("set_status:unknown status: " .. (status or "nil"))
    end
    self.current_status = parsed_status
    if self.constructron then
        self:attach_text(self.constructron.entity, text_status, self.debug_definition.lines.line_1, 2)
    end
    self:log(text_status)
end

---Get's the Job's current status(name)
---@return string
function Job:get_status()
    for k, v in pairs(Job.status) do
        if self:get_status_id() == v then
            return k
        end
    end
end

---Get's the Job's current status(ID)
---@return number|uint
function Job:get_status_id()
    return self.current_status
end

---Updates the Job and all it's Tasks
function Job:update()
    self:log()
    --Check all Tasks/entities
    for key, task in pairs(self.tasks) do
        task:update()
        --> remove tasks with no remaining entities to build
        -- NO, beacuse we want to validate and re-queue them later...
        -- TODO: check tasks's completed flag for next etc.
        --if task:get_completed() == true then
        --task:destroy()
        --self.tasks[key] = nil
        --end
    end
end

---Delete the Job and all dependancies
function Job:destroy()
    self:log()
    --Check all entities
    self:update()
    for _, task in pairs(self.tasks) do
        task:destroy()
    end
    self.tasks = {}

    if self.constructron and self.constructron:is_valid() then
        self.constructron:assign_job(nil)
    end
    global.Jobs[self.id] = nil
end

---Addes a Task to the Job
---@param task Task
function Job:add_task(task)
    self:log()
    log(serpent.block(self))
    self.tasks[#(self.tasks) + 1] = task
    self.active_task = self.active_task or 1
end

---Assign a Constructron to perform the Job's constructions
---@param constructron Ctron
function Job:assign_constructron(constructron)
    self:log()
    if constructron:is_valid() then
        self.constructron = constructron
        constructron:assign_job(self.id)
        self:update_task_positions()
    end
end

---Update all Task positions based on the assigned contructrons contruction radius
function Job:update_task_positions()
    if self.constructron and self.constructron:is_valid() then
        for _, task in pairs(self.tasks) do
            task:update_positions(self.constructron:get_construction_radius() * 2)
        end
    end
end

---Get the currently active task
---@return any
function Job:get_current_task()
    for _, task in ipairs(self.tasks) do --ipairs to ensure ordered processing
        if task:get_completed() ~= true then
            if self.constructron and self.constructron:is_valid() then
                task:update_positions(self.constructron:get_construction_radius() * 2)
            end
            return task
        end
    end
end

---Move to the next task, can mark the previous task completed
---@param mark_completed any
function Job:next_task(mark_completed)
    if #(self.tasks) > 0 then
        local task = table.remove(self.tasks, 1)
        if mark_completed then
            task:mark_completed()
        end
        table.insert(self.tasks, task)
    end
end

---Assign a Service Station to the job
---@param station any
function Job:assign_station(station)
    self.station = station
end

---Unassign the Job's Service Station
function Job:unassign_station()
    self.station = nil
end

---Unassign the Job's Constructron
function Job:clear_constructron()
    self.constructron = nil
end

---Get all the items required by the Job's Tasks
---@return table
function Job:get_items()
    self:log()
    local items = {}
    self:update()
    for _, task in pairs(self.tasks) do
        custom_lib.merge_add(items, task:get_items())
    end
    return items
end

---Get the median position over all the Job's Task's
---@return MapPosition
function Job:get_position()
    self:log()
    local position = {x = 0, y = 0}
    if next(self.tasks) then
        local c = 0
        for _, task in pairs(self.tasks) do
            local task_position = task:get_position()
            if task_position then
                position.x = task_position.x
                position.y = task_position.y
                c = c + 1
            end
        end
        if c > 0 then
            position.x = math.floor(position.x / c * 1000 + 0.5) / 1000
            position.y = math.floor(position.y / c * 1000 + 0.5) / 1000
            self:log(serpent.block(position))
            return position
        end
    end
end

return Job
