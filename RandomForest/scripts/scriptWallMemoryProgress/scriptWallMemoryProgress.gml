/// Returns whether this place already finished printing in any attempt.
function funWallMemoryWasRead(key) {
    return variable_struct_exists(global.wall_memory_read, key)
        and variable_struct_get(global.wall_memory_read, key)
}

/// Persists a completed inscription immediately, independently of level completion.
function funWallMemoryMarkRead(key) {
    if (funWallMemoryWasRead(key)) return;
    variable_struct_set(global.wall_memory_read, key, true)
    funSaveGameState()
}

/// Allows inscriptions again when the campaign itself is reset.
function funResetWallMemories() {
    global.wall_memory_read = {}
}
