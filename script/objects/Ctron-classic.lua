local Ctron = require("__Constructron-2__.script.objects.Ctron")

---@class Ctron_classic : Ctron
local Ctron_classic = {
    class_name = "Ctron_classic"
}
Ctron_classic.__index = Ctron_classic

setmetatable(
    Ctron_classic,
    {
        __index = Ctron, -- this is what makes the inheritance work
        __call = function(cls, ...)
            local self = setmetatable({}, cls)
            self:new(...)
            return self
        end
    }
)

--- setup_gear() is shadowed for `Ctron_classic` because  we do not want to use a gear template
function Ctron_classic:setup_gear()
    self:log()
end

return Ctron_classic
