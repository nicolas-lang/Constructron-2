-- Service Station
local service_station = require("__Constructron-2__.data.service-station.service-station")
data:extend(service_station)

-- Generic Ctron stuff
local pathing_proxy = require("__Constructron-2__.data.ctron-base.pathing-proxy")
data:extend(pathing_proxy)

local base_categories = require("__Constructron-2__.data.ctron-base.categories")
data:extend(base_categories)

-- Classic Constructron
local ctron_classic = require("__Constructron-2__.data.ctron-classic.ctron")
if true then
    data:extend(ctron_classic)
end

-- Steam powered Ctron
local ctron_steam_powered = require("__Constructron-2__.data.ctron-steam-powered.ctron")
local ctron_steam_powered_equipment = require("__Constructron-2__.data.ctron-steam-powered.equipment")
if true then
    data:extend(ctron_steam_powered)
    data:extend(ctron_steam_powered_equipment)
end

-- Solar powered Ctron
local ctron_solar_powered = require("__Constructron-2__.data.ctron-solar-powered.ctron")
local ctron_solar_powered_equipment = require("__Constructron-2__.data.ctron-solar-powered.equipment")
if true then
    data:extend(ctron_solar_powered)
    data:extend(ctron_solar_powered_equipment)
end

-- Nuclear powered Ctron
local ctron_nuclear_powered = require("__Constructron-2__.data.ctron-nuclear-powered.ctron")
local ctron_nuclear_powered_equipment = require("__Constructron-2__.data.ctron-nuclear-powered.equipment")
if true then
    data:extend(ctron_nuclear_powered)
    data:extend(ctron_nuclear_powered_equipment)
end

-- Ctron Buffer chest
local ctron_buffer_chest = require("__Constructron-2__.data.ctron-buffer-chest.buffer-chest")
if true then
    data:extend(ctron_buffer_chest)
end

if true then
    local tech = require("__Constructron-2__.data.technology.tech")
    data:extend(tech)
end
