/// Maps theme names to the four stable background cache slots.
function __funMenuThemeIndex(theme) {
    switch (theme) {
        case "evening": return 1
        case "night": return 2
        case "morning": return 3
    }
    return 0
}

/// Creates room-owned surfaces and restores CPU-only menu motion and blend state.
function funMenuBackgroundCreate(level_index) {
    var cam = view_camera[0]
    var max_x = sprite_get_width(sBackground_x13) - camera_get_view_width(cam)
    var max_y = sprite_get_height(sBackground_x13) - camera_get_view_height(cam)
    var target = __funMenuThemeIndex(funLevelTheme(level_index))
    var state
    if (variable_global_exists("menu_background_motion")) {
        state = variable_clone(global.menu_background_motion)
    } else {
        var vx = choose(-0.1, 0.1)
        state = {x: random_range(0, max_x), y: random_range(0, max_y),
            vx: vx, vy: choose(-1, 1) * vx * camera_get_view_height(cam) / camera_get_view_width(cam),
            weights: array_create(4, 0), from_weights: array_create(4, 0), target: target, frame: 30}
    }
    state.max_x = max(0, max_x)
    state.max_y = max(0, max_y)
    state.x = clamp(state.x, 0, state.max_x)
    state.y = clamp(state.y, 0, state.max_y)
    var handoff = variable_global_exists("menu_background_handoff") and global.menu_background_handoff
    global.menu_background_handoff = false
    // Gameplay entry must immediately show the newly unlocked level's theme.
    if (!handoff) {
        state.weights = array_create(4, 0)
        state.weights[target] = 1
        state.from_weights = variable_clone(state.weights)
        state.target = target
        state.frame = 30
    }
    self.menu_background = state
    self.menu_background_surfaces = array_create(4, noone)
    funMenuBackgroundSetTheme(funLevelTheme(level_index))
}

/// Retargets from the currently visible mixture, even during another transition.
function funMenuBackgroundSetTheme(theme) {
    var state = self.menu_background
    var target = __funMenuThemeIndex(theme)
    if (state.target == target) return;
    state.from_weights = variable_clone(state.weights)
    state.target = target
    state.frame = 0
}

/// Advances camera drift and a thirty-frame smooth crossfade independently.
function funMenuBackgroundStep() {
    var state = self.menu_background
    var next_x = state.x + state.vx
    var next_y = state.y + state.vy
    state.x = clamp(next_x, 0, state.max_x)
    state.y = clamp(next_y, 0, state.max_y)
    if (state.x != next_x) state.vx *= -1
    if (state.y != next_y) state.vy *= -1
    state.frame = min(30, state.frame + 1)
    var t = state.frame / 30
    t = t * t * (3 - 2 * t)
    for (var i = 0; i < 4; ++i) {
        state.weights[i] = lerp(state.from_weights[i], i == state.target ? 1 : 0, t)
    }
}

/// Lazily builds a blurred opaque image and recovers a lost GPU surface.
function __funMenuBackgroundSurface(index) {
    var cached = self.menu_background_surfaces[index]
    if (surface_exists(cached)) return cached
    var themes = ["day", "evening", "night", "morning"]
    var sprite = funThemeBackground(themes[index])
    var width = sprite_get_width(sprite)
    var height = sprite_get_height(sprite)
    var source = surface_create(width, height)
    surface_set_target(source)
    draw_clear_alpha(c_black, 1)
    draw_set_color(c_white)
    draw_set_alpha(1)
    draw_sprite(sprite, 0, 0, 0)
    surface_reset_target()
    cached = funBlurSurface(source, 10, width, height, 1, 4, 0, 0, 0, 0.2)
    surface_free(source)
    self.menu_background_surfaces[index] = cached
    return cached
}

/// Blends opaque images over black with normalized weights, avoiding fade dips.
function funMenuBackgroundDraw(alpha = 1) {
    gpu_set_tex_filter(true)
    draw_set_alpha(1)
    draw_set_color(c_black)
    var cam = view_camera[0]
    draw_rectangle(0, 0, camera_get_view_width(cam), camera_get_view_height(cam), false)
    var state = self.menu_background
    // Blur renders into temporary targets, so prepare caches before blending.
    for (var i = 0; i < 4; ++i) {
        if (state.weights[i] > 0) __funMenuBackgroundSurface(i)
    }
    draw_set_color(c_white)
    gpu_set_blendmode(bm_add)
    for (var i = 0; i < 4; ++i) {
        if (state.weights[i] <= 0) continue
        draw_set_alpha(alpha * state.weights[i])
        draw_surface(self.menu_background_surfaces[i], -state.x, -state.y)
    }
    gpu_set_blendmode(bm_normal)
    draw_set_alpha(1)
    draw_set_color(c_white)
    gpu_set_tex_filter(false)
}

/// Saves CPU-only state and frees every background surface when a menu closes.
function funMenuBackgroundCleanup() {
    global.menu_background_motion = variable_clone(self.menu_background)
    for (var i = 0; i < 4; ++i) {
        var cached = self.menu_background_surfaces[i]
        if (surface_exists(cached)) surface_free(cached)
        self.menu_background_surfaces[i] = noone
    }
}
