/// A single amber firefly wakes the title, leaving a few slowly fading embers.
function funIntroFireflyDraw(frame, alpha, ink) {
    var progress = funIntroEase((frame - 10) / 76)
    for (var i = 8; i >= 0; --i) {
        var t = funIntroEase((frame - 10 - i * 2) / 76)
        var px = lerp(92, 386, t)
        var py = 114 - sin(t * pi) * 24 + sin(t * pi * 2) * 8
        if (i == 0) funIntroGlow(px, py, alpha, ink)
        else {
            draw_set_color(ink)
            draw_set_alpha(alpha * (1 - i / 9) * 0.18 * (1 - progress))
            draw_point(round(px), round(py))
        }
    }
}
