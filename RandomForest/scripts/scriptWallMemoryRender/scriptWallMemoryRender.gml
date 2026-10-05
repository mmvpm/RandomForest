/// Wraps whole words in the cached font while preserving authored line breaks.
function funWallMemoryWrap(text, max_width) {
    var result = []
    var paragraphs = string_split(text, "\n")
    for (var p = 0; p < array_length(paragraphs); ++p) {
        var words = string_split(paragraphs[p], " ")
        var line = ""
        for (var w = 0; w < array_length(words); ++w) {
            var candidate = line == "" ? words[w] : line + " " + words[w]
            if (line != "" and string_width(candidate) > max_width) {
                array_push(result, line)
                line = words[w]
            } else line = candidate
        }
        array_push(result, line)
    }
    return result
}

/// Measures only visible glyph pixels and their one-pixel outline, not empty cache padding.
function funWallMemoryInkBounds(lines) {
    var bounds = [100000, 100000, -100000, -100000]
    for (var row = 0; row < array_length(lines); ++row) {
        var line = lines[row]
        for (var i = 1; i <= string_length(line); ++i) {
            var character = string_char_at(line, i)
            if (character == " ") continue
            var glyph_index = string_pos(character, global.memory_alphabet) - 1
            if (glyph_index < 0) continue
            var glyph = global.memory_glyph_bounds[glyph_index]
            var left = 3 + string_width(string_copy(line, 1, i - 1))
            var top = 3 + row * global.wall_memory_config.defaults.line_height
            bounds[0] = min(bounds[0], left - 1)
            bounds[1] = min(bounds[1], top + glyph[1] - 1)
            bounds[2] = max(bounds[2], left + glyph[2] - glyph[0] + 1)
            bounds[3] = max(bounds[3], top + glyph[3] + 1)
        }
    }
    return bounds
}

/// Stores immutable text geometry and colour from the level-entry snapshot.
function funWallMemoryPrepareAnchor(anchor, phrase, controller) {
    var previous_font = draw_get_font()
    draw_set_font(global.memory_font)
    anchor.lines = funWallMemoryWrap(phrase.text, anchor.width - 6)
    anchor.ink_bounds = funWallMemoryInkBounds(anchor.lines)
    draw_set_font(previous_font)
    anchor.surface_width = ceil(anchor.width)
    anchor.surface_height = 32 + (array_length(anchor.lines) - 1) * global.wall_memory_config.defaults.line_height
    anchor.memory_left = anchor.align == "right" ? round(anchor.x) - anchor.surface_width : round(anchor.x)
    anchor.memory_top = round(anchor.y)
    anchor.theme = funWallMemoryTheme(controller.level_number)
    var rgb = variable_struct_get(global.wall_memory_config.styles, anchor.theme)
    anchor.text_colour = make_colour_rgb(rgb[0], rgb[1], rgb[2])
    anchor.phrase_id = phrase.id
    anchor.reveal_seed = funWallMemoryHash(string(controller.level_number) + ":" + anchor.anchor_id) mod 1024
    anchor.ready = true
}

/// Draws a line in its base colour, overriding only the authored special word.
function funWallMemoryDrawLine(anchor, line, line_y) {
    var special = global.wall_memory_config.special
    var highlight_start = anchor.role == "missing_previous" ? string_pos(special.highlight_word, line) : 0
    var highlight_end = highlight_start + string_length(special.highlight_word)
    var rgb = special.highlight_colour
    for (var i = 1; i <= string_length(line); ++i) {
        var prefix = string_copy(line, 1, i - 1)
        var char_x = 3 + string_width(prefix)
        draw_set_colour(highlight_start > 0 and i >= highlight_start and i < highlight_end
            ? make_colour_rgb(rgb[0], rgb[1], rgb[2]) : anchor.text_colour)
        draw_text(char_x, line_y, string_char_at(line, i))
    }
}

/// Builds one reusable transparent text surface, with a one-pixel dark outline.
function funWallMemoryCache(anchor) {
    if (surface_exists(anchor.text_surface)) return true
    anchor.text_surface = surface_create(anchor.surface_width, anchor.surface_height)
    if (!surface_exists(anchor.text_surface)) return false
    var previous_font = draw_get_font(), previous_colour = draw_get_colour(), previous_alpha = draw_get_alpha()
    var previous_halign = draw_get_halign(), previous_valign = draw_get_valign()
    surface_set_target(anchor.text_surface)
    draw_clear_alpha(c_black, 0)
    draw_set_font(global.memory_font)
    draw_set_halign(fa_left)
    draw_set_valign(fa_top)
    draw_set_colour(c_black)
    draw_set_alpha(0.8)
    for (var i = 0; i < array_length(anchor.lines); ++i) {
        var line_y = 3 + i * global.wall_memory_config.defaults.line_height
        for (var dx = -1; dx <= 1; ++dx) {
            for (var dy = -1; dy <= 1; ++dy) {
                if (dx != 0 or dy != 0) draw_text(3 + dx, line_y + dy, anchor.lines[i])
            }
        }
    }
    draw_set_alpha(1)
    for (var i = 0; i < array_length(anchor.lines); ++i) {
        funWallMemoryDrawLine(anchor, anchor.lines[i], 3 + i * global.wall_memory_config.defaults.line_height)
    }
    surface_reset_target()
    draw_set_font(previous_font)
    draw_set_colour(previous_colour)
    draw_set_alpha(previous_alpha)
    draw_set_halign(previous_halign)
    draw_set_valign(previous_valign)
    return true
}

/// Clips a cached text copy to the safe reading area, retaining whole-pixel coordinates.
function funWallMemoryDrawClipped(anchor, offset_x, offset_y, alpha, clip_rect) {
    var left = anchor.memory_left + offset_x, top = anchor.memory_top + offset_y
    var source_x = max(0, ceil(clip_rect[0] - left)), source_y = max(0, ceil(clip_rect[1] - top))
    var visible_right = min(anchor.surface_width, floor(clip_rect[2] - left))
    var visible_bottom = min(anchor.surface_height, floor(clip_rect[3] - top))
    var visible_width = visible_right - source_x, visible_height = visible_bottom - source_y
    // Keep the draw call outside the early return; a newline alone does not separate it in GML.
    if (visible_width <= 0 or visible_height <= 0) return;
    draw_surface_part_ext(anchor.text_surface, source_x, source_y, visible_width, visible_height,
        left + source_x, top + source_y, 1, 1, c_white, alpha)
}

/// Draws stationary handwriting, with grain and brief echoes only on its first approach.
function funWallMemoryDraw(anchor) {
    if (!anchor.ready or anchor.phase == "idle") return;
    if (!funWallMemoryCache(anchor)) return;
    var cam = view_camera[0]
    var view_x = camera_get_view_x(cam), view_y = camera_get_view_y(cam)
    // Two disjoint rectangles protect the actual top-left HUD without hiding the ceiling.
    var clip_rects = [
        [ceil(view_x + 4), ceil(view_y + 48),
            floor(view_x + camera_get_view_width(cam) - 4), floor(view_y + camera_get_view_height(cam) - 4)],
        [ceil(view_x + 110), ceil(view_y + 4),
            floor(view_x + camera_get_view_width(cam) - 4), ceil(view_y + 48)]
    ]
    var settings = global.wall_memory_config.defaults
    var alpha = settings.opacity
    if (anchor.phase == "fade") alpha *= max(0, 1 - anchor.phase_elapsed / settings.fade_seconds)
    var reveal = anchor.phase == "appear" ? clamp(anchor.phase_elapsed / settings.appear_seconds, 0, 1) : 1
    var grain_reveal = anchor.first_reveal and anchor.phase == "appear"
    var use_shader = grain_reveal and reveal < 1 and shader_is_compiled(shWallMemoryReveal)
    if (use_shader) {
        shader_set(shWallMemoryReveal)
        shader_set_uniform_f(anchor.size_uniform, anchor.surface_width, anchor.surface_height)
        shader_set_uniform_f(anchor.reveal_uniform, reveal)
        shader_set_uniform_f(anchor.seed_uniform, anchor.reveal_seed)
    } else alpha *= reveal
    for (var i = 0; i < array_length(clip_rects); ++i) {
        var clip_rect = clip_rects[i]
        if (anchor.theme == "night" and grain_reveal and anchor.phase_elapsed < 0.2) {
            funWallMemoryDrawClipped(anchor, -2, 1, alpha * 0.10, clip_rect)
            funWallMemoryDrawClipped(anchor, 2, -1, alpha * 0.06, clip_rect)
        }
        funWallMemoryDrawClipped(anchor, 0, 0, alpha, clip_rect)
    }
    if (use_shader) shader_reset()
}
