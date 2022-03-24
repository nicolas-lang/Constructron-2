local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Action = require("__Constructron-2__.script.objects.actions.Action")

-- class Type Action_do_task, nil members exist just to describe fields
local Action_do_task = {
    class_name = "Action_do_task",
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
    Action.new(self,surfacemanager)
end

-- Class Methods
function Action_do_task:handleStateTransition(job)
    self:log()
    local newState = "task_completed"
    return newState
end


return Action_do_task
