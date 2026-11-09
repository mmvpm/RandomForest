/// Eases a bounded interval without overshoot or a sudden stop.
function funIntroEase(value) {
    var t = clamp(value, 0, 1)
    return t * t * (3 - 2 * t)
}

/// Starts the selected V08 only after graphics preparation and a separate black interval.
function funStartupIntroStart() {
    // Сдвиг звука в секундах от совмещения пика с остановкой: минус — раньше, плюс — позже.
    var sound_shift_seconds = -0.5
    self.startup_intro = {active: true, frame: -18, duration: 309, sound: -1,
        // N08-L's measured 35ms RMS crest is at 1.2525416667s in the unchanged file.
        sound_attempted: false, sound_start: (2.75 - 1.2525416666666667 + sound_shift_seconds) * 60,
        ready: false, warm_frames: 0, origin_time: 0, glow_surface: -1}
    self.alpha_animation_counter = 0
}

/// Stops only this intro voice and releases its small, room-owned image cache.
function funStartupIntroFinish() {
    var state = self.startup_intro
    if (state.sound != -1) audio_stop_sound(state.sound)
    state.sound = -1
    if (surface_exists(state.glow_surface)) surface_free(state.glow_surface)
    state.glow_surface = -1
    state.active = false
    self.mouse_allowed_counter = 10
}

/// Advances on a smooth monotonic clock instead of the mixer's block-wise play position.
function funStartupIntroStep() {
    if (keyboard_check_pressed(vk_enter) or keyboard_check_pressed(vk_space)
        or keyboard_check_pressed(vk_escape) or mouse_check_button_pressed(mb_left)) {
        funStartupIntroFinish()
        return;
    }
    var state = self.startup_intro
    if (!state.ready) return;
    state.frame = min(state.duration, max(state.frame, (get_timer() - state.origin_time) * 0.00006))
    if (!state.sound_attempted and state.frame >= state.sound_start) {
        state.sound_attempted = true
        if (global.sfx_enabled and state.frame < 165) {
            // An atomic offset compensates subframe scheduling lateness without moving the light backwards.
            state.sound = audio_play_sound(soundStartupIntro, 1, false, 1,
                max(0, (state.frame - state.sound_start) / 60))
        }
    }
    if (state.frame >= state.duration) funStartupIntroFinish()
}

/// Draws the unchanged original core and halo into its local image cache.
function funIntroGlow(px, py, alpha, color) {
    draw_set_color(color)
    for (var i = 3; i >= 1; --i) {
        draw_set_alpha(alpha * 0.035 * (4 - i))
        draw_circle(round(px), round(py), 1 + i * 3, false)
    }
    draw_set_alpha(alpha)
    draw_rectangle(round(px) - 1, round(py) - 1, round(px) + 1, round(py) + 1, false)
}

/// Warms real title glyphs and caches the original light before the scene clock starts.
function funIntroPrepareGraphics() {
    var state = self.startup_intro
    if (surface_exists(state.glow_surface)) return true
    state.glow_surface = surface_create(32, 32)
    if (!surface_exists(state.glow_surface)) return false
    var previous_blend = gpu_get_blendmode_ext_sepalpha()
    var previous_filter = gpu_get_texfilter()
    gpu_set_tex_filter(false)
    gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_one, bm_inv_src_alpha)
    surface_set_target(state.glow_surface)
    draw_clear_alpha(c_black, 0)
    funIntroGlow(16, 16, 1, make_colour_rgb(235, 224, 188))
    surface_reset_target()
    gpu_set_blendmode_ext_sepalpha(previous_blend)
    gpu_set_tex_filter(previous_filter)
    if (state.ready) return true
    draw_set_font(global.default_font_24)
    draw_set_halign(fa_left)
    draw_set_valign(fa_middle)
    var title = "Random Forest"
    for (var i = 1; i <= string_length(title); ++i) {
        font_cache_glyph(global.default_font_24, string_ord_at(title, i))
    }
    // These real glyph draws are covered by black before the frame is presented.
    draw_set_alpha(1)
    draw_set_color(c_white)
    draw_text_transformed(240, 134, title, 2.15, 2.15, 0)
    return true
}

/// Translates the whole original light at subpixel precision, keeping core and halo rigidly together.
function funIntroSmoothGlow(px, py, alpha) {
    if (alpha <= 0) return;
    var previous_blend = gpu_get_blendmode_ext_sepalpha()
    var previous_filter = gpu_get_texfilter()
    gpu_set_blendmode_ext(bm_one, bm_inv_src_alpha)
    gpu_set_tex_filter(true)
    var tint = round(clamp(alpha, 0, 1) * 255)
    draw_surface_ext(self.startup_intro.glow_surface, px - 16, py - 16,
        1, 1, 0, make_colour_rgb(tint, tint, tint), alpha)
    gpu_set_blendmode_ext_sepalpha(previous_blend)
    gpu_set_tex_filter(previous_filter)
}

/// Reproduces the selected broad, soft, following bloom without adding a white centre.
function funIntroFlashDraw(frame, ink) {
    var age = frame / 60 - 0.25
    if (age < 0 or age >= 0.5) return;
    var pulse
    if (age < 0.025) {
        var attack = clamp(age / 0.025, 0, 1)
        pulse = 1 - sqr(1 - attack)
    } else if (age < 0.05) pulse = 1
    else pulse = power(1 - clamp((age - 0.05) / 0.45, 0, 1), 1.7)
    var radius = 70 * lerp(1, 1.4, age / 0.5)
    var px = funIntroFlightSample(frame, 0)
    var py = funIntroFlightSample(frame, 1)
    draw_set_color(ink)
    for (var i = 24; i >= 1; --i) {
        var fraction = i / 24
        draw_set_alpha(0.4 * pulse / 9 * power(1 - fraction, 2.5))
        draw_circle(px, py, radius * fraction, false)
    }
}

/// Reveals each glyph after the selected return pass and hands the title to the menu.
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
        var letter_x = 240 - string_width(title) * 2.15 / 2
            + (string_width(string_copy(title, 1, i - 1))
            + string_width(string_char_at(title, i)) * 0.5) * 2.15
        var crossing = funIntroFlightFrameAtX(letter_x)
        var alpha = funIntroEase((frame - crossing) / 9)
        draw_set_color(tint)
        draw_set_alpha(alpha)
        draw_text_transformed(left + string_width(string_copy(title, 1, i - 1)) * scale,
            title_y, string_char_at(title, i), scale, scale, 0)
    }
}

/// Covers preparation frames completely; no audio or animation starts behind them.
function funIntroBlackFrame() {
    draw_set_alpha(1)
    draw_set_color(c_black)
    draw_rectangle(0, 0, 480, 270, false)
    draw_set_color(c_white)
    draw_set_halign(fa_center)
}

/// Draws the selected V08 timeline and returns the chosen menu-controls opacity.
function funStartupIntroDraw() {
    var state = self.startup_intro
    var prepared = funIntroPrepareGraphics()
    if (!state.ready) {
        funIntroBlackFrame()
        if (prepared) state.warm_frames++
        // The first real Draw has already prepared and presented the background before this anchor.
        if (state.warm_frames >= 2) {
            state.ready = true
            state.origin_time = get_timer() + 300000
        }
        return 0
    }
    var frame = state.frame
    if (frame < 0) {
        funIntroBlackFrame()
        return 0
    }
    var seconds = frame / 60
    var forest = 0.12 * funIntroEase((seconds - 0.2) / 2.4926164672586766)
    if (seconds >= 3.125070753118221) forest = lerp(0.12, 1, funIntroEase((seconds - 3.125070753118221) / 0.8))
    draw_set_color(c_black)
    draw_set_alpha(1 - forest)
    draw_rectangle(0, 0, 480, 270, false)
    var ink = make_colour_rgb(235, 224, 188)
    funIntroFlashDraw(frame, ink)
    var light_alpha = funIntroEase((seconds - 0.25) / 0.12)
    if (seconds >= 2.5) light_alpha = 1 - funIntroEase((seconds - 2.5) / 0.35)
    if (prepared) funIntroFireflyDraw(frame, light_alpha, ink)
    var handoff = funIntroEase((seconds - 3.12622716411334) / 0.8)
    funIntroTitle(frame, handoff, ink)
    draw_set_alpha(1)
    draw_set_color(c_white)
    draw_set_halign(fa_center)
    return funIntroEase((seconds - 3.68622716411334) / 0.24)
}
