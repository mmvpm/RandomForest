/// Hashes a stable place key without consuming gameplay randomness.
function funWallMemoryHash(value) {
    var result = 0
    for (var i = 1; i <= string_length(value); ++i) {
        result = (result * 31 + ord(string_char_at(value, i))) mod 2147483647
    }
    return result
}

/// Checks records strictly before the current human-numbered level.
function funWallMemoryAllPrevious(level_number, records) {
    for (var i = 0; i < level_number - 1; ++i) {
        if (i >= array_length(records) or !records[i]) return false
    }
    return true
}

/// Tests one fixed inscription against the room-entry progress snapshot.
function funWallMemoryEligible(anchor, controller) {
    if (string_length(string_trim(anchor.text)) == 0) return false
    if (controller.collected < anchor.min_collected) return false
    if (anchor.requires_all_previous and !controller.all_previous) return false
    return anchor.role != "missing_previous" or !controller.all_previous
}

/// Prepares fixed text and one independent palette colour for each place.
function funWallMemoryAssignAnchors(controller) {
    var anchors = []
    for (var i = 0; i < instance_number(oWallMemoryAnchor); ++i) {
        var anchor = instance_find(oWallMemoryAnchor, i)
        anchor.read_key = string(controller.level_number) + ":" + anchor.anchor_id
        if (funWallMemoryEligible(anchor, controller) and !funWallMemoryWasRead(anchor.read_key)) {
            funWallMemoryPrepareAnchor(anchor)
        }
        array_push(anchors, anchor)
    }
    controller.anchors = anchors
    controller.ready = true
}
