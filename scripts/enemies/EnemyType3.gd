extends RangedEnemyBase

class_name EnemyType3

@export var bullet: PackedScene
@export var bullet_speed: float = 200
@export var bullet_damage: int = 5
@export var shoot_interval: float = 3
@export var shoot_range: float = 300
@export var is_elite: bool
@export var elite_bullet_offset = 20

var can_shoot = true

func _ready() -> void:
	super._ready()
	start_behavior_loop()
	
func start_behavior_loop():
	var core = EnemyUtils.get_body_core()
	while true:
		await get_tree().physics_frame
		var dir = core.global_position - global_position
		if dir.length() > shoot_range:
			move_direction = EnemyUtils.force_left(dir.normalized())
		else:
			move_direction = Vector2.ZERO
			if can_shoot:
				shoot(dir)
	
func shoot(dir: Vector2):
	assert(can_shoot)
	can_shoot = false
	var pos = global_position
	dir = dir.normalized()
	if is_elite:
		var dir1 = Vector2(dir.y, -dir.x)
		spawn_bullet(pos+dir1*elite_bullet_offset, dir)
		spawn_bullet(pos-dir1*elite_bullet_offset, dir)
	else:
		spawn_bullet(pos, dir)
	await get_tree().create_timer(shoot_interval).timeout
	can_shoot = true
	
func spawn_bullet(pos: Vector2, dir: Vector2):
	var obj = bullet.instantiate() as Bullet
	obj.global_position = pos
	obj.linear_velocity = dir * bullet_speed
	obj.damage = bullet_damage
	EnemyUtils.get_main_scene().add_child(obj)
