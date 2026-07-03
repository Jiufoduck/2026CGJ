extends Line2D
class_name CardProjectileLine

# 脚本说明：
# - play(start_position, end_position, lifetime)：显示一条从肉体飞向敌人的短暂弹道线，并在淡出后删除自己。


func play(start_position: Vector2, end_position: Vector2, lifetime: float) -> void:
	global_position = Vector2.ZERO
	points = PackedVector2Array([start_position, end_position])
	modulate = Color(1.0, 0.95, 0.25, 1.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, maxf(0.01, lifetime))
	tween.finished.connect(queue_free)

