/// Returns whether the player is inside this enemy's directional sight with a clear line.
function funEnemySeePlayer() {
	if (!instance_exists(oPlayer) or oPlayer.image_alpha <= 0) {
		return false
	}

	var sight_direction = sign(self.image_xscale)
	if (sight_direction == 0) {
		sight_direction = 1
	}
	var distance_x = oPlayer.x - self.x
	var allowed_radius = sign(distance_x) == sight_direction
		? self.vision_radius
		: self.rear_vision_radius
	var vertical_distance = abs(oPlayer.bbox_bottom - self.bbox_bottom)
	if (vertical_distance > self.vertical_vision_radius) {
		return false
	}
	if (point_distance(self.x, self.y, oPlayer.x, oPlayer.y) > allowed_radius) {
		return false
	}

	var sight_x = self.x
	var sight_y = self.y - abs(self.bbox_bottom - self.bbox_top) * 0.5
	var player_x = oPlayer.x
	var player_y = oPlayer.y - abs(oPlayer.bbox_bottom - oPlayer.bbox_top) * 0.5
	var first_blocker = collision_line(
		sight_x,
		sight_y,
		player_x,
		player_y,
		oSolid,
		false,
		false
	)
	if (first_blocker == noone) {
		return true
	}
	if (first_blocker.object_index != oJumpThru) {
		return false
	}

	var blockers = ds_list_create()
	var blocker_count = collision_line_list(
		sight_x,
		sight_y,
		player_x,
		player_y,
		oSolid,
		false,
		false,
		blockers,
		false
	)
	var blocked = false
	for (var i = 0; i < blocker_count; ++i) {
		if (blockers[| i].object_index != oJumpThru) {
			blocked = true
			break
		}
	}
	ds_list_destroy(blockers)
	return !blocked
}
