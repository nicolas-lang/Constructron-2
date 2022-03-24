local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Action = require("__Constructron-2__.script.objects.actions.Action")

-- class Type Action_get_service, nil members exist just to describe fields
local Action_get_service = {
    class_name = "Action_get_service",
}
Action_get_service.__index = Action_get_service

setmetatable(
    Action_get_service,
    {
        __index = Action, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)
-- Action_get_service Constructor
function Action_get_service:new(surfacemanager)
    self:log()
    Action.new(self,surfacemanager)
end

-- Class Methods
function Action_get_service:handleStateTransition(job)
    self:log()
    local newState = "next_task"
    return newState
end


return Action_get_service
