/// Uses the lighting palette while retaining the original movement-effect shape.
var theme = funVisualEffectTheme()
var color = funThemePalette(theme).movement_fx
var alpha = 150.0 / 255.0
draw_sprite_ext(funThemeSprite(sPlayerJumpEffect, theme), self.image_index, self.x, self.y, 0.8, 0.8, 0, color, alpha)
