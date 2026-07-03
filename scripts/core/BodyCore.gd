extends AnimatableBody2D
class_name BodyCore

# 脚本说明：
# - health_changed(current_health, max_health)：血量变化信号。HUD 监听它，把肉体血量放在醒目位置。
# - link_broken_started(seconds_left)：血量见底并断开连线时发出。HUD 用它显示 10 秒倒计时。
# - link_restored()：恢复连线时发出。HUD 和主控制器用它恢复正常显示。
# - game_over_requested()：断线超过允许时间后发出。主控制器收到后结束游戏。
# - max_health：肉体最大血量。恢复连线时会恢复到这个数值。
# - broken_game_over_seconds：断线后距离游戏结束的秒数。文档明确要求断开 10 秒游戏结束。
# - current_health：肉体当前血量。受击减少，恢复连线时回满。
# - link_broken：当前连线是否已经断开。断开后 Line2D 隐藏，倒计时开始。
# - broken_seconds_left：断线后剩余倒计时秒数。它只在 link_broken 为 true 时递减。
# - visual_polygon：肉体视觉节点引用。节点在 BodyCore.tscn 中编辑，脚本只更新颜色状态。
# - _ready()：初始化血量、信号和视觉状态。
# - _physics_process(delta)：断线状态下推进 10 秒倒计时，到 0 后请求游戏结束。
# - place_between(player_one_position, player_two_position)：把肉体放到两个玩家中点，满足“连线中心是受击点：肉体”的设定。
# - take_hit(amount)：处理受击扣血；血量归零时断开连线并启动 10 秒倒计时。
# - restore_link()：恢复连线并回满血量，用于恢复连线卡。
# - is_link_active()：返回连线是否仍然存在，主控制器据此决定是否施加弹性牵引。
# - _break_link()：内部断线流程，集中设置状态和发信号。
# - _refresh_visual_state()：根据当前血量与断线状态更新肉体颜色。

signal health_changed(current_health: float, max_health: float)
signal link_broken_started(seconds_left: float)
signal link_restored
signal game_over_requested

@export var max_health := 100.0
@export var broken_game_over_seconds := 10.0

var current_health := 100.0
var link_broken := false
var broken_seconds_left := 0.0

@onready var visual_polygon: Polygon2D = $Visual


func _ready() -> void:
	current_health = max_health
	link_broken = false
	broken_seconds_left = 0.0
	health_changed.emit(current_health, max_health)
	_refresh_visual_state()


func _physics_process(delta: float) -> void:
	if not link_broken:
		return

	broken_seconds_left = maxf(0.0, broken_seconds_left - delta)
	link_broken_started.emit(broken_seconds_left)
	if broken_seconds_left <= 0.0:
		game_over_requested.emit()


func place_between(player_one_position: Vector2, player_two_position: Vector2) -> void:
	global_position = (player_one_position + player_two_position) * 0.5


func take_hit(amount: float) -> void:
	if amount <= 0.0 or link_broken:
		return

	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	_refresh_visual_state()
	if current_health <= 0.0:
		_break_link()


func restore_link() -> void:
	current_health = max_health
	link_broken = false
	broken_seconds_left = 0.0
	health_changed.emit(current_health, max_health)
	link_restored.emit()
	_refresh_visual_state()


func is_link_active() -> bool:
	return not link_broken


func _break_link() -> void:
	link_broken = true
	broken_seconds_left = broken_game_over_seconds
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
