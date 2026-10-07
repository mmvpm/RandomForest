/// Returns the lighting theme for a zero-based campaign level index.
function funLevelTheme(level_index) {
    if (level_index < 20) return "day"
    if (level_index < 30) return "evening"
    if (level_index < 40) return "night"
    return "morning"
}

/// Resolves authored rooms before their progress controller has run Create.
function funCurrentLevelTheme() {
    var authored_index = funGetRoomIndex()
    if (authored_index >= 0) return funLevelTheme(authored_index)
    if (room == rGeneratedLevel) return funLevelTheme(global.playing_level)
    return "day"
}

/// Selects the full-view or parallax background for one lighting theme.
function funThemeBackground(theme, parallax = true) {
    var name = "sBackground"
    switch (theme) {
        case "evening": name += "Evening"; break
        case "night": name += "Night"; break
        case "morning": name += "Morning"; break
    }
    if (parallax) name += "_x13"
    return asset_get_index(name)
}

/// Caches optional themed siblings; absent variants keep their original asset.
function __funThemeAsset(day_asset, theme, day_name) {
    if (theme == "day") return day_asset
    if (!variable_global_exists("theme_asset_cache")) global.theme_asset_cache = {}
    var suffix = ""
    switch (theme) {
        case "evening": suffix = "Evening"; break
        case "night": suffix = "Night"; break
        case "morning": suffix = "Morning"; break
    }
    var name = day_name + suffix
    if (!variable_struct_exists(global.theme_asset_cache, name)) {
        var variant = asset_get_index(name)
        variable_struct_set(global.theme_asset_cache, name, variant == -1 ? day_asset : variant)
    }
    return variable_struct_get(global.theme_asset_cache, name)
}

/// Selects a visual sibling without changing animation or collision state.
function funThemeSprite(day_sprite, theme) {
    return __funThemeAsset(day_sprite, theme, sprite_get_name(day_sprite))
}

/// Selects a tileset sibling with the same tile indices and geometry.
function funThemeTileset(day_tileset, theme) {
    return __funThemeAsset(day_tileset, theme, tileset_get_name(day_tileset))
}

/// Replaces only the art of authored terrain layers, including either spike set.
function funApplyRoomTheme(theme) {
    var names = ["Platforms", "Grass", "Spikes"]
    for (var i = 0; i < array_length(names); ++i) {
        var layer_id = layer_get_id(names[i])
        if (layer_id == -1) continue
        var map = layer_tilemap_get_id(layer_id)
        if (map != -1) tilemap_tileset(map, funThemeTileset(tilemap_get_tileset(map), theme))
    }
}

/// Draws themed frames while preserving original masks, frame events and blends.
function funDrawThemedSelf(scale_x = 1, scale_y = 1, theme = undefined) {
    if (theme == undefined) theme = funCurrentLevelTheme()
    draw_sprite_ext(
        funThemeSprite(self.sprite_index, theme), self.image_index,
        self.x, self.y, self.image_xscale * scale_x, self.image_yscale * scale_y,
        self.image_angle, self.image_blend, self.image_alpha
    )
}
