local Ctron = require("__Constructron-2__.script.objects.Ctron")


---@class Ctron_classic : Ctron
local Ctron_classic = {
    class_name = "Ctron_classic",
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

function Ctron_classic:new(entity)
    log("Ctron_steam_powered.new")
    Ctron.new(self, entity)
end

-- Class Methods
function Ctron_classic:setup_gear() -- luacheck: ignore
    -- we do not want to use a gear template
end

return Ctron_classic
