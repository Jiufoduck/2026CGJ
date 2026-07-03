extends RangedEnemyBase

class_name EnemyType7

@export var bullet: PackedScene
@export var bullet_speed: float = 200
@export var bullet_damage: int = 5
@export var shoot_interval: float = 3
@export var rotation_speed: float = 0

var can_shoot = true

func _ready() -> void:
	super._ready()
	move_speed = 0

func _physics_process(delta: float) -> void:
	#var core = EnemyUtils.get_body_core()
	rotate(deg_to_rad(rotation_speed * delta))
	if can_shoot:
		shoot()

func shoot():
	assert(can_shoot)
	can_shoot = false
	var pos = global_position
	var angle = rotation_degrees
	for dir in [
		Vector2.UP.rotated(angle),
		Vector2.DOWN.rotated(angle),
		Vector2.LEFT.rotated(angle),
		Vector2.RIGHT.rotated(angle),
	]:
		spawn_bullet(pos, dir)
	await get_tree().create_timer(shoot_interval).timeout
	can_shoot = true

func spawn_bullet(pos: Vector2, dir: Vector2):
	var obj = bullet.instantiate() as Bullet
	obj.global_position = pos
	obj.linear_velocity = dir * bullet_speed
	obj.damage = bullet_damage
	EnemyUtils.get_main_scene().add_child(obj)
