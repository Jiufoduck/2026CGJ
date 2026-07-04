extends CardDefinition
class_name CardA4ClearScreenDefinition

# 脚本说明：
# - push_distance：A4 把摄像机视野内敌人往左推开的强度。
# - overwhelm_decay：A4 推开敌人后，EnemyBase 惯性速度每帧衰减系数。
# - get_effect_data()：只把 A4 需要的效果数值交给运行时牌堆。

@export var push_distance := 260.0
@export var overwhelm_decay := 0.72


func get_effect_data() -> Dictionary:
	return {
		"push_distance": push_distance,
		"overwhelm_decay": overwhelm_decay,
	}
