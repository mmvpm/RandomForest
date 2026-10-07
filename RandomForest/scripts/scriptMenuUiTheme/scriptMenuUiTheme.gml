/// Keeps Copper Evening menu roles separate from the Blue Hour game palette.
function funCopperMenuPalette() {
    if (!variable_global_exists("copper_menu_palette")) {
        var palette = variable_clone(funThemePalette("evening"))
        palette.accent = make_color_rgb(211, 176, 153)
        palette.selected_border = make_color_rgb(175, 146, 127)
        palette.border = make_color_rgb(129, 107, 93)
        global.copper_menu_palette = palette
    }
    return global.copper_menu_palette
}

/// Selects menu-only copper artwork while all other draw paths keep their art.
function funMenuUiSprite(sprite, theme, menu_ui) {
    if (menu_ui and theme == "evening") {
        switch (sprite) {
            case sStar: return sStarMenuEvening
            case sBorder3: return sBorder3MenuEvening
            case sBorder4: return sBorder4MenuEvening
        }
    }
    return funThemeSprite(sprite, theme)
}
