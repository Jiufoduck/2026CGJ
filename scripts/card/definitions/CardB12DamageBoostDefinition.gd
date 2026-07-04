extends CardDefinition
class_name CardB12DamageBoostDefinition

# 脚本说明：
# - damage_multiplier_base：B12 给队友下一次数值伤害使用的倍率。
# - get_effect_data()：只把 B12 需要的效果数值交给运行时牌堆。

@export var damage_multiplier_base := 2.0


func get_effect_data() -> Dictionary:
	return {
		"damage_multiplier_base": damage_multiplier_base,
	}
