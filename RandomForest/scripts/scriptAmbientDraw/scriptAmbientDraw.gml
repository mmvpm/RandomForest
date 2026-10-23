/// Draws a soft lowland bank from an existing bloom mask using normal alpha, never additive light.
function funAmbientDrawFog() {
    var weather = self.weather
    var amount = weather.fog * clamp(1 - weather.rain * 40, 0, 1)
    if (amount < 0.005) return;
    var cam = view_camera[0]
    var cx = camera_get_view_x(cam), cy = camera_get_view_y(cam)
    var colour = funCurrentLevelTheme() == "night" ? make_colour_rgb(107, 116, 143) : make_colour_rgb(151, 172, 162)
    // Filter only the enlarged fog mask, preserving native pixel-art sampling.
    var previous_filter = gpu_get_texfilter()
    gpu_set_tex_filter(true)
    for (var i = floor((cx - 180) / 96); i <= ceil((cx + 660) / 96); ++i) {
        var xx = i * 96
        var column = clamp(floor(xx / 12), 0, self.grid_width - 1)
        var floor_y = self.low_floors[column]
        if (floor_y < 0 or floor_y < cy - 50 or floor_y > cy + 370) continue
        var drift = sin(weather.time * 0.12 + i * 2.1) * 12
        var alpha = amount * 0.4
        draw_sprite_ext(sPlayerBloom, 0, xx + drift, floor_y - 10 + sin(weather.time * 0.1 + i) * 3,
            7.6, 1.7, 0, colour, alpha)
        draw_sprite_ext(sPlayerBloom, 0, xx + 36 - drift * 0.5, floor_y - 26,
            5.8, 0.9, 0, colour, alpha * 0.45)
    }
    gpu_set_tex_filter(previous_filter)
}

/// Restores the original five-pixel dandelion head and rising motion at a lower steady density.
function funAmbientDrawSeeds(cx, cy) {
    var weather = self.weather
    if (weather.rain > 0.005 or weather.fog > 0.1) return;
    if (weather.phase != "seeds") return;
    for (var i = 0; i < 28; ++i) {
        var p = weather.seed_points[(10 + i * 13) mod 100]
        var xx = round(cx - 80 + ((p.x + weather.seed_x + sin(weather.time * 1.5 + i) * 8 - cx) mod 640 + 640) mod 640)
        var yy = round(cy - 45 + ((p.y + weather.seed_y - cy) mod 360 + 360) mod 360)
        draw_set_colour(make_colour_rgb(174, 193, 173))
        draw_set_alpha(0.7)
        draw_line(xx - 2, yy - 2, xx + 2, yy - 2)
        draw_point(xx, yy - 3)
        draw_set_alpha(0.4)
        draw_line(xx, yy - 1, xx, yy + 2)
    }
}

/// Selects restrained, non-reward wing colours for all four lighting themes.
function funAmbientMothColour(theme) {
    switch (theme) {
        case "evening": return make_colour_rgb(169, 183, 188)
        case "night": return make_colour_rgb(132, 151, 185)
        case "morning": return make_colour_rgb(169, 183, 188)
        default: return make_colour_rgb(185, 193, 157)
    }
}

/// Draws the resident colonies without glow, reward colours or generated-on-impact insects.
function funAmbientDrawMoths(cx, cy) {
    var theme = funCurrentLevelTheme()
    var colour = funAmbientMothColour(theme)
    var body_colour = merge_colour(colour, make_colour_rgb(40, 63, 75), 0.65)
    if (theme == "evening" or theme == "morning") body_colour = make_colour_rgb(83, 108, 120)
    for (var i = 0; i < array_length(self.nests); ++i) {
        var nest = self.nests[i]
        if (nest.x < cx - 70 or nest.x > cx + 550 or nest.y < cy - 70 or nest.y > cy + 340) continue
        for (var j = 0; j < array_length(nest.moths); ++j) {
            var moth = nest.moths[j]
            if (moth.weather_alpha <= 0) continue
            var xx = round(moth.x), yy = round(moth.y)
            var wing = 1 + (floor(moth.flap) mod 2)
            draw_set_colour(colour)
            draw_set_alpha(0.7 * moth.weather_alpha)
            draw_rectangle(xx - wing, yy, xx - 1, yy + 1, false)
            draw_rectangle(xx + 1, yy, xx + wing, yy + 1, false)
            draw_set_colour(body_colour)
            draw_line(xx, yy, xx, yy + 2)
        }
    }
}

/// Draws bounded water and dust particles below Platforms, including the non-solid black fill.
function funAmbientDrawParticles() {
    for (var i = 0; i < array_length(self.particles); ++i) {
        var p = self.particles[i]
        if (p.age < 0) continue
        var xx = round(p.x), yy = round(p.y)
        var alpha = min(1, (p.life - p.age) / 24)
        draw_set_colour(make_colour_rgb(158, 178, 183))
        draw_set_alpha(alpha * (p.kind == 1 ? 0.45 : 0.7))
        if (p.kind == 0) draw_line(xx, yy - 2, xx, yy)
        if (p.kind == 1) draw_point(xx, yy)
        if (p.kind == 2) {
            var radius = floor(p.age / 4)
            draw_point(xx - radius, yy)
            draw_point(xx + radius, yy)
        }
    }
}

/// Composes the low-cost background effects and restores draw state for native game objects.
function funAmbientDraw() {
    var cam = view_camera[0]
    var cx = camera_get_view_x(cam), cy = camera_get_view_y(cam)
    funAmbientDrawRain(cx, cy)
    funAmbientDrawFog()
    funAmbientDrawSeeds(cx, cy)
    funAmbientDrawParticles()
    funAmbientDrawMoths(cx, cy)
    draw_set_alpha(1)
    draw_set_colour(c_white)
}
