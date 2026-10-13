/// Adds a faint eye-colour tint only to the dark sword's separate halo.
if (instance_exists(self.following) and self.following.sprite_index == sPlayerDarkTapSword) {
    // Mix just 40% of the night player's pink eyes (255, 120, 250) into white.
    var glow_color = merge_color(self.image_blend, make_color_rgb(255, 120, 250), 0.40)
    draw_sprite_ext(funThemeSprite(self.sprite_index, funVisualEffectTheme()), self.image_index,
        self.x, self.y, self.image_xscale, self.image_yscale, self.image_angle, glow_color, self.image_alpha)
} else {
    funDrawThemeEffectSelf()
}
