local util = require("util")
--  service_station images derived from:
--    https://github.com/nEbul4/Factorio_Roboport_mk2/
--    https://github.com/kirazy/classic-beacon/

local service_station_entity = table.deepcopy(data.raw["roboport"]["roboport"])
service_station_entity.name = "service-station"
service_station_entity.minable = {
    hardness = 0.2,
    mining_time = 0.5,
    result = "service-station"
}
service_station_entity.logistics_radius = 10
service_station_entity.construction_radius = 0

for _, layer in pairs(service_station_entity.base.layers) do
    if layer.filename == "__base__/graphics/entity/roboport/roboport-base.png" then
        layer.filename = "__Constructron-2__/graphics/service-station/constructotron-service-station.png"
        layer.width = 114
        layer.height = 139
        layer.shift = layer.hr_version.shift
        layer.hr_version.filename = "__Constructron-2__/graphics/service-station/hr-constructotron-service-station.png"
    end
end

-- Beacon Antenna
local shft_1 = util.by_pixel(-1, -55)
local shft_2 = util.by_pixel(100.5, 15.5)
service_station_entity.base_animation = {
    layers = {
        -- Base
        {
            filename = "__Constructron-2__/graphics/service-station/antenna.png",
            width = 54,
            height = 50,
            line_length = 8,
            frame_count = 32,
            animation_speed = 0.5,
            shift = {shft_1[1] - 0.5, shft_1[2] - 0.5}
        }, -- Shadow
        {
            filename = "__Constructron-2__/graphics/service-station/antenna-shadow.png",
            width = 63,
            height = 49,
            line_length = 8,
            frame_count = 32,
            animation_speed = 0.5,
            shift = {shft_2[1] - 0.5, shft_2[2] - 0.5},
            draw_as_shadow = true
        }
    }
}

local service_station_item = {
    icons = {
        {
            icon = "__base__/graphics/icons/roboport.png",
            icon_size = 64,
            icon_mipmaps = 4,
            scale = 1
        },
        {
            icon = "__base__/graphics/icons/spidertron.png",
            icon_size = 64,
            icon_mipmaps = 4,
            scale = 0.6,
            shift = {-20, 20}
        }
    },
    name = "service-station",
    order = "c[signal]-a[roboport]b",
    place_result = "service-station",
    stack_size = 5,
    subgroup = "logistic-network",
    type = "item"
}

local service_station_recipe = {
    type = "recipe",
    name = "service-station",
    enabled = false,
    ingredients = {
        {"roboport", 1},
        {"steel-plate", 25},
        {"iron-gear-wheel", 45},
        {"advanced-circuit", 45}
    },
    result = "service-station",
    result_count = 1,
    energy = 1
}

local service_station = {
    service_station_entity,
    service_station_item,
    service_station_recipe
}

return service_station
