extends CardDefinition
class_name CardA3CounterattackDefinition

# 脚本说明：
# - counterattack_duration：A3 反伤持续时间。表格要求持续 3 秒，时间结束后自动失效。
# - projectile_lifetime：A3 反杀触发时肉体到敌人弹道反馈的持续时间。
# - get_effect_data()：只把 A3 需要的效果数值交给运行时牌堆。

@export var counterattack_duration := 3.0
@export var projectile_lifetime := 0.35


func get_effect_data() -> Dictionary:
	return {
		"counterattack_duration": counterattack_duration,
		"projectile_lifetime": projectile_lifetime,
	}
