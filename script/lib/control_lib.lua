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
            -- min int is -9,223,372,036,854,775,808
            -- since we have no binary cast we just shift the digits
            --             x xxx xxx xyy yyy yyy ssS
            -- min map position -2000000
            -- not perfect, but if we collide, so be it...
            local surface_index = entity.surface.index
            local x = math.abs(entity.position.x or entity.position[0]) 
            local y = math.abs(entity.position.y or entity.position[1])
            local sign_x = x<0 and 1 or 0 
            local sign_y = y<0 and 2 or 0
            key = (x * 100000000000 + y * 1000 + surface_index*10 + sign_x + sign_y ) * -1
        end
        return key
    end
end

return me

