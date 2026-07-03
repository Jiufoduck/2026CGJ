extends CardDefinition
class_name CardA5RestoreGenerationDefinition

# 脚本说明：
# - restore_cards_to_add：A5 断线后往自己牌堆加入的恢复牌数量。
# - get_effect_data()：只把 A5 需要的效果数值交给运行时牌堆。

@export var restore_cards_to_add := 3


func get_effect_data() -> Dictionary:
	return {
		"restore_cards_to_add": restore_cards_to_add,
	}
