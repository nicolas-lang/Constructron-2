--local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Action = require("__Constructron-2__.script.objects.actions.Action")
--local Ctron = require("__Constructron-2__.script.objects.Ctron")

-- class Type Action_validate, nil members exist just to describe fields
local Action_validate = {
    class_name = "Action_validate"
}
Action_validate.__index = Action_validate

setmetatable(
    Action_validate,
    {
        __index = Action, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)
-- Action_validate Constructor
function Action_validate:new(surfacemanager)
    self:log()
    Action.new(self, surfacemanager)
end

-- Class Methods
function Action_validate:handleStateTransition(job)
    self:log()
    local newState = Action.handleStateTransition(self, job)
    if newState then
        return newState
    end

    job:update()

    local task = job:get_current_task()
    if task then
        return job.status.start
    else
        return job.status.check_service
    end
end

return Action_validate
