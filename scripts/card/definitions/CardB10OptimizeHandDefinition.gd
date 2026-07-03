extends CardDefinition
class_name CardB10OptimizeHandDefinition

# 脚本说明：
# - restore_cards_to_add：B10 往自己牌堆加入的恢复牌数量。
# - get_effect_data()：只把 B10 需要的效果数值交给运行时牌堆。

@export var restore_cards_to_add := 1


func get_effect_data() -> Dictionary:
	return {
		"restore_cards_to_add": restore_cards_to_add,
	}
