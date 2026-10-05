/// Hashes Unicode codepoints locally, without touching gameplay random state.
function funWallMemoryHash(value) {
    var result = 0
    for (var i = 1; i <= string_length(value); ++i) {
        result = (result * 31 + ord(string_char_at(value, i))) mod 2147483647
    }
    return result
}

/// Checks only records strictly before the current human-numbered level.
function funWallMemoryAllPrevious(level_number, records) {
    for (var i = 0; i < level_number - 1; ++i) {
        if (i >= array_length(records) or !records[i]) return false
    }
    return true
}

/// Tests the authored range, memory threshold, and optional final-level condition.
function funWallMemoryPhraseEligible(phrase, level_number, collected, all_previous) {
    return phrase.from_level <= level_number and phrase.to_level >= level_number
        and phrase.min_collected <= collected
        and (!variable_struct_exists(phrase, "requires_all_previous")
            or !phrase.requires_all_previous or all_previous)
}

/// Selects one fixed or deterministic unused phrase in configuration order.
function funWallMemorySelectPhrase(level_number, anchor_id, collected, all_previous, used_ids, text_id) {
    var candidates = []
    var phrases = global.wall_memory_config.phrases
    for (var i = 0; i < array_length(phrases); ++i) {
        var phrase = phrases[i]
        if (!funWallMemoryPhraseEligible(phrase, level_number, collected, all_previous)) continue
        if (array_contains(used_ids, phrase.id)) continue
        if (text_id != "") {
            if (phrase.id == text_id) return phrase
        } else {
            array_push(candidates, phrase)
        }
    }
    // Fixed story text must disappear when its condition fails, rather than change meaning.
    if (text_id != "" or array_length(candidates) == 0) return undefined
    var seed = string(level_number) + ":" + anchor_id + ":" + string(collected)
    return candidates[funWallMemoryHash(seed) mod array_length(candidates)]
}

/// Returns the lighting palette without depending on which levels already exist.
function funWallMemoryTheme(level_number) {
    if (level_number <= 20) return "day"
    if (level_number <= 30) return "evening"
    if (level_number <= 40) return "night"
    return "morning"
}

/// Assigns stable, non-repeating phrases after every room anchor has run Create.
function funWallMemoryAssignAnchors(controller) {
    var anchors = []
    for (var i = 0; i < instance_number(oWallMemoryAnchor); ++i) array_push(anchors, instance_find(oWallMemoryAnchor, i))
    array_sort(anchors, function(a, b) {
        if (a.anchor_id == b.anchor_id) return 0
        return a.anchor_id < b.anchor_id ? -1 : 1
    })
    var used_ids = []
    for (var i = 0; i < array_length(anchors); ++i) {
        var anchor = anchors[i]
        var phrase = undefined
        if (anchor.role == "missing_previous") {
            if (!controller.all_previous) {
                phrase = {id: "__missing_previous", text: global.wall_memory_config.special.text}
            }
        } else {
            phrase = funWallMemorySelectPhrase(controller.level_number, anchor.anchor_id, controller.collected,
                controller.all_previous, used_ids, anchor.text_id)
            if (phrase != undefined) array_push(used_ids, phrase.id)
        }
        if (phrase != undefined) {
            funWallMemoryPrepareAnchor(anchor, phrase, controller)
        }
    }
    controller.anchors = anchors
    controller.ready = true
}
