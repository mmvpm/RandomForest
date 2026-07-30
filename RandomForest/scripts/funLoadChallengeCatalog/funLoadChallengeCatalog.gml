#macro CHALLENGE_CATALOG_PATH "challenge_levels/catalog.json"

/// Loads the ordered list of bundled challenge level paths.
function funLoadChallengeCatalog() {
	var json_text = funReadGeneratedLevelFile(CHALLENGE_CATALOG_PATH)
	return json_parse(json_text)
}
