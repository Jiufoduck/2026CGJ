extends Line2D

var p1fire = preload("res://assets/art/link/p1.png")
var p2fire = preload("res://assets/art/link/p2.png")

@export var fire_interval = 30
@export var fire_scale_start := 0.04
@export var fire_scale := 0.1

var _p1 := Vector2.ZERO
var _core := Vector2.ZERO
var _p2 := Vector2.ZERO

func _physics_process(_delta: float) -> void:
	if points.size() != 3:
		return
	var p1_pos = points[0]
	var core_pos = points[1]
	var p2_pos = points[2]
	_p1 = p1_pos
	_core = core_pos
	_p2 = p2_pos
	queue_redraw()

func _draw() -> void:
	_draw_fires(_core, _p1, p1fire)
	_draw_fires(_core, _p2, p2fire)

func _draw_fires(from: Vector2, to: Vector2, texture: Texture2D) -> void:
	var dist := from.distance_to(to)
	if dist < fire_interval:
		return
	var count := int(dist / fire_interval)
	for i in range(1, count + 1):
		var t := i / float(count + 1)
		var s := lerpf(fire_scale_start, fire_scale, t)
		var size := texture.get_size() * s
		var pos := from.lerp(to, t)
		draw_texture_rect(texture, Rect2(pos - size / 2.0, size), false)
