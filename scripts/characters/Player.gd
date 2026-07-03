extends CharacterBody2D
class_name TetherPlayer

# 脚本说明：
# - player_id：玩家编号。任务点、卡牌牌堆和 HUD 都通过它判断这是玩家 1 还是玩家 2。
# - move_speed：该角色的基础移动速度。主控制器会读取它，再结合弹性连线阻力计算最终速度。
# - player_color：角色视觉颜色。颜色本身放在 tscn 的 Polygon2D 上，脚本只在运行时同步导出值，方便编辑器里调整。
# - control_enabled：是否允许该角色响应输入。游戏结束或特殊状态时主控制器可以关闭它。
# - visual_polygon：角色可编辑的白模/色块节点引用。它在 Player.tscn 中存在，不由脚本创建。
# - collision_shape：角色碰撞体节点引用。它在 Player.tscn 中存在，用来保证玩家互相、玩家和肉体、玩家和场景障碍不重叠。
# - _ready()：角色进入场景后同步颜色，保证实例化后的导出颜色能反映到视觉节点。
# - get_player_id()：返回玩家编号，任务点通过这个方法判断能否被当前玩家拾取。
# - read_input_vector()：根据玩家编号读取对应输入方向，并返回已经归一化的移动意图。
# - move_with_velocity(requested_velocity)：让角色按主控制器算出的速度移动；真正的阻力、牵引和摄像机限制都由主控制器决定。
# - apply_tether_motion(motion)：让连线控制器对角色施加一小段位置修正，并优先使用碰撞移动避免穿过场景障碍。
# - set_control_enabled(enabled)：切换角色是否可控，同时在禁用时清空速度，避免游戏结束后继续滑动。
# - _update_visual_color()：把导出的 player_color 应用到 tscn 里的视觉节点。

@export var player_id := 1
@export var move_speed := 300.0
@export var player_color := Color(0.2, 0.6, 1.0, 1.0)

var control_enabled := true

@onready var visual_polygon: Polygon2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_update_visual_color()


func get_player_id() -> int:
	return player_id


func read_input_vector() -> Vector2:
	if not control_enabled:
		return Vector2.ZERO

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


func set_control_enabled(enabled: bool) -> void:
	control_enabled = enabled
	if not control_enabled:
		velocity = Vector2.ZERO


func _update_visual_color() -> void:
	if visual_polygon != null:
		visual_polygon.color = player_color
