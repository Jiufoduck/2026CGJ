extends RigidBody2D

class_name Bullet

# 脚本说明：
# - damage：子弹命中肉体时造成的伤害。
# - source_enemy：发射这颗子弹的敌人。A3 反杀怪物需要通过它找到伤害来源。
# - _ready()：进入场景后加入 enemy_projectiles 分组，并启动自动销毁计时。
# - _on_body_entered(body)：命中肉体时传递伤害和来源敌人，然后销毁子弹。
# - self_destroy()：保险销毁逻辑，避免未命中的子弹永久留在场景。

var damage: int = 1
var source_enemy: Node

func _ready() -> void:
	add_to_group("enemy_projectiles")
	self_destroy()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_hit"):
		body.take_hit(damage, source_enemy)
	queue_free()
		
func self_destroy():
	await get_tree().create_timer(10).timeout
	queue_free()
	
