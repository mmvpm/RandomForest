/// Creates a two-dimensional array filled with one value.
function __funGeneratedGrid(width, height, value) {
	var grid = array_create(height)
	for (var row = 0; row < height; ++row) {
		grid[row] = array_create(width, value)
	}
	return grid
}

/// Returns a symbol from a map or the supplied outside value.
function __funGeneratedSymbol(lines, width, height, column, row, outside) {
	if (column < 0 || column >= width || row < 0 || row >= height) {
		return outside
	}
	return string_char_at(lines[row], column + 1)
}

/// Produces a stable local pseudo-random value without changing GameMaker's RNG.
function __funGeneratedStyleHash(seed, column, row, channel) {
	var value = int64(seed)
	value += int64(column + 1) * 73856093
	value += int64(row + 1) * 19349663
	value += int64(channel + 1) * 83492791
	value = value ^ (value >> 13)
	value *= 1274126177
	value = value ^ (value >> 16)
	return abs(value)
}

/// Selects one deterministic value from an array.
function __funGeneratedChoice(values, seed, column, row, channel) {
	var index = __funGeneratedStyleHash(seed, column, row, channel) mod array_length(values)
	return values[index]
}

/// Creates explicit tile data for one tileset index.
function __funGeneratedTileData(tile_index) {
	return tile_set_index(0, tile_index)
}

/// Returns whether one cell belongs to the visible platform mass.
function __funGeneratedPlatformFilled(level_data, column, row) {
	var symbol = __funGeneratedSymbol(level_data.terrain, level_data.width, level_data.height, column, row, ".")
	return symbol == "#" || symbol == "X"
}

/// Returns the one-cell strip axes used only for visual neighbor matching.
function __funGeneratedThinPlatformAxes(level_data, column, row) {
	var symbol = __funGeneratedSymbol(level_data.terrain, level_data.width, level_data.height, column, row, ".")
	if (symbol != "#") {
		return 0
	}
	var horizontal = (
		!__funGeneratedPlatformFilled(level_data, column, row - 1)
		and !__funGeneratedPlatformFilled(level_data, column, row + 1)
	)
	var vertical = (
		!__funGeneratedPlatformFilled(level_data, column - 1, row)
		and !__funGeneratedPlatformFilled(level_data, column + 1, row)
	)
	return horizontal + 2 * vertical
}

/// Ignores attached one-cell strips while styling the main platform mass.
function __funGeneratedPlatformNeighborFilled(
	level_data,
	column,
	row,
	neighbor_column,
	neighbor_row
) {
	if (!__funGeneratedPlatformFilled(level_data, neighbor_column, neighbor_row)) {
		return false
	}
	var neighbor_axes = __funGeneratedThinPlatformAxes(
		level_data,
		neighbor_column,
		neighbor_row
	)
	if (neighbor_axes == 0) {
		return true
	}
	var current_axes = __funGeneratedThinPlatformAxes(level_data, column, row)
	return (current_axes & neighbor_axes) != 0
}

/// Returns whether a spike's black rear overlaps one visible solid cell.
function __funGeneratedPlatformBacksSpike(level_data, column, row) {
	var right_hazard = __funGeneratedSymbol(
		level_data.hazards,
		level_data.width,
		level_data.height,
		column + 1,
		row,
		"."
	)
	var left_hazard = __funGeneratedSymbol(
		level_data.hazards,
		level_data.width,
		level_data.height,
		column - 1,
		row,
		"."
	)
	var lower_hazard = __funGeneratedSymbol(
		level_data.hazards,
		level_data.width,
		level_data.height,
		column,
		row + 1,
		"."
	)
	var upper_hazard = __funGeneratedSymbol(
		level_data.hazards,
		level_data.width,
		level_data.height,
		column,
		row - 1,
		"."
	)
	return (
		right_hazard == ">" or right_hazard == "R"
		or left_hazard == "<" or left_hazard == "L"
		or upper_hazard == "^" or upper_hazard == "U"
		or lower_hazard == "v" or lower_hazard == "D"
	)
}

/// Chooses the platform tile matching exposed sides of one solid cell.
function __funGeneratedPlatformTile(level_data, column, row) {
	if (__funGeneratedPlatformBacksSpike(level_data, column, row)) {
		return 10
	}

	var top_open = !__funGeneratedPlatformNeighborFilled(level_data, column, row, column, row - 1)
	var right_open = !__funGeneratedPlatformNeighborFilled(level_data, column, row, column + 1, row)
	var bottom_open = !__funGeneratedPlatformNeighborFilled(level_data, column, row, column, row + 1)
	var left_open = !__funGeneratedPlatformNeighborFilled(level_data, column, row, column - 1, row)
	var open_mask = top_open + 2 * right_open + 4 * bottom_open + 8 * left_open
	var seed = level_data.style.seed

	// A single missing diagonal inside solid mass is an authored inner corner.
	if (open_mask == 0) {
		var northwest_open = !__funGeneratedPlatformNeighborFilled(level_data, column, row, column - 1, row - 1)
		var northeast_open = !__funGeneratedPlatformNeighborFilled(level_data, column, row, column + 1, row - 1)
		var southeast_open = !__funGeneratedPlatformNeighborFilled(level_data, column, row, column + 1, row + 1)
		var southwest_open = !__funGeneratedPlatformNeighborFilled(level_data, column, row, column - 1, row + 1)
		var open_diagonals = northwest_open + northeast_open + southeast_open + southwest_open
		if (open_diagonals == 1) {
			if (southeast_open) return 28
			if (southwest_open) return 29
			if (northeast_open) return 38
			return 39
		}
		return 10
	}

	switch (open_mask) {
		case 1: return __funGeneratedChoice([1, 2, 3, 4, 5, 6, 7], seed, column, row, 1)
		case 2: return __funGeneratedChoice([21, 22, 23, 24, 25, 26, 27], seed, column, row, 2)
		case 3: return 18
		case 4: return __funGeneratedChoice([11, 12, 13, 14, 15, 16, 17], seed, column, row, 3)
		case 5: return __funGeneratedChoice([42, 43, 44, 52, 53, 54], seed, column, row, 10)
		case 6: return 8
		case 7: return __funGeneratedChoice([52, 53, 54], seed, column, row, 7)
		case 8: return __funGeneratedChoice([31, 32, 33, 34, 35, 36, 37], seed, column, row, 4)
		case 9: return 19
		case 10: return __funGeneratedChoice([62, 63, 64, 72, 73, 74], seed, column, row, 9)
		case 11: return __funGeneratedChoice([62, 63, 64], seed, column, row, 9)
		case 12: return 9
		case 13: return __funGeneratedChoice([42, 43, 44], seed, column, row, 10)
		case 14: return __funGeneratedChoice([72, 73, 74], seed, column, row, 7)
		case 15: return __funGeneratedChoice([20, 30], seed, column, row, 7)
	}

	return 10
}

/// Chooses jump-through end caps only where the run touches a wall.
function __funGeneratedJumpThroughTile(level_data, column, row) {
	if (__funGeneratedPlatformFilled(level_data, column - 1, row)) {
		return 65
	}
	if (__funGeneratedPlatformFilled(level_data, column + 1, row)) {
		return 69
	}
	return __funGeneratedChoice(
		[66, 67, 68],
		level_data.style.seed,
		column,
		row,
		5
	)
}

/// Styles the solid and jump-through platform tile map.
function __funStyleGeneratedPlatforms(level_data) {
	var tiles = __funGeneratedGrid(level_data.width, level_data.height, 0)
	for (var row = 0; row < level_data.height; ++row) {
		for (var column = 0; column < level_data.width; ++column) {
			var symbol = __funGeneratedSymbol(level_data.terrain, level_data.width, level_data.height, column, row, ".")
			if (symbol == "#") {
				var platform_tile_index = __funGeneratedPlatformTile(level_data, column, row)
				tiles[row][column] = __funGeneratedTileData(platform_tile_index)
			}
			else if (symbol == "=") {
				var jump_tile_index = __funGeneratedJumpThroughTile(level_data, column, row)
				tiles[row][column] = __funGeneratedTileData(jump_tile_index)
			}
			else if (symbol == "X") {
				tiles[row][column] = __funGeneratedTileData(10)
			}
		}
	}
	return tiles
}

/// Styles grass only on exposed platform surfaces without spikes.
function __funStyleGeneratedGrass(level_data) {
	var tiles = __funGeneratedGrid(level_data.width, level_data.height, 0)
	var chance_limit = floor(level_data.style.grass_chance * 1000)

	for (var row = 0; row < level_data.height; ++row) {
		for (var column = 0; column < level_data.width; ++column) {
			var terrain = __funGeneratedSymbol(level_data.terrain, level_data.width, level_data.height, column, row, ".")
			var hazard = __funGeneratedSymbol(level_data.hazards, level_data.width, level_data.height, column, row, ".")
			if (terrain != "." || hazard != "." || __funGeneratedPlatformFilled(level_data, column, row)) {
				continue
			}

			var oracle = __funGeneratedStyleHash(level_data.style.seed, column, row, 6) mod 1000
			if (oracle >= chance_limit) {
				continue
			}

			var floor_below = __funGeneratedPlatformFilled(level_data, column, row + 1)
			var ceiling_above = __funGeneratedPlatformFilled(level_data, column, row - 1)
			if (floor_below) {
				var floor_grass_index = __funGeneratedChoice([55, 56, 57, 58, 59], level_data.style.seed, column, row, 7)
				tiles[row][column] = __funGeneratedTileData(floor_grass_index)
			}
			else if (ceiling_above) {
				var ceiling_grass_index = __funGeneratedChoice([45, 46, 47, 48, 49], level_data.style.seed, column, row, 8)
				tiles[row][column] = __funGeneratedTileData(ceiling_grass_index)
			}
		}
	}
	return tiles
}

/// Returns the canonical upward 4x4 extended-spike brush from Level04.
function __funGeneratedUpSpikePattern() {
	return [
		[22, 20, 21, 19],
		[31, 29, 30, 28],
		[62, 60, 61, 59],
		[71, 69, 70, 68]
	]
}

/// Returns the direction shared by centered and cell-aligned hazard symbols.
function __funGeneratedSpikeDirection(symbol) {
	switch (symbol) {
		case "U": return "^"
		case "D": return "v"
		case "L": return "<"
		case "R": return ">"
	}
	return symbol
}

/// Returns the first fine-grid coordinate across one 24-pixel spike brush.
function __funGeneratedSpikeAnchor(position, symbol) {
	if (symbol == "U" || symbol == "L") {
		return position * 2
	}
	if (symbol == "D" || symbol == "R") {
		return position * 2 - 2
	}
	return position * 2 - 1
}

/// Returns one transformed tile from the canonical upward spike brush.
function __funGeneratedSpikeTile(pattern, symbol, target_column, target_row) {
	var source_column = target_column
	var source_row = target_row
	var tile_data = 0

	switch (symbol) {
		case "^":
			tile_data = __funGeneratedTileData(pattern[source_row][source_column])
			tile_data = tile_set_mirror(tile_data, true)
			break
		case "v":
			source_row = 3 - target_row
			tile_data = __funGeneratedTileData(pattern[source_row][source_column])
			tile_data = tile_set_mirror(tile_data, true)
			tile_data = tile_set_flip(tile_data, true)
			break
		case ">":
			source_column = target_row
			source_row = 3 - target_column
			tile_data = __funGeneratedTileData(pattern[source_row][source_column])
			tile_data = tile_set_mirror(tile_data, true)
			tile_data = tile_set_rotate(tile_data, true)
			break
		case "<":
			source_column = 3 - target_row
			source_row = target_column
			tile_data = __funGeneratedTileData(pattern[source_row][source_column])
			tile_data = tile_set_flip(tile_data, true)
			tile_data = tile_set_rotate(tile_data, true)
			break
	}

	return tile_data
}

/// Writes tile data only when an extended spike stays inside its tile map.
function __funWriteGeneratedSpikeTile(tiles, column, row, tile_data) {
	if (row < 0 || row >= array_length(tiles)) {
		return
	}
	if (column < 0 || column >= array_length(tiles[row])) {
		return
	}
	var row_tiles = tiles[row]
	row_tiles[@ column] = tile_data
}

/// Returns the zero-based position inside one same-direction hazard run.
function __funGeneratedSpikeRunOffset(level_data, column, row, symbol) {
	var offset = 0
	var spike_direction = __funGeneratedSpikeDirection(symbol)
	if (spike_direction == "^" || spike_direction == "v") {
		while (__funGeneratedSymbol(level_data.hazards, level_data.width, level_data.height, column - offset - 1, row, ".") == symbol) {
			++offset
		}
	}
	else {
		while (__funGeneratedSymbol(level_data.hazards, level_data.width, level_data.height, column, row - offset - 1, ".") == symbol) {
			++offset
		}
	}
	return offset
}

/// Writes one 12-pixel slice of the repeating Level04 spike brush.
function __funWriteGeneratedSpike(tiles, level_data, column, row, symbol) {
	var pattern = __funGeneratedUpSpikePattern()
	var run_offset = __funGeneratedSpikeRunOffset(level_data, column, row, symbol)
	var phase = (run_offset mod 2) * 2
	var spike_direction = __funGeneratedSpikeDirection(symbol)

	if (spike_direction == "^" || spike_direction == "v") {
		var anchor_row = __funGeneratedSpikeAnchor(row, symbol)
		for (var horizontal_target_row = 0; horizontal_target_row < 4; ++horizontal_target_row) {
			for (var slice_column = 0; slice_column < 2; ++slice_column) {
				var horizontal_target_column = phase + slice_column
				var horizontal_tile_data = __funGeneratedSpikeTile(pattern, spike_direction, horizontal_target_column, horizontal_target_row)
				__funWriteGeneratedSpikeTile(tiles, column * 2 + slice_column, anchor_row + horizontal_target_row, horizontal_tile_data)
			}
		}
	}
	else {
		var anchor_column = __funGeneratedSpikeAnchor(column, symbol)
		for (var slice_row = 0; slice_row < 2; ++slice_row) {
			var vertical_target_row = phase + slice_row
			for (var vertical_target_column = 0; vertical_target_column < 4; ++vertical_target_column) {
				var vertical_tile_data = __funGeneratedSpikeTile(pattern, spike_direction, vertical_target_column, vertical_target_row)
				__funWriteGeneratedSpikeTile(tiles, anchor_column + vertical_target_column, row * 2 + slice_row, vertical_tile_data)
			}
		}
	}
}

/// Styles the 6x6 extended-spike tile map.
function __funStyleGeneratedSpikes(level_data) {
	var tiles = __funGeneratedGrid(level_data.width * 2, level_data.height * 2, 0)
	for (var row = 0; row < level_data.height; ++row) {
		for (var column = 0; column < level_data.width; ++column) {
			var symbol = __funGeneratedSymbol(level_data.hazards, level_data.width, level_data.height, column, row, ".")
			if (symbol != ".") {
				__funWriteGeneratedSpike(tiles, level_data, column, row, symbol)
			}
		}
	}
	return tiles
}

/// Converts readable semantic layers into exact runtime tile grids.
function funStyleGeneratedLevel(level_data) {
	return {
		level: level_data,
		platform_tiles: __funStyleGeneratedPlatforms(level_data),
		grass_tiles: __funStyleGeneratedGrass(level_data),
		spike_tiles: __funStyleGeneratedSpikes(level_data)
	}
}
