extends CardDefinition
class_name CardB10OptimizeHandDefinition

# 脚本说明：
# - body_phase_collision_layer：B10 生效时肉体忽略的普通墙/障碍碰撞层编号。
# - get_effect_data()：只把 B10 需要的效果数值交给运行时牌堆。

@export var body_phase_collision_layer := 3


func get_effect_data() -> Dictionary:
	return {
		"body_phase_collision_layer": body_phase_collision_layer,
	}
