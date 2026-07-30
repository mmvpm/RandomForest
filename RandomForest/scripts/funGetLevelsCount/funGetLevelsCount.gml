#macro CAMPAIGN_LEVELS_COUNT 10

/// Returns the number of campaign and bundled generated levels.
function funGetLevelsCount() {
	return CAMPAIGN_LEVELS_COUNT + array_length(funLoadChallengeCatalog().levels)
}
