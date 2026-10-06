/// Shares the background's current palette and crossfade weights.
funApplyUiPresentation(funUiScenePresentation())
/// Draws one settings row and caches its mouse bounds.
function __funDrawSettingRow(
	item_index,
	y_pos,
	width,
	height,
	left_text,
	right_text = ""
) {
	var selected = item_index == self.current_index
	var ui_scale = selected ? 1 : 0.9
	var text_color = selected ? self.current_color : self.default_color
	var button_color = (
		selected
		? self.current_button_color
		: self.default_button_color
	)
	var x_pos = 240
	var draw_width = width * ui_scale
	var draw_height = height * ui_scale
	var x_left = x_pos - draw_width / 2
	var y_top = y_pos - draw_height / 2

	funDrawUiPanel(
		self.border_sprite,
		0,
		x_left,
		y_top,
		draw_width,
		draw_height,
		button_color,
		1, self.theme_presentation
	)
	self.x_left_cached[item_index] = x_left
	self.y_top_cached[item_index] = y_top
	self.x_right_cached[item_index] = x_left + draw_width
	self.y_bottom_cached[item_index] = y_top + draw_height

	draw_set_color(text_color)
	var label_scale = ui_scale * self.text_scale
	if (right_text == "") {
		draw_set_halign(fa_center)
		draw_text_transformed(
			x_pos,
			y_pos,
			left_text,
			label_scale,
			label_scale,
			0
		)
		return
	}

	draw_set_halign(fa_left)
	draw_text_transformed(
		x_left + 18,
		y_pos,
		left_text,
		label_scale,
		label_scale,
		0
	)
	draw_set_halign(fa_right)
	draw_text_transformed(
		x_left + draw_width - 18,
		y_pos,
		right_text,
		label_scale,
		label_scale,
		0
	)
}

gpu_set_tex_filter(false)
draw_set_font(global.default_font_24)
draw_set_valign(fa_middle)
draw_set_halign(fa_center)
draw_set_color(c_white)
draw_text_transformed(242, 30, "Random Forest", 2, 2, 0)

__funDrawSettingRow(
	0,
	self.row_y[0],
	self.toggle_width,
	self.toggle_height,
	"Музыка",
	global.music_enabled ? "Вкл" : "Выкл"
)
__funDrawSettingRow(
	1,
	self.row_y[1],
	self.toggle_width,
	self.toggle_height,
	"Звуки",
	global.sfx_enabled ? "Вкл" : "Выкл"
)
__funDrawSettingRow(
	2,
	self.row_y[2],
	self.back_width,
	self.back_height,
	"Назад"
)

draw_set_halign(fa_center)
draw_set_color(c_white)
draw_set_alpha(1)
