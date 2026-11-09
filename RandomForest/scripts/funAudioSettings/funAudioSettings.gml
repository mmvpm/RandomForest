/// Applies the saved forest-sound toggle, retaining the existing settings UI and save key.
function funApplyMusicSetting(fade_ms = 0) {
	if (!global.music_enabled) with (oWeatherAudio) funWeatherAudioStop()
}

/// Lists action and UI resources independently of streamed background audio.
function funSfxAssets() {
	return [
		soundTapSwordReturn,
		soundPlayerLanding,
		soundPlayerStompImpact,
		soundWallMemoryReveal,
		soundMenuButton,
		soundDialogueTyping,
		soundStartupIntro,
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
		soundResinSlimeLand,
		soundResinSlimeAttack,
		soundBarkBomberBurst,
		soundForestBatAttack,
		soundForestBatWake,
		soundBarkGuardShot,
		soundBarkGuardImpact,
		soundRootReaperSweep,
		soundRootReaperSlam,
		soundRootMawBite,
	]
}

/// Stops lingering actions without interrupting nature or the black-room background.
function funStopGameplaySounds() {
	var assets = funSfxAssets()
	for (var i = 0; i < array_length(assets); ++i) audio_stop_sound(assets[i])
}

/// Mutes effects while retaining the authored, source-aware balance of every resource.
function funApplySfxSetting(fade_ms = 0) {
	var gain = global.sfx_enabled ? 1 : 0
	var sfx_assets = funSfxAssets()
	// Capture once, before the first mute; reading muted assets would lose their mix.
	if (!variable_global_exists("sfx_base_gains")) {
		global.sfx_base_gains = array_create(array_length(sfx_assets))
		for (var i = 0; i < array_length(sfx_assets); ++i) {
			global.sfx_base_gains[i] = audio_sound_get_gain(sfx_assets[i])
		}
	}
	for (var i = 0; i < array_length(sfx_assets); ++i) {
		audio_sound_gain(sfx_assets[i], global.sfx_base_gains[i] * gain, fade_ms)
	}
}

/// Applies both saved audio settings.
function funApplyAudioSettings(fade_ms = 0) {
	funApplyMusicSetting(fade_ms)
	funApplySfxSetting(fade_ms)
}

/// Changes and immediately saves the forest-sound setting.
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
