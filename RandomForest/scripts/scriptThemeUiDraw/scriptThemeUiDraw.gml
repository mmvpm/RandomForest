/// Draws one frame through the original normal or stretched sprite primitive.
function __funDrawUiFrame(sprite, frame, x_pos, y_pos, sx, sy, angle, blend, alpha, stretched) {
    if (stretched) draw_sprite_stretched_ext(sprite, frame, x_pos, y_pos, sx, sy, blend, alpha)
    else draw_sprite_ext(sprite, frame, x_pos, y_pos, sx, sy, angle, blend, alpha)
}

/// Blends RGB once over an unchanged alpha mask, avoiding darker panel crossfades.
function __funDrawUiLayers(sprite, frame, x_pos, y_pos, sx, sy, angle, blend, alpha, presentation, stretched) {
    if (presentation == undefined) {
        __funDrawUiFrame(sprite, frame, x_pos, y_pos, sx, sy, angle, blend, alpha, stretched)
        return;
    }
    var names = ["day", "evening", "night", "morning"]
    var assets = [], weights = []
    for (var i = 0; i < 4; ++i) {
        if (presentation.weights[i] <= 0) continue
        var asset = funThemeSprite(sprite, names[i])
        var existing = -1
        for (var a = 0; a < array_length(assets); ++a) {
            if (assets[a] == asset) existing = a
        }
        if (existing == -1) {
            array_push(assets, asset)
            array_push(weights, presentation.weights[i])
        } else weights[existing] += presentation.weights[i]
    }
    if (array_length(assets) == 1) {
        __funDrawUiFrame(assets[0], frame, x_pos, y_pos, sx, sy, angle, blend, alpha, stretched)
        return;
    }
    var previous_blend = gpu_get_blendmode_ext_sepalpha()
    gpu_set_blendmode(bm_normal)
    // Occlude the scene only once, even for the translucent interiors of panels.
    __funDrawUiFrame(sprite, frame, x_pos, y_pos, sx, sy, angle, c_black, alpha, stretched)
    gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_one, bm_zero, bm_one)
    for (var i = 0; i < array_length(assets); ++i) {
        __funDrawUiFrame(assets[i], frame, x_pos, y_pos, sx, sy, angle, blend, alpha * weights[i], stretched)
    }
    gpu_set_blendmode_ext_sepalpha(previous_blend)
}

/// Draws themed UI art with an optional backwards-compatible day presentation.
function funDrawUiSprite(sprite, frame, x_pos, y_pos, sx, sy, angle, blend, alpha, presentation = undefined) {
    __funDrawUiLayers(sprite, frame, x_pos, y_pos, sx, sy, angle, blend, alpha, presentation, false)
}

/// Stretches thematic panels while keeping their original mouse-hit geometry.
function funDrawUiPanel(sprite, frame, x_pos, y_pos, width, height, blend, alpha, presentation = undefined) {
    __funDrawUiLayers(sprite, frame, x_pos, y_pos, width, height, 0, blend, alpha, presentation, true)
}
