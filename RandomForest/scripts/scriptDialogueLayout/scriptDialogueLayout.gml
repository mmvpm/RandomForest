/// Lays out the complete line before typing, with word wrap and four-row pages.
function funLayoutDialogue(letters, width, line_height, rows_per_page) {
	var pages = []
	var glyphs = []
	var row = 0
	var x_pos = 0
	var position = 0
	while (position < array_length(letters)) {
		var letter = letters[position]
		var newline = letter.letter == "\n"
		var word_width = 0
		if (!newline and letter.letter != " ") {
			for (var w = position; w < array_length(letters); ++w) {
				if (letters[w].letter == " " or letters[w].letter == "\n") {
					break
				}
				word_width += letters[w].width
			}
		}
		var starts_word = position == 0
			or letters[position - 1].letter == " " or letters[position - 1].letter == "\n"
		if (newline or (x_pos > 0 and ((starts_word and word_width > width - x_pos)
			or letter.width > width - x_pos))) {
			x_pos = 0
			++row
		}
		if (row >= rows_per_page) {
			array_push(pages, {glyphs: glyphs, rows: rows_per_page})
			glyphs = []
			row = 0
		}
		if (!newline and !(x_pos == 0 and letter.letter == " ")) {
			array_push(glyphs, {
				letter: letter.letter, colour: letter.colour,
				x: x_pos, y: row * line_height,
			})
			x_pos += letter.width
		}
		++position
	}
	array_push(pages, {glyphs: glyphs, rows: row + 1})
	return pages
}
