#macro BLACK_ROOM_CONFIG_PATH "narrative/black_room.json"

/// Loads the bundled scene registry once, before save data is read.
function funLoadBlackRoomConfig() {
	global.black_room_config = json_parse(funReadGeneratedLevelFile(BLACK_ROOM_CONFIG_PATH))
	global.black_room_context = undefined
}

/// Returns a scene setting or its shared default.
function funBlackRoomSetting(scene, setting_name) {
	if (variable_struct_exists(scene, setting_name)) {
		return variable_struct_get(scene, setting_name)
	}
	return variable_struct_get(global.black_room_config.defaults, setting_name)
}

/// Finds an enabled, unseen scene after the completed absolute level index.
function funFindBlackRoomScene(level_index) {
	var scenes = global.black_room_config.scenes
	for (var i = 0; i < array_length(scenes); ++i) {
		var scene = scenes[i]
		if (scene.enabled and scene.after_level == level_index + 1
			and !variable_struct_get(global.black_room_seen, scene.id)) {
			return scene
		}
	}
	return undefined
}

/// Clears story visits when the campaign, rather than its records, is reset.
function funResetBlackRoomScenes() {
	global.black_room_seen = {}
	var scenes = global.black_room_config.scenes
	for (var i = 0; i < array_length(scenes); ++i) {
		variable_struct_set(global.black_room_seen, scenes[i].id, false)
	}
	global.black_room_context = undefined
}
