/// Reads the complete contents of a text file.
function funReadGeneratedLevelFile(file_path) {
	var file = file_text_open_read(file_path)
	if (file == -1) {
		show_error("Generated level file cannot be opened: " + file_path, true)
	}

	var contents = ""
	while (!file_text_eof(file)) {
		contents += file_text_readln(file)
		if (!file_text_eof(file)) {
			contents += "\n"
		}
	}
	file_text_close(file)

	return contents
}

/// Returns a level from the current provider.
function funGenerateLevel(request) {
	var json_text = funReadGeneratedLevelFile(request.level_path)
	var level_data = json_parse(json_text)
	return funDecodeGeneratedLevelMap(level_data)
}
