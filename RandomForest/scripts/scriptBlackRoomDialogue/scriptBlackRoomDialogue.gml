/// Captures progress once so a conversation never changes its branch midway.
function funBlackRoomProgress(after_level) {
	var records = array_create(array_length(global.orange_firefly_records), false)
	array_copy(records, 0, global.orange_firefly_records, 0, array_length(records))
	return {
		after_level: after_level,
		collected: funGetOrangeFireflyCount(),
		records: records,
	}
}

/// Checks one authored condition against the entry progress snapshot.
function funBlackRoomConditionMatches(condition, progress) {
	if (variable_struct_exists(condition, "min_collected")
		and progress.collected < condition.min_collected) {
		return false
	}
	if (variable_struct_exists(condition, "max_collected")
		and progress.collected > condition.max_collected) {
		return false
	}
	if (variable_struct_exists(condition, "collected_below_level_ratio")
		and progress.collected >= progress.after_level * condition.collected_below_level_ratio) {
		return false
	}
	if (variable_struct_exists(condition, "all_in_range")) {
		var range = condition.all_in_range
		for (var level_number = range[0]; level_number <= range[1]; ++level_number) {
			var level_index = level_number - 1
			if (level_index >= array_length(progress.records)
				or !progress.records[level_index]) {
				return false
			}
		}
	}
	return true
}

/// Combines opening, the first matching variant, and closing into one monologue.
function funLoadBlackRoomLines(scene, progress) {
	var dialogue = json_parse(funReadGeneratedLevelFile(scene.dialogue))
	var lines = []
	for (var i = 0; i < array_length(dialogue.opening); ++i) {
		array_push(lines, dialogue.opening[i])
	}
	for (var v = 0; v < array_length(dialogue.variants); ++v) {
		var variant = dialogue.variants[v]
		if (!funBlackRoomConditionMatches(variant.when, progress)) {
			continue
		}
		for (var j = 0; j < array_length(variant.lines); ++j) {
			array_push(lines, variant.lines[j])
		}
		break
	}
	for (var k = 0; k < array_length(dialogue.closing); ++k) {
		array_push(lines, dialogue.closing[k])
	}
	return lines
}
