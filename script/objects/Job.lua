local Debug = require("__Constructron-2__.script.objects.Debug")
local custom_lib = require("__Constructron-2__.data.lib.custom_lib")

-- class Type Job, nil members exist just to describe fields
local Job = {
    class_name = "Job",
    area = nil,
    position = nil,
    actions = {
        job_new = require("__Constructron-2__.script.objects.actions.Action_job_new"),
        next_task = require("__Constructron-2__.script.objects.actions.Action_next_task"),
        do_task = require("__Constructron-2__.script.objects.actions.Action_do_task"),
        get_service = require("__Constructron-2__.script.objects.actions.Action_get_service"),
        task_completed = require("__Constructron-2__.script.objects.actions.Action_task_completed"),
        task_failed = require("__Constructron-2__.script.objects.actions.Action_task_failed"),
        job_paused = require("__Constructron-2__.script.objects.actions.Action_job_paused"),
        job_completed = require("__Constructron-2__.script.objects.actions.Action_job_completed"),
        job_failed = require("__Constructron-2__.script.objects.actions.Action_job_failed")
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

Job.status = {
    job_new = 10,
    next_task = 20,
    do_task = 30,
    get_service = 40,
    task_completed = 70,
    task_failed = 80,
    job_paused = 50,
    job_completed = 85,
    job_failed = 90
}
-- Job Constructor
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
    self.status = Job.status.job_new
    self:log("id " .. self.id)
end

-- Generic Type based initialization
function Job.init_globals()
    global.Jobs = global.Jobs or {}
end
-- Class Methods
function Job:set_status(status)
        local parsed_status
        if type(status) == "number" then
            for _, value in pairs(Job.status) do
                if value == status then
                    parsed_status = status
                end
            end
        else
            parsed_status = Job.status[status]
        end
        if not parsed_status then
            log("set_status:unknown status: " .. (status or "nil"))
        end
        self.status = parsed_status
end

function Job:get_status()
    for k, v in pairs(Job.status) do
        if self:get_status_id() == v then
            return k
        end
    end
end

function Job:get_status_id()
    return self.status
end


function Job:destroy()
    self:log()
    --check all tasks for unifinished entities and re-queue
    if self.constructron and self.constructron:is_valid() then
        self.constructron:assign_job(nil)
    end
    global.Jobs[self.id] = nil
end

function Job:add_task(task)
    self:log()
    log(serpent.block(self))
    self.tasks[#(self.tasks) + 1] = task
    self.active_task = self.active_task or 1
end

function Job:assign_constructron(constructron)
    self:log()
    if constructron:is_valid() then
        self.constructron = constructron
        constructron:assign_job(self.id)
    end
end

function Job:get_items()
    self:log()
    local items = {}
    for _, task in pairs(self.tasks) do
        task:update()
        custom_lib.merge_add(items,task:get_items())
    end
    return items
end

return Job
