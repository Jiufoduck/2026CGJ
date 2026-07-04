extends CardDefinition
class_name CardB10OptimizeHandDefinition

# 脚本说明：
# - body_phase_collision_layer：B10 生效时肉体忽略的普通墙/障碍碰撞层编号。
# - duration_seconds：B10 肉体穿墙持续时间。表格要求 7 秒。
# - get_effect_data()：只把 B10 需要的效果数值交给运行时牌堆。

@export var body_phase_collision_layer := 3
@export var duration_seconds := 7.0


func get_effect_data() -> Dictionary:
	return {
		"body_phase_collision_layer": body_phase_collision_layer,
		"duration_seconds": duration_seconds,
	}
