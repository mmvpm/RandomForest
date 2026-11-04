/// Applies the saved forest-sound toggle, retaining the existing settings UI and save key.
function funApplyMusicSetting(fade_ms = 0) {
	if (!global.music_enabled) with (oWeatherAudio) funWeatherAudioStop()
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
	for (var i = 0; i < array_length(sfx_assets); ++i) {
		audio_sound_gain(sfx_assets[i], gain, fade_ms)
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
