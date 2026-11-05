/// Eases a bounded interval without overshoot or a sudden stop.
function funIntroEase(value) {
    var t = clamp(value, 0, 1)
    return t * t * (3 - 2 * t)
}

/// Starts a short, silent title card using the already loaded menu background.
function funStartupIntroStart() {
    self.startup_intro = {active: true, frame: 0, duration: 168}
    self.alpha_animation_counter = 0
}

/// Finishes without letting the skip press activate a menu item.
function funStartupIntroFinish() {
    self.startup_intro.active = false
    self.mouse_allowed_counter = 10
}

/// Advances the title card and consumes skip input before the menu handles it.
function funStartupIntroStep() {
    if (keyboard_check_pressed(vk_enter) or keyboard_check_pressed(vk_space)
        or keyboard_check_pressed(vk_escape) or mouse_check_button_pressed(mb_left)) {
        funStartupIntroFinish()
        return;
    }
    self.startup_intro.frame += 1
    if (self.startup_intro.frame >= self.startup_intro.duration) funStartupIntroFinish()
}

/// Draws a restrained pixel halo without textures, surfaces or random particles.
function funIntroGlow(px, py, alpha, color) {
    draw_set_color(color)
    for (var i = 3; i >= 1; --i) {
        draw_set_alpha(alpha * 0.035 * (4 - i))
        draw_circle(round(px), round(py), 1 + i * 3, false)
    }
    draw_set_alpha(alpha)
    draw_rectangle(round(px) - 1, round(py) - 1, round(px) + 1, round(py) + 1, false)
}

/// Reveals letters in place, then moves the complete title into its menu position.
function funIntroTitle(frame, handoff, color) {
    var title = "Random Forest"
    var scale = lerp(2.15, 2, handoff)
    var title_y = lerp(134, 30, handoff)
    var title_x = lerp(240, 242, handoff)
    draw_set_font(global.default_font_24)
    draw_set_halign(fa_left)
    draw_set_valign(fa_middle)
    var left = title_x - string_width(title) * scale / 2
    var tint = merge_colour(color, c_white, handoff)
    for (var i = 1; i <= string_length(title); ++i) {
        var delay = (i - 1) * 2.5
        var alpha = funIntroEase((frame - 24 - delay) / 30)
        draw_set_color(tint)
        draw_set_alpha(alpha)
        draw_text_transformed(left + string_width(string_copy(title, 1, i - 1)) * scale,
            title_y, string_char_at(title, i), scale, scale, 0)
    }
}

/// Draws the firefly and title over a darkened forest; returns menu opacity.
function funStartupIntroDraw() {
    var state = self.startup_intro
    var frame = state.frame
    var handoff = funIntroEase((frame - 126) / 42)
    var appear = funIntroEase(frame / 24)
    var ink = make_colour_rgb(235, 224, 188)
    draw_set_color(make_colour_rgb(5, 11, 12))
    draw_set_alpha((1 - handoff) * 0.88)
    draw_rectangle(0, 0, 480, 270, false)
    var decor_alpha = appear * (1 - funIntroEase((frame - 108) / 24))
    funIntroFireflyDraw(frame, decor_alpha, ink)
    funIntroTitle(frame, handoff, ink)
    draw_set_alpha(1)
    draw_set_color(c_white)
    draw_set_halign(fa_center)
    // Reveal controls only once the travelling title has cleared their top edge.
    return funIntroEase((frame - 156) / 12)
}
