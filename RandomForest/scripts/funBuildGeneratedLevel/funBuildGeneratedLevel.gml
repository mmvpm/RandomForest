/// Replaces one room tile map with a map sized for generated data.
function __funBuildGeneratedTileMap(layer_name, tileset, tiles, width, height) {
	var layer_id = layer_get_id(layer_name)
	var old_tilemap = layer_tilemap_get_id(layer_id)
	if (old_tilemap != -1) {
		layer_tilemap_destroy(old_tilemap)
	}

	var tilemap = layer_tilemap_create(layer_id, 0, 0, tileset, width, height)
	for (var row = 0; row < height; ++row) {
		for (var column = 0; column < width; ++column) {
			var tile = tiles[row][column]
			if (tile != 0) {
				tilemap_set(tilemap, tile, column, row)
			}
		}
	}
	return tilemap
}

/// Marks one in-bounds 6-pixel cell as solid.
function __funMarkGeneratedFineSolid(solid_cells, column, row) {
	if (row < 0 || row >= array_length(solid_cells)) {
		return
	}
	if (column < 0 || column >= array_length(solid_cells[row])) {
		return
	}
	var row_cells = solid_cells[row]
	row_cells[@ column] = true
}

/// Adds the two solid sections behind one centered or aligned spike brush.
function __funAddGeneratedSpikeSupport(solid_cells, column, row, symbol) {
	var fine_column = column * 2
	var fine_row = row * 2
	for (var offset = 0; offset < 2; ++offset) {
		switch (symbol) {
			case "^":
				__funMarkGeneratedFineSolid(solid_cells, fine_column + offset, fine_row + 1)
				__funMarkGeneratedFineSolid(solid_cells, fine_column + offset, fine_row + 2)
				break
			case "v":
				__funMarkGeneratedFineSolid(solid_cells, fine_column + offset, fine_row)
				__funMarkGeneratedFineSolid(solid_cells, fine_column + offset, fine_row - 1)
				break
			case ">":
				__funMarkGeneratedFineSolid(solid_cells, fine_column, fine_row + offset)
				__funMarkGeneratedFineSolid(solid_cells, fine_column - 1, fine_row + offset)
				break
			case "<":
				__funMarkGeneratedFineSolid(solid_cells, fine_column + 1, fine_row + offset)
				__funMarkGeneratedFineSolid(solid_cells, fine_column + 2, fine_row + offset)
				break
			case "U":
				__funMarkGeneratedFineSolid(solid_cells, fine_column + offset, fine_row + 2)
				__funMarkGeneratedFineSolid(solid_cells, fine_column + offset, fine_row + 3)
				break
			case "D":
				__funMarkGeneratedFineSolid(solid_cells, fine_column + offset, fine_row - 2)
				__funMarkGeneratedFineSolid(solid_cells, fine_column + offset, fine_row - 1)
				break
			case "R":
				__funMarkGeneratedFineSolid(solid_cells, fine_column - 2, fine_row + offset)
				__funMarkGeneratedFineSolid(solid_cells, fine_column - 1, fine_row + offset)
				break
			case "L":
				__funMarkGeneratedFineSolid(solid_cells, fine_column + 2, fine_row + offset)
				__funMarkGeneratedFineSolid(solid_cells, fine_column + 3, fine_row + offset)
				break
		}
	}
}

/// Builds the 6-pixel solid grid from terrain and derived spike supports.
function __funGeneratedSolidGrid(level_data) {
	var fine_width = level_data.width * 2
	var fine_height = level_data.height * 2
	var solid_cells = __funGeneratedGrid(fine_width, fine_height, false)
	for (var row = 0; row < level_data.height; ++row) {
		for (var column = 0; column < level_data.width; ++column) {
			if (string_char_at(level_data.terrain[row], column + 1) == "#") {
				__funMarkGeneratedFineSolid(solid_cells, column * 2, row * 2)
				__funMarkGeneratedFineSolid(solid_cells, column * 2 + 1, row * 2)
				__funMarkGeneratedFineSolid(solid_cells, column * 2, row * 2 + 1)
				__funMarkGeneratedFineSolid(solid_cells, column * 2 + 1, row * 2 + 1)
			}

			var hazard = string_char_at(level_data.hazards[row], column + 1)
			if (hazard != ".") {
				__funAddGeneratedSpikeSupport(solid_cells, column, row, hazard)
			}
		}
	}
	return solid_cells
}

/// Returns whether one fine-grid cell is an unconsumed solid cell.
function __funGeneratedSolidAvailable(solid_cells, used, column, row) {
	if (row < 0 || row >= array_length(solid_cells)) {
		return false
	}
	if (column < 0 || column >= array_length(solid_cells[row])) {
		return false
	}
	return !used[row][column] && solid_cells[row][column]
}

/// Finds the largest simple rectangle starting at one solid cell.
function __funGeneratedSolidRectangle(solid_cells, used, start_column, start_row) {
	var rectangle_width = 0
	while (__funGeneratedSolidAvailable(solid_cells, used, start_column + rectangle_width, start_row)) {
		++rectangle_width
	}

	var rectangle_height = 1
	var can_extend = true
	while (can_extend && start_row + rectangle_height < array_length(solid_cells)) {
		for (var dx = 0; dx < rectangle_width; ++dx) {
			if (!__funGeneratedSolidAvailable(solid_cells, used, start_column + dx, start_row + rectangle_height)) {
				can_extend = false
				break
			}
		}
		if (can_extend) {
			++rectangle_height
		}
	}

	return { width: rectangle_width, height: rectangle_height }
}

/// Marks every cell in one merged solid rectangle.
function __funMarkGeneratedRectangle(used, start_column, start_row, rectangle) {
	for (var dy = 0; dy < rectangle.height; ++dy) {
		var row_cells = used[start_row + dy]
		for (var dx = 0; dx < rectangle.width; ++dx) {
			var target_column = start_column + dx
			row_cells[@ target_column] = true
		}
	}
}

/// Merges solid cells into rectangles and creates their invisible collision instances.
function __funBuildGeneratedSolids(level_data) {
	var solid_cells = __funGeneratedSolidGrid(level_data)
	var fine_width = level_data.width * 2
	var fine_height = level_data.height * 2
	var used = __funGeneratedGrid(fine_width, fine_height, false)
	for (var row = 0; row < fine_height; ++row) {
		for (var column = 0; column < fine_width; ++column) {
			if (!__funGeneratedSolidAvailable(solid_cells, used, column, row)) {
				continue
			}

			var rectangle = __funGeneratedSolidRectangle(solid_cells, used, column, row)
			__funMarkGeneratedRectangle(used, column, row, rectangle)
			instance_create_layer(column * 6, row * 6, "Instances", oSolid, {
				image_xscale: rectangle.width * 0.5,
				image_yscale: rectangle.height * 0.5
			})
		}
	}
}

/// Merges horizontal jump-through runs into collision instances.
function __funBuildGeneratedJumpThroughs(level_data) {
	for (var row = 0; row < level_data.height; ++row) {
		var column = 0
		while (column < level_data.width) {
			if (string_char_at(level_data.terrain[row], column + 1) != "=") {
				++column
				continue
			}

			var start_column = column
			while (column < level_data.width && string_char_at(level_data.terrain[row], column + 1) == "=") {
				++column
			}
			instance_create_layer(start_column * 12, row * 12, "Instances", oJumpThru, {
				image_xscale: column - start_column,
				image_yscale: 1
			})
		}
	}
}

/// Creates one horizontal trap run in the directed half of each hazard cell.
function __funBuildGeneratedHorizontalTrap(start_column, row, run_length, symbol) {
	var trap_y = row * 12
	if (symbol == "v" || symbol == "U") {
		trap_y += 6
	}
	instance_create_layer(start_column * 12, trap_y, "Instances", oTrap, {
		image_xscale: run_length,
		image_yscale: 0.5
	})
}

/// Creates one vertical trap run in the directed half of each hazard cell.
function __funBuildGeneratedVerticalTrap(column, start_row, run_length, symbol) {
	var trap_x = column * 12
	if (symbol == ">" || symbol == "L") {
		trap_x += 6
	}
	instance_create_layer(trap_x, start_row * 12, "Instances", oTrap, {
		image_xscale: 0.5,
		image_yscale: run_length
	})
}

/// Merges semantic hazards into horizontal or vertical trap runs.
function __funBuildGeneratedTraps(level_data) {
	for (var row = 0; row < level_data.height; ++row) {
		var column = 0
		while (column < level_data.width) {
			var symbol = string_char_at(level_data.hazards[row], column + 1)
			if (symbol != "^" && symbol != "v" && symbol != "U" && symbol != "D") {
				++column
				continue
			}

			var start_column = column
			while (column < level_data.width && string_char_at(level_data.hazards[row], column + 1) == symbol) {
				++column
			}
			__funBuildGeneratedHorizontalTrap(start_column, row, column - start_column, symbol)
		}
	}

	for (var column = 0; column < level_data.width; ++column) {
		var row = 0
		while (row < level_data.height) {
			var symbol = string_char_at(level_data.hazards[row], column + 1)
			if (symbol != "<" && symbol != ">" && symbol != "L" && symbol != "R") {
				++row
				continue
			}

			var start_row = row
			while (row < level_data.height && string_char_at(level_data.hazards[row], column + 1) == symbol) {
				++row
			}
			__funBuildGeneratedVerticalTrap(column, start_row, row - start_row, symbol)
		}
	}
}

/// Returns the GameMaker object represented by one entity symbol.
function __funGeneratedEntityObject(symbol) {
	switch (symbol) {
		case "@": return oPlayer
		case "O": return oDoor
		case "o": return oDoor
		case "*": return oCoin
		case "S": return oSlime
		case "s": return oSlime
		case "K": return oSkeleton
		case "k": return oSkeleton
		case "B": return oBungalo
		case "b": return oBungalo
		case "P": return oPointer
		case "p": return oPointer
	}
	return noone
}

/// Creates one entity using explicit runtime coordinates and scale.
function __funCreateGeneratedEntity(symbol, x, y, scale_x, scale_y) {
	var object_asset = __funGeneratedEntityObject(symbol)
	if (object_asset != noone) {
		instance_create_layer(x, y, "Instances", object_asset, {
			image_xscale: scale_x,
			image_yscale: scale_y
		})
	}
}

/// Creates one gameplay entity with the transform encoded by its symbol.
function __funBuildGeneratedEntity(symbol, column, row) {
	var scale = 1
	var facing = 1
	var entity_x = column * 12

	switch (symbol) {
		case "O": entity_x += 6; break
		case "o": entity_x += 6; facing = -1; break
		case "S": scale = 0.8; break
		case "s": scale = 0.8; facing = -1; break
		case "k": facing = -1; break
		case "B": scale = 1.5; break
		case "b": scale = 1.5; facing = -1; break
		case "p": facing = -1; break
	}
	__funCreateGeneratedEntity(symbol, entity_x, row * 12, facing * scale, scale)
}

/// Creates all authored gameplay entities before room UI instances run Create.
function __funBuildGeneratedEntities(level_data) {
	for (var row = 0; row < level_data.height; ++row) {
		for (var column = 0; column < level_data.width; ++column) {
			var symbol = string_char_at(level_data.entities[row], column + 1)
			if (symbol != ".") {
				__funBuildGeneratedEntity(symbol, column, row)
			}
		}
	}
}

/// Builds the current generated room from styled and semantic level data.
function funBuildGeneratedLevel(styled_level) {
	var level_data = styled_level.level
	room_width = level_data.width * 12
	room_height = level_data.height * 12

	var theme = funLevelTheme(global.playing_level)
	var platforms = funThemeTileset(tsPlatforms, theme)
	__funBuildGeneratedTileMap("Platforms", platforms, styled_level.platform_tiles, level_data.width, level_data.height)
	__funBuildGeneratedTileMap("Grass", platforms, styled_level.grass_tiles, level_data.width, level_data.height)
	__funBuildGeneratedTileMap("Spikes", funThemeTileset(tsSpikesExt, theme), styled_level.spike_tiles, level_data.width * 2, level_data.height * 2)

	__funBuildGeneratedSolids(level_data)
	__funBuildGeneratedJumpThroughs(level_data)
	__funBuildGeneratedTraps(level_data)
	__funBuildGeneratedEntities(level_data)
	funBuildGeneratedWallMemoryAnchors(level_data)
	funBeginWallMemories()
}
