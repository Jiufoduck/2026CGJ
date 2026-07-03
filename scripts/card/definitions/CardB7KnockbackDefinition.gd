extends CardDefinition
class_name CardB7KnockbackDefinition

# 脚本说明：
# - body_damage_amount：B7 对肉体造成的伤害。
# - knockback_distance：B7 传给 EnemyBase._on_overwhelmed 的击退强度。
# - overwhelm_decay：B7 击退敌人后，EnemyBase 惯性速度每帧衰减系数。
# - get_effect_data()：只把 B7 需要的效果数值交给运行时牌堆。

@export var body_damage_amount := 4.0
@export var knockback_distance := 260.0
@export var overwhelm_decay := 0.72


func get_effect_data() -> Dictionary:
	return {
		"body_damage_amount": body_damage_amount,
		"knockback_distance": knockback_distance,
		"overwhelm_decay": overwhelm_decay,
	}
