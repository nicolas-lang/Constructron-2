local Task = require("__Constructron-2__.script.objects.Task")

---@class Task_construction : Task
local Task_construction = {
    class_name = "task_construction"
}
Task_construction.__index = Task_construction

setmetatable(
    Task_construction,
    {
        __index = Task, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)

return Task_construction
