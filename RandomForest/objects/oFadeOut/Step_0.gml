/// Completes optional story fades only after an opaque frame reached the screen.
self.global_alpha = min(1, self.global_alpha + self.alpha_step)

if (self.global_alpha >= 1) {
    if (self.hold_black_frame and !self.black_frame_drawn) exit
    var complete = self.end_function
    instance_destroy()
    if (complete != undefined) complete()
}
