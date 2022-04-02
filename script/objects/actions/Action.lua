--local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Debug = require("__Constructron-2__.script.objects.Debug")
local Ctron = require("__Constructron-2__.script.objects.Ctron")

-- class Type Action, nil members exist just to describe fields
local Action = {
    class_name = "Action"
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
    -- state transitions that do not depend on input state happen here.
    if job.constructron and job.constructron:is_valid() then
        job.constructron:status_update()
        if job.constructron:get_status_id() == Ctron.status.no_power then
            --Out-Of-Power --> Paused
            return job.status.paused
        elseif job.constructron:get_status_id() == Ctron.status.no_fuel then
            -- Fuel-Empty --> Failed
            return job.status.failed
        elseif job.constructron:get_status_id() == Ctron.status.error then
            -- Stuck/Timeout --> Failed
            return job.status.failed
        elseif job.constructron:get_health_ratio() < 0.75 then
            -- <75 % HP        --> Failed
            return job.status.failed
        end
    else
        --Ctron is Invalid --> Job Failed
        return job.status.failed
    end
end

return Action
