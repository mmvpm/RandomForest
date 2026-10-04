/// Returns configurable presentation metadata for one human-numbered level.
function funCampaignLevelMetadata(level_index) {
	if (!variable_global_exists("campaign_levels_config")) return undefined
	var levels = global.campaign_levels_config.levels
	for (var i = 0; i < array_length(levels); ++i) {
		if (levels[i].level == level_index + 1) return levels[i]
	}
	return undefined
}

/// Returns whether a level participates in records and mastery goals.
function funLevelTracksProgress(level_index) {
	var metadata = funCampaignLevelMetadata(level_index)
	return metadata == undefined or metadata.track_progress
}

/// Returns the level-select label without coupling it to catalog positions.
function funCampaignLevelLabel(level_index) {
	var metadata = funCampaignLevelMetadata(level_index)
	return metadata == undefined ? string(level_index + 1) : metadata.label
}

/// Identifies a page containing only one deliberately isolated story level.
function funIsSpecialLevelPage(page_index, page_size, levels_count) {
	var first = page_index * page_size
	return levels_count - first == 1 and !funLevelTracksProgress(first)
}

/// Reads one intro setting with a fallback for older or absent configuration.
function funCampaignIntroSetting(name, fallback) {
	if (!variable_global_exists("campaign_levels_config")) return fallback
	var intro = global.campaign_levels_config.intro
	return variable_struct_exists(intro, name) ? variable_struct_get(intro, name) : fallback
}

/// Starts the one-time opening before the first playable level.
function funMenuBeginCampaign() {
	if (global.campaign_intro_seen) {
		funOpenLevel(0)
		return
	}
	instance_create_depth(0, 0, -100, oCampaignIntro)
}
