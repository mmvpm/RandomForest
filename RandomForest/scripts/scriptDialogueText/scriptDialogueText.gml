/// Expands the two supported progress placeholders before measuring text.
function funExpandDialogueText(text, progress) {
	text = string_replace_all(text, "{collected}", string(progress.collected))
	text = string_replace_all(text, "{deaths}", string(progress.deaths))
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
			array_push(letters, {letter: letter, colour: colour, width: funDialogueCharacterWidth(letter)})
			++position
		}
	}
	return letters
}

/// Keeps the approved letter spacing; only dialogue word spaces gain two game pixels.
function funDialogueCharacterWidth(letter) {
    return string_width(letter) + (letter == " " ? 2 : 0)
}

/// Applies the same word spacing to the speaker and continuation hint.
function funDrawDialogueLabel(text, x_pos, y_pos, align_right = false) {
    var width = 0
    for (var i = 1; i <= string_length(text); ++i)
        width += funDialogueCharacterWidth(string_char_at(text, i))
    if (align_right) x_pos -= width
    var previous_align = draw_get_halign()
    draw_set_halign(fa_left)
    for (var i = 1; i <= string_length(text); ++i) {
        var letter = string_char_at(text, i)
        draw_text(x_pos, y_pos, letter)
        x_pos += funDialogueCharacterWidth(letter)
    }
    draw_set_halign(previous_align)
}
