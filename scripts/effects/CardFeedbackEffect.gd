extends Node2D
class_name CardFeedbackEffect

# 脚本说明：
# - MODE_RING：环形反馈，适合范围伤害、断线、恢复、击退冲击波。
# - MODE_MARKER：跟随或定点标记，适合持续状态和命中反馈。
# - MODE_LINE：线段反馈，适合弹道、增伤传递和连线恢复。
# - MODE_SWEEP：摄像机视野扫光反馈，适合清场、冻结等屏幕范围效果。
# - mode：当前绘制模式，由 setup_* 方法设置。
# - lifetime：反馈存在时间。小于 0 表示持续存在，直到外部 queue_free。
# - age：反馈已存在时间。
# - primary_color：反馈主色。
# - start_radius/end_radius：环形或标记反馈的起止半径。
# - start_point/end_point：线段反馈的世界坐标端点。
# - local_rect：扫光反馈的本地矩形范围。
# - sweep_direction：扫光方向。
# - line_width：线条宽度。
# - follow_node：可选跟随目标。持续状态会跟随玩家、肉体或敌人。
# - text_label：可选文字标签，白模阶段直接标出效果名。
# - setup_ring(center, radius, color, duration, text)：创建环形反馈。
# - setup_marker(center, radius, color, duration, text)：创建标记反馈。
# - setup_line(start, end, color, duration, text)：创建线段反馈。
# - setup_sweep(world_rect, direction, color, duration, text)：创建摄像机范围扫光反馈。
# - set_follow_node(target)：让反馈跟随某个 Node2D。
# - _process(delta)：推进生命周期、跟随目标并重绘。
# - _draw()：根据模式绘制白模几何反馈。

const MODE_RING := "ring"
const MODE_MARKER := "marker"
const MODE_LINE := "line"
const MODE_SWEEP := "sweep"

var mode := MODE_RING
var lifetime := 0.5
var age := 0.0
var primary_color := Color.WHITE
var start_radius := 24.0
var end_radius := 96.0
var start_point := Vector2.ZERO
var end_point := Vector2.ZERO
var local_rect := Rect2(Vector2.ZERO, Vector2(100.0, 100.0))
var sweep_direction := Vector2.LEFT
var line_width := 6.0
var follow_node: Node2D
var text_label: Label


func setup_ring(center: Vector2, radius: float, color: Color, duration := 0.55, text := "") -> void:
	mode = MODE_RING
	global_position = center
	start_radius = maxf(8.0, radius * 0.28)
	end_radius = maxf(start_radius + 1.0, radius)
	primary_color = color
	lifetime = duration
	_setup_label(text, Vector2(-110.0, -end_radius - 34.0))


func setup_marker(center: Vector2, radius: float, color: Color, duration := 0.65, text := "") -> void:
	mode = MODE_MARKER
	global_position = center
	start_radius = maxf(8.0, radius * 0.75)
	end_radius = maxf(start_radius + 1.0, radius)
	primary_color = color
	lifetime = duration
	_setup_label(text, Vector2(-110.0, -end_radius - 34.0))


func setup_line(start: Vector2, finish: Vector2, color: Color, duration := 0.45, text := "") -> void:
	mode = MODE_LINE
	global_position = Vector2.ZERO
	start_point = start
	end_point = finish
	primary_color = color
	lifetime = duration
	var midpoint := (start_point + end_point) * 0.5
	_setup_label(text, midpoint + Vector2(-110.0, -34.0))


func setup_sweep(world_rect: Rect2, direction: Vector2, color: Color, duration := 0.55, text := "") -> void:
	mode = MODE_SWEEP
	global_position = world_rect.position
	local_rect = Rect2(Vector2.ZERO, world_rect.size)
	sweep_direction = direction.normalized()
	if sweep_direction.is_zero_approx():
		sweep_direction = Vector2.LEFT
	primary_color = color
	lifetime = duration
	_setup_label(text, local_rect.size * 0.5 + Vector2(-110.0, -20.0))


func set_follow_node(target: Node2D) -> void:
	follow_node = target


func _process(delta: float) -> void:
	if follow_node != null and is_instance_valid(follow_node):
		global_position = follow_node.global_position

	age += delta
	if lifetime > 0.0 and age >= lifetime:
		queue_free()
		return

	if text_label != null:
		text_label.modulate.a = _current_alpha()
	queue_redraw()


func _draw() -> void:
	var alpha := _current_alpha()
	match mode:
		MODE_RING:
			_draw_ring(alpha)
		MODE_MARKER:
			_draw_marker(alpha)
		MODE_LINE:
			_draw_line_feedback(alpha)
		MODE_SWEEP:
			_draw_sweep(alpha)


func _draw_ring(alpha: float) -> void:
	var progress := _progress()
	var radius := lerpf(start_radius, end_radius, progress)
	var color := Color(primary_color.r, primary_color.g, primary_color.b, alpha)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, color, line_width)
	draw_arc(Vector2.ZERO, radius * 0.72, 0.0, TAU, 96, Color(color.r, color.g, color.b, alpha * 0.5), line_width * 0.5)
	draw_circle(Vector2.ZERO, maxf(4.0, 12.0 * (1.0 - progress)), Color(color.r, color.g, color.b, alpha * 0.65))


func _draw_marker(alpha: float) -> void:
	var pulse := 0.5 + sin(age * 9.0) * 0.5
	var radius := lerpf(start_radius, end_radius, pulse)
	var color := Color(primary_color.r, primary_color.g, primary_color.b, alpha)
	draw_circle(Vector2.ZERO, radius * 0.45, Color(color.r, color.g, color.b, alpha * 0.18))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, color, line_width)
	draw_line(Vector2(-radius, 0.0), Vector2(radius, 0.0), color, line_width * 0.45)
	draw_line(Vector2(0.0, -radius), Vector2(0.0, radius), color, line_width * 0.45)


func _draw_line_feedback(alpha: float) -> void:
	var color := Color(primary_color.r, primary_color.g, primary_color.b, alpha)
	draw_line(start_point, end_point, color, line_width)
	var direction := end_point - start_point
	if direction.length() > 0.001:
		var head := end_point
		var normal := direction.normalized()
		var side := normal.orthogonal()
		draw_colored_polygon(PackedVector2Array([
			head,
			head - normal * 28.0 + side * 12.0,
			head - normal * 28.0 - side * 12.0,
		]), color)


func _draw_sweep(alpha: float) -> void:
	var base_color := Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.12)
	draw_rect(local_rect, base_color, true)
	draw_rect(local_rect, Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.8), false, line_width)

	var progress := _progress()
	if absf(sweep_direction.x) >= absf(sweep_direction.y):
		var band_width := local_rect.size.x * 0.18
		var from_x := local_rect.size.x + band_width
		var to_x := -band_width
		if sweep_direction.x > 0.0:
			from_x = -band_width
			to_x = local_rect.size.x + band_width
		var x := lerpf(from_x, to_x, progress)
		draw_rect(Rect2(Vector2(x - band_width * 0.5, 0.0), Vector2(band_width, local_rect.size.y)), Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.28), true)
	else:
		var band_height := local_rect.size.y * 0.18
		var from_y := local_rect.size.y + band_height
		var to_y := -band_height
		if sweep_direction.y > 0.0:
			from_y = -band_height
			to_y = local_rect.size.y + band_height
		var y := lerpf(from_y, to_y, progress)
		draw_rect(Rect2(Vector2(0.0, y - band_height * 0.5), Vector2(local_rect.size.x, band_height)), Color(primary_color.r, primary_color.g, primary_color.b, alpha * 0.28), true)


func _setup_label(text: String, local_position: Vector2) -> void:
	if text.is_empty():
		return

	text_label = Label.new()
	text_label.text = text
	text_label.size = Vector2(220.0, 40.0)
	text_label.position = local_position
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", 22)
	text_label.add_theme_color_override("font_color", Color.WHITE)
	text_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	text_label.add_theme_constant_override("shadow_offset_x", 2)
	text_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(text_label)


func _current_alpha() -> float:
	if lifetime <= 0.0:
		return 0.55 + sin(age * 6.0) * 0.18
	return clampf(1.0 - age / maxf(0.001, lifetime), 0.0, 1.0)


func _progress() -> float:
	if lifetime <= 0.0:
		return fmod(age * 0.65, 1.0)
	return clampf(age / maxf(0.001, lifetime), 0.0, 1.0)
