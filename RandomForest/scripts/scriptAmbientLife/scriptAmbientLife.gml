/// Initializes bounded room-local ecology; weather belongs to the session instead.
function funAmbientCreate() {
    self.weather = funWeatherSession()
    funWeatherApplyTheme(self.weather,funCurrentLevelTheme())
    if (!instance_exists(oWeatherAudio)) instance_create_depth(0, 0, 0, oWeatherAudio)
    with (oWeatherAudio) funWeatherAudioEnterLevel()
    self.local_random = {seed: max(1, (floor(self.weather.seed) + room_width * 71 + room_height * 17) mod 2147483647)}
    self.particles = []
    funAmbientResetRain()
    self.nests = []
    self.drip_timer = 0
    self.impact_cooldown = 0
    funAmbientCacheTerrain()
    funAmbientBuildMoths()
}

/// Creates only authored colonies; absent metadata means no moths on that map.
function funAmbientBuildMoths() {
    if (room != rGeneratedLevel) return;
    var level = global.generated_level_data
    if (!variable_struct_exists(level, "moth_nests")) return;
    for (var i = 0; i < min(3, array_length(level.moth_nests)); ++i) {
        var anchor = level.moth_nests[i]
        var nest = {x:anchor.x, y:anchor.y, radius:65, moths:[]}
        if (variable_struct_exists(anchor, "radius")) nest.radius = clamp(anchor.radius, 36, 80)
        var count = variable_struct_exists(anchor, "count") ? clamp(floor(anchor.count), 18, 36) : 30
        for (var j = 0; j < count; ++j) {
            var phase = funWeatherRandom(self.local_random) * pi * 2
            var xx = nest.x, yy = nest.y
            // Preserve the first cloud's broad silhouette, sampling only visible air.
            for (var attempt = 0; attempt < 12; ++attempt) {
                xx = nest.x + (funWeatherRandom(self.local_random) * 2 - 1) * nest.radius
                yy = nest.y + (funWeatherRandom(self.local_random) * 2 - 1) * nest.radius * 45 / 130
                if (funAmbientTileAtPixel(xx, yy) == 0) break
                xx = nest.x; yy = nest.y
            }
            array_push(nest.moths, {x:xx, y:yy, home_x:xx, home_y:yy,
                vx:0, vy:0, phase:phase, flap:funWeatherRandom(self.local_random) * 10,
                weather_alpha:funWeatherMothInitial(self.weather,j)})
        }
        array_push(self.nests, nest)
    }
}

/// Advances a colony's independent wander, short escape and unhurried return home.
function funAmbientMothsStep() {
    var cam = view_camera[0]
    var cx = camera_get_view_x(cam) + 240
    var cy = camera_get_view_y(cam) + 135
    var player = instance_find(oPlayer, 0)
    var sword = instance_find(oPlayerTapSword, 0)
    var dt = 1 / game_get_speed(gamespeed_fps)
    for (var i = 0; i < array_length(self.nests); ++i) {
        var nest = self.nests[i]
        var in_view = abs(nest.x-cx) <= 330 and abs(nest.y-cy) <= 225
        for (var j = 0; j < array_length(nest.moths); ++j) {
            var moth = nest.moths[j]
            funWeatherMothVisibility(self.weather,moth,j,dt)
            if (!in_view or moth.weather_alpha <= 0) continue
            var tx = moth.home_x + sin(self.weather.time * 1.08 + moth.phase) * 18
            var ty = moth.home_y + cos(self.weather.time * 1.26 + moth.phase) * 10
            if (player != noone) {
                var dx = moth.x - player.x
                var dy = moth.y - (player.y - 7)
                if (dx * dx + dy * dy < 35 * 35) { tx += dx * 1.2; ty -= 18; }
            }
            if (sword != noone) {
                var dx = moth.x - sword.x
                var dy = moth.y - sword.y
                if (dx * dx + dy * dy < 60 * 60) { tx += dx * 1.5; ty -= 18; }
            }
            moth.vx = clamp(moth.vx * 0.91 + (tx - moth.x) * 0.008, -1.5, 1.5)
            moth.vy = clamp(moth.vy * 0.91 + (ty - moth.y) * 0.008, -1.1, 1.1)
            if (funAmbientTileAtPixel(moth.x + moth.vx * 2, moth.y + moth.vy * 2) == 0) {
                moth.x += moth.vx
                moth.y += moth.vy
            } else {
                moth.vx *= -0.4
                moth.vy *= -0.4
            }
            moth.flap += 0.2
        }
    }
}

/// Caps water and dust at 160 lightweight records, including several stronger impacts.
function funAmbientAddParticle(kind, xx, yy, vx, vy, life) {
    if (array_length(self.particles) >= 160) return;
    var delay = kind == 1 ? floor(funWeatherRandom(self.local_random) * 16) : 0
    array_push(self.particles, {kind:kind, x:xx, y:yy, vx:vx, vy:vy, age:-delay, life:life})
}

/// Samples a few cached ceiling points instead of scanning the level each frame.
function funAmbientDripStep() {
    if (self.weather.wetness < 0.06) return;
    if (self.weather.target_rain > 0 or self.weather.rain >= 0.005) return;
    if (self.weather.phase != "drips") return;
    self.drip_timer -= 1
    if (self.drip_timer > 0 or array_length(self.ceilings) == 0) return;
    self.drip_timer = 16 + floor(funWeatherRandom(self.local_random) * 30)
    var cam = view_camera[0]
    var cx = camera_get_view_x(cam), cy = camera_get_view_y(cam)
    var start = floor(funWeatherRandom(self.local_random) * array_length(self.ceilings))
    for (var i = 0; i < 20; ++i) {
        var point = self.ceilings[(start + i * 13) mod array_length(self.ceilings)]
        if (point.x < cx or point.x > cx + 480 or point.y < cy or point.y > cy + 230) continue
        if (funAmbientTileAtPixel(point.x, point.y + 2) != 0) continue
        funAmbientAddParticle(0, point.x, point.y + 2, self.weather.wind * 0.03, 0.05, 150)
        break
    }
}

/// Updates only active dust and droplets using the visual tile cache for impact.
function funAmbientParticlesStep() {
    for (var i = array_length(self.particles) - 1; i >= 0; --i) {
        var p = self.particles[i]
        p.age += 1
        if (p.age < 0) continue
        if (p.kind == 0) p.vy = min(2.8, p.vy + 0.06)
        if (p.kind == 1) p.vx += self.weather.wind * 0.0005
        var next_y = p.y + p.vy
        if (p.kind < 2 and funAmbientTileAtPixel(p.x + p.vx, next_y) != 0) {
            if (p.kind == 0) {
                p.kind = 2
                p.y = floor(next_y / 12) * 12 - 1
                p.vx = 0; p.vy = 0; p.age = 0; p.life = 14
            } else p.life = p.age
        } else { p.x += p.vx; p.y = next_y; }
        if (p.age >= p.life) array_delete(self.particles, i, 1)
    }
}

/// Advances weather and visible ecology with fixed population limits and no room-wide searches.
function funAmbientStep() {
    funWeatherUpdate(self.weather, 1 / game_get_speed(gamespeed_fps))
    funAmbientRainStep()
    self.impact_cooldown = max(0, self.impact_cooldown - 1)
    funAmbientDripStep()
    funAmbientParticlesStep()
    funAmbientMothsStep()
}
