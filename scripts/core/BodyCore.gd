extends AnimatableBody2D
class_name BodyCore

# 脚本说明：
# - health_changed(current_health, max_health)：血量变化信号。HUD 监听它，把肉体血量放在醒目位置。
# - link_broken_started(seconds_left)：血量见底并断开连线时发出。HUD 用它显示 10 秒倒计时。
# - link_restored()：恢复连线时发出。HUD 和主控制器用它恢复正常显示。
# - game_over_requested()：断线超过允许时间后发出。主控制器收到后结束游戏。
# - damaged_by_enemy(amount, source_enemy)：肉体被敌人或敌人子弹伤害时发出。A3 反杀怪物会监听它。
# - max_health：肉体最大血量。恢复连线时会恢复到这个数值。
# - broken_game_over_seconds：断线后距离游戏结束的秒数。文档明确要求断开 10 秒游戏结束。
# - snapback_initial_speed：肉体挣脱 net 后回弹到连线中心的初始高速。
# - snapback_finish_speed：肉体接近连线中心时保留的低速，避免最后一段瞬移。
# - snapback_slow_distance：肉体距离连线中心小于这个距离后开始明显减速。
# - snapback_arrive_distance：肉体距离连线中心小于这个值时认为回弹完成。
# - current_health：肉体当前血量。受击减少，恢复连线时回满。
# - link_broken：当前连线是否已经断开。断开后 Line2D 隐藏，倒计时开始。
# - broken_seconds_left：断线后剩余倒计时秒数。它只在 link_broken 为 true 时递减。
# - game_over_requested_sent：断线倒计时归零后只允许发出一次 Gameover 请求，避免每帧重复触发。
# - last_motion_blocker：肉体尝试回到连线中心时，最近一次挡住它的物体；主控制器用它识别 net。
# - snapback_active：肉体是否正在从 net 中高速回弹到连线中心。
# - snapback_speed：当前回弹速度。启动时较高，接近中心时逐渐降低。
# - visual_polygon：肉体视觉节点引用。节点在 BodyCore.tscn 中编辑，脚本只更新颜色状态。
# - _ready()：初始化血量、信号和视觉状态。
# - _physics_process(delta)：断线状态下推进 10 秒倒计时，到 0 后请求游戏结束。
# - place_between(player_one_position, player_two_position)：把肉体放到两个玩家中点，满足“连线中心是受击点：肉体”的设定。
# - move_toward_position(target_position)：让肉体尝试回到目标点；如果被 net 挡住，就停在碰撞点并记录阻挡物。
# - start_snapback()：net 被挣脱时调用，启动初始高速、随后减速的回弹运动。
# - advance_snapback_to_position(target_position, delta)：按当前回弹速度朝连线中心移动一小段。
# - is_snapback_active()：返回肉体是否仍处于回弹状态。
# - take_hit(amount, source_enemy)：处理受击扣血；血量归零时断开连线并启动 10 秒倒计时。
# - force_break_link()：卡牌直接断线入口。它把肉体血量归零并启动断线倒计时。
# - restore_link()：恢复连线并回满血量，用于恢复连线卡。
# - reset_state()：Try again 时恢复肉体血量、连线、倒计时和 Gameover 请求锁。
# - is_link_active()：返回连线是否仍然存在，主控制器据此决定是否施加弹性牵引。
# - _break_link()：内部断线流程，集中设置状态和发信号。
# - _refresh_visual_state()：根据当前血量与断线状态更新肉体颜色。

signal health_changed(current_health: float, max_health: float)
signal link_broken_started(seconds_left: float)
signal link_restored
signal game_over_requested
signal damaged_by_enemy(amount: float, source_enemy: Node)

@export var max_health := 100.0
@export var broken_game_over_seconds := 10.0
@export var snapback_initial_speed := 1900.0
@export var snapback_finish_speed := 120.0
@export var snapback_slow_distance := 520.0
@export var snapback_arrive_distance := 6.0

var current_health := 100.0
var link_broken := false
var broken_seconds_left := 0.0
var game_over_requested_sent := false
var last_motion_blocker: Node
var snapback_active := false
var snapback_speed := 0.0

@onready var visual_polygon: Polygon2D = $Visual


func _ready() -> void:
	current_health = max_health
	link_broken = false
	broken_seconds_left = 0.0
	game_over_requested_sent = false
	health_changed.emit(current_health, max_health)
	_refresh_visual_state()


func _physics_process(delta: float) -> void:
	if not link_broken:
		return

	broken_seconds_left = maxf(0.0, broken_seconds_left - delta)
	link_broken_started.emit(broken_seconds_left)
	if broken_seconds_left <= 0.0 and not game_over_requested_sent:
		game_over_requested_sent = true
		game_over_requested.emit()


func place_between(player_one_position: Vector2, player_two_position: Vector2) -> void:
	last_motion_blocker = null
	snapback_active = false
	snapback_speed = 0.0
	global_position = (player_one_position + player_two_position) * 0.5


func move_toward_position(target_position: Vector2) -> Node:
	last_motion_blocker = null
	var motion: Vector2 = target_position - global_position
	if motion.length() <= 0.001:
		global_position = target_position
		return null

	var collision := move_and_collide(motion)
	if collision != null:
		last_motion_blocker = collision.get_collider()
	return last_motion_blocker


func start_snapback() -> void:
	last_motion_blocker = null
	snapback_active = true
	snapback_speed = snapback_initial_speed


func advance_snapback_to_position(target_position: Vector2, delta: float) -> Node:
	last_motion_blocker = null
	if not snapback_active:
		return move_toward_position(target_position)

	var to_target: Vector2 = target_position - global_position
	var distance: float = to_target.length()
	if distance <= snapback_arrive_distance:
		global_position = target_position
		snapback_active = false
		snapback_speed = 0.0
		return null
	if delta <= 0.0:
		return null

	var slow_ratio: float = clampf(distance / snapback_slow_distance, 0.0, 1.0)
	var target_speed: float = lerpf(snapback_finish_speed, snapback_initial_speed, slow_ratio)
	snapback_speed = lerpf(snapback_speed, target_speed, clampf(delta * 8.0, 0.0, 1.0))

	var motion: Vector2 = to_target.normalized() * minf(distance, snapback_speed * delta)
	var collision := move_and_collide(motion)
	if collision != null:
		last_motion_blocker = collision.get_collider()
		snapback_active = false
		snapback_speed = 0.0
		return last_motion_blocker

	if motion.length() >= distance - snapback_arrive_distance:
		global_position = target_position
		snapback_active = false
		snapback_speed = 0.0
	return null


func is_snapback_active() -> bool:
	return snapback_active


func take_hit(amount: float, source_enemy: Node = null) -> void:
	if amount <= 0.0 or link_broken:
		return

	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if source_enemy != null:
		damaged_by_enemy.emit(amount, source_enemy)
	_refresh_visual_state()
	if current_health <= 0.0:
		_break_link()


func force_break_link() -> void:
	if link_broken:
		return

	current_health = 0.0
	health_changed.emit(current_health, max_health)
	_break_link()


func restore_link() -> void:
	current_health = max_health
	link_broken = false
	broken_seconds_left = 0.0
	game_over_requested_sent = false
	health_changed.emit(current_health, max_health)
	link_restored.emit()
	_refresh_visual_state()


func reset_state() -> void:
	current_health = max_health
	link_broken = false
	broken_seconds_left = 0.0
	game_over_requested_sent = false
	last_motion_blocker = null
	snapback_active = false
	snapback_speed = 0.0
	health_changed.emit(current_health, max_health)
	_refresh_visual_state()


func is_link_active() -> bool:
	return not link_broken


func _break_link() -> void:
	if link_broken:
		return

	link_broken = true
	broken_seconds_left = broken_game_over_seconds
	game_over_requested_sent = false
	link_broken_started.emit(broken_seconds_left)
	_refresh_visual_state()


func _refresh_visual_state() -> void:
	if visual_polygon == null:
		return

	if link_broken:
		visual_polygon.color = Color(0.55, 0.55, 0.55, 1.0)
	elif current_health <= max_health * 0.35:
		visual_polygon.color = Color(1.0, 0.25, 0.2, 1.0)
	else:
		visual_polygon.color = Color(1.0, 0.82, 0.28, 1.0)
