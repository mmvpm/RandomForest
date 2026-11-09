/// Starts a bounded stream independent of gameplay RNG and the other ambient particles.
function funAmbientResetRain() {
    self.rain_drops = []
    self.rain_credit = 0
    self.rain_birth_index = 3
}

/// Reuses the first preview's deterministic distribution of newly born droplets.
function funAmbientRainNoise(index) {
    return frac(abs(sin(index * 127.1 + 9 * 311.7) * 43758.5453))
}

/// Restores the first preview's uniform stroke alpha and lifetime fade.
function funAmbientRainAlpha(drop) {
    return min(1, drop.age / 10) * min(1, (drop.life - drop.age) / 25) * drop.alpha
}

/// Gives the first drops uneven pauses, settling into the original continuous rain cadence.
function funAmbientRainBirthCost() {
    var t = min(1,self.weather.rain_onset/0.7)
    var regular = t*t*(3-2*t)
    return lerp(0.45+funAmbientRainNoise(self.rain_birth_index+997)*1.1,1,regular)
}

/// Emits the original fine rain, or a denser downpour built from the same short droplets.
function funAmbientRainEmit() {
    var amount = self.weather.rain * (1 - min(1, self.weather.fog * 4))
    if (amount < 0.005) {self.rain_credit = 0; return;}
    var strength = clamp((amount - 0.5) * 2, 0, 1)
    var rate = amount < 0.5 ? amount * 6 : 3 + strength * 5
    // The quiet first drizzle has room to breathe before the continuous shower arrives.
    self.rain_credit += rate * funWeatherRainDensity(self.weather)
    var birth_cost = funAmbientRainBirthCost()
    var onset = self.weather.rain_onset
    var shape = onset*onset*(3-2*onset)
    var cam = view_camera[0]
    var cx = camera_get_view_x(cam), cy = camera_get_view_y(cam)
    while (self.rain_credit >= birth_cost and array_length(self.rain_drops) < 600) {
        self.rain_credit -= birth_cost
        var xx = cx - 40 + funAmbientRainNoise(self.rain_birth_index) * 570
        self.rain_birth_index += 1
        array_push(self.rain_drops, {x:xx, y:cy - 10, age:0, life:65,
            vy:4.8 + strength * 1.8, height:round(lerp(3,5+round(strength*2),shape)), alpha:0.24 + strength * 0.04})
        birth_cost = funAmbientRainBirthCost()
    }
}

/// Advances actual falling droplets; there is no cyclic field or wrapping pattern.
function funAmbientRainStep() {
    funAmbientRainEmit()
    var vx = clamp(self.weather.wind / 0.18, -1, 1) * 0.6
    for (var i = array_length(self.rain_drops) - 1; i >= 0; --i) {
        var drop = self.rain_drops[i]
        drop.age += 1
        drop.x += vx
        drop.y += drop.vy
        if (drop.age >= drop.life) array_delete(self.rain_drops, i, 1)
    }
}

/// Draws the first preview's one-pixel lines, colour and fade below the platform layer.
function funAmbientDrawRain(cx, cy) {
    if (self.weather.rain < 0.005 or self.weather.fog >= 0.25) return;
    var lean = round(clamp(self.weather.wind / 0.18, -1, 1))
    draw_set_colour(make_colour_rgb(157, 180, 199))
    for (var i = 0; i < array_length(self.rain_drops); ++i) {
        var drop = self.rain_drops[i]
        if (drop.x < cx - 8 or drop.x > cx + 488 or drop.y < cy - 8 or drop.y > cy + 278) continue
        var xx = round(drop.x), yy = round(drop.y)
        draw_set_alpha(funAmbientRainAlpha(drop))
        draw_line(xx, yy, xx - lean, yy - drop.height)
    }
}
