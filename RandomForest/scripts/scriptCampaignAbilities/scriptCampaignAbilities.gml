/// Combines saved scene rewards and the current room's temporary reward.
function funCampaignAbilities() {
	var result = variable_clone(global.campaign_abilities_config.base)
	var scenes = global.black_room_config.scenes
	for (var i = 0; i < array_length(scenes); ++i) {
		var scene = scenes[i]
		var saved = variable_struct_get(global.black_room_seen, scene.id)
		var staged = global.black_room_context != undefined
			and global.black_room_context.reward_staged
			and global.black_room_context.scene.id == scene.id
		if (!saved and !staged) continue
		var names = variable_struct_get_names(scene.reward)
		for (var j = 0; j < array_length(names); ++j) {
			var name = names[j]
			var value = variable_struct_get(scene.reward, name)
			// Rewards are milestones, so replay order can never reduce a perk.
			variable_struct_set(result, name, max(variable_struct_get(result, name), value))
		}
	}
	return result
}

/// Selects the campaign skin, with an explicit override during story changes.
function funCampaignPlayerIsDark() {
	if (global.black_room_context != undefined) {
		return global.black_room_context.current_dark
	}
	var abilities = funCampaignAbilities()
	var range = global.campaign_abilities_config.dark_levels
	return abilities.dark_skin and global.playing_level + 1 >= range[0]
		and global.playing_level + 1 <= range[1]
}
