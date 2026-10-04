/// Returns the shared visual and navigation center of one level-select control.
function funLevelSelectButtonCenter(button_index) {
	if (button_index == 0 and funIsSpecialLevelPage(self.page_index, self.page_size, self.levels_count)) {
		return {x: 240, y: 136}
	}
	return {x: self.button_x[button_index], y: self.button_y[button_index]}
}

/// Finds the closest enabled control in one arrow direction on an isolated story page.
function funMoveSpecialLevelSelection(direction_x, direction_y) {
	var origin = funLevelSelectButtonCenter(self.current_index)
	var best_index = self.current_index
	var best_distance = 1000000
	for (var i = 0; i < self.buttons_count; ++i) {
		if (i == self.current_index or !__funLevelButtonIsEnabled(i)) continue
		var center = funLevelSelectButtonCenter(i)
		var dx = center.x - origin.x
		var dy = center.y - origin.y
		var forward = dx * direction_x + dy * direction_y
		if (forward <= 0) continue
		var sideways = abs(dx * direction_y - dy * direction_x)
		var distance = forward + sideways * 2
		if (distance < best_distance) {
			best_distance = distance
			best_index = i
		}
	}
	__funSelectLevelButton(best_index)
}
