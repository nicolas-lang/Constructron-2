local speed_sticker = {
    type = "sticker",
    name = "speed-sticker",
    flags = {"not-on-map"},
    animation = util.empty_sprite(),
    duration_in_ticks = 30,
    vehicle_speed_modifier = 0.25,
    --target_movement_modifier = 1,
    --vehicle_friction_modifier = 1,
}
return {speed_sticker}