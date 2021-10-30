var is_player_over_platform = sign(oPlayer.bbox_bottom - self.bbox_top) == -1
self.is_solid = is_player_over_platform