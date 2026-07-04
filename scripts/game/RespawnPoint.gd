extends Line2D

class_name RespawnPoint

var center: Vector2
var core: Node2D

static var Max: RespawnPoint

func _ready() -> void:
	var p1 = points.get(0)
	var p2 = points.get(1)
	center = ((p1+p2) / 2) + global_position
	core = EnemyUtils.get_body_core()

func _physics_process(_delta: float) -> void:
	if core.global_position.x > center.x:
		Max = self
		print('respawn point arrived!')
		hide()
		set_physics_process(false)
