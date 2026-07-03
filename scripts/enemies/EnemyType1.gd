extends EnemyBase

class_name EnemyType1

# 脚本说明：
# - _physics_process(delta)：让近战敌人持续朝肉体移动，但强制不向右移动，再交给 EnemyBase 处理移动、冻结和接触伤害。

func _physics_process(delta: float) -> void:
	var core = EnemyUtils.get_body_core()
	var dir = core.global_position - global_position
	dir = dir.normalized()
	move_direction = EnemyUtils.force_left(dir)
	super._physics_process(delta)
