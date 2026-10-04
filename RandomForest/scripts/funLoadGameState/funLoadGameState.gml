/// Loads persistent progress and audio preferences for the current level catalog.
function funLoadGameState() {
	ini_open("save.ini")

	// debug mode
	global.is_debug = ini_read_real("general", "is_debug", 0) // default: false

	// fullscreen mode
	global.is_fullscreen = ini_read_real("general", "is_fullscreen", 0) // default: false

	// Load one record array for the full ordered level sequence.
	var levels_count = funGetLevelsCount()
	global.time_records = array_create(levels_count, -1)
	for (var i = 0; i < levels_count; ++i) {
		var str_i = string(i)
		if (i < 10) {
			str_i = "0" + str_i
		}
		global.time_records[i] = ini_read_real("time_records", "level" + str_i, -1)
	}

	// Load persistent mastery goals and orange-firefly progress for every level.
	global.enemy_clear_records = array_create(levels_count, false)
	global.flawless_records = array_create(levels_count, false)
	global.orange_firefly_records = array_create(levels_count, false)
	for (var achievement_index = 0; achievement_index < levels_count; ++achievement_index) {
		var achievement_key = string(achievement_index)
		if (achievement_index < 10) {
			achievement_key = "0" + achievement_key
		}
		global.enemy_clear_records[achievement_index] = (
			ini_read_real(
				"enemy_clear_records",
				"level" + achievement_key,
				0
			) != 0
		)
		global.flawless_records[achievement_index] = (
			ini_read_real(
				"flawless_records",
				"level" + achievement_key,
				0
			) != 0
		)
		global.orange_firefly_records[achievement_index] = (
			ini_read_real(
				"orange_firefly_records",
				"level" + achievement_key,
				0
			) != 0
		)
	}

	// current_level is the furthest unlocked absolute level index.
	global.current_level = clamp(
		floor(ini_read_real("general", "current_level", 0)),
		0,
		levels_count - 1
	)
	// Completing a former final level unlocks one newly appended catalog level.
	if (
		global.current_level < levels_count - 1
		and global.time_records[global.current_level] != -1
	) {
		++global.current_level
	}
	global.playing_level = global.current_level
	global.playing_level_star_times = undefined

	// is training completed
	global.is_training_completed = ini_read_real("general", "is_training_completed", 0) // false by default

	// A saved victory becomes stale when new levels are appended.
	global.campaign_intro_seen = ini_read_real("general", "campaign_intro_seen", 0) != 0
	global.special_level_completed = ini_read_real("general", "special_level_completed", 0) != 0
	global.is_game_finished = (
		ini_read_real("general", "is_game_finished", 0)
		and (funLevelTracksProgress(levels_count - 1)
			? global.time_records[levels_count - 1] != -1 : global.special_level_completed)
	)

	// "hit is stronger than tap-attack" shown or not
	global.hit_vs_tap_text_shown = ini_read_real("general", "hit_vs_tap_text_shown", 0) // 0 by default

	// Main-menu audio settings.
	global.music_enabled = ini_read_real("general", "music_enabled", 1) != 0
	global.sfx_enabled = ini_read_real("general", "sfx_enabled", 1) != 0

	// Visits are keyed by stable scene IDs, independently of level records.
	global.black_room_seen = {}
	var scenes = global.black_room_config.scenes
	for (var scene_index = 0; scene_index < array_length(scenes); ++scene_index) {
		var scene_id = scenes[scene_index].id
		variable_struct_set(global.black_room_seen, scene_id,
			ini_read_real("black_room_seen", scene_id, 0) != 0)
	}

	ini_close()

	// Completion UI uses these runtime-only values.
	global.last_completion_result = undefined
	global.pending_completed_page = -1
}
