local me = {}
-------------------------------------------------------------------------------------
--Enable Recipes if tech researched
-------------------------------------------------------------------------------------
---Re-Unlock all the recipes for a given tech
---@param technology_name string
function me.reload_tech(technology_name)
	log("reload_tech_unlock")
	for _, force in pairs(game.forces) do
		local unlock_state = false
		if force.technologies[technology_name].researched then
			unlock_state = true
		end
		for _, effect in pairs(force.technologies[technology_name].effects) do
			if effect.type == "unlock-recipe" then
				force.recipes[effect.recipe].enabled = unlock_state
				log(effect.recipe .. " enabled: " .. tostring(unlock_state))
			end
		end
	end
end
-------------------------------------------------------------------------------------

return me
