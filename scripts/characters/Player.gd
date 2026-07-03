extends CharacterBody2D
class_name TetherPlayer

# 脚本说明：
# - player_id：玩家编号。任务点、卡牌牌堆和 HUD 都通过它判断这是玩家 1 还是玩家 2。
# - move_speed：该角色的基础移动速度。主控制器会读取它，再结合弹性连线阻力计算最终速度。
# - player_color：角色视觉颜色。颜色本身放在 tscn 的 Polygon2D 上，脚本只在运行时同步导出值，方便编辑器里调整。
# - control_enabled：是否允许该角色响应输入。游戏结束或特殊状态时主控制器可以关闭它。
# - move_speed_multiplier：卡牌临时移动倍率。A2 撞击怪物会降低它，状态结束后恢复为 1。
# - original_collision_mask：玩家初始碰撞掩码。A6 穿墙结束时用它恢复普通碰撞。
# - wall_phase_enabled：是否处于卡牌穿墙状态。开启时玩家不再和墙/普通障碍碰撞。
# - death_animation_placeholder_seconds：当前没有正式死亡动画资源时，脚本用这个时长播放一个可替换的占位反馈。
# - auto_finish_death_animation_placeholder：为 false 时，外部 AnimationPlayer 需要在动画末尾调用 finish_death_animation()。
# - death_animation_playing：死亡动画是否正在等待结束信号，防止 Gameover UI 提前出现。
# - death_animation_tween：占位死亡反馈 Tween。未来替换成正式动画时可以关闭 auto_finish。
# - visual_base_scale/visual_base_modulate：记录视觉节点初始状态，Try again 时完整恢复。
# - visual_polygon：角色可编辑的白模/色块节点引用。它在 Player.tscn 中存在，不由脚本创建。
# - collision_shape：角色碰撞体节点引用。它在 Player.tscn 中存在，用来保证玩家互相、玩家和肉体、玩家和场景障碍不重叠。
# - _ready()：角色进入场景后同步颜色，保证实例化后的导出颜色能反映到视觉节点。
# - get_player_id()：返回玩家编号，任务点通过这个方法判断能否被当前玩家拾取。
# - get_current_move_speed()：返回当前基础速度乘卡牌倍率后的实际速度。
# - read_input_vector()：优先通过全局 InputRouter 读取玩家专属键盘/手柄输入，并返回已经归一化的移动意图。
# - move_with_velocity(requested_velocity)：让角色按主控制器算出的速度移动；真正的阻力、牵引和摄像机限制都由主控制器决定。
# - apply_tether_motion(motion)：让连线控制器对角色施加一小段位置修正，并优先使用碰撞移动避免穿过场景障碍。
# - set_move_speed_multiplier(multiplier)：设置卡牌移动倍率。
# - set_wall_phase_enabled(enabled)：切换玩家是否穿过墙和普通障碍。
# - reset_card_motion_state()：恢复所有卡牌施加在玩家移动/碰撞上的临时状态。
# - play_death_animation()：死亡流程入口。发出 started 信号，并播放当前占位动画或等待外部动画。
# - finish_death_animation()：死亡动画真正结束时调用；主控制器收到后才允许 HUD 显示 Gameover。
# - reset_death_animation_state()：Try again 时清理死亡动画残留并恢复视觉节点。
# - set_control_enabled(enabled)：切换角色是否可控，同时在禁用时清空速度，避免游戏结束后继续滑动。
# - _update_visual_color()：把导出的 player_color 应用到 tscn 里的视觉节点。

signal death_animation_started(player_id: int)
signal death_animation_finished(player_id: int)

@export var player_id := 1
@export var move_speed := 200
@export var player_color := Color(0.2, 0.6, 1.0, 1.0)
@export var death_animation_placeholder_seconds := 0.35
@export var auto_finish_death_animation_placeholder := true

var control_enabled := true
var move_speed_multiplier := 1.0
var original_collision_mask := 0
var wall_phase_enabled := false
var death_animation_playing := false
var death_animation_tween: Tween
var visual_base_scale := Vector2.ONE
var visual_base_modulate := Color.WHITE

@onready var visual_polygon: Polygon2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	original_collision_mask = collision_mask
	if visual_polygon != null:
		visual_base_scale = visual_polygon.scale
		visual_base_modulate = visual_polygon.modulate
	_update_visual_color()


func get_player_id() -> int:
	return player_id


func get_current_move_speed() -> float:
	return move_speed * move_speed_multiplier


func read_input_vector() -> Vector2:
	if not control_enabled:
		return Vector2.ZERO

	var input_router := get_node_or_null("/root/InputRouter")
	if input_router != null and input_router.has_method("get_player_move_vector"):
		return input_router.get_player_move_vector(player_id)

	var left_action := "p%d_move_left" % player_id
	var right_action := "p%d_move_right" % player_id
	var up_action := "p%d_move_up" % player_id
	var down_action := "p%d_move_down" % player_id
	return Input.get_vector(left_action, right_action, up_action, down_action)


func move_with_velocity(requested_velocity: Vector2) -> void:
	if control_enabled:
		velocity = requested_velocity
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func apply_tether_motion(motion: Vector2) -> void:
	if motion.length() <= 0.001:
		return

	var collision := move_and_collide(motion)
	if collision != null:
		velocity = Vector2.ZERO


func set_move_speed_multiplier(multiplier: float) -> void:
	move_speed_multiplier = maxf(0.0, multiplier)


func set_wall_phase_enabled(enabled: bool) -> void:
	if wall_phase_enabled == enabled:
		return

	wall_phase_enabled = enabled
	if enabled:
		set_collision_mask_value(3, false)
	else:
		collision_mask = original_collision_mask


func reset_card_motion_state() -> void:
	set_move_speed_multiplier(1.0)
	set_wall_phase_enabled(false)


func play_death_animation() -> void:
	if death_animation_playing:
		return

	death_animation_playing = true
	set_control_enabled(false)
	death_animation_started.emit(player_id)

	if not auto_finish_death_animation_placeholder:
		return

	var duration := maxf(0.0, death_animation_placeholder_seconds)
	if duration <= 0.0:
		finish_death_animation.call_deferred()
		return

	_kill_death_animation_tween()
	if visual_polygon == null:
		await get_tree().create_timer(duration, true).timeout
		finish_death_animation()
		return

	death_animation_tween = create_tween()
	death_animation_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	death_animation_tween.tween_property(
		visual_polygon,
		"scale",
		visual_base_scale * 1.16,
		duration * 0.35
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	death_animation_tween.parallel().tween_property(
		visual_polygon,
		"modulate",
		Color(1.0, 0.32, 0.22, 1.0),
		duration * 0.35
	)
	death_animation_tween.tween_property(
		visual_polygon,
		"scale",
		visual_base_scale * 0.72,
		duration * 0.65
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	death_animation_tween.parallel().tween_property(
		visual_polygon,
		"modulate",
		Color(0.18, 0.18, 0.18, 1.0),
		duration * 0.65
	)
	death_animation_tween.finished.connect(finish_death_animation)


func finish_death_animation() -> void:
	if not death_animation_playing:
		return

	death_animation_playing = false
	death_animation_tween = null
	death_animation_finished.emit(player_id)


func reset_death_animation_state() -> void:
	death_animation_playing = false
	_kill_death_animation_tween()
	velocity = Vector2.ZERO
	if visual_polygon != null:
		visual_polygon.scale = visual_base_scale
		visual_polygon.modulate = visual_base_modulate
	_update_visual_color()


func set_control_enabled(enabled: bool) -> void:
	control_enabled = enabled
	if not control_enabled:
		velocity = Vector2.ZERO


func _kill_death_animation_tween() -> void:
	if death_animation_tween != null and death_animation_tween.is_valid():
		death_animation_tween.kill()
	death_animation_tween = null


func _update_visual_color() -> void:
	if visual_polygon != null:
		visual_polygon.color = player_color
