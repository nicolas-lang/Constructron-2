--local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Action = require("__Constructron-2__.script.objects.actions.Action")
local Ctron = require("__Constructron-2__.script.objects.Ctron")

-- class Type Action_do_task, nil members exist just to describe fields
local Action_do_task = {
    class_name = "Action_do_task"
}
Action_do_task.__index = Action_do_task

setmetatable(
    Action_do_task,
    {
        __index = Action, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)
-- Action_do_task Constructor
function Action_do_task:new(surfacemanager)
    self:log()
    Action.new(self, surfacemanager)
end

-- Class Methods
function Action_do_task:handleStateTransition(job)
    self:log()
    local newState = Action.handleStateTransition(self, job)
    if newState then
        return newState
    end
    -- Spidertron is valid because it would have failed in Action.handleStateTransition
    -- Job Status is DoTask
    if job.constructron:get_status_id() == Ctron.status.pathfinding_failed then
        local task = job:get_current_task()
        task:next_position()
        job.constructron:set_status(Ctron.status.idle)
    elseif job.constructron:get_status_id() == Ctron.status.idle then
        local task = job:get_current_task()
        local next_position = task:get_next_position()
        if next_position then
            if job.constructron:distance_to(next_position) < 4 then
                -- at Task.NextPosition()
                if job.constructron:get_construction_enabled() then
                    --  Robots Enabled
                    --> Mark Position completed
                    --> Disable robots
                    task:next_position(true)
                    job.constructron:disable_construction()
                else
                    --  Robots Disabled
                    --> Enable robots
                    job.constructron:enable_construction()
                end
            else
                job.constructron:go_to(next_position)
            end
        else
            -- Task.NextPosition() == nil --> Task.set_completed()
            task:mark_completed()
            return job.status.validate
        end
    --elseif job.constructron:get_status_id() == Ctron.status.robots_active then
    --  return
    end
end

return Action_do_task
