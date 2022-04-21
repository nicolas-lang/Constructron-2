local Task = require("__Constructron-2__.script.objects.Task")

---@class Task_delivery : Task
local Task_delivery = {
    class_name = "Task_delivery"
}
Task_delivery.__index = Task_delivery

setmetatable(
    Task_delivery,
    {
        __index = Task, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)

return Task_delivery
