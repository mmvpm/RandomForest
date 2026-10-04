/// Opens either the pending story room or the normal completion overlay.
function funShowCompletedLevel() {
	var scene = funFindBlackRoomScene(global.playing_level)
	if (scene == undefined) {
		instance_create_layer(0, 0, "UI", oLevelPassing)
		return
	}
	global.black_room_context = {
		scene: scene,
		progress: funBlackRoomProgress(scene.after_level),
		health: oPlayer.health,
		max_health: oPlayer.max_health,
	}
	room_goto(rBlackRoom)
}

/// Saves a visit only once the player has actually left through the portal.
function funFinishBlackRoomScene() {
	var scene = global.black_room_context.scene
	variable_struct_set(global.black_room_seen, scene.id, true)
	funSaveGameState()
	funStopBlackRoomMusic()
	if (!audio_is_playing(musicGame)) {
		audio_play_sound(musicGame, 0, true)
	}
	instance_create_layer(0, 0, "UI", oLevelPassing)
}

/// Replays the completed gameplay level even when its results are in the story room.
function funRestartPlayingLevel() {
	funOpenLevel(global.playing_level)
}

/// Stops an optional story track without changing saved volume preferences.
function funStopBlackRoomMusic() {
	if (global.black_room_context == undefined) {
		return
	}
	var track = funBlackRoomSetting(global.black_room_context.scene, "music")
	if (track != undefined) {
		var sound = asset_get_index(track)
		if (sound != -1) {
			audio_stop_sound(sound)
		}
	}
}
