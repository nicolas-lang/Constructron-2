local me = {}

me.distance_between = function(position1, position2)
    return math.sqrt((position1.x - position2.x) ^ 2 + (position1.y - position2.y) ^ 2)
end

me.get_stack_size = function (item_name)
    return game.item_prototypes[item_name].stack_size
end

return me
