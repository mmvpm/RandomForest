/// Counts one entity symbol in the authored entity layer.
function __funCountGeneratedEntity(level_data, symbol) {
	var found = 0
	for (var row = 0; row < level_data.height; ++row) {
		var line = level_data.entities[row]
		for (var column = 0; column < level_data.width; ++column) {
			found += string_char_at(line, column + 1) == symbol
		}
	}
	return found
}

/// Performs the intentionally minimal validation required by singleton gameplay code.
function funValidateGeneratedLevel(level_data) {
	var players = __funCountGeneratedEntity(level_data, "@")
	if (players != 1) {
		return {
			is_valid: false,
			error: "Generated level must contain exactly one player (@)."
		}
	}

	var doors = __funCountGeneratedEntity(level_data, "O")
	doors += __funCountGeneratedEntity(level_data, "o")
	if (doors != 1) {
		return {
			is_valid: false,
			error: "Generated level must contain exactly one door (O or o)."
		}
	}

	if (
		!variable_struct_exists(level_data, "star_times")
		or !variable_struct_exists(level_data.star_times, "three_stars")
		or !variable_struct_exists(level_data.star_times, "two_stars")
	) {
		return {
			is_valid: false,
			error: "Generated level must contain star_times."
		}
	}

	return { is_valid: true, error: "" }
}
