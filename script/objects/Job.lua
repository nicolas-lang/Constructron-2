local custom_lib = require("__Constructron-2__.data.lib.custom_lib")
local Debug = require("__Constructron-2__.script.objects.Debug")

-- class Type Job, nil members exist just to describe fields
local Job = {
    class_name = "Job",
    area = nil,
    position = nil
}
Job.__index = Job

setmetatable(
    Job,
    {
        __index = Debug, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)
-- Job Constructor
function Job:new(obj)
    Debug.new(self)
    self:log()
    for k, v in pairs(obj or {}) do
        self[k] = v
    end
    global.Jobs = global.Jobs or {}
    self.id = self.id or #(global.Jobs) + 1
    global.Jobs[self.id] = self
    self.entities = {}
    self:log("id " .. self.id)
end

-- Generic Type based initialization
function Job.init_globals()
    global.Jobs = global.Jobs or {}
end

-- Class Methods
function Job:destroy()
    self:log()
    global.Jobs[self.id] = nil
end


return Job
