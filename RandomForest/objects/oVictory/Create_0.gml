// texts
self.victory_text  = "Поздравляю, вы прошли игру"
self.continue_text = "Для выхода в меню нажмите любую клавишу дважды"

// find center
self.room_center_x = room_width / 2
self.room_center_y = room_height / 2

// alpha settings
self.text_alpha = 0.5

self.text_continue_alpha_min = 0.1
self.text_continue_alpha_max = 0.6
self.text_continue_alpha_current = 0.5

// time
// self.music_duration = 520 // ~ 8.6 seconds // for mem
self.music_duration = 1043 // ~ 17.38 seconds
self.fade_duration = self.music_duration / 2 // remove ` / 2` for mem
self.tick_counter_start = self.fade_duration / 2 * 1.5 // for starting with sin(..) = -1 => faded text
self.tick_counter = self.tick_counter_start
self.goto_next_level_counter = 0

// music
audio_stop_sound(musicGame)
audio_play_sound(musicVictory, 0, false) // manual repeating in Draw