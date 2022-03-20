local Task = require("__Constructron-2__.script.objects.Task")

-- class Type Task_construction, nil members exist just to describe fields
local Task_construction = {
    class_name = "Task_construction"
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

-- Task_construction Constructor
function Task_construction:new(obj)
    self:log()
    Task.new(self, obj)
end

return Task_construction
