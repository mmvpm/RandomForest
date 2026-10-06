/// Applies the saved music setting to every music resource.
function funApplyMusicSetting(fade_ms = 0) {
	var gain = global.music_enabled ? 1 : 0
	var music_assets = [
		musicMenu,
		musicGame,
		musicVictory,
		musicVictoryMem,
	]
	// Future story tracks follow the same saved music toggle as existing music.
	var scenes = global.black_room_config.scenes
	for (var scene_index = 0; scene_index < array_length(scenes); ++scene_index) {
		var track = funBlackRoomSetting(scenes[scene_index], "music")
		if (track != undefined) {
			var sound = asset_get_index(track)
			if (sound != -1) {
				array_push(music_assets, sound)
			}
		}
	}
	for (var i = 0; i < array_length(music_assets); ++i) {
		audio_sound_gain(music_assets[i], gain, fade_ms)
	}
}

/// Applies the saved effects setting to every non-music sound resource.
function funApplySfxSetting(fade_ms = 0) {
	var gain = global.sfx_enabled ? 1 : 0
	var sfx_assets = [
		soundTapSwordReturn,
		soundPlayerLanding,
		soundPlayerStompImpact,
		soundWallMemoryReveal,
		soundMenuButton,
		soundOrangeFirefly,
		soundStarCollecting,
		soundPlayerHeartBeating,
		soundBungaloSteps,
		soundPlayerAttack2,
		soundSkeletonAttack,
		soundSlimeAttack,
		soundPlayerTeleport,
		soundCoinCollecting,
		soundBungaloAttack,
		soundPlayerAttack1,
		soundTapSwordLanding,
		soundPlayerTapAttack,
		soundPlayerAttack3,
		soundPlayerStep,
	]
	for (var i = 0; i < array_length(sfx_assets); ++i) {
		audio_sound_gain(sfx_assets[i], gain, fade_ms)
	}
}

/// Applies both saved audio settings.
function funApplyAudioSettings(fade_ms = 0) {
	funApplyMusicSetting(fade_ms)
	funApplySfxSetting(fade_ms)
}

/// Changes and immediately saves the music setting.
function funSetMusicEnabled(enabled) {
	global.music_enabled = enabled
	funApplyMusicSetting(200)
	funSaveGameState()
}

/// Changes and immediately saves the effects setting.
function funSetSfxEnabled(enabled) {
	global.sfx_enabled = enabled
	funApplySfxSetting(0)
	funSaveGameState()
}
