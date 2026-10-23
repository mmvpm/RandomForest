/// Returns visual platform occupancy, including black mass with no collision instances.
function funAmbientTileAt(column, row) {
    if (column < 0 or row < 0 or column >= self.grid_width or row >= self.grid_height) return 10;
    return self.tiles[row * self.grid_width + column]
}

/// Returns a cached visual tile at a world position; no collision query is needed.
function funAmbientTileAtPixel(xx, yy) {
    return funAmbientTileAt(floor(xx / 12), floor(yy / 12))
}

/// Samples actual tile art once per room, never the incomplete Solid hierarchy.
function funAmbientCacheTerrain() {
    self.grid_width = ceil(room_width / 12)
    self.grid_height = ceil(room_height / 12)
    self.tiles = array_create(self.grid_width * self.grid_height, 0)
    self.ceilings = []
    self.ceiling_columns = array_create(self.grid_width)
    for (var column = 0; column < self.grid_width; ++column) self.ceiling_columns[column] = []
    self.low_floors = array_create(self.grid_width, -1)
    var platform_map = layer_tilemap_get_id(layer_get_id("Platforms"))
    for (var row = 0; row < self.grid_height; ++row) {
        for (var column = 0; column < self.grid_width; ++column) {
            var index = row * self.grid_width + column
            var data = tilemap_get_at_pixel(platform_map, column * 12 + 6, row * 12 + 6)
            self.tiles[index] = data == -1 ? 0 : tile_get_index(data)
        }
    }
    for (var row = 0; row < self.grid_height; ++row) {
        for (var column = 0; column < self.grid_width; ++column) {
            var tile = funAmbientTileAt(column, row)
            if (tile == 0 or tile == 10) continue
            if (funAmbientTileAt(column, row + 1) == 0) {
                var point = {x:column * 12 + 3 + ((column * 7 + row * 3) mod 7),
                    y:(row + 1) * 12, column:column, row:row}
                array_push(self.ceilings, point)
                var bucket = self.ceiling_columns[column]
                array_push(bucket, point)
                self.ceiling_columns[column] = bucket
            }
            if (row * 12 > room_height * 0.58 and funAmbientTileAt(column, row - 1) == 0)
                self.low_floors[column] = row * 12
        }
    }
}

/// Releases a small irregular puff only from a nearby exposed, visible ceiling.
/// Strengths: 0 landing, 1 sword, 2 third attack, 3 stomp.
function funAmbientImpact(xx, yy, strength = 0) {
    if (!instance_exists(oAmbientSystem)) return;
    with (oAmbientSystem) {
        if (self.impact_cooldown > 0) exit;
        self.impact_cooldown = 18
        var candidates = []
        var reach = 65 + strength * 12
        var first = max(0, floor((xx - reach) / 12)), last = min(self.grid_width - 1, floor((xx + reach) / 12))
        for (var column = first; column <= last; ++column) {
            var bucket = self.ceiling_columns[column]
            for (var i = 0; i < array_length(bucket); ++i) {
                var point = bucket[i]
                if (point.y < yy and yy - point.y < 95) array_push(candidates, point)
            }
        }
        var amounts = [5, 18, 30, 36]
        var count = min(array_length(candidates) * 4, amounts[clamp(floor(strength), 0, 3)])
        var available = array_length(candidates)
        // Shuffle anchors once; repeated grains remain scattered rather than forming a row.
        for (var i = available - 1; i > 0; --i) {
            var at = floor(funWeatherRandom(self.local_random) * (i + 1))
            var point = candidates[i]; candidates[i] = candidates[at]; candidates[at] = point
        }
        for (var i = 0; i < count; ++i) {
            var point = candidates[i mod available]
            var grain_x = point.x + funWeatherRandom(self.local_random) * 7 - 3
            if (funAmbientTileAtPixel(grain_x, point.y + 3) != 0) continue
            funAmbientAddParticle(1, grain_x,
                point.y + 3, (funWeatherRandom(self.local_random) - 0.5) * 0.18,
                0.12 + funWeatherRandom(self.local_random) * 0.15, 90 + floor(funWeatherRandom(self.local_random) * 60))
        }
    }
}
