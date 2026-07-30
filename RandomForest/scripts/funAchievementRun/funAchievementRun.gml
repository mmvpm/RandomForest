/// Starts achievement tracking for a fresh room attempt.
function funBeginAchievementRun() {
	global.current_run_flawless = true
}

/// Marks the current room attempt as having taken damage.
function funMarkAchievementDamage() {
	global.current_run_flawless = false
}

/// Returns whether every combat enemy in the current room is fully defeated.
function funAreAllCombatEnemiesDefeated() {
	var enemy_count = instance_number(oEnemy)
	for (var enemy_index = 0; enemy_index < enemy_count; ++enemy_index) {
		var enemy = instance_find(oEnemy, enemy_index)
		if (!enemy.is_dead) {
			return false
		}
		// A large dying slime is not cleared until its children exist.
		if (enemy.object_index == oSlime and !enemy.is_splitted) {
			return false
		}
	}
	return true
}
