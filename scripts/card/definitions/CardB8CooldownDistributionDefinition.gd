extends CardDefinition
class_name CardB8CooldownDistributionDefinition

# 脚本说明：
# - cooldown_self_multiplier：B8 对自己当前 CD 的倍率。小于 1 表示冷却加快。
# - cooldown_other_multiplier：B8 对对方当前 CD 的倍率。小于 1 表示冷却加快。
# - get_effect_data()：只把 B8 需要的效果数值交给运行时牌堆。

@export var cooldown_self_multiplier := 0.5
@export var cooldown_other_multiplier := 0.5


func get_effect_data() -> Dictionary:
	return {
		"cooldown_self_multiplier": cooldown_self_multiplier,
		"cooldown_other_multiplier": cooldown_other_multiplier,
	}
