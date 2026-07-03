extends CardDefinition
class_name CardB11FocusedFireDefinition

# 脚本说明：
# - focused_ally_cooldown：B11 生效期间另一位玩家出牌或跳过后的固定 CD。
# - get_effect_data()：只把 B11 需要的效果数值交给运行时牌堆。

@export var focused_ally_cooldown := 0.5


func get_effect_data() -> Dictionary:
	return {
		"focused_ally_cooldown": focused_ally_cooldown,
	}
