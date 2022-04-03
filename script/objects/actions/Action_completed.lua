--local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Action = require("__Constructron-2__.script.objects.actions.Action")
--local Ctron = require("__Constructron-2__.script.objects.Ctron")

-- class Type Action_completed, nil members exist just to describe fields
local Action_completed = {
    class_name = "Action_completed"
}
Action_completed.__index = Action_completed

setmetatable(
    Action_completed,
    {
        __index = Action, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)
-- Action_completed Constructor
function Action_completed:new(surfacemanager)
    self:log()
    Action.new(self, surfacemanager)
end

-- Class Methods
function Action_completed:handleStateTransition(_)
    self:log()
    -- final state
    --> job needs to be destroyed by parent
    --> no action
end

return Action_completed
