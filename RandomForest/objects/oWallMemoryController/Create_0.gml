/// Freezes eligibility at entry, before any new firefly is collected.
self.level_number = global.playing_level + 1
self.progress = funBlackRoomProgress(self.level_number)
self.collected = self.progress.collected
self.all_previous = funWallMemoryAllPrevious(self.level_number, self.progress.records)
self.anchors = []
self.ready = false
self.movement_started = false
