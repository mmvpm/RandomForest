/// Wraps words and oversized words without discarding authored line breaks.
function funWallMemoryWrap(text, max_width) {
    var result = [], paragraphs = string_split(text, "\n")
    for (var p = 0; p < array_length(paragraphs); ++p) {
        var words = string_split(paragraphs[p], " "), line = ""
        for (var w = 0; w < array_length(words); ++w) {
            var candidate = line == "" ? words[w] : line + " " + words[w]
            if (line != "" and string_width(candidate) > max_width) {
                array_push(result, line)
                line = words[w]
            } else line = candidate
            while (string_width(line) > max_width) {
                var cut = 1
                while (cut < string_length(line)
                    and string_width(string_copy(line, 1, cut + 1)) <= max_width) { cut += 1 }
                array_push(result, string_copy(line, 1, cut))
                line = string_delete(line, 1, cut)
            }
        }
        if (line != "" or paragraphs[p] == "") array_push(result, line)
    }
    return result
}

/// Measures the complete centred lettering rather than its changing typed prefix.
function funWallMemoryInkBounds(anchor) {
    var bounds = [100000, 100000, -100000, -100000]
    for (var row = 0; row < array_length(anchor.lines); ++row) {
        var line = anchor.lines[row]
        for (var i = 1; i <= string_length(line); ++i) {
            var character = string_char_at(line, i)
            if (character == " ") continue
            var glyph_index = string_pos(character, global.memory_alphabet) - 1
            if (glyph_index < 0) continue
            var glyph = global.memory_glyph_bounds[glyph_index]
            var left = anchor.line_x[row] + string_width(string_copy(line, 1, i - 1))
            var top = 3 + row * global.wall_memory_config.defaults.line_height
            bounds[0] = min(bounds[0], left - 1)
            bounds[1] = min(bounds[1], top + glyph[1] - 1)
            bounds[2] = max(bounds[2], left + glyph[2] - glyph[0] + 1)
            bounds[3] = max(bounds[3], top + glyph[3] + 1)
        }
    }
    return bounds
}

/// Selects optional lighting colours without changing deterministic inscription identity.
function funWallMemoryPalette(theme) {
    var config = global.wall_memory_config
    if (variable_struct_exists(config, "palette_by_theme")) {
        if (variable_struct_exists(config.palette_by_theme, theme)) {
            return variable_struct_get(config.palette_by_theme, theme)
        }
    }
    return config.palette
}

/// Freezes full layout and colour before the first character is revealed.
function funWallMemoryPrepareAnchor(anchor) {
    var previous_font = draw_get_font()
    draw_set_font(global.memory_font)
    anchor.surface_width = max(32, ceil(anchor.width))
    anchor.lines = funWallMemoryWrap(anchor.text, anchor.surface_width - 6)
    anchor.line_x = []
    anchor.glyph_count = 0
    for (var i = 0; i < array_length(anchor.lines); ++i) {
        array_push(anchor.line_x, floor((anchor.surface_width - string_width(anchor.lines[i])) / 2 + 0.5))
        anchor.glyph_count += string_length(anchor.lines[i])
    }
    anchor.ink_bounds = funWallMemoryInkBounds(anchor)
    draw_set_font(previous_font)
    anchor.surface_height = global.memory_glyph_height + 6
        + (array_length(anchor.lines) - 1) * global.wall_memory_config.defaults.line_height
    anchor.memory_left = floor(anchor.x - anchor.surface_width / 2 + 0.5)
    anchor.memory_top = floor(anchor.y - anchor.surface_height / 2 + 0.5)
    var palette = funWallMemoryPalette(funCurrentLevelTheme())
    var rgb = palette[funWallMemoryHash(anchor.read_key) mod array_length(palette)]
    anchor.text_colour = make_colour_rgb(rgb[0], rgb[1], rgb[2])
    anchor.ready = anchor.glyph_count > 0
}

/// Outlines individual letters without drawing the sprite font's hidden space marker.
function funWallMemoryDrawOutline(line, line_x, line_y) {
    for (var i = 1; i <= string_length(line); ++i) {
        var character = string_char_at(line, i)
        if (character == " ") continue
        var char_x = line_x + string_width(string_copy(line, 1, i - 1))
        for (var dx = -1; dx <= 1; ++dx) {
            for (var dy = -1; dy <= 1; ++dy) {
                if (dx != 0 or dy != 0) draw_text(char_x + dx, line_y + dy, character)
            }
        }
    }
}

/// Draws a revealed prefix at the full line's fixed centre alignment.
function funWallMemoryDrawLine(anchor, line, full_line, line_x, line_y) {
    var special = global.wall_memory_config.special
    var highlight_start = anchor.role == "missing_previous" ? string_pos(special.highlight_word, full_line) : 0
    var highlight_end = highlight_start + string_length(special.highlight_word)
    var rgb = special.highlight_colour
    for (var i = 1; i <= string_length(line); ++i) {
        if (string_char_at(line, i) == " ") continue
        var char_x = line_x + string_width(string_copy(line, 1, i - 1))
        draw_set_colour(highlight_start > 0 and i >= highlight_start and i < highlight_end
            ? make_colour_rgb(rgb[0], rgb[1], rgb[2]) : anchor.text_colour)
        draw_text(char_x, line_y, string_char_at(line, i))
    }
}

/// Rebuilds the transparent cache only when another complete character appears.
function funWallMemoryCache(anchor) {
    var visible_count = floor(anchor.revealed)
    if (surface_exists(anchor.text_surface) and anchor.cached_revealed == visible_count) return true
    if (!surface_exists(anchor.text_surface)) {
        anchor.text_surface = surface_create(anchor.surface_width, anchor.surface_height)
        if (!surface_exists(anchor.text_surface)) return false
    }
    var previous_font = draw_get_font(), previous_colour = draw_get_colour(), previous_alpha = draw_get_alpha()
    var previous_halign = draw_get_halign(), previous_valign = draw_get_valign()
    var previous_blend = gpu_get_blendmode_ext_sepalpha(), previous_filter = gpu_get_texfilter()
    // Keep antialiased RGB premultiplied and accumulate surface alpha only once.
    gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_one, bm_inv_src_alpha)
    gpu_set_tex_filter(false)
    surface_set_target(anchor.text_surface)
    draw_clear_alpha(c_black, 0)
    draw_set_font(global.memory_font)
    draw_set_halign(fa_left)
    draw_set_valign(fa_top)
    var remaining = visible_count
    for (var row = 0; row < array_length(anchor.lines); ++row) {
        var count = min(remaining, string_length(anchor.lines[row]))
        var line = string_copy(anchor.lines[row], 1, count)
        remaining -= count
        var line_y = 3 + row * global.wall_memory_config.defaults.line_height
        draw_set_colour(c_black)
        draw_set_alpha(0.8)
        funWallMemoryDrawOutline(line, anchor.line_x[row], line_y)
        draw_set_alpha(1)
        funWallMemoryDrawLine(anchor, line, anchor.lines[row], anchor.line_x[row], line_y)
    }
    surface_reset_target()
    gpu_set_blendmode_ext_sepalpha(previous_blend)
    gpu_set_tex_filter(previous_filter)
    draw_set_font(previous_font)
    draw_set_colour(previous_colour)
    draw_set_alpha(previous_alpha)
    draw_set_halign(previous_halign)
    draw_set_valign(previous_valign)
    anchor.cached_revealed = visible_count
    return true
}

/// Clips lettering to the safe camera area at whole-pixel coordinates.
function funWallMemoryDrawClipped(anchor, alpha, clip_rect) {
    var left = anchor.memory_left, top = anchor.memory_top
    var source_x = max(0, ceil(clip_rect[0] - left)), source_y = max(0, ceil(clip_rect[1] - top))
    var visible_right = min(anchor.surface_width, floor(clip_rect[2] - left))
    var visible_bottom = min(anchor.surface_height, floor(clip_rect[3] - top))
    var visible_width = visible_right - source_x, visible_height = visible_bottom - source_y
    // A bare return would swallow the following draw call in GML.
    if (visible_width <= 0 or visible_height <= 0) return;
    // Premultiplied surfaces need the same fade on RGB and alpha.
    var tint = floor(alpha * 255 + 0.5)
    draw_surface_part_ext(anchor.text_surface, source_x, source_y, visible_width, visible_height,
        left + source_x, top + source_y, 1, 1, make_colour_rgb(tint, tint, tint), alpha)
}

/// Shows the original handwriting without multiplying antialiasing a second time.
function funWallMemoryDraw(anchor) {
    if (!anchor.ready or anchor.phase == "idle" or anchor.phase == "consumed") return;
    if (!funWallMemoryCache(anchor)) return;
    var cam = view_camera[0]
    var view_x = camera_get_view_x(cam), view_y = camera_get_view_y(cam)
    var clip_rects = [
        [ceil(view_x + 4), ceil(view_y + 48),
            floor(view_x + camera_get_view_width(cam) - 4), floor(view_y + camera_get_view_height(cam) - 4)],
        [ceil(view_x + 110), ceil(view_y + 4),
            floor(view_x + camera_get_view_width(cam) - 4), ceil(view_y + 48)]
    ]
    var settings = global.wall_memory_config.defaults
    var alpha = settings.opacity
    if (anchor.phase == "fade") alpha *= max(0, 1 - anchor.phase_elapsed / settings.fade_seconds)
    var previous_blend = gpu_get_blendmode_ext_sepalpha(), previous_filter = gpu_get_texfilter()
    gpu_set_blendmode_ext(bm_one, bm_inv_src_alpha)
    gpu_set_tex_filter(false)
    for (var i = 0; i < array_length(clip_rects); ++i) funWallMemoryDrawClipped(anchor, alpha, clip_rects[i])
    gpu_set_blendmode_ext_sepalpha(previous_blend)
    gpu_set_tex_filter(previous_filter)
}
