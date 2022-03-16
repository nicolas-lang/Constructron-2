-- Generic Ctron stuff
local base_categories = require("__Constructron-2__.data.ctron-base.categories")
data:extend(base_categories)

-- Classic Constructron
local ctron_classic = require("__Constructron-2__.data.ctron-classic.ctron")
if true then
    data:extend(ctron_classic)
end

-- automatic simple tech unlock based on existing entities
require("__Constructron-2__.data.technology.tech")
