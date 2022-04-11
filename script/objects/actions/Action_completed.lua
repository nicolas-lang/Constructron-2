local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Action = require("__Constructron-2__.script.objects.actions.Action")
--local Ctron = require("__Constructron-2__.script.objects.Ctron")
local Task_construction = require("__Constructron-2__.script.objects.Task-construction")
local Task_delivery = require("__Constructron-2__.script.objects.Task-delivery")

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
---comment
---@param job Job
function Action_completed:handleStateTransition(job)
    self:log()
    -- Re-Queue them if required
    for _, task in pairs(job.tasks) do
        -- re-queue remaining entities
        local new_task
        if task.class_name == "task_construction" then
            new_task = Task_construction()
        elseif task.class_name == "task_delivery" then
            new_task = Task_delivery()
        end

        for k, entity in pairs(task.entities) do
            local items = task:get_required_items(entity)
            if entity.valid then
                self:log(entity.name .. " " .. serpent.block(items))
            else
                self:log("entity invalid " .. serpent.block(items))
            end
            if items and custom_lib.table_length(items) > 0 then
                new_task:add_entity(entity)
            end
        end
        new_task:update()
        local items = new_task:get_items()
        self:log(serpent.block(items))
        self:log(serpent.block(new_task))
        if items then
            game.print("re-queued unfinished task")
            self.surfacemanager:add_task(new_task)
        else
            game.print("task requires no items --> completed")
            new_task:destroy()
        end
        task:destroy()
    end
    job.tasks = {}
    -- final state
    --> job needs to be destroyed by parent
end

return Action_completed
