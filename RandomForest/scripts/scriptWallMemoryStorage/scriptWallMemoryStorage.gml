/// Returns an empty read state for damaged JSON without interrupting game loading.
function funWallMemoryParseReadState(text) {
    try {
        var state = json_parse(text)
        if (is_struct(state)) return state
    } catch (error) {
        // A broken inscription record must not prevent loading the other progress.
    }
    return {}
}

/// Recovers the complete legacy JSON before INI parsing truncates embedded quotes.
function funWallMemoryReadLegacyState() {
    if (!file_exists("save.ini")) return {}
    var file = file_text_open_read("save.ini"), inside_section = false, text = "{}"
    while (!file_text_eof(file)) {
        var line = string_trim(file_text_read_string(file))
        file_text_readln(file)
        if (string_char_at(line, 1) == "[") inside_section = line == "[wall_memories]"
        if (!inside_section) continue
        var separator = string_pos("=", line)
        if (separator <= 0 or string_trim(string_copy(line, 1, separator - 1)) != "read") continue
        text = string_trim(string_delete(line, 1, separator))
        // Remove only the INI wrapper; JSON's own quotes remain intact.
        if (string_char_at(text, 1) == "\"" and string_char_at(text, string_length(text)) == "\"") {
            text = string_copy(text, 2, string_length(text) - 2)
        }
        break
    }
    file_text_close(file)
    return funWallMemoryParseReadState(text)
}

/// Loads the quoted-safe encoding, or migrates an existing plain-JSON save.
function funLoadWallMemoryReadState() {
    if (!ini_key_exists("wall_memories", "read_base64")) return funWallMemoryReadLegacyState()
    try {
        return funWallMemoryParseReadState(base64_decode(ini_read_string("wall_memories", "read_base64", "")))
    } catch (error) {
        return {}
    }
}

/// Encodes JSON before INI storage so embedded quotes survive the next launch.
function funSaveWallMemoryReadState() {
    ini_write_string("wall_memories", "read_base64", base64_encode(json_stringify(global.wall_memory_read)))
    ini_key_delete("wall_memories", "read")
}
