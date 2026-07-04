extends CardDefinition
class_name CardA1RangeDamageDefinition

# 脚本说明：
# - damage_amount：A1 锚线对附近怪物造成的伤害。
# - line_hit_radius：A1 判定怪物是否贴近锚线的距离。
# - get_effect_data()：只把 A1 需要的效果数值交给运行时牌堆。

@export var damage_amount := 5.0
@export var line_hit_radius := 42.0


func get_effect_data() -> Dictionary:
	return {
		"damage_amount": damage_amount,
		"line_hit_radius": line_hit_radius,
	}
