extends RigidBody2D

class_name Bullet

var damage: int = 1

func _ready() -> void:
	self_destroy()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_hit"):
		body.take_hit(damage)
		queue_free()
		
func self_destroy():
	await get_tree().create_timer(10).timeout
	queue_free()
	
