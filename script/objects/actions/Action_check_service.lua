--local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Action = require("__Constructron-2__.script.objects.actions.Action")
--local Ctron = require("__Constructron-2__.script.objects.Ctron")

---@class Action_check_service : Action
local Action_check_service = {
    class_name = "Action_check_service"
}
Action_check_service.__index = Action_check_service

setmetatable(
    Action_check_service,
    {
        __index = Action, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)

-- Class Methods
function Action_check_service:handleStateTransition(job)
    self:log()
    local newState = Action.handleStateTransition(self, job)
    if newState then
        return newState
    end

    local required_items = job:get_items()
    local target_position = job:get_position()
    local constructron_position = job.constructron:get_position()
    if constructron_position and not target_position then
        target_position = constructron_position.position
    end
    local station = self.surfacemanager:get_station(required_items, target_position, constructron_position.position)
    if station then
        job:assign_station(station)
        return job.status.get_service
    else
        self:log("no station found with items for the current job")
        return job.status.failed
    end
end

return Action_check_service
