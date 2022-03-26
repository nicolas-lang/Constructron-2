local me = {}

me.distance_between = function(position1, position2)
    return math.sqrt((position1.x - position2.x) ^ 2 + (position1.y - position2.y) ^ 2)
end

me.get_stack_size = function(item_name)
    return game.item_prototypes[item_name].stack_size
end

me.get_entity_key = function(entity)
    if entity and entity.valid then
        local key = entity.unit_number
        if not key then
            -- i would have prefered to get the bit representations of the float values and just do a bitshift... I hate lua...
            -- min int is -9,223,372,036,854,775,808
            -- since we have no binary cast we just shift the digits
            --             Sssx xxx xxx xyy yyy yyy
            -- min map position -2000000
            -- not perfect, but if we collide, so be it...
            -- should only affect tree's & tiles anyways
            local surface_index = entity.surface.index
            local x = entity.position.x or entity.position[0]
            local y = entity.position.y or entity.position[1]
            if math.abs(x - math.floor(x)) > 0.001 then
                x = math.floor(x * 1000)
            else
                x = math.floor(x)
            end
            if math.abs(y - math.floor(y)) > 0.001 then
                y = math.floor(y * 1000)
            else
                y = math.floor(y)
            end
            local sign_x = x < 0 and 1 or 0
            local sign_y = y < 0 and 2 or 0
            key = (sign_x + sign_y) * 1000000000000000
            key = key + surface_index * 10000000000000
            key = key + math.abs(x) * 100000000
            key = key + math.abs(y)
            key = key * -1
        end
        return key
    end
end

return me
