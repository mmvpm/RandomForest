/// Starts each page's sound cadence independently of the unchanged text clock.
function funResetDialogueAudio() {
    self.typing_audio_frame = 0
    self.typing_sound_due_frame = 0
}

/// Thins real glyph appearances to the approved 20/s cadence; slow dots keep their own cue.
function funPlayDialogueGlyph(letter) {
    if (letter == " " or letter == "\n" or letter == "\r" or letter == "\t") return
    var period = 60 / 20
    if (self.typing_audio_frame < self.typing_sound_due_frame) return
    // Carry the fractional cadence rather than rounding 20/s down to 15/s on a 30/s text grid.
    if (self.typing_sound_due_frame == 0
        or self.typing_audio_frame - self.typing_sound_due_frame >= period)
        self.typing_sound_due_frame = self.typing_audio_frame + period
    else self.typing_sound_due_frame += period
    if (global.sfx_enabled) audio_play_sound(soundDialogueTyping, 1, false)
}
