local util = require("util")
local speed_sticker = {
    type = "sticker",
    name = "ctron-speed-sticker",
    flags = {"not-on-map"},
    animation = util.empty_sprite(),
    duration_in_ticks = 30,
    vehicle_speed_modifier = 0.2
}
return {speed_sticker}
