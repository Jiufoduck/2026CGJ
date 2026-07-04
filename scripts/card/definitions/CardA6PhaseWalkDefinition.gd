extends CardDefinition
class_name CardA6PhaseWalkDefinition

# 脚本说明：
# - A6 改成了断裂并增加移动速度

@export var move_speed_scale := 1.5

func get_effect_data() -> Dictionary:
	return {
		"move_speed_scale": move_speed_scale,
	}
