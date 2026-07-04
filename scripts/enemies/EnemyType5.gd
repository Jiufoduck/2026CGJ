extends EnemyBase

class_name EnemyType5

@export var charge_range = 200
@export var charge_startup = 1.0
@export var charge_recovery = 0.5

var initial_move_speed: float

var is_charging = false

func _ready() -> void:
	super._ready()
	initial_move_speed = move_speed

func _physics_process(delta: float) -> void:
	var core = EnemyUtils.get_body_core()

	if not is_charging:
		var dir = core.global_position - global_position
		if dir.length() < charge_range:
			do_charge()
		else:
			dir = dir.normalized()
			move_direction = EnemyUtils.force_left(dir)

	super._physics_process(delta)

func calib_movedir(force_left: bool):
	var core = EnemyUtils.get_body_core()
	var dir = core.global_position - global_position
	if force_left:
		move_direction = EnemyUtils.force_left(dir)
	else:
		move_direction = dir

func do_charge():
	assert(not is_charging)
	is_charging = true
	move_speed = 0
	calib_movedir(false)
	await get_tree().create_timer(charge_startup).timeout
	move_speed = initial_move_speed * 10

	# d = m / a
	# r = 1/2 * a * d^2
	# a = 2r / d^2
	# d = sqrt(2r / a)
	# m^2 / 2r = a
	# d = 2r / m


	var duration = 2 * charge_range / move_speed
	await create_tween().tween_property(self,"move_speed",0,duration).finished
	await get_tree().create_timer(charge_recovery).timeout
	move_speed = initial_move_speed
	calib_movedir(true)
	is_charging = false
