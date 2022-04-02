--local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Action = require("__Constructron-2__.script.objects.actions.Action")
--local Ctron = require("__Constructron-2__.script.objects.Ctron")

-- class Type Action_start, nil members exist just to describe fields
local Action_start = {
    class_name = "Action_start"
}
Action_start.__index = Action_start

setmetatable(
    Action_start,
    {
        __index = Action, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)
-- Action_start Constructor
function Action_start:new(surfacemanager)
    self:log()
    Action.new(self, surfacemanager)
end

-- Class Methods
function Action_start:handleStateTransition(job)
    self:log()
    local newState = Action.handleStateTransition(self, job)
    if newState then
        return newState
    end
    local job_items = job:get_items()
    local task = job:get_current_task()

    if task then
        local inventory_stats = job.constructron:get_main_inventory_stats()
        log(serpent.block(inventory_stats))
        if inventory_stats and inventory_stats.free > 0 then
            local task_items = task:get_items()
            local inventory = job.constructron:get_inventory("spider_trunk")
            log("inventory" .. serpent.block(inventory))
            for item, count in pairs(task_items) do
                log(item .. "?:" .. count)
                --if it is required for construction we want at least 1
                --if it is a decon result 0 is fine
                -- add some kind of check to ensure at least 1 service station visit
                if (count <= 0) or (inventory[item] and inventory[item] > 0) then
                    log(item .. "!:" .. (inventory[item] or "-"))
                    return job.status.do_task
                end
            end
            log("no items for current task")
            for item, count in pairs(job_items) do
                -- add some kind of check to ensure at least 1 service station visit
                -- if it is a mixed decon/cst job cst will not get items in first loop
                if  (count <= 0) or (inventory[item] and inventory[item] > 0) then
                    log("try next task")
                    job:next_task(false)
                    return nil
                end
            end
            log("no items for any task")
        end
        -- no items for any task or inv full
        job:update()
        return job.status.check_service
    end
end

return Action_start
