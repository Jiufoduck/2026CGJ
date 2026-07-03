extends CardDefinition
class_name CardA3CounterattackDefinition

# 脚本说明：
# - projectile_lifetime：A3 反杀触发时肉体到敌人弹道反馈的持续时间。
# - get_effect_data()：只把 A3 需要的效果数值交给运行时牌堆。

@export var projectile_lifetime := 0.35


func get_effect_data() -> Dictionary:
	return {
		"projectile_lifetime": projectile_lifetime,
	}
