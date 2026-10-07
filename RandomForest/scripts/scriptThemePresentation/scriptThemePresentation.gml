/// Defines approved lighting roles; omitted future roles inherit exact day values.
function __funInitThemePalettes() {
    var day = {
        accent: make_color_rgb(112, 211, 112), selected_border: make_color_rgb(58, 110, 58),
        text: c_ltgray, border: c_ltgray, locked_text: c_dkgray,
        inactive: make_color_rgb(72, 72, 72), locked_border: make_color_rgb(72, 72, 72),
        panel_muted: make_color_rgb(140, 140, 140), movement_fx: make_color_rgb(125, 211, 189)
    }
    var overrides = {
        night: {
            // Smoky Heather: quiet decoration, legible text and a distinct focus border.
            accent: make_color_rgb(177, 169, 190), selected_border: make_color_rgb(159, 148, 169),
            text: make_color_rgb(156, 163, 173), border: make_color_rgb(122, 113, 132),
            locked_text: make_color_rgb(103, 109, 121), inactive: make_color_rgb(44, 49, 58),
            locked_border: make_color_rgb(43, 47, 54), panel_muted: make_color_rgb(136, 143, 153),
            movement_fx: make_color_rgb(179, 184, 240)
        },
        evening: {
            // Blue Hour environment with EV2 light/shadow movement accents.
            accent: make_color_rgb(185, 189, 202), selected_border: make_color_rgb(154, 157, 168),
            text: make_color_rgb(181, 185, 187), border: make_color_rgb(113, 115, 123),
            locked_text: make_color_rgb(110, 116, 120), inactive: make_color_rgb(48, 53, 59),
            locked_border: make_color_rgb(48, 53, 59), panel_muted: make_color_rgb(147, 153, 153),
            movement_fx: make_color_rgb(193, 181, 210)
        },
        morning: {
            // Golden Mist environment with MO1 diffuse movement accents.
            accent: make_color_rgb(218, 211, 177), selected_border: make_color_rgb(181, 175, 147),
            text: make_color_rgb(181, 185, 187), border: make_color_rgb(133, 129, 108),
            locked_text: make_color_rgb(110, 116, 120), inactive: make_color_rgb(48, 53, 59),
            locked_border: make_color_rgb(48, 53, 59), panel_muted: make_color_rgb(147, 153, 153),
            movement_fx: make_color_rgb(187, 211, 147)
        }
    }
    global.theme_palettes = {day: day}
    var names = ["evening", "night", "morning"]
    for (var i = 0; i < array_length(names); ++i) {
        var palette = variable_clone(day)
        var changes = variable_struct_get(overrides, names[i])
        var roles = variable_struct_get_names(changes)
        for (var r = 0; r < array_length(roles); ++r) {
            variable_struct_set(palette, roles[r], variable_struct_get(changes, roles[r]))
        }
        variable_struct_set(global.theme_palettes, names[i], palette)
    }
}

/// Returns cached theme colours, leaving day untouched when no override exists.
function funThemePalette(theme) {
    if (!variable_global_exists("theme_palettes")) __funInitThemePalettes()
    return variable_struct_get(global.theme_palettes, theme)
}

/// Blends role colours with the same normalized weights as the moving background.
function funThemePresentation(theme, weights = undefined) {
    var names = ["day", "evening", "night", "morning"]
    if (weights == undefined) {
        weights = array_create(4, 0)
        weights[__funMenuThemeIndex(theme)] = 1
    }
    var palette = variable_clone(funThemePalette(theme))
    var roles = variable_struct_get_names(palette)
    for (var r = 0; r < array_length(roles); ++r) {
        var red = 0, green = 0, blue = 0
        for (var i = 0; i < 4; ++i) {
            if (weights[i] <= 0) continue
            var color = variable_struct_get(funThemePalette(names[i]), roles[r])
            red += color_get_red(color) * weights[i]
            green += color_get_green(color) * weights[i]
            blue += color_get_blue(color) * weights[i]
        }
        variable_struct_set(palette, roles[r], make_color_rgb(round(red), round(green), round(blue)))
    }
    return {theme: theme, weights: variable_clone(weights), palette: palette}
}

/// Resolves overlays from their host scene, not from the furthest unlocked level.
function funUiScenePresentation() {
    var menu = noone
    if (room == rMenu and instance_exists(oMenu)) menu = instance_find(oMenu, 0)
    if (room == rLevelSelect and instance_exists(oLevelSelect)) menu = instance_find(oLevelSelect, 0)
    if (menu != noone) {
        var state = menu.menu_background
        var names = ["day", "evening", "night", "morning"]
        return funThemePresentation(names[state.target], state.weights)
    }
    var theme = room == rBlackRoom ? funLevelTheme(global.playing_level) : funCurrentLevelTheme()
    return funThemePresentation(theme)
}

/// Applies shared menu roles without changing geometry, focus or input handling.
function funApplyUiPresentation(presentation) {
    self.theme_presentation = presentation
    var palette = presentation.palette
    self.current_color = palette.accent
    self.current_button_color = palette.selected_border
    self.default_color = palette.text
    self.default_button_color = palette.border
    self.locked_color = palette.locked_text
    self.locked_button_color = palette.locked_border
}

/// Keeps legacy magic in step with the current body skin inside the black room.
function funVisualEffectTheme() {
    if (room == rBlackRoom and instance_exists(oPlayer) and oPlayer.is_dark) return "night"
    if (room == rBlackRoom) return funLevelTheme(global.playing_level)
    return funCurrentLevelTheme()
}

/// Draws an optional effect sibling without altering masks or animation callbacks.
function funDrawThemeEffectSelf() {
    draw_sprite_ext(funThemeSprite(self.sprite_index, funVisualEffectTheme()), self.image_index,
        self.x, self.y, self.image_xscale, self.image_yscale, self.image_angle, self.image_blend, self.image_alpha)
}
