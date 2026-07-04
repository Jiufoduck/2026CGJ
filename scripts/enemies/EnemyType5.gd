extends EnemyBase

class_name EnemyType5

const SoundCueScript = preload("res://scripts/audio/SoundCue.gd")

@export var charge_range = 200
@export var charge_startup = 1.0
@export var charge_recovery = 0.5

var initial_move_speed: float

var is_charging = false
var reset_flip_accum_time = 0

func _ready() -> void:
	super._ready()
	initial_move_speed = move_speed

func reset_flip(delta: float):
	reset_flip_accum_time += delta
	if reset_flip_accum_time < 0.25:
		return
	reset_flip_accum_time = 0
	if move_direction.x > 0:
		$Visual.flip_h = false
	elif move_direction.x < 0:
		$Visual.flip_h = true

func _physics_process(delta: float) -> void:
	var core = EnemyUtils.get_body_core()

	if not is_charging:
		var dir = core.global_position - global_position
		if dir.length() < charge_range:
			$Visual.play("charge_startup")
			do_charge()
		else:
			$Visual.play("chase")
			dir = dir.normalized()
			move_direction = EnemyUtils.force_left(dir)

	reset_flip(delta)
	#print($Visual.animation)
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
	SoundCueScript.play(self, &"snake_strike")
	$Visual.play("charging")

	# d = m / a
	# r = 1/2 * a * d^2
	# a = 2r / d^2
	# d = sqrt(2r / a)
	# m^2 / 2r = a
	# d = 2r / m


	var duration = 2 * charge_range / move_speed
	await create_tween().tween_property(self,"move_speed",0,duration).finished

	$Visual.play("charge_recovery")
	await get_tree().create_timer(charge_recovery).timeout
	move_speed = initial_move_speed
	calib_movedir(true)
	is_charging = false

	$Visual.play("chase")
