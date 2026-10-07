/// Initializes the shared theme roles without changing the menu layout.
funApplyUiPresentation(funUiScenePresentation(true))
/// @description Initializes the main-menu audio settings screen.

self.items_count = 3
self.current_index = 0

self.border_sprite = sBorder4
self.text_scale = 20 / 24

self.toggle_width = 220
self.toggle_height = 35
self.back_width = 160
self.back_height = 35
self.row_y = [115, 160, 215]

self.mouse_allowed_counter = 10
self.last_mouse_x = 0
self.last_mouse_y = 0
self.x_left_cached = array_create(self.items_count, -1000)
self.y_top_cached = array_create(self.items_count, -1000)
self.x_right_cached = array_create(self.items_count, -1000)
self.y_bottom_cached = array_create(self.items_count, -1000)
