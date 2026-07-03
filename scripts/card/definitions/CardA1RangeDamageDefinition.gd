extends CardDefinition
class_name CardA1RangeDamageDefinition

# 脚本说明：
# - damage_amount：A1 范围伤害对范围内敌人和肉体造成的伤害。
# - get_effect_data()：只把 A1 需要的效果数值交给运行时牌堆。

@export var damage_amount := 5.0


func get_effect_data() -> Dictionary:
	return {
		"damage_amount": damage_amount,
	}
