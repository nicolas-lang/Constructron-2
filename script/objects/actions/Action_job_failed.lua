local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Action = require("__Constructron-2__.script.objects.actions.Action")

-- class Type Action_job_failed, nil members exist just to describe fields
local Action_job_failed = {
    class_name = "Action_job_failed",
}
Action_job_failed.__index = Action_job_failed

setmetatable(
    Action_job_failed,
    {
        __index = Action, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)
-- Action_job_failed Constructor
function Action_job_failed:new(surfacemanager)
    self:log()
    Action.new(self,surfacemanager)
end

-- Class Methods
function Action_job_failed:handleStateTransition(job)
    self:log()
    local newState = nil
    return newState
end


return Action_job_failed
