/// Shows the live weather countdown only in debug, without creating or advancing weather.
if (!global.is_debug or !instance_exists(oAmbientSystem)) exit

var weather = oAmbientSystem.weather
var name = "Ясно"
switch (weather.phase) {
    case "rain": name = "Мелкий дождь"; break
    case "storm": name = "Ливень"; break
    case "drips": name = "Капли со сводов"; break
    case "fog": name = "Туман"; break
    case "seeds": name = "Одуванчики"; break
}
var seconds = max(0, ceil(weather.remaining))
var remainder = seconds mod 60
var minutes = floor(seconds / 60)
var label = name + " - " + (minutes < 10 ? "0" : "") + string(minutes)
    + ":" + (remainder < 10 ? "0" : "") + string(remainder)
if (instance_exists(oWeatherAudio)) {
    with (oWeatherAudio) label += "\n" + funAtmosphereMixLabel()
}

var previous_font = draw_get_font(), previous_colour = draw_get_colour()
var previous_alpha = draw_get_alpha()
var previous_halign = draw_get_halign(), previous_valign = draw_get_valign()
draw_set_font(global.dialogue_font_12)
draw_set_halign(fa_left)
draw_set_valign(fa_top)
var xx = 6, yy = display_get_gui_height() - string_height(label) - 6
draw_set_colour(c_black)
draw_set_alpha(0.65)
draw_rectangle(xx - 3, yy - 2, xx + string_width(label) + 3, yy + string_height(label) + 2, false)
draw_set_colour(c_white)
draw_set_alpha(1)
draw_text(xx, yy, label)
draw_set_font(previous_font)
draw_set_colour(previous_colour)
draw_set_alpha(previous_alpha)
draw_set_halign(previous_halign)
draw_set_valign(previous_valign)
