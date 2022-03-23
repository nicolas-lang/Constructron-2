local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Debug = require("__Constructron-2__.script.objects.Debug")

-- class Type Action, nil members exist just to describe fields
local Action = {
    class_name = "Action",
}
Action.__index = Action

setmetatable(
    Action,
    {
        __index = Debug, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)
-- Action Constructor
function Action:new(surfacemanager)
    Debug.new(self)
    self:log()
    self.surfacemanager = surfacemanager
end

-- Class Methods
function Action:handleStateTransition(job)
    self:log()
    local newState = nil
    return newState
end


return Action
