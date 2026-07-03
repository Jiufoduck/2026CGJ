extends EnemyBase

class_name EnemyType1

func _physics_process(delta: float) -> void:
	var core = EnemyUtils.get_body_core()
	var dir = core.global_position - global_position
	dir = dir.normalized()
	move_direction = EnemyUtils.force_left(dir)
	super._physics_process(delta)
