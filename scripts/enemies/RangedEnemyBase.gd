extends EnemyBase

class_name RangedEnemyBase

func _ready() -> void:
	super._ready()
	damage_area.queue_free()
	
func _try_damage_body() -> void:
	# 禁用近战逻辑
	if contact_damage_timer > 0.0 or damage_area == null:
		return
