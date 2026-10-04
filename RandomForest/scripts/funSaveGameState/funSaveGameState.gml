/// Saves persistent progress and audio preferences.
function funSaveGameState() {
	ini_open("save.ini")

	// debug mode
	if (global.is_debug != undefined) {
		ini_write_real("general", "is_debug", global.is_debug)
	}

	// fullscreen mode
	if (global.is_fullscreen != undefined) {
		ini_write_real("general", "is_fullscreen", global.is_fullscreen)
	}

	// current level number
	if (global.current_level != undefined) {
		ini_write_real("general", "current_level", global.current_level)
	}

	// training completed
	if (global.is_training_completed != undefined) {
		ini_write_real("general", "is_training_completed", global.is_training_completed)
	}

	// is game finished
	if (global.is_game_finished != undefined) {
		ini_write_real("general", "is_game_finished", global.is_game_finished)
	}

	// "hit is stronger than tap-attack" shown or not
	if (global.hit_vs_tap_text_shown != undefined) {
		ini_write_real("general", "hit_vs_tap_text_shown", global.hit_vs_tap_text_shown)
	}

	// audio settings
	if (global.music_enabled != undefined) {
		ini_write_real("general", "music_enabled", global.music_enabled)
	}
	if (global.sfx_enabled != undefined) {
		ini_write_real("general", "sfx_enabled", global.sfx_enabled)
	}

	// save time records
	if (global.time_records != undefined) {
		var levels_count = array_length(global.time_records)
		for (var i = 0; i < levels_count; ++i) {
			var str_i = string(i)
			if (i < 10) {
				str_i = "0" + str_i
			}

			ini_write_real("time_records", "level" + str_i, global.time_records[i])
		}
	}

	// save enemy-clear achievements
	if (global.enemy_clear_records != undefined) {
		var enemy_levels_count = array_length(global.enemy_clear_records)
		for (var enemy_index = 0; enemy_index < enemy_levels_count; ++enemy_index) {
			var enemy_key = string(enemy_index)
			if (enemy_index < 10) {
				enemy_key = "0" + enemy_key
			}
			ini_write_real(
				"enemy_clear_records",
				"level" + enemy_key,
				global.enemy_clear_records[enemy_index]
			)
		}
	}

	// save flawless achievements
	if (global.flawless_records != undefined) {
		var flawless_levels_count = array_length(global.flawless_records)
		for (
			var flawless_index = 0;
			flawless_index < flawless_levels_count;
			++flawless_index
		) {
			var flawless_key = string(flawless_index)
			if (flawless_index < 10) {
				flawless_key = "0" + flawless_key
			}
			ini_write_real(
				"flawless_records",
				"level" + flawless_key,
				global.flawless_records[flawless_index]
			)
		}
	}

	// Save orange-firefly progress independently from level completion.
	if (global.orange_firefly_records != undefined) {
		var orange_levels_count = array_length(global.orange_firefly_records)
		for (var orange_index = 0; orange_index < orange_levels_count; ++orange_index) {
			var orange_key = string(orange_index)
			if (orange_index < 10) {
				orange_key = "0" + orange_key
			}
			ini_write_real(
				"orange_firefly_records",
				"level" + orange_key,
				global.orange_firefly_records[orange_index]
			)
		}
	}

	// Finishing a conversation alone does not count as a completed visit.
	var scenes = global.black_room_config.scenes
	for (var scene_index = 0; scene_index < array_length(scenes); ++scene_index) {
		var scene_id = scenes[scene_index].id
		ini_write_real("black_room_seen", scene_id,
			variable_struct_get(global.black_room_seen, scene_id))
	}

	ini_close()
}
