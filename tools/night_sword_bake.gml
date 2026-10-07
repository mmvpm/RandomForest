/// Builds a two-row nearest-sampled colour table from the supplied reference palette.
function funSwordLookup(job) {
    var lookup = surface_create(256, 2)
    surface_set_target(lookup)
    draw_clear_alpha(c_black, 1)
    for (var i = 0; i < array_length(job.colors); ++i) {
        for (var row = 0; row < 2; ++row) {
            var rgb = job.colors[i][row]
            draw_set_color(make_color_rgb(rgb[0], rgb[1], rgb[2]))
            draw_point(i, row)
        }
    }
    draw_set_color(c_white)
    surface_reset_target()
    return lookup
}

/// Copies alpha exactly while replacing only opaque/partly opaque RGB bytes.
function funSwordBakeFrame(job) {
    var image = sprite_add(job.input, 1, false, false, 0, 0)
    var lookup = funSwordLookup(job)
    var output = surface_create(sprite_get_width(image), sprite_get_height(image))
    surface_set_target(output)
    draw_clear_alpha(c_black, 0)
    shader_set(shSwordColorBake)
    texture_set_stage(shader_get_sampler_index(shSwordColorBake, "u_lookup"), surface_get_texture(lookup))
    shader_set_uniform_f(shader_get_uniform(shSwordColorBake, "u_count"), array_length(job.colors))
    draw_sprite(image, 0, 0, 0)
    shader_reset()
    surface_reset_target()
    surface_save(output, job.output)
    surface_free(output)
    surface_free(lookup)
    sprite_delete(image)
}

/// Shows source diagonal, day geometry and final night colour with separate non-colliding glow.
function funSwordPreview(data) {
    var background = sprite_add(data.background, 1, false, false, 0, 0)
    var day = sprite_add(data.jobs[0].input, 1, false, false, data.sword_origin[0], data.sword_origin[1])
    var night = sprite_add(data.jobs[0].output, 1, false, false, data.sword_origin[0], data.sword_origin[1])
    var glow = sprite_add(data.jobs[1].output, 1, false, false, data.bloom_origin[0], data.bloom_origin[1])
    var reference = sprite_add(data.reference, 1, false, false, 13, 13)
    var output = surface_create(960, 260)
    surface_set_target(output)
    draw_clear_alpha(make_color_rgb(19, 25, 33), 1)
    draw_set_font(global.default_font_24)
    draw_set_halign(fa_left)
    draw_set_valign(fa_top)
    var labels = ["Дневной силуэт", "Ночная диагональ", "Ночной вправо"]
    for (var i = 0; i < 3; ++i) {
        draw_sprite_stretched(background, 0, i*320, 40, 320, 220)
        draw_set_color(make_color_rgb(220, 215, 230))
        draw_text(i*320 + 16, 5, labels[i])
    }
    draw_set_color(c_white)
    draw_sprite_ext(day, 0, 72, 150, 8, 8, 0, c_white, 1)
    draw_sprite_ext(reference, 0, 480, 150, 6, 6, 0, c_white, 1)
    draw_sprite_ext(night, 0, 712, 150, 8, 8, 0, c_white, 1)
    gpu_set_blendmode(bm_add)
    draw_sprite_ext(glow, 0, 712, 150, 8, 8, 0, c_white, 1)
    gpu_set_blendmode(bm_normal)
    surface_reset_target()
    surface_save(output, data.preview)
    surface_free(output)
    sprite_delete(background)
    sprite_delete(day)
    sprite_delete(night)
    sprite_delete(glow)
    sprite_delete(reference)
}

/// Renders native outputs in a save-disabled copy, not in a running user game.
function funNightSwordBake() {
    if (!shader_is_compiled(shSwordColorBake)) show_error("Sword shader failed", true)
    var file = file_text_open_read("night-sword.json")
    var data = json_parse(file_text_readln(file))
    file_text_close(file)
    gpu_set_tex_filter(false)
    gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero)
    for (var i = 0; i < array_length(data.jobs); ++i) funSwordBakeFrame(data.jobs[i])
    gpu_set_blendmode(bm_normal)
    funSwordPreview(data)
    show_debug_message("NIGHT_SWORD_BAKE_PASS")
    game_end()
}
