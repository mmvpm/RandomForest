/// Opens either the pending story room or the normal completion overlay.
function funShowCompletedLevel() {
	if (!funLevelTracksProgress(global.playing_level) and global.ending_stage != 2) {
		funOpenStoryEnding()
		return;
	}
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
		reward_staged: false,
		current_dark: funCampaignPlayerIsDark(),
	}
	room_goto(rBlackRoom)
}

/// Commits the story visit, then reveals its preserved results from black.
function funFinishBlackRoomScene() {
	var scene = global.black_room_context.scene
	variable_struct_set(global.black_room_seen, scene.id, true)
	funSaveGameState()
	var results = instance_create_layer(0, 0, "UI", oLevelPassing)
	// The entry fade reveals the full layout; rewards animate after it finishes.
	results.alpha_animation_counter = 0
	results.border_animation_counter = 0
	var fade = instance_create_depth(0, 0, -10, oFadeIn)
	fade.alpha_step = 1 / (60 * funBlackRoomSetting(scene, "fade_seconds"))
}

/// Replays the completed gameplay level even when its results are in the story room.
function funRestartPlayingLevel() {
	funRestartCurrentRun()
}
