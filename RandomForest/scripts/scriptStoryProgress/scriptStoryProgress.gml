/// Makes level 00 look available after its instruction scene has been completed.
function funStoryLevelUnlocked(level_index) {
    if (funLevelTracksProgress(level_index)) return level_index <= global.current_level
    return global.ending_stage == 2 or global.black_room_seen.ck_after_40
}

/// Centralizes the memory gate for selection, results and direct level opening.
function funStoryLevelCanEnter(level_index) {
    return funLevelTracksProgress(level_index) or global.ending_stage == 2
        or (global.black_room_seen.ck_after_40 and funGetOrangeFireflyCount() >= 40)
}

/// Records a lost character before death/restart can be interrupted by closing the game.
function funRecordLostClone() {
    global.lost_clones++
    funSaveGameState()
}

/// Restarts a live attempt; death already records its loss when the animation starts.
function funRestartCurrentRun() {
    if (!instance_exists(oPlayer) or oPlayer.state != player_states.die) funRecordLostClone()
    if (room == rBlackRoom) funOpenLevel(global.playing_level)
    else room_restart()
}
