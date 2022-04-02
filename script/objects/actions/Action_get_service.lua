--local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Action = require("__Constructron-2__.script.objects.actions.Action")
local Ctron = require("__Constructron-2__.script.objects.Ctron")

-- class Type Action_get_service, nil members exist just to describe fields
local Action_get_service = {
    class_name = "Action_get_service"
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
    Action.new(self, surfacemanager)
end

-- Class Methods
function Action_get_service:handleStateTransition(job)
    self:log()
    local newState = Action.handleStateTransition(self, job)
    if newState then
        return newState
    end

    if job.constructron:get_status_id() == Ctron.status.pathfinding_failed then
        return job.status.failed
    end

    if not job.station or job.station:is_valid() ~= true then
        log("no station or station invalid")
        return job.status.check_service
    end
    log(job.constructron:get_status_name())
    if job.constructron:get_status_id() == Ctron.status.idle then
        local station_position = job.station:get_position()
        if job.constructron:distance_to(station_position.position) < 5 then
            local required_items = job:get_items()
            log("required_items: " .. serpent.block(required_items))
            local updated = job.constructron:set_request_items(required_items)
            if updated then
                return
            end
            -- near station
            if not job:get_current_task() then
                self:log("job has no task to do")
                return job.status.completed
            end
            job:unassign_station()
            return job.status.start
        else
            job.constructron:go_to(station_position.position)
        end
    end
end

return Action_get_service
