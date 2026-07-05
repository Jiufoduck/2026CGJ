extends StaticBody2D
class_name NetObstacle

const SoundCue = preload("res://scripts/audio/SoundCue.gd")

# 脚本说明：
# - release_lag_distance：肉体和玩家连线中心拉开到这个距离后，网开始积累挣脱进度。
# - release_strain_seconds：持续拉扯达到这个时长后，网会被挣脱并不再阻挡肉体。
# - strain_decay_speed：拉扯不够时，挣脱进度回落的速度。
# - strain_progress：当前已经积累的挣脱进度。
# - released：网是否已经被挣脱。挣脱后碰撞关闭，肉体会回到连线中心。
# - initial_collision_layer/initial_collision_mask：记录网初始碰撞配置，Try again 后恢复。
# - initial_collision_disabled：记录碰撞体初始启用状态，避免重置时破坏场景配置。
# - collision_shape：网的碰撞形状，只在肉体移动时生效；玩家不会检测这个碰撞层。
# - visual_polygon：网的底色。挣脱进度越高，颜色越亮；挣脱后变淡。
# - initial_canvas_item_states：记录视觉子节点的初始可见性和颜色，Try again 后把破碎视觉完整还原。
# - _ready()：加入 net_obstacles 分组并刷新初始视觉。
# - apply_tether_strain(lag_distance, delta)：主控制器在肉体被网挡住时调用，用玩家和肉体的距离积累挣脱进度。
# - get_strain_ratio()：返回 0 到 1 的挣脱进度比例，供视觉和调试使用。
# - is_released()：返回网是否已经失效。
# - reset_state()：Try again 时恢复未挣脱状态和碰撞配置。
# - _reset_child_animations()：把网内所有动画节点停回初始帧，兼容后续替换成动画网资源。
# - _release()：关闭碰撞并刷新视觉。
# - _refresh_visual_state()：按挣脱进度更新网的颜色。

@export var release_lag_distance := 30.0
@export var release_strain_seconds := 2
@export var strain_decay_speed := 2

var strain_progress := 0.0
var released := false
var initial_collision_layer := 0
var initial_collision_mask := 0
var initial_collision_disabled := false
var initial_canvas_item_states := {}

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_polygon: Polygon2D = $Visual


func _ready() -> void:
	add_to_group("net_obstacles")
	initial_collision_layer = collision_layer
	initial_collision_mask = collision_mask
	if collision_shape != null:
		initial_collision_disabled = collision_shape.disabled
	_capture_initial_canvas_item_states(self)
	_refresh_visual_state()


func apply_tether_strain(lag_distance: float, delta: float) -> bool:
	if released or delta <= 0.0:
		return false

	if lag_distance >= release_lag_distance:
		var excess_ratio: float = clampf((lag_distance - release_lag_distance) / release_lag_distance, 0.0, 1.0)
		strain_progress = minf(release_strain_seconds, strain_progress + delta * (1.0 + excess_ratio * 1.5))
	else:
		strain_progress = maxf(0.0, strain_progress - delta * strain_decay_speed)

	if strain_progress >= release_strain_seconds:
		_release()
		return true

	_refresh_visual_state()
	return false


func get_strain_ratio() -> float:
	if release_strain_seconds <= 0.0:
		return 1.0
	return clampf(strain_progress / release_strain_seconds, 0.0, 1.0)


func is_released() -> bool:
	return released


func reset_state() -> void:
	strain_progress = 0.0
	released = false
	collision_layer = initial_collision_layer
	collision_mask = initial_collision_mask
	if collision_shape != null:
		collision_shape.disabled = initial_collision_disabled
		collision_shape.set_deferred("disabled", initial_collision_disabled)
	_restore_initial_canvas_item_states()
	_reset_child_animations()
	_refresh_visual_state()


func _capture_initial_canvas_item_states(node: Node) -> void:
	if node is CanvasItem:
		var canvas_item := node as CanvasItem
		initial_canvas_item_states[node.get_path()] = {
			"visible": canvas_item.visible,
			"modulate": canvas_item.modulate,
			"self_modulate": canvas_item.self_modulate,
		}

	for child in node.get_children():
		_capture_initial_canvas_item_states(child)


func _restore_initial_canvas_item_states() -> void:
	for path in initial_canvas_item_states.keys():
		var node := get_node_or_null(path) as CanvasItem
		if node == null:
			continue
		var state: Dictionary = initial_canvas_item_states[path]
		node.visible = bool(state.get("visible", node.visible))
		node.modulate = state.get("modulate", node.modulate)
		node.self_modulate = state.get("self_modulate", node.self_modulate)


func _reset_child_animations() -> void:
	_reset_animation_node(self)


func _reset_animation_node(node: Node) -> void:
	if node is AnimatedSprite2D:
		var sprite := node as AnimatedSprite2D
		sprite.stop()
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(&"default"):
			sprite.animation = &"default"
		sprite.frame = 0
		sprite.frame_progress = 0.0
	elif node is AnimationPlayer:
		var animation_player := node as AnimationPlayer
		animation_player.stop()
		if not animation_player.current_animation.is_empty():
			animation_player.seek(0.0, true)

	for child in node.get_children():
		_reset_animation_node(child)


func _release() -> void:
	released = true
	SoundCue.play(self, &"net_break")
	collision_layer = 0
	collision_mask = 0
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	_refresh_visual_state()


func _refresh_visual_state() -> void:
	if visual_polygon == null:
		return

	if released:
		visual_polygon.color = Color(0.36, 0.9, 1.0, 0.18)
		return

	var ratio := get_strain_ratio()
	visual_polygon.color = Color(0.1, 0.78, 0.95, 0.36).lerp(Color(1.0, 0.95, 0.35, 0.62), ratio)
