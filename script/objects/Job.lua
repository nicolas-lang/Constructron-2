--local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Debug = require("__Constructron-2__.script.objects.Debug")

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

Job.state = {
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
    self.entities = {}
    self.state = Job.state.job_new
    self:log("id " .. self.id)
end

-- Generic Type based initialization
function Job.init_globals()
    global.Jobs = global.Jobs or {}
end

function Job:set_state(state)
    self.state = Job.state[state]
end

function Job:get_state()
    for k, v in pairs(Job.state) do
        if self.state == v then
            return k
        end
    end
end

-- Class Methods
function Job:destroy()
    self:log()
    global.Jobs[self.id] = nil
end

return Job
