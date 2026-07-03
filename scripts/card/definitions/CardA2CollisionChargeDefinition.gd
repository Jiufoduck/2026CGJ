extends CardDefinition
class_name CardA2CollisionChargeDefinition

# 脚本说明：
# - enemy_damage_amount：A2 撞到敌人时造成的伤害。
# - move_speed_scale：A2 持续期间使用者的移动速度倍率。
# - hit_radius：A2 判定撞到敌人的距离半径。
# - hit_cooldown：同一个敌人两次撞击受伤之间的最短间隔，避免贴身时每帧扣血。
# - get_effect_data()：只把 A2 需要的效果数值交给运行时牌堆。

@export var enemy_damage_amount := 4.0
@export var move_speed_scale := 0.65
@export var hit_radius := 48.0
@export var hit_cooldown := 0.35


func get_effect_data() -> Dictionary:
	return {
		"enemy_damage_amount": enemy_damage_amount,
		"move_speed_scale": move_speed_scale,
		"hit_radius": hit_radius,
		"hit_cooldown": hit_cooldown,
	}
