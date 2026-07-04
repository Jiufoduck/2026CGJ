extends CardDefinition
class_name CardA5RestoreGenerationDefinition

# 脚本说明：
# - heal_amount：A5 回血牌给肉体恢复的生命值。
# - get_effect_data()：只把 A5 需要的效果数值交给运行时牌堆。

@export var heal_amount := 10.0


func get_effect_data() -> Dictionary:
	return {
		"heal_amount": heal_amount,
	}
