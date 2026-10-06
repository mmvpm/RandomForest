/// Uses the lighting palette while retaining the original landing-effect shape.
var theme = funVisualEffectTheme()
var color = funThemePalette(theme).movement_fx
var alpha = 150.0 / 255.0
draw_sprite_ext(funThemeSprite(sPlayerLandingEffect, theme), self.image_index, self.x, self.y, 0.7, 0.5, 0, color, alpha)
