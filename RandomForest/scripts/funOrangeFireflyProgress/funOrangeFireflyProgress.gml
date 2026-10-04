#macro ORANGE_FIREFLY_SPAWN_CHANCE 0.30
#macro ORANGE_FIREFLY_COLOUR make_color_rgb(255, 100, 0)
#macro ORANGE_FIREFLY_GLOW_COLOUR make_color_rgb(255, 106, 50)
#macro ORANGE_FIREFLY_CORE_SCALE 0.25
#macro ORANGE_FIREFLY_GLOW_SCALE 1.56
#macro ORANGE_FIREFLY_GLOW_ALPHA 0.50
#macro ORANGE_FIREFLY_BODY_ALPHA 0.95
#macro ORANGE_FIREFLY_HIGHLIGHT_COLOUR make_color_rgb(255, 196, 96)
#macro ORANGE_FIREFLY_HIGHLIGHT_ALPHA 0.65
#macro ORANGE_FIREFLY_MENU_COLOUR make_color_rgb(221, 148, 82)

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
