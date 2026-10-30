/// Creates presentation-only prank state; campaign data stays untouched.
function funBrokenMenuCreate() {
    self.broken_menu = global.ending_stage == 1
    self.runtime_errors = 0
    self.runtime_error_font = -1
    self.glitch_frames = 0
    if (!self.broken_menu) return
    font_add_enable_aa(true)
    self.runtime_error_font = font_add("fonts/DejaVuSansMono.ttf", 18, false, false, 32, 126)
    font_add_enable_aa(false)
    if (variable_global_exists("story_menu_glitch") and global.story_menu_glitch) {
        self.glitch_frames = 6
        global.story_menu_glitch = false
    }
}

/// Keeps Continue selectable while substituting a harmless runtime-error notice.
function funBrokenMenuContinue() {
    self.runtime_errors++
}

/// Draws a brief torn frame, then native-resolution error text above pixel UI.
function funBrokenMenuDraw() {
    if (!self.broken_menu or instance_exists(oSettings)) return
    funBrokenMenuGlitch()
    funBrokenMenuErrors()
}

/// Tears a few horizontal bands for exactly six rendered menu frames.
function funBrokenMenuGlitch() {
    var gui_w = display_get_gui_width()
    var gui_h = display_get_gui_height()
    if (self.glitch_frames > 0) {
        if (surface_exists(application_surface)) {
            var sw = surface_get_width(application_surface)
            var sh = surface_get_height(application_surface)
            for (var strip = 0; strip < 4; ++strip) {
                var top = (strip * 61 + self.glitch_frames * 17) mod 240
                var shift = (strip mod 2 == 0 ? 1 : -1) * self.glitch_frames * 3
                draw_surface_part_ext(application_surface, 0, top * sh / 270, sw, 9 * sh / 270,
                    shift * gui_w / 480, top * gui_h / 270, gui_w / sw, gui_h / sh, c_white, 1)
            }
        }
        self.glitch_frames--
    }
}

/// Draws the bounded error stack without changing global GUI dimensions.
function funBrokenMenuErrors() {
    var gui_w = display_get_gui_width()
    var gui_h = display_get_gui_height()
    if (self.runtime_errors == 0) return
    // Scale only this draw's world matrix: the font raster remains native-sized.
    var bounds = application_get_position()
    var native_w = bounds[2] - bounds[0]
    var native_h = bounds[3] - bounds[1]
    if (native_w <= 0 or native_h <= 0) return
    var previous_world = matrix_get(matrix_world)
    var previous_font = draw_get_font()
    var previous_colour = draw_get_color()
    var previous_alpha = draw_get_alpha()
    var previous_halign = draw_get_halign()
    var previous_valign = draw_get_valign()
    var previous_filter = gpu_get_texfilter()
    matrix_set(matrix_world, matrix_build(0, 0, 0, 0, 0, 0, gui_w / native_w, gui_h / native_h, 1))
    gpu_set_tex_filter(true)
    draw_set_font(self.runtime_error_font)
    draw_set_halign(fa_left)
    draw_set_valign(fa_top)
    draw_set_color(make_colour_rgb(240, 55, 55))
    draw_set_alpha(1)
    var message = "Runtime Error: player.obj is not found. Cannot initialize level."
    var text_width = min(native_w - 32, string_width(message))
    var text_height = string_height_ext(message, -1, text_width)
    var spacing = text_height + 10
    // Drop only messages whose entire rectangle has moved above the window.
    self.runtime_errors = min(self.runtime_errors, ceil((native_h - 16) / spacing))
    for (var i = 0; i < self.runtime_errors; ++i) {
        draw_text_ext(native_w - 16 - text_width, native_h - 16 - text_height - i * spacing,
            message, -1, text_width)
    }
    matrix_set(matrix_world, previous_world)
    gpu_set_tex_filter(previous_filter)
    draw_set_font(previous_font)
    draw_set_color(previous_colour)
    draw_set_alpha(previous_alpha)
    draw_set_halign(previous_halign)
    draw_set_valign(previous_valign)
}

/// Releases only the menu-owned font when this room is left.
function funBrokenMenuCleanup() {
    if (self.runtime_error_font != -1) font_delete(self.runtime_error_font)
}
