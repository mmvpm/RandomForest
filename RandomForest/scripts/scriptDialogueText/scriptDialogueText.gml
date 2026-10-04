/// Expands the two supported progress placeholders before measuring text.
function funExpandDialogueText(text, progress) {
	text = string_replace_all(text, "{collected}", string(progress.collected))
	return string_replace_all(text, "{after_level}", string(progress.after_level))
}

/// Removes color tags while retaining one color per visible Unicode character.
function funParseDialogueText(text) {
	var letters = []
	var colour = c_ltgray
	var orange = ORANGE_FIREFLY_COLOUR
	var position = 1
	while (position <= string_length(text)) {
		if (string_copy(text, position, 8) == "[orange]") {
			colour = orange
			position += 8
		}
		else if (string_copy(text, position, 9) == "[/orange]") {
			colour = c_ltgray
			position += 9
		}
		else {
			var letter = string_char_at(text, position)
			array_push(letters, {letter: letter, colour: colour, width: string_width(letter)})
			++position
		}
	}
	return letters
}
