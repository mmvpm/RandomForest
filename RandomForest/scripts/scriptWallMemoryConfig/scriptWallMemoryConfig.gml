/// Loads shared inscription settings and the baked handwritten font.
function funLoadWallMemoryConfig() {
    global.wall_memory_config = json_parse(funReadGeneratedLevelFile("narrative/wall_memories.json"))
    var font_metadata = json_parse(funReadGeneratedLevelFile("narrative/memory_font.json"))
    global.memory_alphabet = font_metadata.characters
    global.memory_glyph_bounds = font_metadata.glyph_bounds
    global.memory_glyph_height = font_metadata.glyph_height
    global.memory_font = font_add_sprite_ext(sMemoryAlphabet, global.memory_alphabet, true, 1)
}

/// Creates one ordinary gameplay controller, after the level index is ready.
function funBeginWallMemories() {
    // GML needs the terminator here, otherwise the next call becomes the return value.
    if (room == rBlackRoom or instance_exists(oWallMemoryController)) return;
    instance_create_depth(0, 0, 350, oWallMemoryController)
}

/// Creates generated anchors from optional, authored world-coordinate metadata.
function funBuildGeneratedWallMemoryAnchors(level_data) {
    if (!variable_struct_exists(level_data, "wall_memories")) return;
    for (var i = 0; i < array_length(level_data.wall_memories); ++i) {
        var placement = level_data.wall_memories[i]
        instance_create_depth(placement.x, placement.y, 350, oWallMemoryAnchor, {
            anchor_id: placement.id,
            width: placement.width,
            role: placement.role,
            text: placement.text,
            min_collected: variable_struct_exists(placement, "min_collected") ? placement.min_collected : 0,
            requires_all_previous: variable_struct_exists(placement, "requires_all_previous")
                ? placement.requires_all_previous : false
        })
    }
}
