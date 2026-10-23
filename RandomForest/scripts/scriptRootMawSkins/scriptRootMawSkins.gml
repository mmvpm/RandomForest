/// Chooses one appearance for the active level and keeps it through death and room restart.
function funRootMawStartLevel(level_index) {
    if (!variable_global_exists("root_maw_level_skin") or global.root_maw_level_skin.level != level_index) {
        var skins = ["N1", "N5"]
        global.root_maw_level_skin = {level:level_index, skin:skins[irandom(1)]}
    }
    return global.root_maw_level_skin.skin
}

/// Resolves a visual-only sibling without changing the logical pose or its collision mask.
function funRootMawSkinSprite(base_sprite, skin) {
    return skin == "N5" ? asset_get_index(sprite_get_name(base_sprite) + "N5") : base_sprite
}
