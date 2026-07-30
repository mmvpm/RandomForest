/// Writes one character into a decoded semantic row.
function __funSetGeneratedDecodedSymbol(rows, column, row, symbol) {
	var line = rows[row]
	line = string_delete(line, column + 1, 1)
	rows[@ row] = string_insert(symbol, line, column + 1)
}

/// Places one entity without allowing two map cells to share a runtime anchor.
function __funSetGeneratedDecodedEntity(rows, column, row, symbol) {
	if (row < 0 || row >= array_length(rows)) {
		show_error("Generated entity leaves the map: " + symbol, true)
	}
	if (string_char_at(rows[row], column + 1) != ".") {
		show_error("Generated entities share one runtime anchor.", true)
	}
	__funSetGeneratedDecodedSymbol(rows, column, row, symbol)
}

/// Decodes the editable map into the runtime semantic layers.
function funDecodeGeneratedLevelMap(level_data) {
	if (!variable_struct_exists(level_data, "map")) {
		show_error("Generated level has no map.", true)
	}
	if (array_length(level_data.map) != level_data.height) {
		show_error("Generated map has an invalid row count.", true)
	}

	var empty_row = string_repeat(".", level_data.width)
	var terrain = array_create(level_data.height, empty_row)
	var hazards = array_create(level_data.height, empty_row)
	var entities = array_create(level_data.height, empty_row)
	for (var row = 0; row < level_data.height; ++row) {
		var map_row = level_data.map[row]
		if (string_length(map_row) != level_data.width) {
			show_error("Generated map has an invalid row width.", true)
		}
		for (var column = 0; column < level_data.width; ++column) {
			var symbol = string_char_at(map_row, column + 1)
			if (symbol == ".") {
				continue
			}
			if (string_pos(symbol, "#X=") > 0) {
				__funSetGeneratedDecodedSymbol(terrain, column, row, symbol)
				continue
			}
			if (string_pos(symbol, "^v<>UDLR") > 0) {
				__funSetGeneratedDecodedSymbol(hazards, column, row, symbol)
				continue
			}
			if (string_pos(symbol, "@SsKkBbPp") > 0) {
				__funSetGeneratedDecodedEntity(entities, column, row + 1, symbol)
				continue
			}
			if (string_pos(symbol, "Oo*") > 0) {
				__funSetGeneratedDecodedEntity(entities, column, row, symbol)
				continue
			}
			show_error("Generated map contains an unsupported symbol: " + symbol, true)
		}
	}

	variable_struct_set(level_data, "terrain", terrain)
	variable_struct_set(level_data, "hazards", hazards)
	variable_struct_set(level_data, "entities", entities)
	return level_data
}
