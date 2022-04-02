--local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Action = require("__Constructron-2__.script.objects.actions.Action")
--local Ctron = require("__Constructron-2__.script.objects.Ctron")

-- class Type Action_failed, nil members exist just to describe fields
local Action_failed = {
    class_name = "Action_failed"
}
Action_failed.__index = Action_failed

setmetatable(
    Action_failed,
    {
        __index = Action, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)
-- Action_failed Constructor
function Action_failed:new(surfacemanager)
    self:log()
    Action.new(self, surfacemanager)
end

-- Class Methods
function Action_failed:handleStateTransition(job)
    self:log()
    game.print("job failed " .. (job.id or ""))
    return job.status.completed
end

return Action_failed
