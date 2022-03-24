local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Action = require("__Constructron-2__.script.objects.actions.Action")

-- class Type Action_next_task, nil members exist just to describe fields
local Action_next_task = {
    class_name = "Action_next_task",
}
Action_next_task.__index = Action_next_task

setmetatable(
    Action_next_task,
    {
        __index = Action, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)
-- Action_next_task Constructor
function Action_next_task:new(surfacemanager)
    self:log()
    Action.new(self,surfacemanager)
end

-- Class Methods
function Action_next_task:handleStateTransition(job)
    self:log()
    local newState = "do_task"
    return newState
end


return Action_next_task
