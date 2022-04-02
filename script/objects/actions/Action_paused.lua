--local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Action = require("__Constructron-2__.script.objects.actions.Action")
local Ctron = require("__Constructron-2__.script.objects.Ctron")

-- class Type Action_paused, nil members exist just to describe fields
local Action_paused = {
    class_name = "Action_paused"
}
Action_paused.__index = Action_paused

setmetatable(
    Action_paused,
    {
        __index = Action, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)
-- Action_paused Constructor
function Action_paused:new(surfacemanager)
    self:log()
    Action.new(self, surfacemanager)
end

-- Class Methods
function Action_paused:handleStateTransition(job)
    self:log()
    local newState = Action.handleStateTransition(self, job)
    if newState then
        return newState
    end
    if job.constructron:get_status_id() == Ctron.status.idle then
        return job.status.start
    end
end

return Action_paused
