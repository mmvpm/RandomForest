/// Keeps every story room and the staged ending menu free of background sound.
function funAtmosphereSceneKind() {
    if (room == rMenu) {
        if (global.ending_stage == 1) return "silent"
        if (instance_exists(oMenu) and oMenu.startup_intro.active) return "silent"
        return "menu"
    }
    if (room == rLevelSelect) return "menu"
    // Results may live inside the story room; they never start a new background.
    if (instance_exists(oLevelPassing)) return "results"
    if (room == rBlackRoom) return "silent"
    if (instance_exists(oAmbientSystem) and (instance_exists(oPlayer) or instance_exists(oTapController))) return "game"
    return "suspended"
}

/// Uses the displayed menu page, never the furthest unlocked level during replays.
function funAtmosphereSceneTheme(kind) {
    if (kind == "game") return funCurrentLevelTheme()
    return variable_global_exists("menu_audio_theme") ? global.menu_audio_theme : funLevelTheme(global.current_level)
}

/// Uses live weather during gameplay and the displayed clear forest in ordinary menus.
function funAtmosphereSceneGroup(kind, theme) {
    if (kind != "game") return theme
    var phase = global.forest_weather.phase
    return phase == "dry" or phase == "seeds" ? theme : phase
}

/// Debounces browsing only; actual gameplay always selects its own theme immediately.
function funAtmosphereMenuReady(kind, theme, dt) {
    if (kind != "menu" or theme == self.scene_theme or self.scene_theme == "") {
        self.menu_pending_theme = ""
        self.menu_pending_time = 0
        return true
    }
    if (self.menu_pending_theme != theme) {
        self.menu_pending_theme = theme
        self.menu_pending_time = 0
    }
    self.menu_pending_time += dt
    return self.menu_pending_time >= 0.4
}
