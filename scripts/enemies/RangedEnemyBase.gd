extends EnemyBase

class_name RangedEnemyBase

# 脚本说明：
# - _ready()：调用敌人基类初始化后移除近战伤害区，让远程敌人只通过子弹造成伤害。
# - _try_damage_body()：覆盖近战接触伤害逻辑，避免远程敌人本体接触肉体扣血。

func _ready() -> void:
	super._ready()
	if damage_area != null:
		damage_area.queue_free()
		damage_area = null
		
func _try_damage_body() -> void:
	# 禁用近战逻辑
	if contact_damage_timer > 0.0 or damage_area == null:
		return
