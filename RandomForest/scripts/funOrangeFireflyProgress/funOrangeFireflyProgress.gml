#macro ORANGE_FIREFLY_SPAWN_CHANCE 0.30
#macro ORANGE_FIREFLY_COLOUR make_color_rgb(255, 100, 0)
#macro ORANGE_FIREFLY_GLOW_COLOUR make_color_rgb(255, 106, 50)
#macro ORANGE_FIREFLY_UI_COLOUR make_color_rgb(242, 140, 58)
#macro ORANGE_FIREFLY_ICON_COLOUR make_color_rgb(214, 160, 108)

/// Returns the total number of orange fireflies collected across all levels.
function funGetOrangeFireflyCount() {
	var collected_count = 0
	for (
		var level_index = 0;
		level_index < array_length(global.orange_firefly_records);
		++level_index
	) {
		collected_count += global.orange_firefly_records[level_index]
	}
	return collected_count
}
