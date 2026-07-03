extends Area2D
class_name TaskPoint

# 脚本说明：
# - CardDeckScript：显式预加载卡牌脚本，用来兼容手动配置奖励时的类型常量。
# - task_point_claimed(point, player_id, reward_cards)：任务点被正确玩家拾取时发出，主控制器据此打开三选一卡牌奖励 UI。
# - assigned_player_id：指定能拾取该任务点的玩家编号。1 代表玩家 1，2 代表玩家 2，0 可作为后续扩展的双方可拾取。
# - reward_card_ids：手动奖励候选牌 ID。默认空数组表示交给 GameController 从对应玩家奖励池随机生成。
# - reward_card_names：手动奖励候选牌名称。它和 reward_card_ids 按索引一一对应。
# - reward_card_types：手动奖励候选牌类型。使用 attack 或 other，对应 HUD 类型显示。
# - reward_card_descriptions：手动奖励候选牌说明。HUD 选择按钮会显示这些说明，方便玩家做选择。
# - reward_label：显示在任务点上的短标签。节点放在 TaskPoint.tscn 中，便于后续改 UI 样式。
# - deactivate_after_pickup：拾取后是否关闭任务点。默认关闭，避免同一个任务点重复发牌。
# - claimed：任务点是否已经被拾取。它防止重复触发。
# - visual_polygon：任务点视觉节点引用。颜色变化用于显示已领取状态。
# - label_node：任务点文字节点引用。用于显示指定玩家和奖励信息。
# - _ready()：把任务点加入 task_points 组，连接碰撞信号，并刷新外观。
# - _on_body_entered(body)：玩家进入任务点时尝试领取；非玩家或错误玩家不会触发奖励。
# - try_claim(body)：集中处理领取规则、发信号和关闭任务点。
# - get_reward_cards()：把 tscn 中编辑的候选牌字段组装成标准卡牌字典数组；未配置时返回空数组。
# - _get_reward_value(values, index, fallback)：安全读取某个手动候选牌字段；字段缺失时使用 fallback。
# - _body_is_allowed_player(body)：判断碰到任务点的物体是否是允许拾取的玩家。
# - _set_claimed_visual()：领取后关闭碰撞监控并降低视觉亮度。
# - _refresh_label()：根据导出属性更新任务点上显示的短标签。

const CardDeckScript = preload("res://scripts/card/CardDeck.gd")

signal task_point_claimed(point: Node, player_id: int, reward_cards: Array)

@export var assigned_player_id := 1
@export var reward_card_ids := PackedStringArray()
@export var reward_card_names := PackedStringArray()
@export var reward_card_types := PackedStringArray()
@export var reward_card_descriptions := PackedStringArray()
@export var reward_label := "三选一奖励"
@export var deactivate_after_pickup := true

var claimed := false

@onready var visual_polygon: Polygon2D = $Visual
@onready var label_node: Label = $Label


func _ready() -> void:
	add_to_group("task_points")
	body_entered.connect(_on_body_entered)
	_refresh_label()


func _on_body_entered(body: Node) -> void:
	try_claim(body)


func try_claim(body: Node) -> void:
	if claimed or not _body_is_allowed_player(body):
		return

	var player_id: int = body.get_player_id()
	task_point_claimed.emit(self, player_id, get_reward_cards())
	if deactivate_after_pickup:
		claimed = true
		_set_claimed_visual()


func get_reward_cards() -> Array:
	var reward_cards: Array = []
	for index in range(reward_card_ids.size()):
		reward_cards.append(CardDeckScript.make_card(
			_get_reward_value(reward_card_ids, index, "reward_card_%d" % (index + 1)),
			_get_reward_value(reward_card_names, index, "奖励牌 %d" % (index + 1)),
			_get_reward_value(reward_card_types, index, CardDeckScript.CARD_TYPE_OTHER),
			_get_reward_value(reward_card_descriptions, index, "从任务点获得的候选卡牌。")
		))
	return reward_cards


func _get_reward_value(values: PackedStringArray, index: int, fallback: String) -> String:
	if index >= 0 and index < values.size() and not values[index].is_empty():
		return values[index]
	return fallback


func _body_is_allowed_player(body: Node) -> bool:
	if not body.has_method("get_player_id"):
		return false

	var touching_player_id: int = body.get_player_id()
	return assigned_player_id == 0 or touching_player_id == assigned_player_id


func _set_claimed_visual() -> void:
	set_deferred("monitoring",false)
	set_deferred("monitorable",false)
	if visual_polygon != null:
		visual_polygon.color = Color(0.35, 0.35, 0.35, 0.55)
	if label_node != null:
		label_node.text = "已领取"


func _refresh_label() -> void:
	if label_node == null:
		return

	var owner_text: String = "P%d" % assigned_player_id
	if assigned_player_id == 0:
		owner_text = "P1/P2"
	label_node.text = "%s %s" % [owner_text, reward_label]
