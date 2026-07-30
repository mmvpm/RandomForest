/// Initializes the shared fields used by local enemy movement.
function funEnemyInitializeMovement(collision_sprite) {
	self.mask_index = collision_sprite
	self.drop_through_counter = 0
	self.vertical_decision_counter = 0
	self.air_navigation_active = false
	self.air_was_airborne = false
	self.air_target_x = self.x
	self.air_target_y = self.y
	self.air_move_speed = 0
}

/// Returns a trap or stopped player sword intersecting the enemy at a position.
function funEnemyDangerInstanceAt(check_x, check_y) {
	var trap = instance_place(check_x, check_y, oTrap)
	if (trap != noone) {
		return trap
	}

	var tap_sword = instance_place(check_x, check_y, oPlayerTapSword)
	if (tap_sword != noone and tap_sword.current_speed == 0) {
		return tap_sword
	}

	return noone
}

/// Returns whether a position intersects a trap or stopped player sword.
function funEnemyPositionIsDangerous(check_x, check_y) {
	return funEnemyDangerInstanceAt(check_x, check_y) != noone
}

/// Checks solid collisions while allowing upward or intentional jump-through movement.
function funEnemyCollidesWithSolid(check_x, check_y, previous_y, vertical_speed, ignore_jump_thru) {
	var first_solid = instance_place(check_x, check_y, oSolid)
	if (first_solid == noone) {
		return false
	}
	if (first_solid.object_index != oJumpThru) {
		return true
	}

	var bbox_bottom_offset = self.bbox_bottom - self.y
	var previous_bottom = previous_y + bbox_bottom_offset
	var lands_on_first =
		!ignore_jump_thru and
		vertical_speed >= 0 and
		previous_bottom <= first_solid.bbox_top + 1
	if (lands_on_first) {
		return true
	}

	var result = false
	var solid_list = ds_list_create()
	var solid_count = instance_place_list(check_x, check_y, oSolid, solid_list, false)
	for (var i = 0; i < solid_count; ++i) {
		var solid_instance = solid_list[| i]
		if (solid_instance.object_index != oJumpThru) {
			result = true
			break
		}

		var lands_from_above =
			!ignore_jump_thru and
			vertical_speed >= 0 and
			previous_bottom <= solid_instance.bbox_top + 1
		if (lands_from_above) {
			result = true
			break
		}
	}

	ds_list_destroy(solid_list)
	return result
}

/// Returns whether the enemy has solid or jump-through support below it.
function funEnemyOnGroundAt(check_x, check_y) {
	return funEnemyCollidesWithSolid(check_x, check_y + 1, check_y, 1, false)
}

/// Returns whether the center of the collision mask has support below it.
function funEnemyHasStableSupportAt(check_x, check_y) {
	var center_offset = (self.bbox_left + self.bbox_right) * 0.5 - self.x
	var bottom_offset = self.bbox_bottom - self.y
	var support_x = check_x + center_offset
	var support_y = check_y + bottom_offset + 1
	return collision_point(support_x, support_y, oSolid, false, false) != noone
}

/// Returns whether the leading foot will remain supported after one step.
function funEnemyHasGroundAhead(move_direction, move_speed) {
	if (move_direction == 0) {
		return funEnemyHasStableSupportAt(self.x, self.y)
	}

	var offset_x = move_direction * move_speed
	var foot_x = move_direction > 0 ? self.bbox_right + offset_x : self.bbox_left + offset_x
	var foot_y = self.bbox_bottom + 1
	return collision_point(foot_x, foot_y, oSolid, false, false) != noone
}

/// Returns whether moving to a position avoids entering a new danger.
function funEnemyMoveAvoidsDanger(new_x, new_y) {
	var current_danger = funEnemyDangerInstanceAt(self.x, self.y)
	var new_danger = funEnemyDangerInstanceAt(new_x, new_y)
	if (new_danger == noone) {
		return true
	}
	if (current_danger == noone or new_danger != current_danger) {
		return false
	}

	var current_distance = point_distance(self.x, self.y, current_danger.x, current_danger.y)
	var new_distance = point_distance(new_x, new_y, current_danger.x, current_danger.y)
	return new_distance > current_distance
}

/// Returns whether a horizontal move is solid-free, supported, and no more dangerous.
function funEnemyCanWalkAtSpeed(move_direction, move_speed) {
	if (move_direction == 0) {
		return true
	}

	var new_x = self.x + move_direction * move_speed
	if (funEnemyCollidesWithSolid(new_x, self.y, self.y, 0, false)) {
		return false
	}
	if (!funEnemyHasGroundAhead(move_direction, move_speed)) {
		return false
	}

	return funEnemyMoveAvoidsDanger(new_x, self.y)
}

/// Returns whether one ordinary horizontal step is safe.
function funEnemyCanWalk(move_direction) {
	return funEnemyCanWalkAtSpeed(move_direction, self.step_xspeed)
}

/// Returns whether pursuit can advance while keeping the mask center supported.
function funEnemyCanPursueStep(move_direction) {
	if (move_direction == 0) {
		return false
	}

	var new_x = self.x + move_direction * self.step_xspeed
	if (funEnemyCollidesWithSolid(new_x, self.y, self.y, 0, false)) {
		return false
	}
	if (!funEnemyHasStableSupportAt(new_x, self.y)) {
		return false
	}
	return funEnemyMoveAvoidsDanger(new_x, self.y)
}

/// Chooses a safe direction that moves the enemy out of its current danger.
function funEnemyGetEscapeDirection() {
	var danger = funEnemyDangerInstanceAt(self.x, self.y)
	if (danger == noone) {
		return 0
	}

	var preferred = sign(self.x - danger.x)
	if (preferred == 0) {
		preferred = -sign(self.image_xscale)
	}
	if (preferred == 0) {
		preferred = 1
	}

	if (funEnemyCanWalk(preferred)) {
		return preferred
	}
	if (funEnemyCanWalk(-preferred)) {
		return -preferred
	}
	return 0
}

/// Returns whether a landing makes local progress toward the target.
function funEnemyLandingApproachesTarget(landing_x, landing_y, target_x, target_y) {
	var bottom_offset = self.bbox_bottom - self.y
	var start_bottom = self.y + bottom_offset
	var landing_bottom = landing_y + bottom_offset
	var start_horizontal_distance = abs(target_x - self.x)
	var landing_horizontal_distance = abs(target_x - landing_x)
	if (landing_horizontal_distance + 6 < start_horizontal_distance) {
		return true
	}

	var start_vertical_distance = abs(target_y - start_bottom)
	var landing_vertical_distance = abs(target_y - landing_bottom)
	return landing_vertical_distance + 6 < start_vertical_distance
}

/// Simulates one fixed local air action using the same Y-then-X order as runtime movement.
function funEnemySimulateAirAction(move_direction, initial_yspeed, air_speed, ignore_jump_thru_frames, target_x, target_y) {
	var sim_x = self.x
	var sim_y = self.y
	var sim_yspeed = initial_yspeed
	var sim_was_airborne = false
	var max_frames = 48

	for (var frame = 0; frame < max_frames; ++frame) {
		sim_yspeed = min(20, sim_yspeed + self.gravitation)

		var previous_y = sim_y
		var y_direction = sign(sim_yspeed)
		var moved_y = false
		var ignore_jump_thru = y_direction < 0 or frame < ignore_jump_thru_frames
		for (var speed_y = abs(sim_yspeed); speed_y > 0; --speed_y) {
			var next_y = sim_y + y_direction * speed_y
			var blocked_y = funEnemyCollidesWithSolid(
				sim_x,
				next_y,
				previous_y,
				sim_yspeed,
				ignore_jump_thru
			)
			if (!blocked_y) {
				if (funEnemyPositionIsDangerous(sim_x, next_y)) {
					return { success: false, landing_x: self.x, landing_y: self.y }
				}
				sim_y = next_y
				moved_y = true
				break
			}
		}

		if (moved_y) {
			sim_was_airborne = true
		}
		else if (y_direction != 0) {
			sim_yspeed = 0
		}

		if (move_direction != 0) {
			for (var speed_x = air_speed; speed_x > 0; --speed_x) {
				var next_x = sim_x + move_direction * speed_x
				var blocked_x = funEnemyCollidesWithSolid(next_x, sim_y, sim_y, 0, false)
				if (!blocked_x and !funEnemyPositionIsDangerous(next_x, sim_y)) {
					sim_x = next_x
					break
				}
			}
			// Runtime retries blocked horizontal steering on the next air frame.
		}

		var stable_landing =
			sim_was_airborne and
			sim_yspeed == 0 and
			funEnemyOnGroundAt(sim_x, sim_y) and
			funEnemyHasStableSupportAt(sim_x, sim_y) and
			!funEnemyPositionIsDangerous(sim_x, sim_y)
		if (stable_landing) {
			return {
				success: funEnemyLandingApproachesTarget(
					sim_x,
					sim_y,
					target_x,
					target_y
				),
				landing_x: sim_x,
				landing_y: sim_y
			}
		}

		if (sim_x < 0 or sim_x > room_width or sim_y < 0 or sim_y > room_height) {
			break
		}
	}

	return { success: false, landing_x: self.x, landing_y: self.y }
}

/// Starts a previously validated jump or fall.
function funEnemyStartAirAction(action, initial_yspeed, air_speed, ignore_jump_thru_frames) {
	self.current_yspeed = initial_yspeed
	self.air_navigation_active = true
	self.air_was_airborne = false
	self.air_target_x = action.landing_x
	self.air_target_y = action.landing_y
	self.air_move_speed = air_speed
	self.drop_through_counter = ignore_jump_thru_frames
	self.vertical_decision_counter = 15
}

/// Builds one air candidate without changing the enemy's current action.
function funEnemyBuildAirCandidate(move_direction, initial_yspeed, air_speed, ignore_jump_thru_frames, target_x, target_y) {
	var trajectory = funEnemySimulateAirAction(
		move_direction,
		initial_yspeed,
		air_speed,
		ignore_jump_thru_frames,
		target_x,
		target_y
	)
	if (!trajectory.success) {
		return undefined
	}

	return {
		landing_x: trajectory.landing_x,
		landing_y: trajectory.landing_y,
		initial_yspeed: initial_yspeed,
		air_speed: air_speed,
		ignore_jump_thru_frames: ignore_jump_thru_frames
	}
}

/// Rejects a lower landing when the visible target is above the enemy.
function funEnemyAirCandidateFitsTarget(candidate, target_above) {
	if (candidate == undefined) {
		return false
	}
	if (!target_above) {
		return true
	}

	var bottom_offset = self.bbox_bottom - self.y
	var landing_bottom = candidate.landing_y + bottom_offset
	return landing_bottom <= self.bbox_bottom + 2
}

/// Returns the candidate whose stable landing is closer to the target.
function funEnemyChooseBetterAirCandidate(current_candidate, new_candidate, target_x, target_y) {
	if (new_candidate == undefined) {
		return current_candidate
	}
	if (current_candidate == undefined) {
		return new_candidate
	}

	var bottom_offset = self.bbox_bottom - self.y
	var current_distance = point_distance(
		current_candidate.landing_x,
		current_candidate.landing_y + bottom_offset,
		target_x,
		target_y
	)
	var new_distance = point_distance(
		new_candidate.landing_x,
		new_candidate.landing_y + bottom_offset,
		target_x,
		target_y
	)
	if (new_distance + 1 < current_distance) {
		return new_candidate
	}
	if (current_distance + 1 < new_distance) {
		return current_candidate
	}

	// Prefer a natural fall when both landings are effectively equal.
	if (new_candidate.initial_yspeed == 0 and current_candidate.initial_yspeed < 0) {
		return new_candidate
	}
	return current_candidate
}

/// Tries one safe local step, jump, or descent toward a visible target.
function funEnemyTryPursuitAction(target_x, target_y, jump_impulse, air_speed) {
	if (self.air_navigation_active) {
		return true
	}

	var distance_x = target_x - self.x
	var move_direction = abs(distance_x) < 12 ? 0 : sign(distance_x)
	var target_below = target_y > self.bbox_bottom + 12
	var target_above = target_y < self.bbox_bottom - 8

	if (move_direction != 0) {
		self.current_direction = move_direction
		self.image_xscale = move_direction * abs(self.image_xscale)
		if (funEnemyCanPursueStep(move_direction)) {
			return true
		}
	}

	if (self.vertical_decision_counter > 0 or !funEnemyOnGroundAt(self.x, self.y)) {
		return false
	}

	var standing_on_jump_thru = instance_place(self.x, self.y + 1, oJumpThru) != noone
	var best_candidate = undefined
	var candidate = undefined
	if (target_below and standing_on_jump_thru) {
		var drop_direction = abs(target_x - self.x) < 6 ? 0 : move_direction
		candidate = funEnemyBuildAirCandidate(
			drop_direction,
			0,
			air_speed,
			8,
			target_x,
			target_y
		)
		best_candidate = funEnemyChooseBetterAirCandidate(
			best_candidate,
			candidate,
			target_x,
			target_y
		)
	}
	else if (move_direction != 0) {
		candidate = funEnemyBuildAirCandidate(
			move_direction,
			0,
			air_speed,
			0,
			target_x,
			target_y
		)
		if (funEnemyAirCandidateFitsTarget(candidate, target_above)) {
			best_candidate = funEnemyChooseBetterAirCandidate(
				best_candidate,
				candidate,
				target_x,
				target_y
			)
		}
	}

	if (target_above or move_direction != 0) {
		candidate = funEnemyBuildAirCandidate(
			move_direction,
			jump_impulse,
			air_speed,
			0,
			target_x,
			target_y
		)
		if (funEnemyAirCandidateFitsTarget(candidate, target_above)) {
			best_candidate = funEnemyChooseBetterAirCandidate(
				best_candidate,
				candidate,
				target_x,
				target_y
			)
		}
	}

	if (best_candidate != undefined) {
		funEnemyStartAirAction(
			best_candidate,
			best_candidate.initial_yspeed,
			best_candidate.air_speed,
			best_candidate.ignore_jump_thru_frames
		)
		return true
	}

	self.vertical_decision_counter = 15
	return false
}

/// Applies horizontal steering for the current validated air action.
function funEnemyApplyAirMovement() {
	if (!self.air_navigation_active) {
		return false
	}

	var distance_x = self.air_target_x - self.x
	if (abs(distance_x) <= self.air_move_speed) {
		self.current_xspeed = distance_x
	}
	else {
		self.current_xspeed = sign(distance_x) * self.air_move_speed
	}

	var move_direction = sign(self.current_xspeed)
	if (move_direction != 0) {
		self.image_xscale = move_direction * abs(self.image_xscale)
	}
	return true
}

/// Ends an air action after landing and reports whether landing happened now.
function funEnemyFinishAirMovement() {
	if (!self.air_navigation_active) {
		return false
	}

	var on_ground = funEnemyOnGroundAt(self.x, self.y)
	if (self.current_yspeed != 0 or !on_ground) {
		self.air_was_airborne = true
		return false
	}
	if (!self.air_was_airborne or !funEnemyHasStableSupportAt(self.x, self.y)) {
		return false
	}

	self.air_navigation_active = false
	self.air_was_airborne = false
	self.current_xspeed = 0
	self.drop_through_counter = 0
	// Prevent repeated hops immediately after touching the ground.
	self.vertical_decision_counter = max(self.vertical_decision_counter, 30)
	return true
}

/// Cancels tactical air steering without cancelling ordinary gravity.
function funEnemyCancelAirMovement() {
	self.air_navigation_active = false
	self.air_was_airborne = false
	self.drop_through_counter = 0
	self.current_xspeed = 0
}

/// Updates counters shared by all local enemy movement.
function funEnemyUpdateMovement() {
	self.drop_through_counter = max(0, self.drop_through_counter - 1)
	self.vertical_decision_counter = max(0, self.vertical_decision_counter - 1)
}
