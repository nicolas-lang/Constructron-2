local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Action = require("__Constructron-2__.script.objects.actions.Action")

-- class Type Action_task_completed, nil members exist just to describe fields
local Action_task_completed = {
    class_name = "Action_task_completed",
}
Action_task_completed.__index = Action_task_completed

setmetatable(
    Action_task_completed,
    {
        __index = Action, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)
-- Action_task_completed Constructor
function Action_task_completed:new(surfacemanager)
    self:log()
    Action.new(self,surfacemanager)
end
-- Class Methods
function Action_task_completed:handleStateTransition(job)
    self:log()
    local newState = "job_completed"
    return newState
end


return Action_task_completed
