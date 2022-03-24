local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Action = require("__Constructron-2__.script.objects.actions.Action")

-- class Type Action_job_completed, nil members exist just to describe fields
local Action_job_completed = {
    class_name = "Action_job_completed",
}
Action_job_completed.__index = Action_job_completed

setmetatable(
    Action_job_completed,
    {
        __index = Action, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)
-- Action_job_completed Constructor
function Action_job_completed:new(surfacemanager)
    self:log()
    Action.new(self,surfacemanager)
end

-- Class Methods
function Action_job_completed:handleStateTransition(job)
    self:log()
    local newState = nil
    return newState
end


return Action_job_completed
